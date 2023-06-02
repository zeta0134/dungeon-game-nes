        .setcpu "6502"
        .include "collision.inc"
        .include "compression.inc"
        .include "entity.inc"
        .include "far_call.inc"
        .include "generators.inc"
        .include "kernel.inc"
        .include "level_logic.inc"
        .include "map.inc"
        .include "palette.inc"
        .include "saves.inc"
        .include "scrolling.inc"
        .include "sound.inc"
        .include "word_util.inc"
        .include "zeropage.inc"

        .segment "RAM"
MetatileIndex: .res 1

        .segment "PRGFIXED_E000"

; Loads a map into PRG RAM buffer, in preparation for drawing and gameplay
; maybe gameplay stuff
; Inputs:
;   R4: 16bit address of the map to load
; Clobbers: R0 - R4

.proc load_map
SourceAddr := R0
DestAddr := R2
MapAddr := R4
TilesetAddress := R6
MetatileCount := R8
TilesetChrBank := R9
        ; Save the original map's area flags, since we are about to update current_area
        far_call FAR_save_area_flags
        ; Now do just that
        ldy #MapHeader::area_id
        lda (MapAddr), y
        sta current_area
        far_call FAR_load_area_flags

        ; First read in the map's dimensions in tiles, and store them. The scrolling engine and
        ; several other game mechanics rely on these values
        ldy #MapHeader::width
        lda (MapAddr), y
        sta MapWidth
        ; the attribute width is half of the map width
        clc
        ror
        sta AttributeWidth
        ldy #MapHeader::height
        lda (MapAddr), y
        sta MapHeight

        far_call FAR_update_nav_lut_ptr

        ; First, decompress the first tileset. This will clobber MapData, but that's okay since we're about to
        ; overwrite it anyway
        lda #0
        sta MetatileIndex

        ldy #MapHeader::first_tileset
        lda (MapAddr), y
        sta TilesetAddress
        iny
        lda (MapAddr), y
        sta TilesetAddress+1
        jsr load_tileset
        lda TilesetChrBank
        sta DynamicChrBank

        ; now, add MetatileCount to MetatileIndex, allowing us to keep going with the next tileset
        lda MetatileCount
        clc
        adc MetatileIndex
        sta MetatileIndex

        ; And now the second tileset. Notably we don't reset the MetatileIndex here, allowing it to be unzipped
        ; immediately following the first
        ldy #MapHeader::second_tileset
        lda (MapAddr), y
        sta TilesetAddress
        iny
        lda (MapAddr), y
        sta TilesetAddress+1
        jsr load_tileset
        lda TilesetChrBank
        sta StaticChrBank

        ; the second tileset needs all of its CHR indexes adjusted to point to the proper 2k block, do that now
        jsr fix_second_tileset

        ; Next decompress the blocks of data, starting with the graphics map
        ldy #MapHeader::graphics_ptr
        lda (MapAddr), y
        sta SourceAddr
        iny
        lda (MapAddr), y
        sta SourceAddr+1
        st16 DestAddr, (MapData)
        jsr decompress

        ; then the collision map
        ldy #MapHeader::collision_ptr
        lda (MapAddr), y
        sta SourceAddr
        iny
        lda (MapAddr), y
        sta SourceAddr+1
        st16 DestAddr, (NavMapData)
        jsr decompress

        ; now for colors; first the background palette
        ldy #MapHeader::palette_ptr
        lda (MapAddr), y
        sta SourceAddr
        iny
        lda (MapAddr), y
        sta SourceAddr+1
        jsr load_palette

        ; and finally the attribute map
        ldy #MapHeader::attributes_ptr
        lda (MapAddr), y
        sta SourceAddr
        iny
        lda (MapAddr), y
        sta SourceAddr+1
        st16 DestAddr, (AttributeData)
        jsr decompress

        ; if this map specifies a music track, cue that up
        ldy #MapHeader::music_track
        lda (MapAddr), y
        cmp #$FF
        beq no_music_track
        jsr fade_to_track
no_music_track:

        ; ditto for a music variant
        ldy #MapHeader::music_variant
        lda (MapAddr), y
        cmp #$FF
        beq no_music_variant
        jsr play_variant
no_music_variant:

        ldy #MapHeader::distortion_index
        lda (MapAddr), y
        sta CurrentDistortion

        ldy #MapHeader::color_emphasis
        lda (MapAddr), y
        ; emphasis is stored as an unshifted value in map data, so we need to shift it into place
        asl
        asl
        asl
        asl
        asl
        ; then combine it with a standard ppumask for the playfield
        ora #$1E
        sta PlayfieldPpuMask

        ; load up the map's logic function, which will be called once per frame
        ldy #MapHeader::logic_function
        lda (MapAddr), y
        sta maplogic_ptr+0
        iny
        lda (MapAddr), y
        sta maplogic_ptr+1

        ; For now that is all.
        rts
.endproc

; Load a tilemap into memory. Important: This uses the map data area
; as scratch space! Make sure this is called when it is okay to clobber
; this area.
; Inputs:
;   R0: 16bit address of the tileset to load
.proc load_tileset
SourceAddr := R0
DestAddr := R2
TilesetAddress := R6
MetatileCount := R8
TilesetChrBank := R9
        ldy #0

        ; first, grab the chr bank and the metatile count, since we'll need it to unzip the data properly later
        ldy #0
        lda (TilesetAddress), y
        sta TilesetChrBank
        inc16 TilesetAddress

        lda (TilesetAddress), y
        sta MetatileCount
        inc16 TilesetAddress

        ; now TilesetAddress points at the decompression header; set that header up as the source
        lda TilesetAddress
        sta SourceAddr
        lda TilesetAddress+1
        sta SourceAddr+1
        ; set MapData up as the destination, and perform the decompression
        st16 DestAddr, (MapData)
        jsr decompress

        ; okay, now our tileset is in memory at MapData, but it's collapsed. We need to
        ; run through it one segment at a time and unzip it into its final location

        ; we'll stop when we reach MetatileCount, but that needs to include the previous
        ; tileset's count, if any
        lda MetatileCount
        clc
        adc MetatileIndex
        sta MetatileCount

        st16 SourceAddr, (MapData)
        ldx MetatileIndex
top_left_loop:
        lda (SourceAddr), y
        sta TilesetTopLeft, x
        inc16 SourceAddr
        inx
        cpx MetatileCount
        bne top_left_loop

        ldx MetatileIndex
top_right_loop:
        lda (SourceAddr), y
        sta TilesetTopRight, x
        inc16 SourceAddr
        inx
        cpx MetatileCount
        bne top_right_loop   

        ldx MetatileIndex
bottom_left_loop:
        lda (SourceAddr), y
        sta TilesetBottomLeft, x
        inc16 SourceAddr
        inx
        cpx MetatileCount
        bne bottom_left_loop

        ldx MetatileIndex
bottom_right_loop:
        lda (SourceAddr), y
        sta TilesetBottomRight, x
        inc16 SourceAddr
        inx
        cpx MetatileCount
        bne bottom_right_loop

        ldx MetatileIndex
attribute_loop:
        lda (SourceAddr), y
        sta TilesetAttributes, x
        inc16 SourceAddr
        inx
        cpx MetatileCount
        bne attribute_loop

        rts
.endproc

.proc fix_second_tileset
MetatileCount := R8
        ; start right after the first tileset, which is fine as is
        ldx MetatileIndex
loop:
        ; for each CHR entry in the second tileset, add 128 (by forcing the high bit to 1) so that
        ; it now references the second 2K CHR bank, instead of the first
        lda TilesetTopLeft, x
        ora #$80
        sta TilesetTopLeft, x

        lda TilesetTopRight, x
        ora #$80
        sta TilesetTopRight, x

        lda TilesetBottomLeft, x
        ora #$80
        sta TilesetBottomLeft, x

        lda TilesetBottomRight, x
        ora #$80
        sta TilesetBottomRight, x
        ; continue until we exhaust the entire buffer
        inx
        ; helpfully we still have MetatileCount from the 2nd tileset copy, so we can use that here
        cpx MetatileCount
        bne loop
        ; all done
        rts
.endproc

.proc load_palette
SourceAddr := R0
        ldy #0
loop:
        lda (SourceAddr), y
        sta BgPaletteBuffer, y
        iny
        cpy #16
        bne loop

        ; apply the hud gradient here
        ; (these colors are not usually seen)
        lda HudGradientBuffer + 0
        sta BgPaletteBuffer + 4
        lda HudGradientBuffer + 1
        sta BgPaletteBuffer + 8
        lda HudGradientBuffer + 2
        sta BgPaletteBuffer + 12

        lda #1
        sta BgPaletteDirty
        rts
.endproc

.proc load_entities
EntityStateFunc := R0
EntityTableAddr := R2
MapAddr := R4
EntityCount := R5
        ldy #MapHeader::entity_table_ptr
        lda (MapAddr), y
        sta EntityTableAddr
        iny
        lda (MapAddr), y
        sta EntityTableAddr+1

        ldy #0
        lda (EntityTableAddr), y
        sta EntityCount
        beq done ; if there are no entities to load, do nothing!
        inc16 EntityTableAddr
entity_loop:
        ; load the initial update function for this entity
        ; and attempt to spawn it
        ldy #0
        lda (EntityTableAddr), y
        sta EntityStateFunc
        inc16 EntityTableAddr
        lda (EntityTableAddr), y
        sta EntityStateFunc+1
        inc16 EntityTableAddr
        far_call FAR_spawn_entity
        ; should the spawn fail, it means our entity table is full.
        ; there is no need to continue, and we definitely should not
        ; set the other properties
        cpy #$FF
        beq done
        ; y now contains the new entity index; preserve it
        sty CurrentEntityIndex
        ; now load initial properties from the entity table, and apply them
        ; for now, this is just the starting tile coordinates
        ldy #0
        ldx CurrentEntityIndex
        lda (EntityTableAddr), y
        sta entity_table + EntityState::PositionX+1, x
        inc16 EntityTableAddr
        lda (EntityTableAddr), y
        sta entity_table + EntityState::PositionY+1, x
        inc16 EntityTableAddr
        ; zero out the other components of the position here
        lda #0
        sta entity_table + EntityState::PositionX, x
        sta entity_table + EntityState::PositionY, x
        ; all done; next!
        dec EntityCount
        bne entity_loop
done:
        rts
.endproc
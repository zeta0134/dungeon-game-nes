        .setcpu "6502"
        .include "collision.inc"
        .include "compression.inc"
        .include "far_call.inc"
        .include "map.inc"
        .include "palette.inc"
        .include "scrolling.inc"
        .include "word_util.inc"
        .include "zeropage.inc"

        .segment "PRGFIXED_E000"

.struct MapHeader
        width .byte
        height .byte
        graphics_ptr .word
        collision_ptr .word
        entrance_table_ptr .word
        exit_table_ptr .word
        first_tileset .word
.endstruct

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
TilesetChrBank := R9
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

        ; First, decompress the tileset. This will clobber MapData, but that's okay since we're about to
        ; overwrite it anyway
        ldy #MapHeader::first_tileset
        lda (MapAddr), y
        sta TilesetAddress
        iny
        lda (MapAddr), y
        sta TilesetAddress+1
        jsr load_tileset
        lda TilesetChrBank
        sta DynamicChrBank

        ; Next decompress the blocks of data, starting with the graphics map
        ldy #MapHeader::graphics_ptr
        lda (MapAddr), y
        sta SourceAddr
        iny
        lda (MapAddr), y
        sta SourceAddr+1
        st16 DestAddr, (MapData)
        jsr decompress

        ; And finally the collision map
        ldy #MapHeader::collision_ptr
        lda (MapAddr), y
        sta SourceAddr
        iny
        lda (MapAddr), y
        sta SourceAddr+1
        st16 DestAddr, (NavMapData)
        jsr decompress

        ; For now that is all, we need to make sure that worked.
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

        ; First things first, load in the palette data
        lda (TilesetAddress), y
        sta SourceAddr
        inc16 TilesetAddress
        lda (TilesetAddress), y
        sta SourceAddr+1
        inc16 TilesetAddress
        jsr load_palette

        ; next, grab the chr bank and the metatile count, since we'll need it to unzip the data properly later
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

        ; TODO: We want to eventually load two tilesets at once. The second one needs to get
        ; unzipped *after* the first one, so we need a way to set an offset for this routine.

        st16 SourceAddr, (MapData)
        ldx #0
top_left_loop:
        lda (SourceAddr), y
        sta TilesetTopLeft, x
        inc16 SourceAddr
        inx
        cpx MetatileCount
        bne top_left_loop

        ldx #0
top_right_loop:
        lda (SourceAddr), y
        sta TilesetTopRight, x
        inc16 SourceAddr
        inx
        cpx MetatileCount
        bne top_right_loop   

        ldx #0
bottom_left_loop:
        lda (SourceAddr), y
        sta TilesetBottomLeft, x
        inc16 SourceAddr
        inx
        cpx MetatileCount
        bne bottom_left_loop

        ldx #0
bottom_right_loop:
        lda (SourceAddr), y
        sta TilesetBottomRight, x
        inc16 SourceAddr
        inx
        cpx MetatileCount
        bne bottom_right_loop

        ldx #0
attribute_loop:
        lda (SourceAddr), y
        sta TilesetAttributes, x
        inc16 SourceAddr
        inx
        cpx MetatileCount
        bne attribute_loop

        rts
.endproc

.proc load_palette
SourceAddr := R0
        ldy #0
loop:
        lda (SourceAddr), y
        sta BgPaletteBuffer, y
        iny
        cpy #12
        bne loop

        ; FOR NOW, we will load in a static HUD palette
        lda #$30 ; ignored
        sta BgPaletteBuffer, y
        iny
        lda #$30
        sta BgPaletteBuffer, y
        iny
        lda #$00
        sta BgPaletteBuffer, y
        iny
        lda #$0F
        sta BgPaletteBuffer, y
        iny

        lda #1
        sta BgPaletteDirty
        rts
.endproc
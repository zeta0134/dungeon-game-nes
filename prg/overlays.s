.macpack longbranch     

        .setcpu "6502"
        .include "collision.inc"
        .include "far_call.inc"
        .include "kernel.inc"
        .include "map.inc"
        .include "mmc3.inc"
        .include "nes.inc"
        .include "overlays.inc"
        .include "ppu.inc"
        .include "scrolling.inc"
        .include "sound.inc"
        .include "tilebuffer.inc"
        .include "word_util.inc"
        .include "zeropage.inc"

; Most of this subsystem deals with map data, which means it needs to bank that
; data in. Thus, it can't easily be moved out of fixed memory. Use caution!
        .segment "PRGFIXED_E000"

; This is in precious fixed memory, so we'll eat some cycles to avoid
; duplicating a bunch of setup code
.proc _global_setup
MapAddr := R2
OverlayListAddr := R4  
        lda TargetMapAddr
        sta MapAddr
        lda TargetMapAddr+1
        sta MapAddr+1

        ldy #MapHeader::overlay_list
        lda (MapAddr), y
        sta OverlayListAddr
        iny
        lda (MapAddr), y
        sta OverlayListAddr + 1

        rts
.endproc

; event_id in A
; clobbers a bunch of stuff
; returns overlay index in A, metadata in X
; on failure, A is set to $FF
.proc _find_overlay
EventId := R0
MapAddr := R2
OverlayListAddr := R4
Length := R6
OverlayIndex := R7
OverlayMetadata := R8
MetadataMatch := R9
MetadataMask := R10
        access_data_bank TargetMapBank
        jsr _global_setup

        ldy #0
        sty OverlayIndex
        lda (OverlayListAddr), y
        sta Length
        iny
loop:
        ; skip past the overlay pointer
        iny
        iny
        ; is this the event ID we seek?
        lda (OverlayListAddr), y
        cmp EventId
        bne event_mismatch
        ; does this match the conditions we asked for?
        iny
        lda (OverlayListAddr), y
        and MetadataMask
        cmp MetadataMatch
        bne metadata_mismatch
        ; we've found our overlay! Gather the data and return it
        sta OverlayMetadata
        jmp finish_and_return
event_mismatch:
        ; skip over the event ID
        iny
metadata_mismatch:
        ; skip over the metadata byte
        iny
        ; move on to the next overlay
        inc OverlayIndex
        dec Length
        bne loop
no_overlay_found:
        ; play an error buzz, as this is almost certianly a level design bug and not the fault of the player
        st16 R0, sfx_error_buzz
        jsr play_sfx_noise
        ; load $FF into all variables and fall through to the exit
        lda #$FF
        sta OverlayIndex
        sta OverlayMetadata
        ; fall through
finish_and_return:
        restore_previous_bank
        rts
.endproc

; event_id in A
; clobbers a bunch of stuff
; returns overlay index in A, metadata in X
; on failure, A is set to $FF
.proc find_overlay_to_set
EventId := R0
MapAddr := R2
OverlayListAddr := R4
Length := R6
OverlayIndex := R7
OverlayMetadata := R8
MetadataMatch := R9
MetadataMask := R10
        sta EventId
        lda #%10000000
        sta MetadataMask
        lda #%10000000
        sta MetadataMatch
        jsr _find_overlay
        lda OverlayIndex
        ldx OverlayMetadata
        rts
.endproc

; event_id in A
; clobbers a bunch of stuff
; returns overlay index in A, metadata in X
; on failure, A is set to $FF
.proc find_overlay_to_unset
EventId := R0
MapAddr := R2
OverlayListAddr := R4
Length := R6
OverlayIndex := R7
OverlayMetadata := R8
MetadataMatch := R9
MetadataMask := R10
        sta EventId
        lda #%10000000
        sta MetadataMask
        lda #0
        sta MetadataMatch
        jsr _find_overlay
        lda OverlayIndex
        ldx OverlayMetadata
        rts
.endproc

; overlay index in the A register
; clobbers a bunch of stuff
.proc apply_overlay_by_index
OverlayIndex := R0
MapAddr := R2
OverlayAddr := R2 ; by the time we write here we're done with the map header
OverlayListAddr := R4
        sta OverlayIndex
        access_data_bank TargetMapBank
        jsr _global_setup

        ldy #0
        ; The first byte of the overlay list is the number of entries
        ; Sanity check: does the requested overlay actually exist?
        lda OverlayIndex
        cmp (OverlayListAddr), y
        bcs fail_and_bail
        ; The remainder of the list is comprised of 4-byte overlay entries. We
        ; will NEVER have more than 64 overlays in a single room. That's insane.
        ; Convert accordingly
        asl ; * 2
        asl ; * 4
        tay
        iny ; + 1 to move past the length byte
        lda (OverlayListAddr), y
        sta OverlayAddr
        iny
        lda (OverlayListAddr), y
        sta OverlayAddr+1

        jsr process_overlay_list

        jmp finish_up
fail_and_bail:
        st16 R0, sfx_error_buzz
        jsr play_sfx_noise
finish_up:
        restore_previous_bank
all_done:
        rts
.endproc

.struct OverlayTileDef
        tile_x .byte
        tile_y .byte
        graphics_tile .byte
        nav_tile .byte
        attributes .byte
.endstruct

.proc process_overlay_list
OverlayAddr := R2
NumTiles := R10
        ldy #0
        lda (OverlayAddr), y
        ; safety: if this overlay has 0 tiles (?) we're done (???!)
        beq done
        sta NumTiles
        inc16 OverlayAddr
loop:
        jsr process_single_tile
        add16b OverlayAddr, #.sizeof(OverlayTileDef)
        dec NumTiles
        bne loop
done:
        rts
.endproc

; here OverlayAddr is assumed to point to the first byte of the tile definition
.proc process_single_tile
; Used by tilebuffer_queue_tile
TilePosX := R0
TilePosY := R1
; provided by the list processor, do not clobber
OverlayAddr := R2
; used internally, also we may clobber freely
TileX := R4
TileY := R5
TileAddr := R7
AttributeBits := R9
        ldy #OverlayTileDef::tile_x
        lda (OverlayAddr), y
        sta TileX
        sta TilePosX
        ldy #OverlayTileDef::tile_y
        lda (OverlayAddr), y
        sta TileY
        sta TilePosY

        ; as a light optimizaiton, do the nav tile bits first
        ; note: clobbers A, Y
        nav_map_index TileX, TileY, TileAddr
        ldy #OverlayTileDef::nav_tile
        lda (OverlayAddr), y
        ldy #0
        sta (TileAddr), y

        ; here we can do the same as the macro: subtract the difference between the nav
        ; map and the graphics map to obtain the address of the equivalent graphics tile
        sec
        lda TileAddr
        sbc #<(NavMapData - MapData)
        sta TileAddr
        lda TileAddr+1
        sbc #>(NavMapData - MapData)
        sta TileAddr+1

        ; Now apply that
        ldy #OverlayTileDef::graphics_tile
        lda (OverlayAddr), y
        ldy #0
        sta (TileAddr), y

        ; Finally deal with attributes (yuck!)
        ldy #OverlayTileDef::attributes
        lda (OverlayAddr), y
        sta AttributeBits
        jsr set_tile_attribute

        ; Now all we have to do is queue up the tile
        jsr tilebuffer_queue_tile

        rts
.endproc

attribute_mask_lut:
        .byte %00000011
        .byte %00001100
        .byte %00110000
        .byte %11000000

attribute_inverted_mask_lut:
        .byte %11111100
        .byte %11110011
        .byte %11001111
        .byte %00111111

attribute_equivalence_lut:
        .byte %00000000
        .byte %01010101
        .byte %10101010
        .byte %11111111

; Note: clobbers TileX and TileY. Best to run this last.
.proc set_tile_attribute
OverlayAddr := R2
TileX := R4
TileY := R5
AttributeByteAddr := R7
AttributeBits := R9
        ; Divide both the map tile by 2 so that
        ; we address the 32x32 region that the 16x16 tile belongs to
        lda TileY
        lsr
        sta AttributeByteAddr+0
        lda #0
        sta AttributeByteAddr+1

        lda MapWidth ; in 16x16 tiles
        lsr ; now in 32x32 tiles
        ; Now multiply the Y coordinate by the effective attribute width
        lsr ; once more to prime the loop
attr_mul_loop:
        asl AttributeByteAddr+0
        rol AttributeByteAddr+1
        lsr
        bcc attr_mul_loop
        ; Add in the X coord, which cannot carry due to width being a power of 2
        lda TileX
        lsr
        clc
        adc AttributeByteAddr+0
        sta AttributeByteAddr+0
        ; Now add this to AttributeData...
        add16w AttributeByteAddr, #AttributeData

        ; Prep: isolate the 2 attribute bits and apply them uniformly to the whole byte 
        lda AttributeBits
        and #%00000011
        tax
        lda attribute_equivalence_lut, x
        sta AttributeBits
        ; Now, using the low bits of 16x16 TileX and TileY,
        ; figure out which of the 4 attribute slots we'll be
        ; using for this tile update
        lda #0
        lsr TileY
        rol 
        lsr TileX
        rol
        tax
        ; First mask out the bits we want to apply, so we only apply to that slot
        lda attribute_mask_lut, x
        and AttributeBits
        sta AttributeBits
        ; Next mask out the target byte, removing the bits we are about to apply
        ldy #0
        lda (AttributeByteAddr), y
        and attribute_inverted_mask_lut, x
        ; And finally combine
        ora AttributeBits
        sta (AttributeByteAddr), y

        rts
.endproc
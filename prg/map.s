        .setcpu "6502"
        .include "compression.inc"
        .include "scrolling.inc"
        .include "word_util.inc"
        .include "zeropage.inc"

.scope PRGLAST_E000
        .segment "PRGLAST_E000"
        ;.org $e000

.export load_map, load_tileset

.struct MapHeader
        width .byte
        height .byte
        graphics_ptr .word
        collision_ptr .word
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

        ; Next decompress the blocks of data, starting with the graphics map
        ldy #MapHeader::graphics_ptr
        lda (MapAddr), y
        sta SourceAddr
        iny
        lda (MapAddr), y
        sta SourceAddr+1
        st16 DestAddr, (MapData)
        jsr decompress

        ; For now that is all, we need to make sure that worked.
        rts
.endproc

; Load a tilemap into memory; these always have a fixed size of 256 bytes
; Inputs:
;   R0: 16bit address of the map to load
.proc load_tileset
        ldy #$00
loop:
        lda (R0),y
        sta TilesetData,y
        iny
        bne loop
        rts
.endproc

.endscope
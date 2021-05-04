        .setcpu "6502"
        .include "scrolling.inc"
        .include "word_util.inc"
        .include "zeropage.inc"

.scope PRGLAST_E000
        .segment "PRGLAST_E000"
        ;.org $e000

.export load_map, load_tileset

; Loads a map into PRG RAM buffer, in preparation for drawing and gameplay
; maybe gameplay stuff
; Inputs:
;   R4: 16bit address of the map to load
; Clobbers: R0 - R4

.proc load_map
TempHeight := R0
TempWidth := R1
DestAddr := R2
SourceAddr := R4
        ldy #$00 ; we'll use indirect mode, but without an offset
        lda (SourceAddr),y
        sta MapWidth
        sta TempHeight
        clc
        ror
        sta AttributeWidth
        inc16 SourceAddr
        lda (SourceAddr),y
        sta MapHeight
        sta TempWidth
        inc16 SourceAddr
        st16 DestAddr, (MapData)
loop:
        ; copy in one byte
        lda (SourceAddr),y
        sta (DestAddr),y
        inc16 SourceAddr
        inc16 DestAddr
        ; check MapWidth
        dec TempWidth
        bne loop
        ; reload MapWidth and check MapHeight
        lda MapWidth
        sta TempWidth
        dec TempHeight
        bne loop
        ; all done
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
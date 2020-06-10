        .setcpu "6502"
        .include "nes.inc"
        .include "word_util.inc"
        .include "zeropage.inc"

.scope PRGLAST_E000
        .segment "PRGLAST_E000"
        ;.org $e000

.export draw_row
.export draw_col

; Draws a run of an upper row of 16x16 metatiles
; Inputs:
;   R0: 16bit starting address (map tiles)
;   R2: 16bit chrmap address (base)
;   R4: 8bit tiles to copy
;   PPUADDR: nametable destination
; Note: PPUCTRL should be set to VRAM+1 mode before calling

; Optimization note: if we can decode tile index data into a
; consistent target address, we can do an absolute,y index, and save
; 2 cycles per 8x8 tile over storing the address in zero page

.proc draw_row
        clc
column_loop:
        ldy #$00
        lda (R0),y ; a now holds the tile index
        asl a
        asl a ; a now holds an offset into the chrmap for this tile
        tay
        lda (R2),y ; a now holds CHR index of the top-left tile
        sta PPUDATA
        iny
        lda (R2),y ; a now holds CHR index of the top-right tile
        sta PPUDATA
        inc16 R0
        dec R4
        bne column_loop
        rts
.endproc



.proc draw_col
        clc
row_loop:
        ldy #$00
        lda (R0),y ; a now holds the tile index
        asl a
        asl a ; a now holds an offset into the chrmap for this tile
        tay 
        lda (R2), y
        sta PPUDATA
        iny
        iny
        lda (R2), y
        sta PPUDATA
        add16 R0, #64
        dec R4
        bne row_loop
        rts
.endproc

.endscope
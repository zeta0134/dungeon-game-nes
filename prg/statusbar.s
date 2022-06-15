        .setcpu "6502"
        .include "statusbar.inc"
        .include "nes.inc"
        .include "ppu.inc"

        .segment "PRGFIXED_E000"


BLANK = $00
FILL = $00
BORDER_ML = $73
BORDER_BL = $70
BORDER_BM = $72
BORDER_MR = $63
BORDER_BR = $71
BORDER_TL = $60
BORDER_TM = $62
BORDER_TR = $61

basic_hud:
        .incbin "../art/raw_chr/basic_hud.map"

.proc init_statusbar
        ; top row
        lda #(OBJ_0000 | BG_1000)
        sta PPUCTRL
        set_ppuaddr #$2380
        ldx #0
top_row_loop:
        lda basic_hud, x
        sta PPUDATA
        inx
        cpx #64
        bne top_row_loop
        set_ppuaddr #$2780
bottom_row_loop:
        lda basic_hud, x
        sta PPUDATA
        inx
        cpx #128
        bne bottom_row_loop
        ; finally, set the attribute for this whole status region to palette 3
        set_ppuaddr #$23F8
        lda #$FF
        .repeat 8
        sta PPUDATA
        .endrepeat

        set_ppuaddr #$27F8
        lda #$FF
        .repeat 8
        sta PPUDATA
        .endrepeat
        ; done with basic setup
        rts
.endproc

.proc demo_init_statusbar
        ; first, blank out this whole region
        lda #(OBJ_0000 | BG_1000)
        sta PPUCTRL
        set_ppuaddr #$2380
        ldx #32*2
        lda #BLANK
loop_top_half:
        sta PPUDATA
        dex
        bne loop_top_half   

        set_ppuaddr #$2780
        ldx #32*2
        lda #BLANK
loop_bottom_half:
        sta PPUDATA
        dex
        bne loop_bottom_half

        ; now, draw a little portrait border
        set_ppuaddr #$2382
        lda #BORDER_TL
        sta PPUDATA
        lda #BORDER_TM
        sta PPUDATA
        sta PPUDATA
        lda #BORDER_TR
        sta PPUDATA
        ; and a larger blank region, to imply we have some plan (we don't yet)
        lda #BORDER_TL
        sta PPUDATA
        ldx #22
        lda #BORDER_TM
loop1:
        sta PPUDATA
        dex
        bne loop1   
        lda #BORDER_TR
        sta PPUDATA

        set_ppuaddr #$23A2
        lda #BORDER_ML
        sta PPUDATA
        lda #FILL
        sta PPUDATA
        sta PPUDATA
        lda #BORDER_MR
        sta PPUDATA

        lda #BORDER_ML
        sta PPUDATA
        ldx #22
        lda #FILL
loop2:
        sta PPUDATA
        dex
        bne loop2
        lda #BORDER_MR
        sta PPUDATA

        set_ppuaddr #$2782
        lda #BORDER_ML
        sta PPUDATA
        lda #FILL
        sta PPUDATA
        lda #FILL
        sta PPUDATA
        lda #BORDER_MR
        sta PPUDATA

        lda #BORDER_ML
        sta PPUDATA
        ldx #22
        lda #FILL
loop3:
        sta PPUDATA
        dex
        bne loop3
        lda #BORDER_MR
        sta PPUDATA

        set_ppuaddr #$27A2
        lda #BORDER_BL
        sta PPUDATA
        lda #BORDER_BM
        sta PPUDATA
        sta PPUDATA
        lda #BORDER_BR
        sta PPUDATA

        lda #BORDER_BL
        sta PPUDATA
        ldx #22
        lda #BORDER_BM
loop4:
        sta PPUDATA
        dex
        bne loop4
        lda #BORDER_BR
        sta PPUDATA
        
        ; finally, set the attribute for this whole status region to palette 3
        set_ppuaddr #$23F8
        lda #$FF
        .repeat 8
        sta PPUDATA
        .endrepeat

        set_ppuaddr #$27F8
        lda #$FF
        .repeat 8
        sta PPUDATA
        .endrepeat

        rts
.endproc

        .setcpu "6502"
        .include "nes.inc"
        .include "ppu.inc"

.scope PRGLAST_E000
        .segment "PRGLAST_E000"

.export demo_init_statusbar

;BLANK = 128
;FILL = 129
;BORDER_ML = 130
;BORDER_BL = 131
;BORDER_BM = 132
;BORDER_MR = 133
;BORDER_BR = 134
;BORDER_TL = 135
;BORDER_TM = 136
;BORDER_TR = 137

BLANK = 3
FILL = 2
BORDER_ML = 4
BORDER_BL = 5
BORDER_BM = 6
BORDER_MR = 7
BORDER_BR = 8
BORDER_TL = 9
BORDER_TM = 10
BORDER_TR = 11

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

.endscope



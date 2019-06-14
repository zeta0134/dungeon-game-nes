        .setcpu "6502"
        .include "word_util.inc"
        .include "zeropage.inc"

.scope PRGLAST_E000
        .segment "PRGLAST_E000"
        ;.org $e000

.export initialize_oam

SHADOW_OAM = $0200
; offsets
OAM_Y_POS = 0
OAM_TILE = 1
OAM_ATTRIBUTES = 2
OAM_X_POS = 3

.proc initialize_oam
        st16 R0, (SHADOW_OAM)
        ldy #$0
loop:
        lda #$FF   ; y-position off screen
        sta (R0),y
        iny
        lda #$00   ; tile index = 0
        sta (R0),y
        iny
        sta (R0),y ; first palette, no attributes enabled
        iny
        sta (R0),y ; x-position: far left
        iny
        bne loop ; Continue until Y rolls back around to 0
        rts
.endproc

.endscope
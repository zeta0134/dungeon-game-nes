        .setcpu "6502"
        .include "word_util.inc"
        .include "zeropage.inc"

.scope PRGFIXED_E000
        .segment "PRGFIXED_E000"
        ;.org $e000

.export clear_memory

; Arguments:
; R0 - starting address (16bit)
; R2 - length (16bit)
.proc clear_memory
        ldy #0
        ; decrement once to start, since we exit when the counter reaches -1
        dec16 R2
loop:
        lda #0
        sta (R0),y
        inc16 R0
        dec16 R2 ; sets A to 0xFF
        cmp R2+1 ; check if the high byte has rolled around to 0xFF; if so, terminate the loop
        bne loop
        rts
.endproc

.endscope
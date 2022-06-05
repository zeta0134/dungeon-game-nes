        .setcpu "6502"
        .include "far_call.inc"
        .include "nes.inc"
        .include "mmc3.inc"

        .zeropage
TargetBank: .byte $00
CurrentBank: .byte $00
JumpTarget: .word $0000

        .segment "PRGFIXED_E000"

.proc launch_far_call
        ; preserve the current bank
        lda CurrentBank
        pha

        mmc3_select_bank 7, TargetBank

        lda TargetBank
        sta CurrentBank
        
        ; setup indirect jump to the far call address
        lda #>(return_from_indirect-1)
        pha
        lda #<(return_from_indirect-1)
        pha
        jmp (JumpTarget)
return_from_indirect:
        ; (rts removes return address)
        ; restore the original bank
        lda #(MMC3_BANKING_MODE | 7) ; select bank at 0xA000
        sta mmc3_bank_select_shadow
        sta MMC3_BANK_SELECT
        pla
        sta MMC3_BANK_DATA
        sta CurrentBank
finished:
        rts
.endproc

        .setcpu "6502"
        .include "nes.inc"
        .include "mmc3.inc"

.scope PRGLAST_E000
        .zeropage
TargetBank: .byte $00
CurrentBank: .byte $00
JumpTarget: .word $0000
.exportzp TargetBank, CurrentBank, JumpTarget

        .segment "PRGLAST_E000"
.export launch_far_call

.proc launch_far_call
        ; preserve the current bank
        lda CurrentBank
        pha
        ; switch to the target bank
        lda #(MMC3_BANKING_MODE | 7) ; select bank at 0xA000
        sta MMC3_BANK_SELECT
        lda TargetBank
        sta MMC3_BANK_DATA
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
        sta MMC3_BANK_SELECT
        pla
        sta MMC3_BANK_DATA
        sta CurrentBank
finished:
        rts
.endproc

.endscope
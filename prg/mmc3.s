        .setcpu "6502"
        .include "mmc3.inc"
        .include "nes.inc"

        .zeropage
mmc3_bank_select_shadow: .byte $00

        .segment "PRGFIXED_E000"

.proc initialize_mmc3
        ; Note: the high bits of MMC3_BANK_SELECT determine the mode.
        ; We have this at %10 on purpose, which puts CHR1 in 2k mode,
        ; and leaves both fixed banks at $C000 - $FFFF

        mmc3_select_bank $0, #$00 ; CHR 2K LOW
        mmc3_select_bank $1, #$00 ; CHR 2K HIGH
        mmc3_select_bank $2, #$1C ; CHR 1K A
        mmc3_select_bank $3, #$1D ; CHR 1K B
        mmc3_select_bank $4, #$1E ; CHR 1K C
        mmc3_select_bank $5, #$1F ; CHR 1K D

        mmc3_select_bank $6, #$00 ; PRG0
        mmc3_select_bank $7, #$00 ; PRG1

        ; Mirroring mode: vertical
        lda #$00
        sta MMC3_MIRRORING

        ; Enable PRG RAM
        lda #$80
        sta MMC3_RAM_PROTECT

        ; Disable IRQ interrupts for init
        sta MMC3_IRQ_DISABLE
        rts
.endproc

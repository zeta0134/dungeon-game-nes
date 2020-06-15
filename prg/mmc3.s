        .setcpu "6502"
        .include "mmc3.inc"
        .include "nes.inc"

.scope PRGLAST_E000
        .segment "PRGLAST_E000"
        ;.org $e000

.export initialize_mmc3

.proc initialize_mmc3
        ; Note: the high bits of MMC3_BANK_SELECT determine the mode.
        ; We leave these at 0 on purpose, which puts CHR0 in 2k mode,
        ; and leaves both fixed banks at $C000 - $FFFF
        
        lda #$00 ; CHR0_LOW
        sta MMC3_BANK_SELECT
        sta MMC3_BANK_DATA

        lda #$01 ; CHR0_HIGH
        sta MMC3_BANK_SELECT
        lda #$02
        sta MMC3_BANK_DATA

        lda #$02 ; CHR1_A
        sta MMC3_BANK_SELECT
        lda #$04
        sta MMC3_BANK_DATA

        lda #$03 ; CHR1_B
        sta MMC3_BANK_SELECT
        lda #$05
        sta MMC3_BANK_DATA

        lda #$04 ; CHR1_C
        sta MMC3_BANK_SELECT
        lda #$06
        sta MMC3_BANK_DATA

        lda #$05 ; CHR1_D
        sta MMC3_BANK_SELECT
        lda #$07
        sta MMC3_BANK_DATA

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

.endscope
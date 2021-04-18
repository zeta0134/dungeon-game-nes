        .setcpu "6502"
        .include "mmc3.inc"
        .include "nes.inc"

.scope PRGLAST_E000
        .segment "PRGLAST_E000"
        ;.org $e000

.export initialize_mmc3

.proc initialize_mmc3
        ; Note: the high bits of MMC3_BANK_SELECT determine the mode.
        ; We have this at %10 on purpose, which puts CHR1 in 2k mode,
        ; and leaves both fixed banks at $C000 - $FFFF
        
        lda #$82 ; CHR0_A
        sta MMC3_BANK_SELECT
        lda #$04
        sta MMC3_BANK_DATA

        lda #$83 ; CHR0_B
        sta MMC3_BANK_SELECT
        lda #$05
        sta MMC3_BANK_DATA

        lda #$84 ; CHR0_C
        sta MMC3_BANK_SELECT
        lda #$06
        sta MMC3_BANK_DATA

        lda #$85 ; CHR0_D
        sta MMC3_BANK_SELECT
        lda #$07
        sta MMC3_BANK_DATA

        lda #$80 ; CHR1_LOW
        sta MMC3_BANK_SELECT
        lda #$00
        sta MMC3_BANK_DATA

        lda #$81 ; CHR1_HIGH
        sta MMC3_BANK_SELECT
        lda #$02
        sta MMC3_BANK_DATA

        lda #$86 ; PRG0
        sta MMC3_BANK_SELECT
        lda #$00
        sta MMC3_BANK_DATA        

        lda #$87 ; PRG1
        sta MMC3_BANK_SELECT
        lda #$00
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
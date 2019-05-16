        .setcpu "6502"
        .include "nes.inc"
        .include "mmc3.inc"
        .include "globals.inc"

.scope PRGLAST_E000
        .segment "PRGLAST_E000"
        ;.org $e000


initialize_mmc3:
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

        ; Disable IRQ interrupts for init
        sta MMC3_IRQ_DISABLE
        rts

initialize_palettes:
        ; TEST: Set the palettes up with a nice pink for everything
        lda #$3F
        sta PPUADDR
        lda #$00
        sta PPUADDR

        lda #$25
        sta PPUDATA
        lda #$00
        sta PPUADDR
        sta PPUADDR
        rts

        .export start
start:
        jsr initialize_mmc3
        jsr initialize_palettes

loop_endlessly:
        jmp loop_endlessly

.endscope

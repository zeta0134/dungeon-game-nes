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

        ; Backgrounds
        lda #$3F
        sta PPUADDR
        lda #$00
        sta PPUADDR
        lda #$25
        sta PPUDATA
        lda #$15
        sta PPUDATA
        lda #$05
        sta PPUDATA
        lda #$0F
        sta PPUDATA

        ; Sprites
        lda #$3F
        sta PPUADDR
        lda #$11
        sta PPUADDR
        lda #$34
        sta PPUDATA
        lda #$14
        sta PPUDATA
        lda #$04
        sta PPUDATA

        ; Reset PPUADDR to 0,0
        lda #$00
        sta PPUADDR
        sta PPUADDR

        rts

initialize_ppu:
        ; enable NMI interrupts and 8x16 sprites
        lda #$A0
        sta PPUCTRL
        ; enable rendering everywhere
        lda #$1E
        sta PPUMASK
        rts

demo_oam_init:
        lda #30
        sta $0200 ;sprite[0].Y
        lda #01
        sta $0201 ;sprite[0].Tile + Nametable
        lda #$00
        sta $0202 ;sprite[0].Palette + Attributes
        lda #30
        sta $0203 ;sprite[0].X

        lda #30
        sta $0204 ;sprite[1].Y
        lda #01
        sta $0205 ;sprite[1].Tile + Nametable
        lda #$40
        sta $0206 ;sprite[1].Palette + Attributes
        lda #38
        sta $0207 ;sprite[1].X
        rts

        .export start
start:
        jsr initialize_mmc3
        jsr initialize_palettes
        jsr initialize_ppu
        jsr demo_oam_init


loop_endlessly:
        jmp loop_endlessly

.endscope

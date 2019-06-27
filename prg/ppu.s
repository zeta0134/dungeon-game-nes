        .setcpu "6502"
        .include "nes.inc"
        .include "ppu.inc"
        .include "word_util.inc"
        .include "zeropage.inc"

.scope PRGLAST_E000
        .segment "PRGLAST_E000"
        ;.org $e000

.export initialize_ppu
.export initialize_palettes

.proc initialize_ppu
        ; disable rendering
        lda #$00
        sta PPUMASK

        ; enable NMI interrupts and 8x16 sprites
        lda #$A0
        sta PPUCTRL

        ; Set PPUADDR to 0,0
        set_ppuaddr #$2000

        ; Zero out all four nametables
        st16 R0, ($1000)
        dec16 R0
loop:
        lda #0
        sta PPUDATA
        dec16 R0 ; sets A to 0xFF
        cmp R0+1
        bne loop

        ; Re-Set PPUADDR to 0,0
        lda #$00
        sta PPUADDR
        sta PPUADDR

        ; enable rendering everywhere
        lda #$1E
        sta PPUMASK
        rts
.endproc

.proc initialize_palettes
        ; TEST: Set the palettes up with a nice greyscale for everything

        ; disable rendering
        lda #$00
        sta PPUMASK

        ; Backgrounds
        set_ppuaddr #$3F00

        lda #$0F
        sta PPUDATA
        lda #$00
        sta PPUDATA
        lda #$10
        sta PPUDATA
        lda #$20
        sta PPUDATA
        

        ; Sprites
        set_ppuaddr #$3F11
        lda #$20
        sta PPUDATA
        lda #$10
        sta PPUDATA
        lda #$0F
        sta PPUDATA

        ; Reset PPUADDR to 0,0
        lda #$00
        sta PPUADDR
        sta PPUADDR

        rts
.endproc

.endscope
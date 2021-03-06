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

        ; enable NMI interrupts and 8x16 sprites
        lda #$A0
        sta PPUCTRL

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

        ; level regions use this greyscale thing
        lda #$2D
        sta PPUDATA
        lda #$00
        sta PPUDATA
        lda #$10
        sta PPUDATA
        lda #$20
        sta PPUDATA

        ; and this green thing

        lda #$09
        sta PPUDATA
        lda #$19
        sta PPUDATA
        lda #$29
        sta PPUDATA
        lda #$39
        sta PPUDATA

        ; and now also this "warm" thing

        lda #$06
        sta PPUDATA
        lda #$17
        sta PPUDATA
        lda #$27
        sta PPUDATA
        lda #$37
        sta PPUDATA        

        ; Sprites
        ; gray!
        set_ppuaddr #$3F11
        lda #$20
        sta PPUDATA
        lda #$10
        sta PPUDATA
        lda #$0F
        sta PPUDATA

        ; red!
        set_ppuaddr #$3F15
        lda #$36
        sta PPUDATA
        lda #$26
        sta PPUDATA
        lda #$06
        sta PPUDATA

        ; blue!
        set_ppuaddr #$3F19
        lda #$31
        sta PPUDATA
        lda #$21
        sta PPUDATA
        lda #$01
        sta PPUDATA

        ; green(ish)!
        set_ppuaddr #$3F1D
        lda #$39
        sta PPUDATA
        lda #$29
        sta PPUDATA
        lda #$09
        sta PPUDATA

        ; Reset PPUADDR to 0,0
        lda #$00
        sta PPUADDR
        sta PPUADDR

        rts
.endproc

.endscope
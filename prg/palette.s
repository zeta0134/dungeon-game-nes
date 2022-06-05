        .setcpu "6502"

        .include "nes.inc"
        .include "palette.inc"
        .include "ppu.inc"

        .zeropage

        .segment "RAM"
BgPaletteDirty: .res 1
ObjPaletteDirty: .res 1
BgPaletteBuffer: .res 16
ObjPaletteBuffer: .res 16

        .segment "PRGFIXED_E000"

.proc refresh_palettes
        lda BgPaletteDirty
        beq check_obj_palettes
        set_ppuaddr #$3F00
        .repeat 16, i
        lda BgPaletteBuffer+i
        sta PPUDATA
        .endrepeat
        lda #0
        sta BgPaletteDirty
check_obj_palettes:
        lda ObjPaletteDirty
        beq done
        set_ppuaddr #$3F10
        .repeat 16, i
        lda ObjPaletteBuffer+i
        sta PPUDATA
        .endrepeat
        lda #0
        sta BgPaletteDirty
done:
        rts
.endproc

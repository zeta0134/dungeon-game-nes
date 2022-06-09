        .setcpu "6502"

        .include "branch_util.inc"
        .include "nes.inc"
        .include "palette.inc"
        .include "ppu.inc"
        .include "vram_buffer.inc"
        .include "zeropage.inc"

        .zeropage

        .segment "RAM"
BgPaletteDirty: .res 1
ObjPaletteDirty: .res 1
BgPaletteBuffer: .res 16
ObjPaletteBuffer: .res 16
Brightness: .res 16

        .segment "PRGFIXED_E000"

white_palette:
        .byte $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30
        .byte $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30
        .byte $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30
        .byte $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30

light_palette_3:
        .byte $30, $31, $32, $33, $34, $35, $36, $37, $38, $39, $3a, $3b, $3c, $10, $10, $10
        .byte $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $10, $10
        .byte $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $10, $10
        .byte $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $10, $10

light_palette_2:
        .byte $20, $21, $22, $23, $24, $25, $26, $27, $28, $29, $2a, $2b, $2c, $00, $00, $00
        .byte $30, $31, $32, $33, $34, $35, $36, $37, $38, $39, $3a, $3b, $3c, $00, $00, $00
        .byte $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $10, $00, $00
        .byte $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $00, $00

light_palette_1:
        .byte $10, $11, $12, $13, $14, $15, $16, $17, $18, $19, $1a, $1b, $1c, $2d, $2d, $2d
        .byte $20, $21, $22, $23, $24, $25, $26, $27, $28, $29, $2a, $2b, $2c, $2d, $2d, $2d
        .byte $30, $31, $32, $33, $34, $35, $36, $37, $38, $39, $3a, $3b, $3c, $00, $2d, $2d
        .byte $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $2d, $2d

standard_palette:
        .byte $00, $01, $02, $03, $04, $05, $06, $07, $08, $09, $0a, $0b, $0c, $0f, $0e, $0f
        .byte $10, $11, $12, $13, $14, $15, $16, $17, $18, $19, $1a, $1b, $1c, $1d, $1e, $1f
        .byte $20, $21, $22, $23, $24, $25, $26, $27, $28, $29, $2a, $2b, $2c, $2d, $2e, $2f
        .byte $30, $31, $32, $33, $34, $35, $36, $37, $38, $39, $3a, $3b, $3c, $3d, $3e, $3f

dark_palette_1:
        .byte $2d, $0f, $0f, $0f, $0f, $0f, $0f, $0f, $0f, $0f, $0f, $0f, $0f, $0f, $0f, $0f
        .byte $00, $01, $02, $03, $04, $05, $06, $07, $08, $09, $0a, $0b, $0c, $0f, $0e, $0f
        .byte $10, $11, $12, $13, $14, $15, $16, $17, $18, $19, $1a, $1b, $1c, $1d, $1e, $1f
        .byte $10, $21, $22, $23, $24, $25, $26, $27, $28, $29, $2a, $2b, $2c, $2d, $2e, $2f

dark_palette_2:
        .byte $0f, $0f, $0f, $0f, $0f, $0f, $0f, $0f, $0f, $0f, $0f, $0f, $0f, $0f, $0f, $0f
        .byte $2d, $0f, $0f, $0f, $0f, $0f, $0f, $0f, $0f, $0f, $0f, $0f, $0f, $0f, $0f, $0f
        .byte $00, $01, $02, $03, $04, $05, $06, $07, $08, $09, $0a, $0b, $0c, $0f, $0e, $0f
        .byte $00, $11, $12, $13, $14, $15, $16, $17, $18, $19, $1a, $1b, $1c, $1d, $1e, $1f

dark_palette_3:
        .byte $0f, $0f, $0f, $0f, $0f, $0f, $0f, $0f, $0f, $0f, $0f, $0f, $0f, $0f, $0f, $0f
        .byte $0f, $0f, $0f, $0f, $0f, $0f, $0f, $0f, $0f, $0f, $0f, $0f, $0f, $0f, $0f, $0f
        .byte $2d, $0f, $0f, $0f, $0f, $0f, $0f, $0f, $0f, $0f, $0f, $0f, $0f, $0f, $0f, $0f
        .byte $2d, $01, $02, $03, $04, $05, $06, $07, $08, $09, $0a, $0b, $0c, $0f, $0e, $0f

black_palette:
        .byte $0f, $0f, $0f, $0f, $0f, $0f, $0f, $0f, $0f, $0f, $0f, $0f, $0f, $0f, $0f, $0f
        .byte $0f, $0f, $0f, $0f, $0f, $0f, $0f, $0f, $0f, $0f, $0f, $0f, $0f, $0f, $0f, $0f
        .byte $0f, $0f, $0f, $0f, $0f, $0f, $0f, $0f, $0f, $0f, $0f, $0f, $0f, $0f, $0f, $0f
        .byte $0f, $0f, $0f, $0f, $0f, $0f, $0f, $0f, $0f, $0f, $0f, $0f, $0f, $0f, $0f, $0f        

brightness_table:
        .word black_palette
        .word dark_palette_3
        .word dark_palette_2
        .word dark_palette_1
        .word standard_palette
        .word light_palette_1
        .word light_palette_2
        .word light_palette_3
        .word white_palette

; call with desired brightness in a
.proc set_brightness
        sta Brightness
        lda #1
        sta BgPaletteDirty
        sta ObjPaletteDirty
        rts
.endproc

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

.proc refresh_palettes_gameloop
PalAddr := R0
PalIndex := R2
        lda BgPaletteDirty
        ora ObjPaletteDirty
        jeq done

        lda Brightness
        asl
        tax
        lda brightness_table, x
        sta PalAddr
        lda brightness_table+1, x
        sta PalAddr+1

        lda BgPaletteDirty
        beq check_obj_palette

        write_vram_header_imm $3F00, #16, VRAM_INC_1
        lda #0
        sta PalIndex
bg_loop:
        ; for the first entry, always use the global BG color
        ldx #0
        ldx PalIndex           ; From the original buffer
        ldy BgPaletteBuffer, x ; Grab a palette color
        lda (PalAddr), y       ; And use it to index the brightness table we picked
        ldx VRAM_TABLE_INDEX
        sta VRAM_TABLE_START,x
        inc VRAM_TABLE_INDEX
        inc PalIndex

        ; for subsequent entries, use the palette colors
        .repeat 3
        ldx PalIndex           ; From the original buffer
        ldy BgPaletteBuffer, x ; Grab a palette color
        lda (PalAddr), y       ; And use it to index the brightness table we picked
        ldx VRAM_TABLE_INDEX
        sta VRAM_TABLE_START,x
        inc VRAM_TABLE_INDEX
        inc PalIndex
        .endrepeat

        lda #16
        cmp PalIndex
        bne bg_loop
        inc VRAM_TABLE_ENTRIES

check_obj_palette:
        lda ObjPaletteDirty
        beq done

        write_vram_header_imm $3F10, #16, VRAM_INC_1
        lda #0
        sta PalIndex
obj_loop:
       ; for the first entry, always use the global BG color
        ldx #0
        ldx PalIndex           ; From the original buffer
        ldy BgPaletteBuffer, x ; Grab a palette color
        lda (PalAddr), y       ; And use it to index the brightness table we picked
        ldx VRAM_TABLE_INDEX
        sta VRAM_TABLE_START,x
        inc VRAM_TABLE_INDEX
        inc PalIndex

        ; for subsequent entries, use the Obj palette colors
        .repeat 3
        ldx PalIndex           ; From the original buffer
        ldy ObjPaletteBuffer, x ; Grab a palette color
        lda (PalAddr), y       ; And use it to index the brightness table we picked
        ldx VRAM_TABLE_INDEX
        sta VRAM_TABLE_START,x
        inc VRAM_TABLE_INDEX
        inc PalIndex
        .endrepeat

        lda #16
        cmp PalIndex
        bne obj_loop
        inc VRAM_TABLE_ENTRIES

done:
        lda #0
        sta BgPaletteDirty
        sta ObjPaletteDirty
        rts
.endproc
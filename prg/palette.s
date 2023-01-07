        .setcpu "6502"

        .include "branch_util.inc"
        .include "nes.inc"
        .include "palette.inc"
        .include "ppu.inc"
        .include "vram_buffer.inc"
        .include "zeropage.inc"

        .zeropage
NmiPalAddr: .res 2

        .segment "RAM"
BgPaletteDirty: .res 1
ObjPaletteDirty: .res 1
BgPaletteBuffer: .res 16
ObjPaletteBuffer: .res 16
HudPaletteBuffer: .res 16
HudGradientBuffer: .res 3
Brightness: .res 1
HudPaletteActive: .res 1

        .segment "PRGFIXED_E000"

; call with desired brightness in a
.proc set_brightness
        sta Brightness
        lda #1
        sta BgPaletteDirty
        sta ObjPaletteDirty
        rts
.endproc

        .segment "UTILITIES_A000"

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

hud_base_pal:
        .incbin "../art/palettes/hud_base.pal"

.proc FAR_init_hud_palette
        ; for now, this is a static (and quite ugly) palette for testing
        ; The global background is always black
        lda #$0F
        sta HudPaletteBuffer + 0
        
        lda hud_base_pal+1
        sta HudPaletteBuffer + 1
        lda hud_base_pal+2
        sta HudPaletteBuffer + 2
        lda hud_base_pal+3
        sta HudPaletteBuffer + 3

        lda hud_base_pal+5
        sta HudPaletteBuffer + 5
        lda hud_base_pal+66
        sta HudPaletteBuffer + 6
        lda hud_base_pal+7
        sta HudPaletteBuffer + 7

        lda hud_base_pal+9
        sta HudPaletteBuffer + 9
        lda hud_base_pal+10
        sta HudPaletteBuffer + 10
        lda hud_base_pal+11
        sta HudPaletteBuffer + 11

        lda hud_base_pal+13
        sta HudPaletteBuffer + 13
        lda hud_base_pal+14
        sta HudPaletteBuffer + 14
        lda hud_base_pal+15
        sta HudPaletteBuffer + 15

        ; finally, the palette gradient during the transition looks like this:
        ; - old BG3.0
        ; - new BG0.0
        ; - new BG1.0
        ; - new BG2.0
        ; - new BG3.0
        ; - new BG0.0

        ; Since old BG3.0 and new BG0.0 will both be black, we can do a 3-color gradient
        ; in the remaining area. Let's use a boring grey gradient

        lda #$30
        sta HudGradientBuffer + 0
        lda #$10
        sta HudGradientBuffer + 1
        lda #$0F
        sta HudGradientBuffer + 2
        ; all set!
        ; TODO: make this not awful, and later, incorporate the ability icon colors in here

        rts
.endproc

.proc FAR_refresh_palettes
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

.proc FAR_refresh_palettes_gameloop
PalAddr := R0
PalIndex := R2
        lda BgPaletteDirty
        ora ObjPaletteDirty
        ora HudPaletteActive
        jeq done

        lda Brightness
        asl
        tax
        lda brightness_table, x
        sta PalAddr
        lda brightness_table+1, x
        sta PalAddr+1

        lda BgPaletteDirty
        ora HudPaletteActive
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
       ; for the first entry, always use the global *BG* color
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

.proc FAR_refresh_palettes_lag_frame
        lda HudPaletteActive
        beq done
        
        set_ppuaddr #$3F00
        ; quickly copy the BG palette *directly* into PPU memory, bypassing
        ; the vram buffer entirely. This is meant to be called from NMI during
        ; lag frames
        lda Brightness
        asl
        tax
        lda brightness_table, x
        sta NmiPalAddr
        lda brightness_table+1, x
        sta NmiPalAddr+1

        ldx #0
bg_loop:
        ; for the first entry, always use the global BG color
        ldy BgPaletteBuffer, x ; Grab a palette color
        lda (NmiPalAddr), y       ; And use it to index the brightness table we picked
        sta PPUDATA
        inx
        cpx #16
        bne bg_loop

done:
        rts        
.endproc

.proc _queue_arbitrary_palette
BasePaletteAddr := R0
Brightness := R2
PalAddr := R3
PalIndex := R5
        ; First, pick the appropriate brightness LUT based on the supplied parameter
        lda Brightness
        asl
        tax
        lda brightness_table, x
        sta PalAddr
        lda brightness_table+1, x
        sta PalAddr+1

        lda #0
        sta PalIndex
loop:
        ldy PalIndex             ; From the original buffer
        lda (BasePaletteAddr), y ; Grab a palette color
        tay
        lda (PalAddr), y       ; And use it to index the brightness table we picked
        ldx VRAM_TABLE_INDEX
        sta VRAM_TABLE_START,x
        inc VRAM_TABLE_INDEX
        inc PalIndex
        lda #16
        cmp PalIndex
        bne loop
        inc VRAM_TABLE_ENTRIES

        rts
.endproc

.proc FAR_queue_arbitrary_bg_palette
        ; Now use this table to copy in the palette, from the supplied address
        write_vram_header_imm $3F00, #16, VRAM_INC_1
        jmp _queue_arbitrary_palette ; tail call
.endproc

.proc FAR_queue_arbitrary_obj_palette
        ; Now use this table to copy in the palette, from the supplied address
        write_vram_header_imm $3F10, #16, VRAM_INC_1
        jmp _queue_arbitrary_palette ; tail call
.endproc
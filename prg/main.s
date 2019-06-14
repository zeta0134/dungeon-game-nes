        .setcpu "6502"
        .include "nes.inc"
        .include "mmc3.inc"
        .include "ppu.inc"
        .include "word_util.inc"
        .include "zeropage.inc"

.scope PRGLAST_E000
        .segment "PRGLAST_E000"
        ;.org $e000

test_map:
        .incbin "build/maps/test_room.bin"
test_tileset:
        .byte $00, $00, $00, $00 ;tile 0 shouldn't exist in valid map data
        .byte $00, $01, $02, $03
        .byte $04, $05, $06, $07
        .byte $08, $09, $0A, $0B
        .byte $0C, $0D, $0E, $0F
        .byte $10, $11, $12, $13
        .byte $14, $15, $16, $17
        .byte $18, $19, $1A, $1B
        .byte $1C, $1D, $1E, $1F
        .byte $20, $21, $22, $23
        .byte $24, $25, $26, $27
        .byte $28, $29, $2A, $2B
        .byte $2C, $2D, $2E, $2F
        .byte $30, $31, $32, $33
        .byte $34, $35, $36, $37
        .byte $38, $39, $3A, $3B
        .byte $3C, $3D, $3E, $3F
        .byte $40, $41, $42, $43
        .byte $44, $45, $46, $47
        .byte $48, $49, $4A, $4B
        .byte $4C, $4D, $4E, $4F
        .byte $50, $51, $52, $53
        .byte $54, $55, $56, $57
        .byte $58, $59, $5A, $5B
        .byte $5C, $5D, $5E, $5F
        .byte $60, $61, $62, $63
        .byte $64, $65, $66, $67
        .byte $68, $69, $6A, $6B
        .byte $6C, $6D, $6E, $6F
        .byte $70, $71, $72, $73
        .byte $74, $75, $76, $77
        .byte $78, $79, $7A, $7B
        .byte $7C, $7D, $7E, $7F
        .byte $80, $81, $82, $83
        .byte $84, $85, $86, $87
        .byte $88, $89, $8A, $8B
        .byte $8C, $8D, $8E, $8F

.proc zero_zp
        ldy #0
        lda #0
loop:
        dey
        sta (0),y
        bne loop
        rts
.endproc

; Arguments:
; R0 - starting address (16bit)
; R2 - length (16bit)
.proc zero_memory
        ldy #0
        ; decrement once to start, since we exit when the counter reaches -1
        dec16 R2
loop:
        lda #0
        sta (R0),y
        inc16 R0
        dec16 R2 ; sets A to 0xFF
        cmp R2+1 ; check if the high byte has rolled around to 0xFF; if so, terminate the loop
        bne loop
        rts
.endproc

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
        ; TEST: Set the palettes up with a nice greyscale for everything

        ; disable rendering
        lda #$00
        sta PPUMASK

        ; Backgrounds
        set_ppuaddr #$3F00

        lda #$20
        sta PPUDATA
        lda #$10
        sta PPUDATA
        lda #$00
        sta PPUDATA
        lda #$0F
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

; Draws a run of an upper row of 16x16 metatiles
; Inputs:
;   R0: 16bit starting address (map tiles)
;   R2: 16bit chrmap address (base)
;   R4: 8bit tiles to copy
;   PPUADDR: nametable destination
; Note: PPUCTRL should be set to VRAM+1 mode before calling
.proc draw_row
        clc
column_loop:
        ldy #$00
        lda (R0),y ; a now holds the tile index
        asl a
        asl a ; a now holds an offset into the chrmap for this tile
        tay
        lda (R2),y ; a now holds CHR index of the top-left tile
        sta PPUDATA
        iny
        lda (R2),y ; a now holds CHR index of the top-right tile
        sta PPUDATA
        inc16 R0
        dec R4
        bne column_loop
        rts
.endproc

.proc demo_map_init
        lda #$00
        sta PPUMASK ; disable rendering
        lda PPUSTATUS ; reset read/write latch
        lda #$A0
        sta PPUCTRL ; ensure VRAM increment mode is +1

        st16 R5, $2000 ; Initialize a shadow PPUADDR to track our position onscreen
        st16 R7, (test_map+2) ;skip past width and height bytes
        lda #15
        sta R9
row_loop:
        ; upper row
        set_ppuaddr R5
        mov16 R7, R0
        st16 R2, (test_tileset)
        lda #16
        sta R4
        jsr draw_row

        ; move PPUADDR to the next row
        clc
        add16 R5, #32
        set_ppuaddr R5

        ; lower row
        mov16 R7, R0
        st16 R2, (test_tileset+2)
        lda #16
        sta R4
        jsr draw_row

        ; move PPUADDR to the next row
        clc
        add16 R5, #32

        ; move down one row in the tileset
        clc
        add16 R7, #16
        dec R9
        bne row_loop

        ; reset PPUADDR to top-left
        set_ppuaddr #$2000

        ; re-enable graphics
        lda #$1E
        sta PPUMASK
        rts
.endproc        

        .export start
        .importzp FrameCounter, TestBlobbyDelay
start:
        jsr zero_zp
        st16 R0, ($0200) ; starting address
        st16 R2, ($0600) ; length in bytes
        jsr zero_memory
        jsr initialize_mmc3
        jsr initialize_palettes
        jsr initialize_ppu
        jsr demo_oam_init
        jsr demo_map_init

        lda #$00
        sta FrameCounter
        lda #$20
        sta TestBlobbyDelay
gameloop:
        dec TestBlobbyDelay
        bne wait_for_next_vblank
        lda #$20
        sta TestBlobbyDelay
        lda $0201
        eor #%00000010
        sta $0201
        sta $0205
wait_for_next_vblank:
        lda FrameCounter
@loop:
        cmp FrameCounter
        beq @loop
        jmp gameloop

.endscope

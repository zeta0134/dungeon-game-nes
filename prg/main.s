        .setcpu "6502"
        .include "nes.inc"
        .include "mmc3.inc"
        .include "word_util.inc"

.scope PRGLAST_E000
        .segment "PRGLAST_E000"
        ;.org $e000

test_map:
        .incbin "build/maps/test_room.bin"

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

        lda #$3c
        sta PPUDATA
        lda #$2b
        sta PPUDATA
        lda #$1a
        sta PPUDATA
        lda #$09
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

; Draws a run of an upper row of 16x16 metatiles
; Inputs:
;   R0: 16bit starting address (map tiles)
;   PPUADDR: nametable destination
;   R2: 8bit count
.proc draw_upper_row
column_loop:
        lda ($00),y ; a now holds the tile index
        sta PPUDATA
        iny
        cpy #16
        bne column_loop
.endproc

.proc demo_map_init
        lda #$00
        sta PPUMASK ; disable rendering
        lda PPUSTATUS ; reset read/write latch
        lda #$20
        sta PPUADDR
        lda #$00
        sta PPUADDR ; set PPUADDR to top-left of the first nametable
        lda $A0
        sta PPUCTRL ; ensure VRAM increment mode is +1
        st16 $00, test_map ; initialize pointer into map data
        ldy #$00 ; initialize column offset
column_loop:
        lda ($00),y ; a now holds the tile index
        sta PPUDATA
        iny
        cpy #16
        bne column_loop
        rts
.endproc
        

        .export start
        .importzp FrameCounter, TestBlobbyDelay
start:
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

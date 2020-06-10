        .setcpu "6502"
        .include "nes.inc"
        .include "mmc3.inc"
        .include "memory_util.inc"
        .include "ppu.inc"
        .include "sprites.inc"
        .include "word_util.inc"
        .include "zeropage.inc"

.scope PRGLAST_E000
        .segment "PRGLAST_E000"
        ;.org $e000

test_map:
        .incbin "build/maps/large_test_room.bin"
test_tileset:
        .byte $00, $00, $00, $00 ;tile 0 shouldn't exist in valid map data
        .incbin "build/tilesets/skull_tiles.mt"
        
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
        add16 R7, #64
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

        st16 R0, ($0200) ; starting address
        st16 R2, ($0600) ; length in bytes
        jsr clear_memory
        jsr initialize_mmc3
        jsr initialize_palettes
        jsr initialize_ppu
        jsr initialize_oam
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

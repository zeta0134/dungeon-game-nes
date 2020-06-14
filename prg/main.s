        .setcpu "6502"
        .include "nes.inc"
        .include "input.inc"
        .include "mmc3.inc"
        .include "memory_util.inc"
        .include "ppu.inc"
        .include "scrolling.inc"
        .include "sprites.inc"
        .include "word_util.inc"
        .include "zeropage.inc"
        .include "input.inc"

.scope PRGLAST_E000
        .export start
        .importzp FrameCounter
        .zeropage
TestBlobbyDelay: .byte $00
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
start:

        st16 R0, ($0200) ; starting address
        st16 R2, ($0600) ; length in bytes
        jsr clear_memory
        jsr initialize_mmc3
        jsr initialize_palettes
        jsr initialize_ppu
        jsr initialize_oam
        jsr demo_oam_init

        lda #$00
        sta PPUMASK ; disable rendering

        ; less demo map init
        st16 R4, (test_map)
        jsr load_map
        st16 R0, (test_tileset)
        jsr load_tileset
        lda #8
        sta R0
        sta R1
        jsr init_map

        ; reset PPUADDR to top-left
        set_ppuaddr #$2000

        ; re-enable graphics
        lda #$1E
        sta PPUMASK

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

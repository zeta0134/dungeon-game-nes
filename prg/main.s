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
        .include "animations/blobby.inc"
        .include "statusbar.inc"

.scope PRGLAST_E000
        .export start
        .importzp FrameCounter, CameraXTileTarget, CameraXScrollTarget, CameraYTileTarget, CameraYScrollTarget
        .zeropage
TestBlobbyDelay: .byte $00
        .segment "PRGLAST_E000"
        ;.org $e000


test_map:
        .incbin "build/maps/large_test_room.bin"
test_tileset:
        ;.byte $00, $00, $00, $00 ;tile 0 shouldn't exist in valid map data
        .incbin "build/tilesets/skull_tiles.mt"

.proc demo_scroll_camera
CameraSpeed := $10
        lda #KEY_RIGHT
        bit ButtonsHeld
        beq right_not_held
        clc
        lda #CameraSpeed
        adc CameraXScrollTarget
        sta CameraXScrollTarget
        lda #$00
        adc CameraXTileTarget
        sta CameraXTileTarget
right_not_held:
        lda #KEY_LEFT
        bit ButtonsHeld
        beq left_not_held
        clc
        lda CameraXScrollTarget
        sbc #CameraSpeed
        sta CameraXScrollTarget
        lda CameraXTileTarget
        sbc #$00
        sta CameraXTileTarget
left_not_held:
        lda #KEY_DOWN
        bit ButtonsHeld
        beq down_not_held
        clc
        lda #CameraSpeed
        adc CameraYScrollTarget
        sta CameraYScrollTarget
        lda #$00
        adc CameraYTileTarget
        sta CameraYTileTarget
down_not_held:
        lda #KEY_UP
        bit ButtonsHeld
        beq up_not_held
        clc
        lda CameraYScrollTarget
        sbc #CameraSpeed
        sta CameraYScrollTarget
        lda CameraYTileTarget
        sbc #$00
        sta CameraYTileTarget
up_not_held:

        rts
.endproc

.macro initialize_metasprite index, pos_x, pos_y, palette, tilebase, animation
        st16 R0, pos_x
        set_metasprite_x #.sizeof(MetaSpriteState)*index, R0
        st16 R0, pos_y
        set_metasprite_y #.sizeof(MetaSpriteState)*index, R0
        set_metasprite_tile_offset #.sizeof(MetaSpriteState)*index, #tilebase
        set_metasprite_palette_offset #.sizeof(MetaSpriteState)*index, #palette
        set_metasprite_animation #.sizeof(MetaSpriteState)*index, animation
.endmacro

.proc demo_oam_init
        ; Setup a demo blob; this happens to also be sprite zero, which is needed for scrolling
        lda #200
        sta $0200 ;sprite[0].Y
        lda #00
        sta $0201 ;sprite[0].Tile
        lda #$00
        sta $0202 ;sprite[0].Palette + Attributes
        lda #24
        sta $0203 ;sprite[0].X

        lda #200
        sta $0204 ;sprite[1].Y
        lda #00
        sta $0205 ;sprite[1].Tile
        lda #$40
        sta $0206 ;sprite[1].Palette + Attributes
        lda #32
        sta $0207 ;sprite[1].X

        lda #208
        sta $0208 ;sprite[0].Y
        lda #01
        sta $0209 ;sprite[0].Tile
        lda #$00
        sta $020A ;sprite[0].Palette + Attributes
        lda #24
        sta $020B ;sprite[0].X

        lda #208
        sta $020C ;sprite[1].Y
        lda #01
        sta $020D ;sprite[1].Tile
        lda #$40
        sta $020E ;sprite[1].Palette + Attributes
        lda #32
        sta $020F ;sprite[1].X

        ; EVEN MORE JOY: initialize three animation states
        initialize_metasprite 0, 20, 50, 1, 0, blobby_anim_idle_alt
        initialize_metasprite 1, 40, 50, 2, 0, blobby_anim_jump
        initialize_metasprite 2, 60, 50, 3, 0, blobby_anim_roll

        rts  
.endproc

start:
        lda #$00
        sta PPUMASK ; disable rendering
        sta PPUCTRL ; and NMI

        jsr clear_memory
        jsr initialize_mmc3
        jsr initialize_palettes
        jsr initialize_oam
        jsr demo_oam_init
        jsr initialize_ppu

        lda #$00
        sta PPUMASK ; disable rendering (again)
        sta PPUCTRL ; and NMI

        ; less demo map init
        st16 R4, (test_map)
        jsr load_map
        st16 R0, (test_tileset)
        jsr load_tileset
        lda #0
        sta R0
        lda #0
        sta R1
        jsr init_map
        jsr install_irq_handler

        ; init the statusarea to something not stupid
        jsr demo_init_statusbar

        ; reset PPUADDR to top-left
        set_ppuaddr #$2000

        ; re-enable graphics
        lda #$1E
        sta PPUMASK
        lda #(VBLANK_NMI | OBJ_0000 | BG_1000)
        sta PPUCTRL

        lda #$00
        sta FrameCounter
        lda #$20
        sta TestBlobbyDelay

        ; disable unusual IRQ sources
        lda #%01000000
        sta $4017 ; APU frame counter
        lda #0
        sta $4010
        cli
gameloop:
        lda #$9F
        sta PPUMASK
        jsr demo_scroll_camera
        jsr update_animations
        jsr draw_metasprites
        lda #$1E
        sta PPUMASK
        dec TestBlobbyDelay
        bne wait_for_next_vblank
        lda #$20
        sta TestBlobbyDelay
        lda $0201
        eor #%00000010
        sta $0201
        sta $0205
        lda $0209
        eor #%00000010
        sta $0209
        sta $020D        
wait_for_next_vblank:
        lda FrameCounter
@loop:
        cmp FrameCounter
        beq @loop
        jmp gameloop

.endscope

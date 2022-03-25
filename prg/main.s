        .setcpu "6502"

        .include "blobby.inc"
        .include "camera.inc"
        .include "collision.inc"
        .include "debug.inc"
        .include "entity.inc"
        .include "far_call.inc"
        .include "generators.inc"
        .include "input.inc"
        .include "irq_table.inc"
        .include "map.inc"
        .include "memory_util.inc"
        .include "mmc3.inc"
        .include "nes.inc"
        .include "ppu.inc"
        .include "scrolling.inc"
        .include "sprites.inc"
        .include "statusbar.inc"
        .include "vram_buffer.inc"
        .include "word_util.inc"
        .include "zeropage.inc"

.scope PRGLAST_E000
        .export start
        .importzp GameloopCounter, LastNmi, CameraXTileTarget, CameraXScrollTarget, CameraYTileTarget, CameraYScrollTarget
        .zeropage
TestBlobbyDelay: .byte $00


.segment "PRG0_A000"
; note: this is probably a bad idea
test_map:
        .incbin "build/maps/large_test_room.bin"
test_tileset:
        .incbin "build/tilesets/skull_tiles.mt"

.segment "PRGLAST_E000"

.macro initialize_metasprite index, pos_x, pos_y, palette, tilebase, animation
        st16 R0, pos_x
        set_metasprite_x #.sizeof(MetaSpriteState)*index, R0
        st16 R0, pos_y
        set_metasprite_y #.sizeof(MetaSpriteState)*index, R0
        set_metasprite_tile_offset #.sizeof(MetaSpriteState)*index, #tilebase
        set_metasprite_palette_offset #.sizeof(MetaSpriteState)*index, #palette
        set_metasprite_animation #.sizeof(MetaSpriteState)*index, animation
.endmacro

.proc demo_init
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

        st16 R0, blobby_init
        jsr spawn_entity
        ; y now contains the entity index. Use this to set the tile
        ; coordinate to 5, 5 for testing
        lda #0
        sta entity_table + EntityState::PositionX, y
        sta entity_table + EntityState::PositionY, y
        lda #5
        sta entity_table + EntityState::PositionX+1, y
        sta entity_table + EntityState::PositionY+1, y
        ; in theory, blobby is now ready to go        
        rts
.endproc


test_vram_data:
        .byte $00, $01, $02, $03, $04, $05, $06, $07

test_vram_transfer:
        write_vram_header_imm $214A, #8, VRAM_INC_1
        vramcpy test_vram_data, 8
        inc VRAM_TABLE_ENTRIES
        write_vram_header_imm $218A, #8, VRAM_INC_32
        vramcpy test_vram_data, 8
        inc VRAM_TABLE_ENTRIES
        rts

start:
        lda #$00
        sta PPUMASK ; disable rendering
        sta PPUCTRL ; and NMI

        ; Clear out main memory regions
        st16 R0, ($0000)
        st16 R2, ($0100)
        jsr clear_memory
        st16 R0, ($0200)
        st16 R2, ($0600)
        jsr clear_memory

        jsr initialize_mmc3
        jsr initialize_palettes
        jsr initialize_oam
        jsr demo_init
        jsr initialize_ppu
        jsr initialize_irq_table

        lda #$00
        sta PPUMASK ; disable rendering (again)
        sta PPUCTRL ; and NMI

        ; less demo map init
        st16 R4, (test_map)
        jsr load_map
        st16 R0, (test_tileset)
        jsr load_tileset
        st16 R0, (test_tileset+256)
        jsr load_tileset_attributes
        
        far_call FAR_init_map
        far_call FAR_init_attributes

        ; render the initial viewport before we turn on graphics
        far_call FAR_render_initial_viewport

        ; init the statusarea to something not stupid
        jsr demo_init_statusbar

        ; reset PPUADDR to top-left
        set_ppuaddr #$2000

        lda #$00
        sta GameloopCounter
        sta LastNmi
        lda #$20
        sta TestBlobbyDelay

        ; disable unusual IRQ sources
        lda #%01000000
        sta $4017 ; APU frame counter
        lda #0
        sta $4010
        cli

        ; re-enable graphics
        lda #$1E
        sta PPUMASK
        lda #(VBLANK_NMI | BG_0000 | OBJ_1000)
        sta PPUCTRL

        ; immediately wait for one vblank, for sync purposes
        jmp wait_for_next_vblank

gameloop:
        debug_color LIGHTGRAY
        far_call FAR_update_camera
        debug_color TINT_R | TINT_G
        jsr update_entities
        debug_color TINT_B
        jsr update_animations
        debug_color TINT_B | TINT_G
        jsr draw_metasprites
        debug_color TINT_R
        far_call FAR_scroll_camera
        debug_color 0 ; disable debug colors

        lda inactive_irq_index
        sta R0
        jsr generate_basic_playfield
        jsr generate_standard_hud
        jsr swap_irq_buffers

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
        inc GameloopCounter
@loop:
        lda LastNmi
        cmp GameloopCounter
        bne @loop
        jmp gameloop

.endscope

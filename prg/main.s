        .setcpu "6502"

        .include "blobby.inc"
        .include "boxgirl.inc"
        .include "animations/blobby.inc"
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


.segment "PRG0_A000"
; note: this is probably a bad idea
test_map:
        ;.incbin "build/maps/large_test_room.bin"
        .include "debug_maps/test_room_3d.incs"
test_tileset:
        ;.incbin "build/tilesets/skull_tiles.mt"
        .include "../build/tilesets/tiles_3d.mt"


.segment "PRGLAST_E000"

.proc spawn_static_sprite
MetaspriteIndex := R0
PosX := R1
PosY := R3

        jsr find_unused_metasprite
        lda #$FF
        cmp MetaspriteIndex
        beq failed_to_spawn

        set_metasprite_x MetaspriteIndex, PosX
        set_metasprite_y MetaspriteIndex, PosY
        set_metasprite_animation MetaspriteIndex, blobby_anim_idle
        set_metasprite_tile_offset MetaspriteIndex, #0
        set_metasprite_palette_offset MetaspriteIndex, #1

failed_to_spawn:
        ; do nothing!
        rts
.endproc

.proc demo_init
        st16 R0, boxgirl_init
        jsr spawn_entity
        ; y now contains the entity index. Use this to set the tile
        ; coordinate to 5, 5 for testing
        lda #0
        sta entity_table + EntityState::PositionX, y
        sta entity_table + EntityState::PositionY, y
        lda #5
        sta entity_table + EntityState::PositionX+1, y
        sta entity_table + EntityState::PositionY+1, y
        ; in theory, blobby is now ready to go.
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
        st16 R6, (tiles_3d)
        jsr load_tileset
        st16 R4, (test_room_3d)
        jsr load_map
        
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

        ; disable unusual IRQ sources
        lda #%01000000
        sta $4017 ; APU frame counter
        lda #0
        sta $4010
        cli

        ; re-enable graphics
        lda #$1E
        sta PPUMASK
        lda #(VBLANK_NMI | BG_0000 | OBJ_1000 | OBJ_8X16)
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

        ; starting IRQ index for the playfield
        lda inactive_irq_index
        sta R0
        ; CHR bank to use for BG graphics
        lda #4
        sta R1
        jsr generate_basic_playfield
        jsr generate_standard_hud
        jsr swap_irq_buffers
wait_for_next_vblank:
        inc GameloopCounter
@loop:
        lda LastNmi
        cmp GameloopCounter
        bne @loop
        jmp gameloop

.endscope

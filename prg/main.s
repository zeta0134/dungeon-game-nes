        .setcpu "6502"

        .include "boxgirl.inc"
        .include "animations/blobby.inc"
        .include "camera.inc"
        .include "debug.inc"
        .include "entity.inc"
        .include "far_call.inc"
        .include "generators.inc"
        .include "governer.inc"
        .include "input.inc"
        .include "irq_table.inc"
        .include "main.inc"
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


.segment "PRGFIXED_8000"
; note: this is probably a bad idea
test_maps:
        .include "../build/maps/test_room_3d.incs"
        .include "../build/maps/bridges.incs"
test_tileset:
        .include "../build/tilesets/tiles_3d.mt"
        .include "../build/tilesets/grassy_fields.mt"
grassy_fields_pal:
        .incbin "../build/tilesets/grassy_fields.pal"


.segment "PRGFIXED_E000"

.proc demo_load_palette
        set_ppuaddr #$3F00
        ldy #0
loop:
        lda grassy_fields_pal, y
        sta PPUDATA
        iny
        cpy #12
        bne loop
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
        ; in theory, boxgirl is now ready to go.
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
        ;st16 R4, (test_room_3d)
        st16 R4, (bridges)
        jsr load_map

        ; load in the demo palette
        jsr demo_load_palette
        
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
        jsr wait_for_next_vblank

        ; choose our starting game mode
        st16 GameMode, standard_gameplay_loop

        ; hand control over to the governer, which will manage game mode
        ; switching from here on out
main_loop:
        jsr run_game
        jmp main_loop


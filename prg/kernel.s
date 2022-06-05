        .setcpu "6502"

        .include "boxgirl.inc"
        .include "camera.inc"
        .include "debug.inc"
        .include "entity.inc"
        .include "far_call.inc"
        .include "generators.inc"
        .include "irq_table.inc"
        .include "kernel.inc"
        .include "levels.inc"
        .include "map.inc"
        .include "mmc3.inc"
        .include "nes.inc"
        .include "ppu.inc"
        .include "scrolling.inc"
        .include "sprites.inc"
        .include "statusbar.inc"
        .include "word_util.inc"
        .include "zeropage.inc"

        .zeropage
GameMode: .res 2
        .segment "RAM"
TargetMapAddr: .res 2
TargetMapBank: .res 1
TargetMapEntrance: .res 1



        .segment "PRGFIXED_E000"

; === Utility Functions ===
.proc wait_for_next_vblank
        inc GameloopCounter
@loop:
        lda LastNmi
        cmp GameloopCounter
        bne @loop
        rts
.endproc

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

; === Kernel Entrypoint ===
.proc run_kernel
        ; whatever game mode we are currently in, run one loop of that and exit
        jmp (GameMode)
        ; the game state function will exit
.endproc

; === Game Mode Functions Follow ===
.proc load_new_map
        ; while we are working on level loading, disable interrupts entirely
        sei

        lda #$00
        sta PPUMASK ; disable rendering
        sta PPUCTRL ; and NMI

        ; less demo map init
        lda TargetMapAddr
        sta R4
        lda TargetMapAddr+1
        sta R4+1

        access_data_bank TargetMapBank
        jsr load_map
        ; FOR NOW, load in the demo palette
        jsr demo_load_palette
        restore_previous_bank
        
        far_call FAR_init_map
        far_call FAR_init_attributes
        far_call FAR_init_camera

        ; render the initial viewport before we turn on graphics
        far_call FAR_render_initial_viewport

        ; init the statusarea to something not stupid
        jsr demo_init_statusbar

        ; reset PPUADDR to top-left
        set_ppuaddr #$2000

        ; clear all entities and metasprites
        jsr despawn_all_entities
        jsr despawn_all_metasprites

        ; FOR NOW, spawn in the player and nothing else
        ; (later this will be replaced with loading the entity list defined by the level)
        jsr demo_init

        lda #$00
        sta GameloopCounter
        sta LastNmi

        ; re-enable graphics
        lda #$1E
        sta PPUMASK
        lda #(VBLANK_NMI | BG_0000 | OBJ_1000 | OBJ_8X16)
        sta PPUCTRL

        ; immediately wait for one vblank, for sync purposes
        jsr wait_for_next_vblank

        ; now we may safely enable interrupts
        cli

        ; we are done with map loading. Run the standard gameplay loop next.
        st16 GameMode, standard_gameplay_loop

        rts
.endproc

.proc standard_gameplay_loop
        .if ::DEBUG_MODE
        ; waste a bunch of time
        ldx #$FF
time_waste_loop:
        .repeat 1
        nop
        .endrepeat
        dex
        bne time_waste_loop
        .endif
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
        lda DynamicChrBank
        sta R1
        far_call FAR_generate_basic_playfield
        far_call FAR_generate_standard_hud
        jsr swap_irq_buffers
        jsr wait_for_next_vblank
        rts
.endproc


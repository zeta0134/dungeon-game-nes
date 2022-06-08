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

.proc demo_init
ScratchAddr := R0
CurrentEntityIndex := R2
        st16 ScratchAddr, boxgirl_init
        jsr spawn_entity

        ; y now contains the entity index; preserve it
        sty CurrentEntityIndex

        access_data_bank TargetMapBank
        ; load the coordinates from this map's entrance, and teleport boxgirl there
        lda TargetMapAddr
        sta ScratchAddr
        lda TargetMapAddr+1
        sta ScratchAddr+1

        ldy #MapHeader::entrance_table_ptr
        lda (ScratchAddr), y
        tax
        ldy #MapHeader::entrance_table_ptr+1
        lda (ScratchAddr), y
        stx ScratchAddr
        sta ScratchAddr+1

        ldx CurrentEntityIndex
        lda TargetMapEntrance
        asl
        tay
        lda (ScratchAddr), y
        sta entity_table + EntityState::PositionX+1, x
        iny
        lda (ScratchAddr), y
        sta entity_table + EntityState::PositionY+1, x

        ; clear out the pixel and subpixel coordinates
        lda #0
        sta entity_table + EntityState::PositionX, x
        sta entity_table + EntityState::PositionY, x 

        ; all done
        restore_previous_bank

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

         ; disable rendering
        lda #$00
        sta PPUMASK

        ; soft-disable NMI (sound engine updates only)
        lda #1
        sta NmiSoftDisable
        ; Reset PPUCTRL, but leave NMI enabled
        lda #(VBLANK_NMI)
        sta PPUCTRL

        ; less demo map init
        lda TargetMapAddr
        sta R4
        lda TargetMapAddr+1
        sta R4+1

        access_data_bank TargetMapBank
        jsr load_map
        restore_previous_bank
        
        far_call FAR_init_map
        far_call FAR_init_attributes
        far_call FAR_init_camera

        ; clear all entities and metasprites
        jsr despawn_all_entities
        jsr despawn_all_metasprites

        ; FOR NOW, spawn in the player and nothing else
        ; (later this will be replaced with loading the entity list defined by the level)
        jsr demo_init

        ; Initialize the map's scroll coordinates based on the camera-tracked position
        ; of the entity in slot 0 (which is usually the player)
        far_call FAR_update_desired_pos_only

        ; DEBUG, these numbers are arbitrary
        lda FollowCameraDesiredX+1
        lsr
        and #$FE ; force this to be even
        sta R0
        lda FollowCameraDesiredY+1
        lsr
        and #$FE ; force this to be even
        sta R1
        far_call FAR_init_scroll_position

        ; render the initial viewport before we turn on graphics
        far_call FAR_render_initial_viewport

        ; init the statusarea to something not stupid
        jsr demo_init_statusbar

        ; reset PPUADDR to top-left
        set_ppuaddr #$2000

        lda #$00
        sta GameloopCounter
        sta LastNmi

        ; re-enable graphics
        lda #$1E
        sta PPUMASK
        lda #(VBLANK_NMI | BG_0000 | OBJ_1000 | OBJ_8X16)
        sta PPUCTRL

        ; un-soft-disable NMI
        lda #0
        sta NmiSoftDisable

        ; immediately wait for one vblank, for sync purposes
        jsr wait_for_next_vblank

        ; now we may safely enable interrupts
        cli

        ; we are done with map loading. Run the standard gameplay loop next.
        st16 GameMode, standard_gameplay_loop

        rts
.endproc

.proc standard_gameplay_loop
        .if ::DEBUG_TIME_WASTE
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


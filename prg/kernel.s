        .setcpu "6502"

        .include "camera.inc"
        .include "debug.inc"
        .include "entity.inc"
        .include "far_call.inc"
        .include "generators.inc"
        .include "irq_table.inc"
        .include "kernel.inc"
        .include "scrolling.inc"
        .include "sprites.inc"
        .include "zeropage.inc"

        .zeropage
GameMode: .res 2
        .segment "RAM"
TargetMapAddr: .res 2
TargetMapBank: .res 1
TargetMapEntrance: .res 1



        .segment "PRGFIXED_E000"

.proc run_game
        ; whatever game mode we are currently in, run one loop of that and exit
        jmp (GameMode)
        ; the game state function will exit
.endproc

.proc wait_for_next_vblank
        inc GameloopCounter
@loop:
        lda LastNmi
        cmp GameloopCounter
        bne @loop
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


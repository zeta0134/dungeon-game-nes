        .setcpu "6502"

        .include "blobby.inc"
        .include "boxgirl.inc"
        .include "camera.inc"
        .include "debug.inc"
        .include "dialog.inc"
        .include "entity.inc"
        .include "far_call.inc"
        .include "generators.inc"
        .include "input.inc"
        .include "irq_table.inc"
        .include "kernel.inc"
        .include "levels.inc"
        .include "map.inc"
        .include "mmc3.inc"
        .include "nes.inc"
        .include "palette.inc"
        .include "particles.inc"
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
FadeTimer: .res 1
HitstunTimer: .res 1
AnimTimer: .res 1


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
MapAddr := R4 ; load_entities requires that MapAddr be R4
        st16 ScratchAddr, boxgirl_init
        far_call FAR_spawn_entity

        ; y now contains the entity index; preserve it
        sty CurrentEntityIndex

        access_data_bank TargetMapBank
        ; load the coordinates from this map's entrance, and teleport boxgirl there
        lda TargetMapAddr
        sta MapAddr
        lda TargetMapAddr+1
        sta MapAddr+1

        ldy #MapHeader::entrance_table_ptr
        lda (MapAddr), y
        tax
        ldy #MapHeader::entrance_table_ptr+1
        lda (MapAddr), y
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

        ; Set our starting height to 0
        sta entity_table + EntityState::PositionZ, x 
        sta entity_table + EntityState::PositionZ+1, x 

        ; now spawn in all the other entities that this map references
        jsr load_entities

        ; all done
        restore_previous_bank

        rts
.endproc

.proc demo_obj_palette
        ; grey!
        lda #$20
        sta ObjPaletteBuffer+1
        lda #$10
        sta ObjPaletteBuffer+2
        lda #$0F
        sta ObjPaletteBuffer+3

        ; red!
        lda #$36
        sta ObjPaletteBuffer+5
        lda #$26
        sta ObjPaletteBuffer+6
        lda #$06
        sta ObjPaletteBuffer+7

        ; blue!
        lda #$31
        sta ObjPaletteBuffer+9
        lda #$21
        sta ObjPaletteBuffer+10
        lda #$01
        sta ObjPaletteBuffer+11

        lda #$39
        sta ObjPaletteBuffer+13
        lda #$29
        sta ObjPaletteBuffer+14
        lda #$09
        sta ObjPaletteBuffer+15
        
        rts        
.endproc

; === Kernel Entrypoint ===
.proc run_kernel
        ; whatever game mode we are currently in, run one loop of that and exit
        jmp (GameMode)
        ; the game state function will exit
.endproc

; === Game Mode Functions Follow ===
.proc init_engine
        lda #4
        sta Brightness
        lda #1
        sta HudPaletteActive
        jsr init_hud_palette

        st16 TargetMapAddr, (debug_hub)
        lda #<.bank(debug_hub)
        sta TargetMapBank
        st16 GameMode, load_new_map
        rts
.endproc

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
        far_call FAR_init_camera

        ; clear all entities and metasprites
        far_call FAR_despawn_all_entities
        far_call FAR_despawn_all_metasprites

        ; FOR NOW, spawn in the player and nothing else
        ; (later this will be replaced with loading the entity list defined by the level)
        jsr demo_init
        jsr demo_obj_palette

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
        jsr init_statusbar

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
        far_call FAR_update_entities
        debug_color TINT_B
        far_call FAR_update_animations
        debug_color TINT_B | TINT_G
        far_call FAR_draw_metasprites
        debug_color TINT_R
        far_call FAR_scroll_camera
        debug_color TINT_G
        jsr update_particles
        jsr draw_particles
        debug_color 0 ; disable debug colors

        jsr refresh_palettes_gameloop
        jsr update_statusbar

        ; starting IRQ index for the playfield
        lda inactive_irq_index
        sta R0
        ; CHR bank to use for BG graphics
        lda DynamicChrBank
        sta R1
        ; height of the playfield
        lda #192
        sta R5
        far_call FAR_generate_basic_playfield
        far_call FAR_generate_hud_palette_swap
        far_call FAR_generate_standard_hud
        jsr swap_irq_buffers
        jsr wait_for_next_vblank
        rts
.endproc

.proc hitstun_gameplay_loop
        dec HitstunTimer
        bne still_in_hitstun
        st16 GameMode, standard_gameplay_loop
still_in_hitstun:
        ; Update absolutely nothing! That's the whole point.

        far_call FAR_update_camera
        far_call FAR_scroll_camera
        far_call FAR_draw_metasprites
        jsr refresh_palettes_gameloop
        jsr update_statusbar

        ; starting IRQ index for the playfield
        lda inactive_irq_index
        sta R0
        ; CHR bank to use for BG graphics
        lda DynamicChrBank
        sta R1
        far_call FAR_generate_basic_playfield
        far_call FAR_generate_hud_palette_swap
        far_call FAR_generate_standard_hud
        jsr swap_irq_buffers
        jsr wait_for_next_vblank

        rts
.endproc

; setup a fade to black
.proc blackout_to_new_map
        lda #40
        sta FadeTimer
        st16 GameMode, _blackout_to_new_map
        rts
.endproc

.proc _blackout_to_new_map
        ; decrement the fade timer
        dec FadeTimer
        ; use that to determine the current brightness
        lda FadeTimer
        lsr
        lsr
        lsr
        jsr set_brightness
        ; now, execute a standard game loop
        jsr standard_gameplay_loop
        ; finally, if our FadeTimer has reached zero, load a new map
        lda FadeTimer
        bne done
        st16 GameMode, _blackout_load_new_map
done:
        rts
.endproc

.proc _blackout_load_new_map
        jsr load_new_map
        lda #0
        sta FadeTimer
        st16 GameMode, _blackin_load_new_map
        rts
.endproc

.proc _blackin_load_new_map
        ; decrement the fade timer
        inc FadeTimer
        ; use that to determine the current brightness
        lda FadeTimer
        lsr
        lsr
        jsr set_brightness
        ; now, execute a standard game loop
        jsr standard_gameplay_loop
        ; finally, if our FadeTimer has reached zero, load a new map
        lda FadeTimer
        cmp #16
        bne done
        st16 GameMode, standard_gameplay_loop
done:
        rts
.endproc

DIALOG_ANIM_LENGTH = 17

; note: this is probably *way* too lengthy
dialog_transition_lut:
.byte 192
.byte 192
.byte 191
.byte 190
.byte 188
.byte 185
.byte 183
.byte 179
.byte 176
.byte 173
.byte 169
.byte 167
.byte 164
.byte 162
.byte 161
.byte 160
.byte 160

.proc dialog_init
        lda #(DIALOG_ANIM_LENGTH-1)
        sta AnimTimer
        st16 GameMode, dialog_opening
        rts   
.endproc

.proc dialog_opening
        jsr refresh_palettes_gameloop

        ; starting IRQ index for the playfield
        lda inactive_irq_index
        sta R0
        ; CHR bank to use for BG graphics
        lda DynamicChrBank
        sta R1
        ; compute temporary height of the playfield
        lda #(DIALOG_ANIM_LENGTH-1)
        sec
        sbc AnimTimer
        tax
        lda dialog_transition_lut, x
        sta R5
        far_call FAR_generate_basic_playfield
        far_call FAR_generate_hud_palette_swap
        lda #10 ; first font bank, maybe make this not magic later
        sta R1
        far_call FAR_generate_blank_hud

        jsr swap_irq_buffers
        jsr wait_for_next_vblank

        dec AnimTimer
        bne continue
        st16 GameMode, dialog_active
continue:
        rts
.endproc

.proc dialog_active
        jsr refresh_palettes_gameloop
        jsr update_dialog_engine

        ; starting IRQ index for the playfield
        lda inactive_irq_index
        sta R0
        ; CHR bank to use for BG graphics
        lda DynamicChrBank
        sta R1
        ; height of the playfield
        lda #160
        sta R5
        far_call FAR_generate_basic_playfield
        far_call FAR_generate_hud_palette_swap
        lda #10 ; first font bank, maybe make this not magic later
        sta R1
        far_call FAR_generate_dialog_hud

        jsr swap_irq_buffers
        jsr wait_for_next_vblank

        ; DEBUG
        ; exit the dialog system with a SELECT press
        lda #KEY_SELECT
        bit ButtonsDown
        beq no_debug
        ; activate the dialog system!
        ; (until this is finished, this also freezes the game)
        st16 GameMode, dialog_closing
        lda #(DIALOG_ANIM_LENGTH-1)
        sta AnimTimer
no_debug:

        rts
.endproc

.proc dialog_closing
        jsr refresh_palettes_gameloop

        ; starting IRQ index for the playfield
        lda inactive_irq_index
        sta R0
        ; CHR bank to use for BG graphics
        lda DynamicChrBank
        sta R1
        ; compute temporary height of the playfield
        ldx AnimTimer
        lda dialog_transition_lut, x
        sta R5
        far_call FAR_generate_basic_playfield
        far_call FAR_generate_hud_palette_swap
        lda #10 ; first font bank, maybe make this not magic later
        sta R1
        far_call FAR_generate_blank_hud

        jsr swap_irq_buffers
        jsr wait_for_next_vblank

        dec AnimTimer
        bne continue
        st16 GameMode, standard_gameplay_loop
continue:
        rts
.endproc

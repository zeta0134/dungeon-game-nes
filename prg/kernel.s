        .setcpu "6502"

        .include "actions.inc"
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
        .include "level_logic.inc"
        .include "main_menu.inc"
        .include "map.inc"
        .include "mmc3.inc"
        .include "nes.inc"
        .include "overlays.inc"
        .include "palette.inc"
        .include "particles.inc"
        .include "ppu.inc"
        .include "saves.inc"
        .include "scrolling.inc"
        .include "sprites.inc"
        .include "statusbar.inc"
        .include "subscreen.inc"
        .include "tilebuffer.inc"
        .include "word_util.inc"
        .include "zeropage.inc"

        .zeropage
GameMode: .res 2
        .segment "RAM"
TargetMapEntrance: .res 1
FadeTimer: .res 1
HitstunTimer: .res 1
AnimTimer: .res 1
PlayfieldPpuMask: .res 1

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

; These must be fixed because they access the data bank
.proc demo_init
ScratchAddr := R0
CurrentEntityIndex := R2
MapAddr := R4 ; load_entities requires that MapAddr be R4

        ; Currently hardcoded: all maps will contain boxgirl
        st16 ScratchAddr, boxgirl_init
        far_call FAR_spawn_entity

        ; y now contains the entity index; preserve it
        sty CurrentEntityIndex

        access_data_bank working_save+SaveFile::CurrentMapBank
        ; load the coordinates from this map's entrance, and teleport boxgirl there
        lda working_save + SaveFile::CurrentMapPtr
        sta MapAddr
        lda working_save + SaveFile::CurrentMapPtr+1
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

.proc load_target_map
        access_data_bank working_save+SaveFile::CurrentMapBank
        jsr load_map
        restore_previous_bank
        rts
.endproc

        .segment "UTILITIES_A000"

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
.proc FAR_run_kernel
        ; Read controller registers and update button status
        jsr poll_input
        ; whatever game mode we are currently in, run one loop of that and exit
        jmp (GameMode)
        ; the game state function will exit
.endproc

; === Game Mode Functions Follow ===
.proc init_engine
        ; Initialize the palette system
        lda #4
        sta Brightness
        lda #1
        sta HudPaletteActive
        near_call FAR_init_hud_palette
        lda #$1E
        sta PlayfieldPpuMask

        ; The map to load here is specified by the save file that we
        ; (hopefully) just loaded
        st16 GameMode, _blackout_load_new_map

        ; Initialize some bits of global state here
        far_call FAR_initialize_actions
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

        ; Reset map state to its default
        far_call FAR_init_maplogic

        ; less demo map init
        lda working_save + SaveFile::CurrentMapPtr
        sta R4
        lda working_save + SaveFile::CurrentMapPtr+1
        sta R4+1

        jsr load_target_map
        jsr pre_apply_all_map_overlays
        
        far_call FAR_init_map
        far_call FAR_init_camera
        far_call FAR_initialize_playfield_fx

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
        near_call FAR_init_statusbar

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

        lda #MAX_TILE_BUDGET
        sta tile_budget

        far_call FAR_update_action_buttons
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
        near_call FAR_update_particles
        near_call FAR_draw_particles
        debug_color 0 ; disable debug colors

        near_call FAR_refresh_palettes_gameloop
        near_call FAR_update_statusbar
        far_call FAR_run_map_logic
        far_call FAR_process_tilebuffer_queue



        ; starting IRQ index for the playfield
        lda inactive_irq_index
        sta R0
        ; CHR bank to use for BG graphics
        lda DynamicChrBank
        sta R1
        ; height of the playfield
        lda #192
        sta R5
        lda PlayfieldPpuMask
        sta R6
        
        debug_color TINT_R | TINT_B
        far_call FAR_generate_playfield
        debug_color 0 ; disable debug colors

        ; The main hud graphics will use CHR0, but we also need
        ; ability icons, so put those in CHR1
        lda #ABILITY_ICON_BANK
        sta HudChr1Bank

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
        jsr _hitstun_gameplay_loop

        rts
.endproc

.proc _hitstun_gameplay_loop
        ; Update absolutely nothing! That's the whole point.
        far_call FAR_update_camera
        far_call FAR_scroll_camera
        far_call FAR_draw_metasprites
        near_call FAR_refresh_palettes_gameloop
        near_call FAR_update_statusbar

        ; starting IRQ index for the playfield
        lda inactive_irq_index
        sta R0
        ; CHR bank to use for BG graphics
        lda DynamicChrBank
        sta R1
        lda PlayfieldPpuMask
        sta R6
        debug_color TINT_R | TINT_B
        far_call FAR_generate_playfield
        debug_color 0 ; disable debug colors

        ; The main hud graphics will use CHR0, but we also need
        ; ability icons, so put those in CHR1
        lda #ABILITY_ICON_BANK
        sta HudChr1Bank
        
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
        near_call FAR_init_dialog_engine
        lda #(DIALOG_ANIM_LENGTH-1)
        sta AnimTimer
        st16 GameMode, dialog_opening
        rts   
.endproc

.proc dialog_opening
        near_call FAR_refresh_palettes_gameloop
        near_call FAR_write_blank_hud_palette

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
        lda PlayfieldPpuMask
        sta R6
        debug_color TINT_R | TINT_B
        far_call FAR_generate_playfield
        debug_color 0 ; disable debug colors
        far_call FAR_generate_hud_palette_swap
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
        near_call FAR_refresh_palettes_gameloop
        near_call FAR_update_dialog_engine

        ; starting IRQ index for the playfield
        lda inactive_irq_index
        sta R0
        ; CHR bank to use for BG graphics
        lda DynamicChrBank
        sta R1
        ; height of the playfield
        lda #160
        sta R5
        lda PlayfieldPpuMask
        sta R6
        debug_color TINT_R | TINT_B
        far_call FAR_generate_playfield
        debug_color 0 ; disable debug colors
        far_call FAR_generate_hud_palette_swap
        lda #12 ; first font bank, maybe make this not magic later
        sta R1
        far_call FAR_generate_dialog_hud

        jsr swap_irq_buffers
        jsr wait_for_next_vblank

        ; refresh the animation timer (... repeatedly) so that it starts in the right spot
        ; when we close the dialog
        lda #(DIALOG_ANIM_LENGTH-1)
        sta AnimTimer
no_debug:

        rts
.endproc

.proc dialog_closing
        near_call FAR_refresh_palettes_gameloop
        near_call FAR_write_blank_hud_palette

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
        lda PlayfieldPpuMask
        sta R6
        debug_color TINT_R | TINT_B
        far_call FAR_generate_playfield
        debug_color 0 ; disable debug colors
        far_call FAR_generate_hud_palette_swap
        far_call FAR_generate_blank_hud

        jsr swap_irq_buffers
        jsr wait_for_next_vblank

        dec AnimTimer
        bne continue
        st16 GameMode, standard_gameplay_loop
        near_call FAR_init_statusbar
continue:
        rts
.endproc

; setup a fade to black
.proc subscreen_init
        lda #10
        sta FadeTimer
        st16 GameMode, _blackout_to_subscreen
        rts
.endproc

.proc _blackout_to_subscreen
        ; decrement the fade timer
        dec FadeTimer
        ; use that to determine the current brightness
        lda FadeTimer
        lsr
        jsr set_brightness
        ; now, execute a paused standard game loop
        jsr _hitstun_gameplay_loop
        ; finally, if our FadeTimer has reached zero, switch to the subscreen
        lda FadeTimer
        bne done
        st16 GameMode, _load_subscreen
done:
        rts
.endproc

.proc _load_subscreen
        ; We are about to clobber the HUD state, so write a blank palette
        near_call FAR_write_blank_hud_palette
        ; And reset the HUD to its initial state. (This won't take effect until
        ; we exit the subscreen later, but this will cause the HUD to re-initialize
        ; itself and restore all of its graphics tiles and palette.)
        near_call FAR_init_statusbar

        ; The subscreen does not use the HUD, so stop updating the palette for it
        lda #0
        sta HudPaletteActive

        ; Initialize the subscreen state machine
        far_call FAR_init_subscreen
        
        st16 GameMode, _subscreen_active

        rts
.endproc

.proc _subscreen_active
        far_call FAR_update_subscreen

        ; starting IRQ index for the subscreen
        lda inactive_irq_index
        sta R0

        ; CHR bank to use for BG graphics
        debug_color TINT_R | TINT_B
        far_call FAR_generate_subscreen
        debug_color 0 ; disable debug colors

        jsr swap_irq_buffers
        jsr wait_for_next_vblank

        ; refresh the animation timer (... repeatedly) so that it starts in the right spot
        ; when we close the subscreen
        lda #20
        sta FadeTimer

        rts
.endproc

.proc return_from_subscreen
        lda #1
        sta HudPaletteActive

        lda #0
        sta FadeTimer
        st16 GameMode, _blackin_from_subscreen
        rts
.endproc

.proc _blackin_from_subscreen
        ; increment the fade timer
        inc FadeTimer
        ; use that to determine the current brightness
        lda FadeTimer
        lsr
        jsr set_brightness
        ; now, execute a standard game loop
        jsr standard_gameplay_loop
        ; finally, if our FadeTimer has capped out, switch to standard gameplay. We're done!
        lda FadeTimer
        cmp #8
        bne done
        st16 GameMode, standard_gameplay_loop
done:
        rts
.endproc

.proc init_main_menu
        ; The main menu does not use the HUD, so make sure we don't update the palette for it
        ; (otherwise NMI will screw with our nametable updates)
        lda #0
        sta HudPaletteActive

        ; Initialize the subscreen state machine
        far_call FAR_init_main_menu
        
        st16 GameMode, _main_menu_active

        rts
.endproc

.proc _main_menu_active
        far_call FAR_update_main_menu

        ; starting IRQ index for the subscreen
        lda inactive_irq_index
        sta R0

        ; CHR bank to use for BG graphics
        debug_color TINT_R | TINT_B
        far_call FAR_generate_subscreen
        debug_color 0 ; disable debug colors

        jsr swap_irq_buffers
        jsr wait_for_next_vblank

        ; refresh the animation timer (... repeatedly) so that it starts in the right spot
        ; when we close the subscreen
        lda #20
        sta FadeTimer

        rts
.endproc


        .setcpu "6502"
        .include "boxgirl.inc"
        .include "branch_util.inc"
        .include "collision.inc"
        .include "far_call.inc"
        .include "kernel.inc"
        .include "map.inc"
        .include "mmc3.inc"
        .include "nes.inc"
        .include "input.inc"
        .include "scrolling.inc"
        .include "sound.inc"
        .include "sprites.inc"
        .include "entity.inc"
        .include "palette.inc"
        .include "physics.inc"
        .include "word_util.inc"
        .include "zeropage.inc"

        ; temp
        .include "levels.inc"

        .segment "PRGFIXED_E000"
; Note: this needs to bank in the map header, so it lives in fixed memory
.proc handle_teleport
MapAddr := R0
TestPosX := R3
TestTileX := R4
TestPosY := R5
TestTileY := R6
ExitTableAddr := R7
MetaSpriteIndex := R9
        ; helpfully our scratch registers are still set from the physics function,
        ; so we don't need to re-do the lookup here
        
        ; The target registers are our currently loaded map. Use these to locate the
        ; map header
        access_data_bank TargetMapBank
        lda TargetMapAddr
        sta MapAddr
        lda TargetMapAddr+1
        sta MapAddr+1

        ldy #MapHeader::exit_table_ptr
        lda (MapAddr), y
        sta ExitTableAddr
        iny
        lda (MapAddr), y
        sta ExitTableAddr+1


        ; loop through all the exits, stopping if we find a match for our current tile position
        ldy #0
        lda (ExitTableAddr), y ; length byte
        inc16 ExitTableAddr
        jeq done ; sanity check, can't leave a map with no exits defined
        tax ; x is otherwise unused, so it is our counter
loop:
        ldy #ExitTableEntry::tile_x
        lda (ExitTableAddr), y
        cmp TestTileX
        jne no_match
        ldy #ExitTableEntry::tile_y
        lda (ExitTableAddr), y
        cmp TestTileY
        jne no_match

        ; MATCH FOUND (!!!)

        ; Set these map details as our new target map
        ldy #ExitTableEntry::target_map
        lda (ExitTableAddr), y
        sta TargetMapAddr
        ldy #ExitTableEntry::target_map+1
        lda (ExitTableAddr), y
        sta TargetMapAddr+1
        ldy #ExitTableEntry::target_bank
        lda (ExitTableAddr), y
        sta TargetMapBank
        ldy #ExitTableEntry::target_entrance
        lda (ExitTableAddr), y
        sta TargetMapEntrance

        ; Set the new game mode to "load a new map"
        st16 GameMode, blackout_to_new_map

        ; play a nifty "whoosh" sfx
        st16 R0, sfx_teleport
        jsr play_sfx_pulse2

        ; switch boxgirl to the teleport state and animation
        ldx CurrentEntityIndex
        lda #0
        sta entity_table + EntityState::SpeedZ, x
        lda entity_table + EntityState::MetaSpriteIndex, x
        sta MetaSpriteIndex
        set_metasprite_animation MetaSpriteIndex, boxgirl_anim_teleport
        set_update_func CurrentEntityIndex, boxgirl_teleport

        ; cleanup and let the kernel handle the rest
        jmp done

no_match:
        clc
        add16 ExitTableAddr, #.sizeof(ExitTableEntry)
        dex
        jne loop
        ; we did NOT find a valid exit. Do nothing!
done:
        restore_previous_bank
        rts
.endproc


        .segment "PRGFIXED_8000" ; will eventually move to an AI page
        .include "animations/boxgirl/idle.inc"
        .include "animations/boxgirl/move.inc"
        .include "animations/boxgirl/teleport.inc"
        .include "animations/shadow/flicker.inc"

WALKING_SPEED = 16
WALKING_ACCEL = 2

; because of how this is used by the macro which applies friction,
; this must be a define and not a numeric constant
.define SLIPPERINESS 4

; Reminder: Data only goes up to 5
; Some of these probably need to be global
; ... the entity struct is gonna need to be bigger
; (other musings, etc)
DATA_FLAGS = 0

FLAG_FACING =  %00000001
FACING_LEFT =  %00000001
FACING_RIGHT = %00000000

; mostly performs a whole bunch of one-time setup
; expects the entity position to have been set by whatever did the initial spawning
.proc boxgirl_init
        ; allocate our main character sprite
        jsr find_unused_metasprite
        lda #$FF
        cmp R0
        jeq failed_to_spawn
        ldy CurrentEntityIndex
        lda R0
        sta entity_table + EntityState::MetaSpriteIndex, y
        ; basic initialization of the main sprite
        set_metasprite_animation R0, boxgirl_anim_idle_right
        set_metasprite_tile_offset R0, #0
        set_metasprite_palette_offset R0, #0
        ldx R0
        metasprite_set_flag FLAG_VISIBILITY, VISIBILITY_DISPLAYED
        ; allocate a shadow sprite
        jsr find_unused_metasprite
        lda #$FF
        cmp R0
        beq failed_to_spawn
        ldy CurrentEntityIndex
        lda R0
        sta entity_table + EntityState::ShadowSpriteIndex, y
        ; basic init for the shadow sprite
        set_metasprite_animation R0, shadow_flicker
        set_metasprite_tile_offset R0, #$18 ; note: probably move this to its own bank later
        set_metasprite_palette_offset R0, #0
        ldx R0
        metasprite_set_flag FLAG_VISIBILITY, VISIBILITY_DISPLAYED

        jsr set_3d_metasprite_pos

        ; use data bytes 0 and 1 to track speed
        lda #0
        ldy CurrentEntityIndex
        sta entity_table + EntityState::SpeedX, y
        sta entity_table + EntityState::SpeedY, y
        sta entity_table + EntityState::SpeedZ, y
        ; default our ground height to 0
        sta entity_table + EntityState::PositionZ, y
        sta entity_table + EntityState::PositionZ+1, y
        ; set all flag bits to 0
        sta entity_table + EntityState::Data + DATA_FLAGS, y
        ; finally, switch to the idle routine
        set_update_func CurrentEntityIndex, boxgirl_idle
        rts
failed_to_spawn:
        despawn_entity CurrentEntityIndex
        rts
.endproc



; works out the proper location to display the character and shadow metasprite, based
; on the character's position and current height relative to the ground
.proc set_3d_metasprite_pos
MetaSpriteIndex := R0
        ldy CurrentEntityIndex

        ; We'll work on the main sprite first
        ldx entity_table + EntityState::MetaSpriteIndex, y

        ; first, copy the coordinates into place
        lda entity_table + EntityState::PositionX, y
        sta metasprite_table + MetaSpriteState::PositionX, x
        lda entity_table + EntityState::PositionX+1, y
        sta metasprite_table + MetaSpriteState::PositionX+1, x
        lda entity_table + EntityState::PositionY, y
        sta metasprite_table + MetaSpriteState::PositionY, x
        lda entity_table + EntityState::PositionY+1, y
        sta metasprite_table + MetaSpriteState::PositionY+1, x

        ; Now we need to subtract the player's height from their Y coordinate
        sec
        lda metasprite_table + MetaSpriteState::PositionY, x
        sbc entity_table + EntityState::PositionZ, y
        sta metasprite_table + MetaSpriteState::PositionY, x
        lda metasprite_table + MetaSpriteState::PositionY+1, x
        sbc entity_table + EntityState::PositionZ + 1, y
        sta metasprite_table + MetaSpriteState::PositionY+1, x

        ; now, shift the metasprite position to the right by 4, taking
        ; the coordinates from *subtile* space to *pixel* space
        .repeat 4
        lsr metasprite_table + MetaSpriteState::PositionX+1, x
        ror metasprite_table + MetaSpriteState::PositionX, x
        .endrepeat
        .repeat 4
        lsr metasprite_table + MetaSpriteState::PositionY+1, x
        ror metasprite_table + MetaSpriteState::PositionY, x
        .endrepeat

        ; Alright now, repeat most of the above but for the shadow sprite
        ldx entity_table + EntityState::ShadowSpriteIndex, y
        stx MetaSpriteIndex

        ; Shadow check: is our height nonzero?
        lda entity_table + EntityState::PositionZ, y
        ora entity_table + EntityState::PositionZ + 1, y
        jeq no_shadow

        ; x already contains MetaSpriteIndex
        metasprite_set_flag FLAG_VISIBILITY, VISIBILITY_DISPLAYED

        ; copy the coordinates into place
        lda entity_table + EntityState::PositionX, y
        sta metasprite_table + MetaSpriteState::PositionX, x
        lda entity_table + EntityState::PositionX+1, y
        sta metasprite_table + MetaSpriteState::PositionX+1, x
        lda entity_table + EntityState::PositionY, y
        sta metasprite_table + MetaSpriteState::PositionY, x
        lda entity_table + EntityState::PositionY+1, y
        sta metasprite_table + MetaSpriteState::PositionY+1, x

        ; now, shift the metasprite position to the right by 4, taking
        ; the coordinates from *subtile* space to *pixel* space
        .repeat 4
        lsr metasprite_table + MetaSpriteState::PositionX+1, x
        ror metasprite_table + MetaSpriteState::PositionX, x
        .endrepeat
        .repeat 4
        lsr metasprite_table + MetaSpriteState::PositionY+1, x
        ror metasprite_table + MetaSpriteState::PositionY, x
        .endrepeat

        ; done drawing the shadow, get outta here
        rts

no_shadow:
        ; There is no shadow to draw; turn off the shadow animation
        ; x already contains MetaSpriteIndex
        metasprite_set_flag FLAG_VISIBILITY, VISIBILITY_HIDDEN
        ; and done
        rts
.endproc

JUMP_SPEED = 48

.proc apply_jump
        ldx CurrentEntityIndex
        lda #JUMP_SPEED
        sta entity_table + EntityState::SpeedZ, x
        rts
.endproc

.proc walking_acceleration
        ldx CurrentEntityIndex
check_right:
        lda #KEY_RIGHT
        bit ButtonsHeld
        beq right_not_held
        ; right is held, so accelerate to the +X
        accelerate entity_table + EntityState::SpeedX, #WALKING_ACCEL
        max_speed entity_table + EntityState::SpeedX, #WALKING_SPEED
        ; note: we explicitly skip checking for left, to work around
        ; worn controllers and broken emulators; right wins
        jmp check_up
right_not_held:
check_left:
        lda #KEY_LEFT
        bit ButtonsHeld
        beq left_not_held
        ; left is held, so accelerate to the -X
        accelerate entity_table + EntityState::SpeedX, #(256-WALKING_ACCEL)
        min_speed entity_table + EntityState::SpeedX, #(256-WALKING_SPEED)
        jmp check_up
left_not_held:
        apply_friction entity_table + EntityState::SpeedX, SLIPPERINESS
check_up:
        lda #KEY_UP
        bit ButtonsHeld
        beq up_not_held
        ; up is held, so accelerate to the -Y
        accelerate entity_table + EntityState::SpeedY, #(256-WALKING_ACCEL)
        min_speed entity_table + EntityState::SpeedY, #(256-WALKING_SPEED)
        ; note: we explicitly skip checking for down, to work around
        ; worn controllers and broken emulators; up wins
        jmp done
up_not_held:
check_down:
        lda #KEY_DOWN
        bit ButtonsHeld
        beq down_not_held
        ; down is held, so accelerate to the +Y
        accelerate entity_table + EntityState::SpeedY, #WALKING_ACCEL
        max_speed entity_table + EntityState::SpeedY, #WALKING_SPEED
        jmp done
down_not_held:
        apply_friction entity_table + EntityState::SpeedY, SLIPPERINESS
done:
        rts
.endproc

.proc pick_walk_animation
MetaSpriteIndex := R0
        ldy CurrentEntityIndex
        lda entity_table + EntityState::MetaSpriteIndex, y
        sta MetaSpriteIndex

        lda #KEY_RIGHT
        bit ButtonsHeld
        beq right_not_held
        ; switch to the walk right animation and state
        set_metasprite_animation MetaSpriteIndex, boxgirl_anim_move_right
        set_update_func CurrentEntityIndex, boxgirl_walk_right
        rts
right_not_held:       
        lda #KEY_LEFT
        bit ButtonsHeld
        beq left_not_held
        ; switch to the walk right animation and state
        set_metasprite_animation MetaSpriteIndex, boxgirl_anim_move_left
        set_update_func CurrentEntityIndex, boxgirl_walk_left
        rts
left_not_held:
        lda #KEY_UP
        bit ButtonsHeld
        beq up_not_held
        ; switch to the walk right animation and state
        set_metasprite_animation MetaSpriteIndex, boxgirl_anim_move_up
        set_update_func CurrentEntityIndex, boxgirl_walk_up
        rts
up_not_held:
        lda #KEY_DOWN
        bit ButtonsHeld
        beq down_not_held
        ; switch to the walk right animation and state
        set_metasprite_animation MetaSpriteIndex, boxgirl_anim_move_down
        set_update_func CurrentEntityIndex, boxgirl_walk_down
        rts
down_not_held:
        set_update_func CurrentEntityIndex, boxgirl_idle
        ; pick an idle state based on our most recent walking direction
        ldy CurrentEntityIndex
        entity_check_flag FLAG_FACING
        bne facing_left
facing_right:
        set_metasprite_animation MetaSpriteIndex, boxgirl_anim_idle_right
        rts
facing_left:
        set_metasprite_animation MetaSpriteIndex, boxgirl_anim_idle_left
        rts
.endproc

; we probably want to reorganize the states later, and separate the concept of "facing direction"
; out from everything else, as it results in a lot of tedious duplication. Anyway though, for jumping
; we really just need to check if the player is grounded and set their vertical speed, so let's
; do that.
.proc handle_jump
        ; have we pressed the jump button?
        lda #KEY_A
        bit ButtonsDown
        beq jump_not_pressed
        ; are we currently grounded? (height == 0)
        ldx CurrentEntityIndex
        lda entity_table + EntityState::PositionZ, x
        ora entity_table + EntityState::PositionZ + 1, x
        bne not_grounded
        ; set our upwards velocity immediately; gravity will take
        ; care of the rest
        lda #JUMP_SPEED
        sta entity_table + EntityState::SpeedZ, x
        ; play a jump sfx
        st16 R0, sfx_jump
        jsr play_sfx_pulse2
not_grounded:
jump_not_pressed:
        rts
.endproc


.proc handle_ground_tile
GroundType := R0
        lda GroundType
        beq done

        cmp #(1 << 2) ; MAGIC NUMBER == EXIT
        bne done
        jsr handle_teleport
done:
        rts
.endproc

; === States ===

.proc boxgirl_idle
        jsr handle_jump
        jsr walking_acceleration
        ; apply physics normally
        far_call FAR_standard_entity_vertical_acceleration
        far_call FAR_apply_standard_entity_speed
        jsr set_3d_metasprite_pos
        ; check for special ground tiles
        far_call FAR_sense_ground
        jsr handle_ground_tile
        ; check for state changes
        lda #(KEY_RIGHT | KEY_LEFT | KEY_UP | KEY_DOWN)
        bit ButtonsHeld
        beq still_idle
        jsr pick_walk_animation
still_idle:
        ; DEBUG DEBUG TEST REMOVE LATER
        lda #(KEY_SELECT)
        bit ButtonsHeld
        beq all_done
        ; While holding select, press Up to increase the brightness:
check_up:
        lda #(KEY_UP)
        bit ButtonsDown
        beq check_down
increase_brightness:
        lda #8
        cmp Brightness
        beq check_down
        inc Brightness
        lda #1
        sta ObjPaletteDirty
        sta BgPaletteDirty

check_down:
        lda #(KEY_DOWN)
        bit ButtonsDown
        beq all_done
decrease_brightness:
        lda Brightness
        beq check_down
        dec Brightness
        lda #1
        sta ObjPaletteDirty
        sta BgPaletteDirty

all_done:
        rts
.endproc

.proc boxgirl_walk_right
        jsr handle_jump
        jsr walking_acceleration
        ; apply physics normally
        far_call FAR_standard_entity_vertical_acceleration
        far_call FAR_apply_standard_entity_speed
        jsr set_3d_metasprite_pos
        ; check for special ground tiles
        far_call FAR_sense_ground
        jsr handle_ground_tile
        ; set our "last facing" bit to the right
        ldy CurrentEntityIndex
        entity_set_flag FLAG_FACING, FACING_RIGHT
        ; check for state changes
        lda #KEY_RIGHT
        bit ButtonsHeld
        bne right_not_held
        ; switch to the idle right animation and state
        jsr pick_walk_animation
right_not_held:
        rts
.endproc

.proc boxgirl_walk_left
        jsr handle_jump
        jsr walking_acceleration
        ; apply physics normally
        far_call FAR_standard_entity_vertical_acceleration
        far_call FAR_apply_standard_entity_speed
        jsr set_3d_metasprite_pos
        ; check for special ground tiles
        far_call FAR_sense_ground
        jsr handle_ground_tile
        ; set our "last facing" bit to the left
        ldy CurrentEntityIndex
        entity_set_flag FLAG_FACING, FACING_LEFT
        ; check for state changes
        lda #KEY_LEFT
        bit ButtonsHeld
        bne left_not_held
        ; switch to the idle right animation and state
        jsr pick_walk_animation
left_not_held:
        rts
.endproc

.proc boxgirl_walk_up
        jsr handle_jump
        jsr walking_acceleration
        ; apply physics normally
        far_call FAR_standard_entity_vertical_acceleration
        far_call FAR_apply_standard_entity_speed
        jsr set_3d_metasprite_pos
        ; check for special ground tiles
        far_call FAR_sense_ground
        jsr handle_ground_tile
        ; check for state changes
        lda #KEY_UP
        bit ButtonsHeld
        bne up_not_held
        ; switch to the idle right animation and state
        jsr pick_walk_animation
up_not_held:
        rts
.endproc

.proc boxgirl_walk_down
        jsr handle_jump
        jsr walking_acceleration
        ; apply physics normally
        far_call FAR_standard_entity_vertical_acceleration
        far_call FAR_apply_standard_entity_speed
        jsr set_3d_metasprite_pos
        ; check for special ground tiles
        far_call FAR_sense_ground
        jsr handle_ground_tile
        ; check for state changes
        lda #KEY_DOWN
        bit ButtonsHeld
        bne down_not_held
        ; switch to the idle right animation and state
        jsr pick_walk_animation
down_not_held:
        rts
.endproc

.proc boxgirl_teleport
        ; freeze position, and rise into the air
        ldx CurrentEntityIndex
        lda entity_table + EntityState::SpeedZ, x
        sta R0
        sadd16x entity_table + EntityState::PositionZ, R0
        lda entity_table + EntityState::SpeedZ, x
        adc #10
        bmi no_store
        sta entity_table + EntityState::SpeedZ, x
no_store:
        jsr set_3d_metasprite_pos        

        rts
.endproc
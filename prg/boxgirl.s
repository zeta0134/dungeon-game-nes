        .setcpu "6502"
        .include "branch_util.inc"
        .include "nes.inc"
        .include "collision_3d.inc"
        .include "input.inc"
        .include "sprites.inc"
        .include "entity.inc"
        .include "physics.inc"
        .include "word_util.inc"
        .include "zeropage.inc"

.scope PRGLAST_E000
        .segment "PRGLAST_C000"
        ;.org $e000
        .include "animations/boxgirl/idle.inc"
        .include "animations/boxgirl/move.inc"
        .include "animations/shadow/flicker.inc"
        .export boxgirl_init

WALKING_SPEED = 16
WALKING_ACCEL = 2

; because of how this is used by the macro which applies friction,
; this must be a define and not a numeric constant
.define SLIPPERINESS 4

; Reminder: Data only goes up to 5
; Some of these probably need to be global
; ... the entity struct is gonna need to be bigger
; (other musings, etc)
DATA_SPEED_X = 0
DATA_SPEED_Y = 1
DATA_SPEED_Z = 2
DATA_FLAGS = 3

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
        sta entity_table + EntityState::Data + DATA_SPEED_X, y
        sta entity_table + EntityState::Data + DATA_SPEED_Y, y
        ; set all flag bits to 0
        sta entity_table + EntityState::Data + DATA_FLAGS, y
        ; finally, switch to the idle routine
        set_update_func CurrentEntityIndex, boxgirl_idle
        rts
failed_to_spawn:
        despawn_entity CurrentEntityIndex
        rts
.endproc

.proc apply_speed
LeftX := R1
RightX := R2
VerticalOffset := R3
        ; set our palette index to 0 by default, for debugging
        ldx CurrentEntityIndex
        ldy entity_table + EntityState::MetaSpriteIndex, x
        lda #0
        sta metasprite_table + MetaSpriteState::PaletteOffset, y

        ; Set up the hitbox coordinates for collision
        ; Note: later when we generalize "apply_speed", we need to move
        ; these registers somewhere more global probably

        ; Boxgirl's "hitbox" is more like a hit line segment, with a
        ; left and right edge, and a height relative to her position.
        ; For now, make that height at position 0.

        ; left
        lda #(3 << 4)
        sta LeftX
        ; right
        lda #(12 << 4)
        sta RightX
        ; top
        lda #(0 << 4)
        sta VerticalOffset

        ; apply speed to position for each axis, then check the
        ; tilemap and correct for any tile collisions
        ldx CurrentEntityIndex
        lda entity_table + EntityState::Data + DATA_SPEED_X, x
        sta R0
        bmi move_left
move_right:
        sadd16x entity_table + EntityState::PositionX, R0
        jsr collide_right_with_map_3d
        jmp done_with_x
move_left:
        sadd16x entity_table + EntityState::PositionX, R0
        jsr collide_left_with_map_3d
done_with_x:
        ldx CurrentEntityIndex
        lda entity_table + EntityState::Data + DATA_SPEED_Y, x
        sta R0
        bmi move_up
move_down:
        sadd16x entity_table + EntityState::PositionY, R0
        jsr collide_down_with_map_3d
        jmp done
move_up:
        sadd16x entity_table + EntityState::PositionY, R0
        jsr collide_up_with_map_3d

done:
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

GRAVITY_ACCEL = ($FF - 2)
TERMINAL_VELOCITY = ($FF - 60)
JUMP_SPEED = 48

.proc vertical_acceleration
        ldx CurrentEntityIndex
        ; first apply the player's current speed to their height coordinate
        lda entity_table + EntityState::Data + DATA_SPEED_Z, x
        sta R0
        sadd16x entity_table + EntityState::PositionZ, R0
        ; if their height coordinate is now negative, cap it at 0
        lda entity_table + EntityState::PositionZ + 1, x
        bpl height_not_negative
        lda #0
        sta entity_table + EntityState::PositionZ, x
        sta entity_table + EntityState::PositionZ+1, x
height_not_negative:
        ; Now apply acceleration due to gravity, and clamp it to the terminal velocity
        accelerate entity_table + EntityState::Data + DATA_SPEED_Z, #GRAVITY_ACCEL
        min_speed entity_table + EntityState::Data + DATA_SPEED_Z, #TERMINAL_VELOCITY
        ; and we should be done
        rts
.endproc

.proc apply_jump
        ldx CurrentEntityIndex
        lda #JUMP_SPEED
        sta entity_table + EntityState::Data + DATA_SPEED_Z, x
        rts
.endproc

.proc walking_acceleration
        ldx CurrentEntityIndex
check_right:
        lda #KEY_RIGHT
        bit ButtonsHeld
        beq right_not_held
        ; right is held, so accelerate to the +X
        accelerate entity_table + EntityState::Data + DATA_SPEED_X, #WALKING_ACCEL
        max_speed entity_table + EntityState::Data + DATA_SPEED_X, #WALKING_SPEED
        ; note: we explicitly skip checking for left, to work around
        ; worn controllers and broken emulators; right wins
        jmp check_up
right_not_held:
check_left:
        lda #KEY_LEFT
        bit ButtonsHeld
        beq left_not_held
        ; left is held, so accelerate to the -X
        accelerate entity_table + EntityState::Data + DATA_SPEED_X, #(256-WALKING_ACCEL)
        min_speed entity_table + EntityState::Data + DATA_SPEED_X, #(256-WALKING_SPEED)
        jmp check_up
left_not_held:
        apply_friction entity_table + EntityState::Data + DATA_SPEED_X, SLIPPERINESS
check_up:
        lda #KEY_UP
        bit ButtonsHeld
        beq up_not_held
        ; up is held, so accelerate to the -Y
        accelerate entity_table + EntityState::Data + DATA_SPEED_Y, #(256-WALKING_ACCEL)
        min_speed entity_table + EntityState::Data + DATA_SPEED_Y, #(256-WALKING_SPEED)
        ; note: we explicitly skip checking for down, to work around
        ; worn controllers and broken emulators; up wins
        jmp done
up_not_held:
check_down:
        lda #KEY_DOWN
        bit ButtonsHeld
        beq down_not_held
        ; down is held, so accelerate to the +Y
        accelerate entity_table + EntityState::Data + DATA_SPEED_Y, #WALKING_ACCEL
        max_speed entity_table + EntityState::Data + DATA_SPEED_Y, #WALKING_SPEED
        jmp done
down_not_held:
        apply_friction entity_table + EntityState::Data + DATA_SPEED_Y, SLIPPERINESS
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
        sta entity_table + EntityState::Data + DATA_SPEED_Z, x
not_grounded:
jump_not_pressed:
        rts
.endproc

.proc boxgirl_idle
        jsr handle_jump
        jsr walking_acceleration
        jsr vertical_acceleration
        ; apply physics normally
        jsr apply_speed
        jsr set_3d_metasprite_pos
        ; check for state changes
        lda #(KEY_RIGHT | KEY_LEFT | KEY_UP | KEY_DOWN)
        bit ButtonsHeld
        beq still_idle
        jsr pick_walk_animation
still_idle:
        rts
.endproc

.proc boxgirl_walk_right
        jsr handle_jump
        jsr walking_acceleration
        jsr vertical_acceleration
        ; apply physics normally
        jsr apply_speed
        jsr set_3d_metasprite_pos
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
        jsr vertical_acceleration
        ; apply physics normally
        jsr apply_speed
        jsr set_3d_metasprite_pos
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
        jsr vertical_acceleration
        ; apply physics normally
        jsr apply_speed
        jsr set_3d_metasprite_pos
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
        jsr vertical_acceleration
        ; apply physics normally
        jsr apply_speed
        jsr set_3d_metasprite_pos
        ; check for state changes
        lda #KEY_DOWN
        bit ButtonsHeld
        bne down_not_held
        ; switch to the idle right animation and state
        jsr pick_walk_animation
down_not_held:
        rts
.endproc


.endscope

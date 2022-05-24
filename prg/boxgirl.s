        .setcpu "6502"
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
        .export boxgirl_init

WALKING_SPEED = 16
WALKING_ACCEL = 2

; because of how this is used by the macro which applies friction,
; this must be a define and not a numeric constant
.define SLIPPERINESS 4

DATA_SPEED_X = 0
DATA_SPEED_Y = 1
DATA_FLAGS = 2

FLAG_FACING =  %00000001
FACING_LEFT =  %00000001
FACING_RIGHT = %00000000

; note: assumes Y is already set to CurrentEntityIndex
.macro set_flag flag_mask, flag_value
        lda entity_table + EntityState::Data + DATA_FLAGS, y
        and #(flag_mask ^ $FF)
        ora #flag_value
        sta entity_table + EntityState::Data + DATA_FLAGS, y
.endmacro

; note: assumes Y is already set to CurrentEntityIndex
.macro check_flag flag_mask
        lda entity_table + EntityState::Data + DATA_FLAGS, y
        and #flag_mask
        ; now you can beq for unset, and bne for flag set
.endmacro

; mostly performs a whole bunch of one-time setup
; expects the entity position to have been set by whatever did the initial spawning
.proc boxgirl_init
        jsr find_unused_metasprite
        lda #$FF
        cmp R0
        beq failed_to_spawn
        ldy CurrentEntityIndex
        sty R1 ; used to set entity position in a moment
        lda R0
        sta entity_table + EntityState::MetaSpriteIndex, y
        set_metasprite_animation R0, boxgirl_anim_idle_right
        ; uses the EntityIndex in R1 and the MetaSprite index, still in R0 at this point
        jsr set_metasprite_pos
        ; ensure the rest of the metasprite attributes are sensibly defaulted
        set_metasprite_tile_offset R0, #0
        set_metasprite_palette_offset R0, #0
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
        lda #KEY_RIGHT
        bit ButtonsHeld
        beq right_not_held
        ; switch to the walk right animation and state
        set_metasprite_animation R0, boxgirl_anim_move_right
        set_update_func CurrentEntityIndex, boxgirl_walk_right
        rts
right_not_held:       
        lda #KEY_LEFT
        bit ButtonsHeld
        beq left_not_held
        ; switch to the walk right animation and state
        set_metasprite_animation R0, boxgirl_anim_move_left
        set_update_func CurrentEntityIndex, boxgirl_walk_left
        rts
left_not_held:
        lda #KEY_UP
        bit ButtonsHeld
        beq up_not_held
        ; switch to the walk right animation and state
        set_metasprite_animation R0, boxgirl_anim_move_up
        set_update_func CurrentEntityIndex, boxgirl_walk_up
        rts
up_not_held:
        lda #KEY_DOWN
        bit ButtonsHeld
        beq down_not_held
        ; switch to the walk right animation and state
        set_metasprite_animation R0, boxgirl_anim_move_down
        set_update_func CurrentEntityIndex, boxgirl_walk_down
        rts
down_not_held:
        set_update_func CurrentEntityIndex, boxgirl_idle
        ; pick an idle state based on our most recent walking direction
        ldy CurrentEntityIndex
        check_flag FLAG_FACING
        bne facing_left
facing_right:
        set_metasprite_animation R0, boxgirl_anim_idle_right
        rts
facing_left:
        set_metasprite_animation R0, boxgirl_anim_idle_left
        rts
.endproc

.proc boxgirl_idle
        jsr walking_acceleration
        ; apply physics normally
        jsr apply_speed
        ldx CurrentEntityIndex
        txa
        sta R1
        lda entity_table + EntityState::MetaSpriteIndex, x
        sta R0
        jsr set_metasprite_pos
        ; check for state changes
        lda #(KEY_RIGHT | KEY_LEFT | KEY_UP | KEY_DOWN)
        bit ButtonsHeld
        beq still_idle
        jsr pick_walk_animation
still_idle:
        rts
.endproc

.proc boxgirl_walk_right
        jsr walking_acceleration
        ; apply physics normally
        jsr apply_speed
        ldx CurrentEntityIndex
        txa
        sta R1
        lda entity_table + EntityState::MetaSpriteIndex, x
        sta R0
        jsr set_metasprite_pos
        ; set our "last facing" bit to the right
        ldy CurrentEntityIndex
        set_flag FLAG_FACING, FACING_RIGHT
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
        jsr walking_acceleration
        ; apply physics normally
        jsr apply_speed
        ldx CurrentEntityIndex
        txa
        sta R1
        lda entity_table + EntityState::MetaSpriteIndex, x
        sta R0
        jsr set_metasprite_pos
        ; set our "last facing" bit to the left
        ldy CurrentEntityIndex
        set_flag FLAG_FACING, FACING_LEFT
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
        jsr walking_acceleration
        ; apply physics normally
        jsr apply_speed
        ldx CurrentEntityIndex
        txa
        sta R1
        lda entity_table + EntityState::MetaSpriteIndex, x
        sta R0
        jsr set_metasprite_pos
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
        jsr walking_acceleration
        ; apply physics normally
        jsr apply_speed
        ldx CurrentEntityIndex
        txa
        sta R1
        lda entity_table + EntityState::MetaSpriteIndex, x
        sta R0
        jsr set_metasprite_pos
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

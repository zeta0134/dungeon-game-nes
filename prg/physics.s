        .setcpu "6502"
        .include "sprites.inc"
        .include "entity.inc"
        .include "collision.inc"
        .include "far_call.inc"
        .include "physics.inc"
        .include "word_util.inc"
        .include "zeropage.inc"

        .segment "PHYSICS_A000"

.proc FAR_apply_standard_entity_speed
LeftX := R1
RightX := R2
VerticalOffset := R3
        ; set our palette index to 0 by default, for debugging
        ldx CurrentEntityIndex
        ldy entity_table + EntityState::MetaSpriteIndex, x
        lda #0
        sta metasprite_table + MetaSpriteState::PaletteOffset, y

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
        lda entity_table + EntityState::SpeedX, x
        sta R0
        bmi move_left
move_right:
        sadd16x entity_table + EntityState::PositionX, R0
        far_call FAR_collide_right_with_map
        jmp done_with_x
move_left:
        sadd16x entity_table + EntityState::PositionX, R0
        far_call FAR_collide_left_with_map
done_with_x:
        ldx CurrentEntityIndex
        lda entity_table + EntityState::SpeedY, x
        sta R0
        bmi move_up
move_down:
        sadd16x entity_table + EntityState::PositionY, R0
        far_call FAR_collide_down_with_map
        jmp done
move_up:
        sadd16x entity_table + EntityState::PositionY, R0
        far_call FAR_collide_up_with_map

done:
        rts
.endproc

.proc FAR_standard_entity_vertical_acceleration
        ldx CurrentEntityIndex
        ; first apply the entity's current speed to their height coordinate
        lda entity_table + EntityState::SpeedZ, x
        sta R0
        sadd16x entity_table + EntityState::PositionZ, R0
        ; if their height coordinate is now negative, cap it at 0
        lda entity_table + EntityState::PositionZ + 1, x
        bpl height_not_negative
        lda #0
        sta entity_table + EntityState::PositionZ, x
        sta entity_table + EntityState::PositionZ+1, x
        ; also zero out speed, so that if we fall off a ledge we start accelerating again
        sta entity_table + EntityState::SpeedZ, x
height_not_negative:
        ; Now apply acceleration due to gravity, and clamp it to the terminal velocity
        accelerate entity_table + EntityState::SpeedZ, #GRAVITY_ACCEL
        min_speed entity_table + EntityState::SpeedZ, #TERMINAL_VELOCITY
        ; and we should be done
        rts
.endproc
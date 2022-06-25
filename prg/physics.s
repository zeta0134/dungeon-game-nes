        .setcpu "6502"
        .include "branch_util.inc"
        .include "sprites.inc"
        .include "entity.inc"
        .include "collision.inc"
        .include "far_call.inc"
        .include "scrolling.inc"
        .include "physics.inc"
        .include "word_util.inc"
        .include "zeropage.inc"

        .segment "PHYSICS_A000"

.proc FAR_apply_standard_entity_speed
LeftX := R1
RightX := R2
VerticalOffset := R3
        ; left
        lda #(3 << 4)
        sta LeftX
        ; right
        lda #(12 << 4)
        sta RightX

        ; apply speed to position for each axis, then check the
        ; tilemap and correct for any tile collisions
        ldx CurrentEntityIndex
        lda entity_table + EntityState::SpeedX, x
        sta R0
        ; if we aren't moving horizontally, don't perform collision
        ; in this direction at all
        beq done_with_x
        bmi move_left
move_right:
        sadd16x entity_table + EntityState::PositionX, R0
        near_call FAR_collide_right_with_map
        jmp done_with_x
move_left:
        sadd16x entity_table + EntityState::PositionX, R0
        near_call FAR_collide_left_with_map
done_with_x:
        ldx CurrentEntityIndex
        lda entity_table + EntityState::SpeedY, x
        sta R0
        ; if we aren't moving vertically, don't perform collision
        ; in this direction at all.
        ; TODO: if the map changes, do we need to unconditioanlly perform
        ; some basic collision check?
        beq done
        bmi move_up
move_down:
        sadd16x entity_table + EntityState::PositionY, R0
        near_call FAR_collide_down_with_map
        jmp done
move_up:
        sadd16x entity_table + EntityState::PositionY, R0
        near_call FAR_collide_up_with_map
        jmp done

done:
        apply_bg_priority        
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

.proc FAR_vertical_speed_only
        ; Does what it says on the tin. Some states ignore gravity momentarily; this
        ; handles speed and makes sure the player's height can't go negative, but
        ; skips all the other fancy junk.
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
height_not_negative:
        rts
.endproc

; Clobbers: R1-R6
; Returns: Ground value in R0

.proc FAR_sense_ground
GroundType := R0
CollisionFlags := R1
CollisionHeights := R2
; union, TileAddr is used last
TileAddr := R3
CenterX := R3
VerticalOffset := R4
; normal
TestPosX := R5
TestTileX := R6
TestPosY := R7
TestTileY := R8
        ; first of all, are we even on the ground?
        ldx CurrentEntityIndex
        lda entity_table + EntityState::PositionZ, x
        ora entity_table + EntityState::PositionZ+1, x
        bne not_grounded

        ; left
        lda #((7 << 4) + 8) ; 7 and one half
        sta CenterX

        tile_offset CenterX, TestPosX, TestPosY
        graphics_map_index TestTileX, TestTileY, TileAddr
        ldy #0
        lda (TileAddr), y
        tay
        lda TilesetAttributes, y ; a now contains combined attribute byte
        and #%11111100 ; strip off the palette
        sta GroundType
        beq boring_tile
        ; if this is an interesting tile, do some extra work and identify
        ; the collision properties
        nav_map_index TestTileX, TestTileY, TileAddr
        ldy #0
        lda (TileAddr), y
        tay ; now holds the collision index
        lda collision_heights, y
        sta CollisionHeights
        lda collision_flags, y
        sta CollisionFlags
boring_tile:
        rts
        
not_grounded:
        lda #0
        sta GroundType
        rts
.endproc

; No sensing logic, just grab the collision heights and flags
; underneath our feet
.proc FAR_ground_nav_properties
CollisionFlags := R1
CollisionHeights := R2
; union, TileAddr is used last
TileAddr := R3
CenterX := R3
VerticalOffset := R4
; normal
TestPosX := R5
TestTileX := R6
TestPosY := R7
TestTileY := R8
        ; left
        lda #((7 << 4) + 8) ; 7 and one half
        sta CenterX

        tile_offset CenterX, TestPosX, TestPosY
        nav_map_index TestTileX, TestTileY, TileAddr

        ldy #0
        lda (TileAddr), y
        tay ; now holds the collision index
        lda collision_heights, y
        sta CollisionHeights
        lda collision_flags, y
        sta CollisionFlags
        rts
.endproc
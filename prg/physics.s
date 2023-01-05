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

        .segment "RAM"
; Physics "Constants," tweakable by area
GravityAccel: .res 1
TerminalVelocity: .res 1

        .zeropage
RampLutPtr: .res 1

        .segment "PHYSICS_A000"

no_ramp_lut: ; identity, used to make ramp sampling code simpler and less dumb
        ; at px: 00, 01, 02, 03, 04, 05, 06, 07, 08, 09, 10, 11, 12, 13, 14, 15
        .byte     0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0

steep_ramp_east_lut:   ; towards +X
        ; at px: 00, 01, 02, 03, 04, 05, 06, 07, 08, 09, 10, 11, 12, 13, 14, 15
        .byte     1,  2,  3,  4,  5,  6,  7,  8,  9, 10, 11, 12, 13, 14, 15, 16

steep_ramp_west_lut:   ; towards -X
steep_ramp_north_lut:  ; towards -Y
        ; at px: 00, 01, 02, 03, 04, 05, 06, 07, 08, 09, 10, 11, 12, 13, 14, 15
        .byte    16, 15, 14, 13, 12, 11, 10,  9,  8,  7,  6,  5,  4,  3,  2,  1

ramp_types_table:
        .word no_ramp_lut
        .word steep_ramp_west_lut
        .word steep_ramp_east_lut
        .word steep_ramp_north_lut

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

        lda #0
        sta AccumulatedColFlags

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
        sadd16 {entity_table + EntityState::PositionX, x}, R0
        near_call FAR_collide_right_with_map
        jmp done_with_x
move_left:
        sadd16 {entity_table + EntityState::PositionX, x}, R0
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
        sadd16 {entity_table + EntityState::PositionY, x}, R0
        near_call FAR_collide_down_with_map
        jmp done
move_up:
        sadd16 {entity_table + EntityState::PositionY, x}, R0
        near_call FAR_collide_up_with_map
        jmp done

done:
        apply_bg_priority

        lda AccumulatedColFlags
        ; if we perform collision at all, we should have accumulated visible/hidden surface
        ; flags. Otherwise this byte will be entirely 0; in that case, do NOT perform any
        ; height adjustment and exit immediately
        bne check_ramp_adjustment
        rts
check_ramp_adjustment:
        and #%00111111
        sta AccumulatedColFlags
        beq no_ramp_adjustment
        jsr compute_ramp_height
        rts
no_ramp_adjustment:
        ldx CurrentEntityIndex
        lda #0
        sta entity_table + EntityState::RampHeight, x
        rts
.endproc

.proc FAR_standard_entity_vertical_acceleration
        ldx CurrentEntityIndex
        ; first apply the entity's current speed to their height coordinate
        sadd16 {entity_table + EntityState::PositionZ, x}, {entity_table + EntityState::SpeedZ, x}
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
        accelerate entity_table + EntityState::SpeedZ, GravityAccel
        min_speed entity_table + EntityState::SpeedZ, TerminalVelocity
        ; and we should be done
        rts
.endproc

.proc FAR_vertical_speed_only
        ; Does what it says on the tin. Some states ignore gravity momentarily; this
        ; handles speed and makes sure the player's height can't go negative, but
        ; skips all the other fancy junk.
        ldx CurrentEntityIndex
        ; first apply the entity's current speed to their height coordinate
        sadd16 {entity_table + EntityState::PositionZ, x}, {entity_table + EntityState::SpeedZ, x}
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

.proc compute_ramp_height
SampledRampHeight := R0

LeftX := R1
RightX := R2
  
SubtileX := R4
TileX := R5
SubtileY := R6
TileY := R7
TileAddr := R8

        ; At this stage we know that *some* ramp collision has occurred, now we need to work out the specifics.
        

        ; First, sample the left hitpoint and figure out the ramp height at this point
check_left_sample:
        tile_offset LeftX, SubtileX, SubtileY
        nav_map_index TileX, TileY, TileAddr
        ldy #0
        lda (TileAddr), y
        ; we only care about samples that match our current ground height, this
        ; deals with one foot hanging off a ledge near a ramp
        tax
        lda collision_heights, x
        ldy CurrentEntityIndex
        cmp entity_table + EntityState::GroundLevel, y
        bne check_right_sample

        lda collision_flags, x
        jsr sample_ramp_height ; clobbers X, Y
        sta SampledRampHeight

check_right_sample:
        tile_offset RightX, SubtileX, SubtileY
        nav_map_index TileX, TileY, TileAddr
        ldy #0
        lda (TileAddr), y
        ; we only care about samples that match our current ground height, this
        ; deals with one foot hanging off a ledge near a ramp
        tax
        lda collision_heights, x
        ldy CurrentEntityIndex
        cmp entity_table + EntityState::GroundLevel, y
        bne keep_left_sample

        lda collision_flags, x
        jsr sample_ramp_height ; clobbers X, Y

        ; Keep this height only if it's higher than the previous sample
        cmp SampledRampHeight
        bcc keep_left_sample
keep_right_sample:
        sta SampledRampHeight        
keep_left_sample:
        lda SampledRampHeight
        ldx CurrentEntityIndex
        sta entity_table + EntityState::RampHeight, x

        rts
.endproc

; ColFlags byte in A, test point X position in SubtileY
; Resulting height bonus in A
; Clobbers X, Y
.proc sample_ramp_height
SubtileX := R4

        ; First, work out what kind of ramp is here and set the approprite LUT
        ; TODO: expand this mask if we add more ramp types
        and #%00000011 ; safety
        asl
        tax
        lda ramp_types_table, x
        sta RampLutPtr
        lda ramp_types_table+1, x
        sta RampLutPtr+1
        ; Next work out the pixel position and use that to index the LUT
        lda SubtileX
        .repeat 4
        lsr
        .endrepeat
        tay
        lda (RampLutPtr), y 
        rts

.endproc
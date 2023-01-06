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
; (We never need both of these at the same time)
RampGroundHeight:
RampLutPtr: .res 2

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

shallow_ramp_east_lower_lut:
        ; at px: 00, 01, 02, 03, 04, 05, 06, 07, 08, 09, 10, 11, 12, 13, 14, 15
        .byte     1,  1,  2,  2,  3,  3,  4,  4,  5,  5,  6,  6,  7,  7,  8,  8

shallow_ramp_east_upper_lut:
        ; at px: 00, 01, 02, 03, 04, 05, 06, 07, 08, 09, 10, 11, 12, 13, 14, 15
        .byte     9,  9, 10, 10, 11, 11, 12, 12, 13, 13, 14, 14, 15, 15, 16, 16

shallow_ramp_west_lower_lut:
shallow_ramp_north_lower_lut:
        ; at px: 00, 01, 02, 03, 04, 05, 06, 07, 08, 09, 10, 11, 12, 13, 14, 15
        .byte     8,  8,  7,  7,  6,  6,  5,  5,  4,  4,  3,  3,  2,  2,  1,  1

shallow_ramp_west_upper_lut:
shallow_ramp_north_upper_lut:
        ; at px: 00, 01, 02, 03, 04, 05, 06, 07, 08, 09, 10, 11, 12, 13, 14, 15
        .byte    16, 16, 15, 15, 14, 14, 13, 13, 12, 12, 11, 11, 10, 10,  9,  9

ramp_types_table:
        .word no_ramp_lut
        .word steep_ramp_west_lut
        .word steep_ramp_east_lut
        .word steep_ramp_north_lut
        .word shallow_ramp_west_lower_lut
        .word shallow_ramp_west_upper_lut
        .word shallow_ramp_east_lower_lut
        .word shallow_ramp_east_upper_lut
        .word shallow_ramp_north_lower_lut
        .word shallow_ramp_north_upper_lut
        .word no_ramp_lut
        .word no_ramp_lut
        .word no_ramp_lut
        .word no_ramp_lut
        .word no_ramp_lut
        .word no_ramp_lut ; 0xF, just to fill out the table for safety reasons

; For speed reasons these are words, as the code responsible is called in a timing
; critical loop. We don't even have room in the collision table for more than 256
; ramp types (even 10 is pushing it honestly) so the high bytes of these words will
; always be 0. It's fine.
RAMP_DIRECTION_HORIZONTAL := 0
RAMP_DIRECTION_VERTICAL := 1
ramp_direction_table:
        .word RAMP_DIRECTION_HORIZONTAL ; no ramp, coordinate system doesn't matter
        .word RAMP_DIRECTION_HORIZONTAL ; steep west
        .word RAMP_DIRECTION_HORIZONTAL ; steep east
        .word RAMP_DIRECTION_VERTICAL   ; steep north
        .word RAMP_DIRECTION_HORIZONTAL ; shallow west lower
        .word RAMP_DIRECTION_HORIZONTAL ; shallow west upper
        .word RAMP_DIRECTION_HORIZONTAL ; shallow east lower
        .word RAMP_DIRECTION_HORIZONTAL ; shallow east upper
        .word RAMP_DIRECTION_VERTICAL ; shallow north lower
        .word RAMP_DIRECTION_VERTICAL ; shallow north upper
        ; no need to fill out the rest for safety; the LUT encodes 0px

HEIGHT_FUDGE = 2 ; pixels
HEIGHT_FUDGE_ACTUAL = (HEIGHT_FUDGE << 4) ; subtiles

.proc apply_height_fudge
        ldx CurrentEntityIndex
        add16b {entity_table + EntityState::PositionZ, x}, #HEIGHT_FUDGE_ACTUAL
        rts
.endproc

.proc remove_height_fudge
        ldx CurrentEntityIndex
        sec
        lda entity_table + EntityState::PositionZ, x
        sbc #HEIGHT_FUDGE_ACTUAL
        sta entity_table + EntityState::PositionZ, x
        lda entity_table + EntityState::PositionZ+1, x
        sbc #0
        sta entity_table + EntityState::PositionZ+1, x
        ; If this brings PositionZ into the negative (which it might, we just
        ; fudged a collision requirement) then zero it back out
        lda entity_table + EntityState::PositionZ+1, x
        bpl done
        lda #1
        sta entity_table + EntityState::PositionZ, x
        lda #0
        sta entity_table + EntityState::PositionZ+1, x
done:
        rts
.endproc

.proc FAR_apply_standard_entity_speed
LeftX := R1
RightX := R2
VerticalOffset := R3

SubtileX := R4
TileX := R5
SubtileY := R6
TileY := R7

OldLeftTileX := R16
OldRightTileX := R17
OldLeftTileY := R18
OldRightTileY := R18

        ; left
        lda #(3 << 4)
        sta LeftX
        ; right
        lda #(12 << 4)
        sta RightX

        lda #0
        sta AccumulatedColFlags

        ; First, compute the *current* tilex and tiley coordinates for both hitpoints.
        ; We'll use these during collision to bail early, skipping a lot of work and also
        ; avoiding some glitchy ramp behaviors
        ldx CurrentEntityIndex
        tile_offset LeftX, SubtileX, SubtileY
        lda TileX
        sta OldLeftTileX
        lda TileY
        sta OldLeftTileY

        tile_offset RightX, SubtileX, SubtileY
        lda TileX
        sta OldRightTileX
        lda TileY
        sta OldRightTileY

        ; Apply some wiggle room to upwards collision checks, mostly to make
        ; ramps behave, but also to make tight-looking jumps and dashes 
        ; somewhat more forgiving
        jsr apply_height_fudge

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
        ; Undo the changes we made to PositionZ, lest we float into the air (!)
        jsr remove_height_fudge
        apply_bg_priority

        ; Check to see if a new ramp was observed this frame
        ldx CurrentEntityIndex
        lda AccumulatedColFlags
        and #%00111111
        beq handle_ramp_adjustments
enable_ramp_mode:
        lda entity_table + EntityState::RampHeight, x
        ora #%10000000
        sta entity_table + EntityState::RampHeight, x
handle_ramp_adjustments:
        lda entity_table + EntityState::RampHeight, x
        and #%10000000
        beq ramps_not_enabled
        jsr update_ramp_height ; will disable ramps if one is not sampled
ramps_not_enabled:
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

.proc FAR_compute_ramp_height
        ; here we check for ramps. If we're nowhere near a ramp then we're done
        lda entity_table + EntityState::RampHeight, x
        ; if a ramp is active, we consider the ramp height to be our minimum ground height.
        ; ramp height is given in pixels, so expand that to a 16bit Z coordinate here
        asl
        asl
        asl
        asl ; possible bit into carry
        sta RampGroundHeight
        lda #0
        sta RampGroundHeight+1
        rol RampGroundHeight+1 ; put that carry bit into place
        rts
.endproc

; Identical to the above, but uses Y for the entity index. Used during drawing
.proc FAR_compute_ramp_height_y
        ; here we check for ramps. If we're nowhere near a ramp then we're done
        lda entity_table + EntityState::RampHeight, y
        ; if a ramp is active, we consider the ramp height to be our minimum ground height.
        ; ramp height is given in pixels, so expand that to a 16bit Z coordinate here
        asl
        asl
        asl
        asl ; possible bit into carry
        sta RampGroundHeight
        lda #0
        sta RampGroundHeight+1
        rol RampGroundHeight+1 ; put that carry bit into place
        rts
.endproc

.proc FAR_apply_ramp_height
        ; here we check for ramps. If we're nowhere near a ramp then we're done
        lda entity_table + EntityState::RampHeight, x
        beq done_with_ramps
        near_call FAR_compute_ramp_height

        ; Now compare against the Z coordinate
        lda RampGroundHeight+1
        cmp entity_table + EntityState::PositionZ+1, x
        bne check_if_below_ramp
        lda RampGroundHeight
        cmp entity_table + EntityState::PositionZ, x
check_if_below_ramp:
        bcc done_with_ramps
apply_ramp_response:
        ; the computed ramp height becomes our new Z coordinate
        lda RampGroundHeight
        sta entity_table + EntityState::PositionZ, x
        lda RampGroundHeight+1
        sta entity_table + EntityState::PositionZ+1, x
        ; and just like hitting the ground normally, we now zero out
        ; our speed
        lda #0
        sta entity_table + EntityState::SpeedZ, x
done_with_ramps:
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

.proc update_ramp_height
SampledRampHeight := R0

LeftX := R1
RightX := R2
  
SubtileX := R4
TileX := R5
SubtileY := R6
TileY := R7
TileAddr := R8

        ; At this stage we know that *some* ramp collision has occurred, now we need to work out the specifics.
        lda #0
        sta SampledRampHeight
        sta AccumulatedColFlags

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
        and #%00111111
        ora AccumulatedColFlags
        sta AccumulatedColFlags
        lda collision_flags, x
        near_call FAR_sample_ramp_height ; clobbers X, Y
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
        and #%00111111
        ora AccumulatedColFlags
        sta AccumulatedColFlags
        lda collision_flags, x
        near_call FAR_sample_ramp_height ; clobbers X, Y

        ; Keep this height only if it's higher than the previous sample
        cmp SampledRampHeight
        bcc keep_left_sample
keep_right_sample:
        sta SampledRampHeight        
keep_left_sample:
        lda SampledRampHeight
        ldx CurrentEntityIndex
        sta entity_table + EntityState::RampHeight, x ; this disables ramp mode also
        ; If we sampled anything other than a ground tile, remain
        ; in ramp mode. Otherwise we're done (exit ramp mode)
        lda AccumulatedColFlags
        beq done
        lda entity_table + EntityState::RampHeight, x
        ora #%10000000
        sta entity_table + EntityState::RampHeight, x
done:
        rts
.endproc

; ColFlags byte in A, test point X position in SubtileX
; Resulting height bonus in A
; Clobbers X, Y
.proc FAR_sample_ramp_height
SubtileX := R4
SubtileY := R6

        ; First, work out what kind of ramp is here and set the approprite LUT
        ; TODO: expand this mask if we add more ramp types
        and #%00001111 ; safety
        asl
        tax
        lda ramp_types_table, x
        sta RampLutPtr
        lda ramp_types_table+1, x
        sta RampLutPtr+1
        ; Next work out the pixel position and use that to index the LUT
        ; TODO: we need to check the ramp type and use X or Y here
        lda ramp_direction_table, x
        beq horizontal
        ; for speed reasons, avoid jumps/branches, and duplicate code as needed
vertical:
        lda SubtileY
        .repeat 4
        lsr
        .endrepeat
        tay
        lda (RampLutPtr), y 
        rts
horizontal:
        lda SubtileX
        .repeat 4
        lsr
        .endrepeat
        tay
        lda (RampLutPtr), y 
        rts
.endproc
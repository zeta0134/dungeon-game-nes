        .setcpu "6502"
        .include "branch_util.inc"
        .include "collision.inc"
        .include "entity.inc"
        .include "far_call.inc"
        .include "nes.inc"
        .include "physics.inc"
        .include "scrolling.inc"
        .include "sprites.inc"
        .include "word_util.inc"
        .include "zeropage.inc"


        .segment "PRGRAM"

; old dead pointer, remove when you are done refactoring
MetatileAttributes:

NavMapData: .res 1536

        .zeropage
NavLutPtrLow: .res 2
NavLutPtrHigh: .res 2
ScratchWord: .res 2 ; used by a few routines

; Temporary values used during movement and hit detection
AccumulatedColFlags: .res 1

        .segment "PHYSICS_A000"

.align 256

hidden_surface_height_lut:
        .repeat 256, i
        .byte ((i & $F0) >> 4)
        .endrep

.include "../build/collision_tileset.incs"

hidden_surface_reverse_height_lut:
        .repeat 16, i
        .byte (i << 4)
        .endrep

nav_lut_width_128_low:
        .repeat 128, i
        .byte <(NavMapData + (128 * i))
        .endrep
nav_lut_width_64_low:
        .repeat 64, i
        .byte <(NavMapData + (64 * i))
        .endrep
nav_lut_width_32_low:
        .repeat 32, i
        .byte <(NavMapData + (32 * i))
        .endrep
nav_lut_width_16_low:
        .repeat 16, i
        .byte <(NavMapData + (16 * i))
        .endrep

nav_lut_width_128_high:
        .repeat 128, i
        .byte >(NavMapData + (128 * i))
        .endrep
nav_lut_width_64_high:
        .repeat 64, i
        .byte >(NavMapData + (64 * i))
        .endrep
nav_lut_width_32_high:
        .repeat 32, i
        .byte >(NavMapData + (32 * i))
        .endrep
nav_lut_width_16_high:
        .repeat 16, i
        .byte >(NavMapData + (16 * i))
        .endrep

.proc FAR_update_nav_lut_ptr
        lda MapWidth
        cmp #128
        bne check_64
        st16 NavLutPtrHigh, nav_lut_width_128_high
        st16 NavLutPtrLow, nav_lut_width_128_low
        rts
check_64:
        lda MapWidth
        cmp #64
        bne check_32
        st16 NavLutPtrHigh, nav_lut_width_64_high
        st16 NavLutPtrLow, nav_lut_width_64_low
        rts
check_32:
        lda MapWidth
        cmp #32
        bne must_be_16
        st16 NavLutPtrHigh, nav_lut_width_32_high
        st16 NavLutPtrLow, nav_lut_width_32_low
        rts
must_be_16:
        st16 NavLutPtrHigh, nav_lut_width_16_high
        st16 NavLutPtrLow, nav_lut_width_16_low
        rts
.endproc

.macro surface_matches_adjusted_ground
lda ColHeights
and #$0F
cmp AdjustedGround
.endmacro

.macro hidden_surface_matches_adjusted_ground
ldx ColHeights
lda hidden_surface_height_lut, x
cmp AdjustedGround
.endmacro

.macro if_not_valid HandleResponse
.scope
LeftX := R1
RightX := R2
SubtileX := R4
TileX := R5
SubtileY := R6
TileY := R7
TileAddr := R8
HighestGround := R10
AdjustedGround := R12
AdjustedHeight := R13
ColFlags := R14
ColHeights := R15

RampHeight := ScratchWord
        ; initialize our ground level to match the player's starting height
        ldx CurrentEntityIndex
        lda entity_table + EntityState::GroundLevel, x
        clc
        adc entity_table + EntityState::PositionZ + 1, x
        sta AdjustedGround
        ; subtract the player's jumping height from their hitpoint TileY
        sec
        lda TileY
        sbc entity_table + EntityState::PositionZ + 1, x
        bpl in_bounds
out_of_bounds:
        ; Tile Y is currently negative, and we can't safely index the map out of bounds.
        ; Instead, tweak AdjustedGround by this much to skip rows until we are in-bounds again
        clc
        adc AdjustedGround
        sta AdjustedGround
        ; And now set TileY to 0, the highest block we can safely check
        lda #0
in_bounds:
        sta TileY
        ; now our Tile coordinates point to the highest block the player could
        ; theoretically clear. We'll start our loop here
        nav_map_index TileX, TileY, TileAddr

        ; y will pretty much stay 0 for most of this routine, for quick indexing
        ldy #0
loop:
        lda (TileAddr), y ; now contains collision index
        tax
        lda collision_heights, x
        sta ColHeights
        lda collision_flags, x
        sta ColFlags
        ; If the high bit of ColFlags is set, then this tile has a visible surface
        bpl check_hidden_surface
check_surface:
        ; compare the visible surface here with our adjusted ground
        ; If it matches, we've found a valid tile and can stop here
        surface_matches_adjusted_ground
        beq is_valid_move
check_hidden_surface:
        bit ColFlags
        bvc no_hidden_surface
        ; compare the hidden surface now, same as before
        hidden_surface_matches_adjusted_ground
        beq is_valid_move
no_hidden_surface:
        dec AdjustedGround
        ; if we dropped below floor_height = 0, there are no more valid tiles to consider
        bmi invalid_move 
        ; otherwise, move to the next map row        
        fadd16b TileAddr, MapWidth
        jmp loop

invalid_move:
        ; If we get here, neither a jump nor a fall located a valid tile, so we need to treat this
        ; like a wall and push the player out.
        jsr HandleResponse
        ; we also just invalidated any height adjustments we were going to make, so cancel
        ; those out. (Otherwise we can get stale height adjustments, and that causes problems)
        lda #$FF
        sta HighestGround
        jmp finished
is_valid_move:
        ; For every valid move, merge ColFlags high bits into AccumulatedColFlags; we use this later to
        ; detect ramp adjustments
        lda ColFlags
        ; TODO: can we branch here for a speedup, to skip some of this flag checking busienss for non-ramps?
        ora AccumulatedColFlags
        sta AccumulatedColFlags
        ; if this is a ramp, we need to perform additional logic
        lda ColFlags
        and #%00111111
        beq adjust_highest_ground
check_ramp_height:
        ; We need to check player PositionZ (which is block+subblock) against AdjustedGround+RampHeight
        near_call FAR_sample_ramp_height ; ramp height at this SubtileX in A, also clobbers X and Y
        ; This is in pixels, but we need to be in the movement coordinate system, so do that math here
        asl
        asl
        asl
        asl ; high bit -> carry
        sta RampHeight
        lda #0
        rol ; carry -> low bit of the high byte, also clears carry for the adc below
        ; To this, we add the computed ground height
        adc AdjustedGround
        ; TODO: and subtract the player's ground height? for a fair comparison
        sta RampHeight+1
        ; if PlayerZ clears RampHeight, this is a valid collision

        ldx CurrentEntityIndex
        lda entity_table + EntityState::PositionZ+1, x
        clc
        adc entity_table + EntityState::GroundLevel, x 
        cmp RampHeight+1
        bne check_if_below_ramp
        lda entity_table + EntityState::PositionZ, x
        cmp RampHeight
check_if_below_ramp:
        bcc invalid_move

        ; This was a valid move, so correct HighestGround if needed
adjust_highest_ground:
        lda HighestGround
        bpl keep_highest_only
        lda AdjustedGround
        sta HighestGround
        jmp finished
keep_highest_only:
        lda AdjustedGround
        ; only write if we are higher than the existing value
        cmp HighestGround
        bcc finished
write_highest_surface:
        sta HighestGround
finished:
.endscope
.endmacro

.macro fix_height
.scope
LeftX := R1
RightX := R2
SubtileX := R4
TileX := R5
SubtileY := R6
TileY := R7
TileAddr := R8
HighestGround := R10
HeightDifference := R11
        ; Early sanity check: was HighestGround written this frame?
        ; If not, perform no adjustment; there is not a valid (known) height
        ; to snap to.
        bit HighestGround
        bmi done_with_height_fix

        ; Work out the difference between the player's current ground level
        ; and the ground level where they ended up
        ldx CurrentEntityIndex
        lda entity_table + EntityState::GroundLevel, x
        ; sanity check: are these actually different? If not, skip this mess
        cmp HighestGround
        beq done_with_height_fix
        sec
        sbc HighestGround
        sta HeightDifference ; stash, we need this later
        ; At this point, HeightDifference is *positive* if the player needs to fall,
        ; and *negative* if they need to rise. This matches the adjustment we need
        ; to make to their height:
        clc
        adc entity_table + EntityState::PositionZ+1, x
        sta entity_table + EntityState::PositionZ+1, x
        lda HighestGround
        sta entity_table + EntityState::GroundLevel, x
        ; ...and it also matches the direction their Y coordinate needs to move
        lda entity_table + EntityState::PositionY+1, x
        clc
        adc HeightDifference
        sta entity_table + EntityState::PositionY+1, x
done_with_height_fix:
.endscope
.endmacro

.proc collision_response_push_down
SubtileX := R4
TileX := R5
SubtileY := R6
TileY := R7
        lda #0
        sec
        sbc SubtileY
        sta SubtileY
        ldy CurrentEntityIndex
        clc
        lda entity_table + EntityState::PositionY, y
        adc SubtileY
        sta entity_table + EntityState::PositionY, y
        lda entity_table + EntityState::PositionY + 1, y
        adc #0
        sta entity_table + EntityState::PositionY + 1, y

        rts
.endproc

.proc collision_response_push_up
SubtileX := R4
TileX := R5
SubtileY := R6
TileY := R7
        ldy CurrentEntityIndex
        clc
        lda entity_table + EntityState::PositionY, y
        sbc SubtileY
        sta entity_table + EntityState::PositionY, y
        lda entity_table + EntityState::PositionY + 1, y
        sbc #0
        sta entity_table + EntityState::PositionY + 1, y

        rts
.endproc

.proc collision_response_push_right
SubtileX := R4
TileX := R5
SubtileY := R6
TileY := R7
        lda #0
        sec
        sbc SubtileX
        sta SubtileX
        ldy CurrentEntityIndex
        clc
        lda entity_table + EntityState::PositionX, y
        adc SubtileX
        sta entity_table + EntityState::PositionX, y
        lda entity_table + EntityState::PositionX + 1, y
        adc #0
        sta entity_table + EntityState::PositionX + 1, y

        rts
.endproc

.proc dummy
        rts
.endproc

.proc collision_response_push_left
SubtileX := R4
TileX := R5
SubtileY := R6
TileY := R7
        ldy CurrentEntityIndex
        clc
        lda entity_table + EntityState::PositionX, y
        sbc SubtileX
        sta entity_table + EntityState::PositionX, y
        lda entity_table + EntityState::PositionX + 1, y
        sbc #0
        sta entity_table + EntityState::PositionX + 1, y

        rts
.endproc

; Handles collision response of an axis aligned line segment.
; Restrictions: line segment maximum offset in any direction is 16px
; Inputs:
;   - CurrentEntityIndex
;   - R0 - R8: various (see below)
; Clobbers:
;   - yes
.proc FAR_collide_up_with_map
LeftX := R1
RightX := R2
SubtileX := R4
TileX := R5
SubtileY := R6
TileY := R7
TileAddr := R8
HighestGround := R10

OldLeftTileX := R16
OldRightTileX := R17
OldLeftTileY := R18
OldRightTileY := R18

        lda #$FF
        sta HighestGround

        tile_offset LeftX, SubtileX, SubtileY
        lda TileY
        cmp OldLeftTileY
        jeq skip_left
        if_not_valid collision_response_push_down
skip_left:

        tile_offset RightX, SubtileX, SubtileY
        lda TileY
        cmp OldRightTileY
        jeq skip_right
        if_not_valid collision_response_push_down
skip_right:

        fix_height
        rts
.endproc

.proc FAR_collide_down_with_map
LeftX := R1
RightX := R2
SubtileX := R4
TileX := R5
SubtileY := R6
TileY := R7
TileAddr := R8
HighestGround := R10

OldLeftTileX := R16
OldRightTileX := R17
OldLeftTileY := R18
OldRightTileY := R18

        lda #$FF
        sta HighestGround

        tile_offset LeftX, SubtileX, SubtileY
        lda TileY
        cmp OldLeftTileY
        jeq skip_left
        if_not_valid collision_response_push_up
skip_left:

        tile_offset RightX, SubtileX, SubtileY
        lda TileY
        cmp OldRightTileY
        jeq skip_right
        if_not_valid collision_response_push_up
skip_right:

        fix_height
        rts
.endproc

; For the left and right directions, since our line segment is aligned to an axis, we
; can safely ignore the opposite point of the direction of movement. The response for such
; a collision would be wrong anyway. This cuts down on 25% of collision checks per entity
.proc FAR_collide_left_with_map
LeftX := R1
RightX := R2
SubtileX := R4
TileX := R5
SubtileY := R6
TileY := R7
TileAddr := R8
HighestGround := R10

OldLeftTileX := R16
OldRightTileX := R17
OldLeftTileY := R18
OldRightTileY := R18

        lda #$FF
        sta HighestGround

        tile_offset LeftX, SubtileX, SubtileY
        lda TileX
        cmp OldLeftTileX
        jeq skip_left
        if_not_valid collision_response_push_right
skip_left:

        tile_offset RightX, SubtileX, SubtileY
        lda TileX
        cmp OldRightTileX
        jeq skip_right
        if_not_valid collision_response_push_right
        jmp done_with_checks
skip_right:
        lda HighestGround
        bmi done_with_checks
        ; If we got here, then the frontmost check succeeded, and we
        ; skipped the secondmost one. In this case our "back" foot might
        ; still be on a higher platform. This affects the HighestGround
        ; situation, so fix it. (This is a *dirty* hack)
        ldx CurrentEntityIndex
        cmp entity_table + EntityState::GroundLevel, x
        bcs done_with_checks
        lda entity_table + EntityState::GroundLevel, x
        sta HighestGround

done_with_checks:
        fix_height
        rts
.endproc

.proc FAR_collide_right_with_map
LeftX := R1
RightX := R2
SubtileX := R4
TileX := R5
SubtileY := R6
TileY := R7
TileAddr := R8
HighestGround := R10

OldLeftTileX := R16
OldRightTileX := R17
OldLeftTileY := R18
OldRightTileY := R18

        lda #$FF
        sta HighestGround

        tile_offset RightX, SubtileX, SubtileY
        lda TileX
        cmp OldRightTileX
        jeq skip_right
        if_not_valid collision_response_push_left
skip_right:

        tile_offset LeftX, SubtileX, SubtileY
        lda TileX
        cmp OldLeftTileX
        jeq skip_left
        if_not_valid collision_response_push_left
        jmp done_with_checks
skip_left:
        lda HighestGround
        bmi done_with_checks
        ; If we got here, then the frontmost check succeeded, and we
        ; skipped the secondmost one. In this case our "back" foot might
        ; still be on a higher platform. This affects the HighestGround
        ; situation, so fix it. (This is a *dirty* hack)
        ldx CurrentEntityIndex
        cmp entity_table + EntityState::GroundLevel, x
        bcs done_with_checks
        lda entity_table + EntityState::GroundLevel, x
        sta HighestGround

done_with_checks:
        fix_height
        rts
.endproc


; standard hitbox:
; 4px in from each side
; 0px off the ground
; height of 16px
; intended to be suitable for most interactions
.proc FAR_aabb_standard_vs_standard
EntityIndexA := R4
EntityIndexB := R5
CollisionResult := R6
ScratchA := R6
ScratchB := R8

LeftX = (4 << 4)
RightX = (12 << 4)
TopY = LeftX
BottomY = RightX
LowerZ = (0)
UpperZ = (15 << 4)

        ldx EntityIndexA
        ldy EntityIndexB
        ; === X Axis, A-left < B-right ===
        clc
        lda entity_table + EntityState::PositionX, x
        adc #LeftX
        sta ScratchA
        lda entity_table + EntityState::PositionX+1, x
        adc #0
        sta ScratchA+1

        clc
        lda entity_table + EntityState::PositionX, y
        adc #RightX
        sta ScratchB
        lda entity_table + EntityState::PositionX+1, y
        adc #0
        sta ScratchB+1

        cmp16 ScratchA, ScratchB
        jcs no_collision

        ; === X Axis, B-left < A-right ===
        clc
        lda entity_table + EntityState::PositionX, y
        adc #LeftX
        sta ScratchA
        lda entity_table + EntityState::PositionX+1, y
        adc #0
        sta ScratchA+1

        clc
        lda entity_table + EntityState::PositionX, x
        adc #RightX
        sta ScratchB
        lda entity_table + EntityState::PositionX+1, x
        adc #0
        sta ScratchB+1

        cmp16 ScratchA, ScratchB
        jcs no_collision

        ; === Y Axis, A-top < B-bottom ===
        clc
        lda entity_table + EntityState::PositionY, x
        adc #TopY
        sta ScratchA
        lda entity_table + EntityState::PositionY+1, x
        adc #0
        adc entity_table + EntityState::GroundLevel, x
        sta ScratchA+1

        clc
        lda entity_table + EntityState::PositionY, y
        adc #BottomY
        sta ScratchB
        lda entity_table + EntityState::PositionY+1, y
        adc #0
        adc entity_table + EntityState::GroundLevel, y
        sta ScratchB+1

        cmp16 ScratchA, ScratchB
        jcs no_collision

        ; === Y Axis, B-top < A-bottom ===
        clc
        lda entity_table + EntityState::PositionY, y
        adc #TopY
        sta ScratchA
        lda entity_table + EntityState::PositionY+1, y
        adc #0
        adc entity_table + EntityState::GroundLevel, y
        sta ScratchA+1

        clc
        lda entity_table + EntityState::PositionY, x
        adc #BottomY
        sta ScratchB
        lda entity_table + EntityState::PositionY+1, x
        adc #0
        adc entity_table + EntityState::GroundLevel, x
        sta ScratchB+1

        cmp16 ScratchA, ScratchB
        jcs no_collision

        ; === Z Axis, A-lower < B-upper ===
        clc
        lda entity_table + EntityState::PositionZ, x
        adc #LowerZ
        sta ScratchA
        lda entity_table + EntityState::PositionZ+1, x
        adc #0
        adc entity_table + EntityState::GroundLevel, x
        sta ScratchA+1

        clc
        lda entity_table + EntityState::PositionZ, y
        adc #UpperZ
        sta ScratchB
        lda entity_table + EntityState::PositionZ+1, y
        adc #0
        adc entity_table + EntityState::GroundLevel, y
        sta ScratchB+1

        cmp16 ScratchA, ScratchB
        jcs no_collision

        ; === Z Axis, B-lower < A-upper ===
        clc
        lda entity_table + EntityState::PositionZ, y
        adc #LowerZ
        sta ScratchA
        lda entity_table + EntityState::PositionZ+1, y
        adc #0
        adc entity_table + EntityState::GroundLevel, y
        sta ScratchA+1

        clc
        lda entity_table + EntityState::PositionZ, x
        adc #UpperZ
        sta ScratchB
        lda entity_table + EntityState::PositionZ+1, x
        adc #0
        adc entity_table + EntityState::GroundLevel, x
        sta ScratchB+1

        cmp16 ScratchA, ScratchB
        jcs no_collision
oh_boy_a_collision:
        lda #1
        sta CollisionResult
        rts
no_collision:
        lda #0
        sta CollisionResult
        rts
.endproc


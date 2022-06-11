        .setcpu "6502"
        .include "branch_util.inc"
        .include "collision.inc"
        .include "entity.inc"
        .include "nes.inc"
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
ScratchTileAddr: .res 2 ; used by the collision scanning routines

        .segment "PHYSICS_A000"

.include "../build/collision_tileset.incs"

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

.macro cheaty_tile_offset OffsetX, DestX, DestY
        ; identical to tile_offset, but throws away the
        ; lower bytes intead of keeping them. Useful in functions
        ; that only need to consider the tile index
        ldy CurrentEntityIndex
        ; Calculate the tile coordinates for the X axis:
        clc
        lda entity_table + EntityState::PositionX, y
        adc OffsetX ; and throw it away; we just need the carry
        ;sta DestX
        lda entity_table + EntityState::PositionX+1, y
        adc #0
        sta DestX+1 ; now contains map tile for top-left

        ; just copy the DestY pointer directly
        ;lda entity_table + EntityState::PositionY, y
        ;sta DestY
        lda entity_table + EntityState::PositionY+1, y
        sta DestY+1
.endmacro

.macro jumping_tile_offset OffsetX, DestX, DestY
        ldy CurrentEntityIndex
        ; Calculate the tile coordinates for the X axis:
        clc
        lda entity_table + EntityState::PositionX, y
        adc OffsetX ; and throw it away; we just need the carry
        sta DestX
        lda entity_table + EntityState::PositionX+1, y
        adc #0
        sta DestX+1 ; now contains map tile for top-left

        ; subtract jump height here
        sec
        lda entity_table + EntityState::PositionY, y
        sbc entity_table + EntityState::PositionZ, y
        sta DestY
        lda entity_table + EntityState::PositionY+1, y
        sbc entity_table + EntityState::PositionZ+1, y
        sta DestY+1
.endmacro

.macro surface_matches_adjusted_ground
lda ColHeights
and #$0F
cmp AdjustedGround
.endmacro

.macro hidden_surface_matches_adjusted_ground
lda ColHeights
; note: we could spend 256 bytes on a LUT and save
; 4 cycles by replacing these with lda lut, x, with x
; set to ColHeights
lsr
lsr
lsr
lsr
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
        clc
        add16 TileAddr, MapWidth
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
        ; This was a valid move, so correct HighestGround if needed
        lda AdjustedGround
        ; only write if we are higher than the existing value
        cmp HighestGround
        bcc finished
write_highest_surface:
        sta HighestGround
finished:
.endscope
.endmacro

.proc fix_height
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
        rts
.endproc

.proc FAR_apply_bg_priority
LeftX := R1
RightX := R2
SubtileX := R4
TileX := R5
SubtileY := R6
TileY := R7
TileAddr := R8
GroundLevel := R10
GroundType := R11
        lda #0
        sta GroundType

        ldx CurrentEntityIndex
        lda entity_table + EntityState::GroundLevel, x
        asl
        asl
        asl
        asl
        sta GroundLevel

check_left_tile:
        ; check both tiles under our new position's hit points
        cheaty_tile_offset LeftX, SubtileX, SubtileY
        nav_map_index TileX, TileY, TileAddr
        ldy #0
        lda (TileAddr), y
        tay
        ; if the hidden surface height matches our player's height
        lda collision_heights, y
        and #$F0
        cmp GroundLevel
        bne check_right_tile
        ; collect the flags and stash them
        lda collision_flags, y
        sta GroundType

check_right_tile:
        cheaty_tile_offset RightX, SubtileX, SubtileY
        nav_map_index TileX, TileY, TileAddr
        ldy #0
        lda (TileAddr), y ;
        tay
        ; if the hidden surface height matches our player's height
        lda collision_heights, y
        and #$F0
        cmp GroundLevel
        bne check_combined_flags
        ; combine these flags with the previous value and store them
        lda collision_flags, y
        ora GroundType
        sta GroundType

check_combined_flags:
        ; at this point if bit 6 is set, one of our shadow hit points is "behind" a surface,
        bit GroundType
        jvc shadow_visible_surface
shadow_hidden_surface:
        ldx CurrentEntityIndex
        ldy entity_table + EntityState::ShadowSpriteIndex, x
        lda metasprite_table + MetaSpriteState::PaletteOffset, y
        ora #%00100000 ; set the bgPriority bit
        sta metasprite_table + MetaSpriteState::PaletteOffset, y
        ; now we check the player sprite and apply bgPriority to it also, if appropriate
        jmp check_left_jumping_tile
shadow_visible_surface:
        ldx CurrentEntityIndex
        ldy entity_table + EntityState::ShadowSpriteIndex, x
        lda metasprite_table + MetaSpriteState::PaletteOffset, y
        and #%11011111 ; clear the bgPriority bit
        sta metasprite_table + MetaSpriteState::PaletteOffset, y
        ; If the shadow isn't behind something, then we don't try to put the player sprite behing
        ; something either
        jmp visible_surface

        ; Okay, now perform a similar check but for the base of the player's jump height
        ; This tries to ensure that if the player jumps out of the bgPriority region, we don't
        ; apply it incorrectly and have them slip behind nearby scene geometry

check_left_jumping_tile:
        ; check both tiles under our new position's hit points
        jumping_tile_offset LeftX, SubtileX, SubtileY
        nav_map_index TileX, TileY, TileAddr
        ldy #0
        lda (TileAddr), y
        tay
        ; if the hidden surface height matches our player's height
        lda collision_heights, y
        and #$F0
        cmp GroundLevel
        bne check_right_jumping_tile
        ; collect the flags and stash them
        ; (note: this also clears the result from the shadow round of checks)
        lda collision_flags, y
        sta GroundType

check_right_jumping_tile:
        jumping_tile_offset RightX, SubtileX, SubtileY
        nav_map_index TileX, TileY, TileAddr
        ldy #0
        lda (TileAddr), y ;
        tay
        ; if the hidden surface height matches our player's height
        lda collision_heights, y
        and #$F0
        cmp GroundLevel
        bne check_combined_jumping_flags
        ; combine these flags with the previous value and store them
        lda collision_flags, y
        ora GroundType
        sta GroundType

check_combined_jumping_flags:
        ; at this point if bit 6 is set, in addition to our shadow being behind a surface, our
        ; player position is *also* behind a surface. Hopefully that same surface.
        bit GroundType
        bvc visible_surface

hidden_surface:
        ldx CurrentEntityIndex
        ldy entity_table + EntityState::MetaSpriteIndex, x
        lda metasprite_table + MetaSpriteState::PaletteOffset, y
        ora #%00100000 ; set the bgPriority bit
        sta metasprite_table + MetaSpriteState::PaletteOffset, y
        rts

visible_surface:
        ldx CurrentEntityIndex
        ldy entity_table + EntityState::MetaSpriteIndex, x
        lda metasprite_table + MetaSpriteState::PaletteOffset, y
        and #%11011111 ; clear the bgPriority bit
        sta metasprite_table + MetaSpriteState::PaletteOffset, y
        rts
.endproc

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
        lda #$00
        sta HighestGround

        tile_offset LeftX, SubtileX, SubtileY
        if_not_valid collision_response_push_down

        tile_offset RightX, SubtileX, SubtileY
        if_not_valid collision_response_push_down

        jsr fix_height
        ;jsr apply_bg_priority
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
        lda #$00
        sta HighestGround

        tile_offset LeftX, SubtileX, SubtileY
        if_not_valid collision_response_push_up

        tile_offset RightX, SubtileX, SubtileY
        if_not_valid collision_response_push_up

        jsr fix_height
        ;jsr apply_bg_priority
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
        lda #$00
        sta HighestGround

        tile_offset RightX, SubtileX, SubtileY
        if_not_valid collision_response_push_right

        tile_offset LeftX, SubtileX, SubtileY
        if_not_valid collision_response_push_right

        jsr fix_height
        ;jsr apply_bg_priority
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
        lda #$00
        sta HighestGround

        tile_offset RightX, SubtileX, SubtileY
        if_not_valid collision_response_push_left

        tile_offset LeftX, SubtileX, SubtileY
        if_not_valid collision_response_push_left

        jsr fix_height
        ;jsr apply_bg_priority
        rts
.endproc

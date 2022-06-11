.global NavMapData

.globalzp NavLutPtrLow
.globalzp NavLutPtrHigh

.global FAR_collide_up_with_map
.global FAR_collide_down_with_map
.global FAR_collide_left_with_map
.global FAR_collide_right_with_map
.global FAR_update_nav_lut_ptr
.global FAR_apply_bg_priority

.global collision_heights
.global collision_flags
.global hidden_surface_height_lut, hidden_surface_reverse_height_lut

.macro tile_offset OffsetX, DestX, DestY
        ldy CurrentEntityIndex
        ; Calculate the tile coordinates for the X axis:
        clc
        lda entity_table + EntityState::PositionX, y
        adc OffsetX
        sta DestX
        lda entity_table + EntityState::PositionX+1, y
        adc #0
        sta DestX+1 ; now contains map tile for top-left

        ; just copy the DestY pointer directly
        lda entity_table + EntityState::PositionY, y
        sta DestY
        lda entity_table + EntityState::PositionY+1, y
        sta DestY+1
.endmacro

; clobbers a and y
.macro nav_map_index TileX, TileY, DestAddr
        ldy TileY
        lda (NavLutPtrHigh), y
        sta DestAddr+1
        lda (NavLutPtrLow), y
        clc
        adc TileX
        sta DestAddr
.endmacro

; clobbers a and y
.macro graphics_map_index TileX, TileY, DestAddr
        ; cheat: first grab the navmap index
        nav_map_index TileX, TileY, DestAddr
        ; now subtract the difference between the two maps
        sec
        lda DestAddr
        sbc #<(NavMapData - MapData)
        sta DestAddr
        lda DestAddr+1
        sbc #>(NavMapData - MapData)
        sta DestAddr+1
.endmacro

.macro cheaty_tile_offset OffsetX, DestX, DestY
        ; identical to tile_offset, but throws away the
        ; lower bytes intead of keeping them. Useful in functions
        ; that only need to consider the tile index
        ldy CurrentEntityIndex
        ; Calculate the tile coordinates for the X axis:
        clc
        lda entity_table + EntityState::PositionX, y
        adc OffsetX ; and throw it away; we just need the carry
        lda entity_table + EntityState::PositionX+1, y
        adc #0
        sta DestX+1 ; now contains map tile for top-left

        ; just copy the DestY tile directly
        lda entity_table + EntityState::PositionY+1, y
        sta DestY+1
.endmacro

.macro jumping_tile_offset OffsetX, DestX, DestY
        ldy CurrentEntityIndex
        ; Calculate the tile coordinates for the X axis:
        clc
        lda entity_table + EntityState::PositionX, y
        adc OffsetX ; and throw it away; we just need the carry
        lda entity_table + EntityState::PositionX+1, y
        adc #0
        sta DestX+1 ; now contains map tile for top-left

        ; subtract jump height here
        sec
        lda entity_table + EntityState::PositionY, y
        sbc entity_table + EntityState::PositionZ, y
        ; and throw the result away; we only need the carry here
        lda entity_table + EntityState::PositionY+1, y
        sbc entity_table + EntityState::PositionZ+1, y
        sta DestY+1
.endmacro

.macro apply_bg_priority
.scope
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
        ldy entity_table + EntityState::GroundLevel, x
        lda hidden_surface_reverse_height_lut, y
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
        jmp done

visible_surface:
        ldx CurrentEntityIndex
        ldy entity_table + EntityState::MetaSpriteIndex, x
        lda metasprite_table + MetaSpriteState::PaletteOffset, y
        and #%11011111 ; clear the bgPriority bit
        sta metasprite_table + MetaSpriteState::PaletteOffset, y
done:
.endscope
.endmacro
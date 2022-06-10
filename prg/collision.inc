.global NavMapData

.globalzp NavLutPtrLow
.globalzp NavLutPtrHigh

.global FAR_collide_up_with_map
.global FAR_collide_down_with_map
.global FAR_collide_left_with_map
.global FAR_collide_right_with_map
.global FAR_update_nav_lut_ptr

.global collision_heights
.global collision_flags

.macro tile_offset OffsetX, DestX, DestY
        ldy CurrentEntityIndex
        ; Calculate the tile coordinates for the X axis:
        clc
        lda entity_table + EntityState::PositionX, y
        adc OffsetX ; and throw it away; we just need the carry
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
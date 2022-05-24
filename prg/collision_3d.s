        .setcpu "6502"
        .include "entity.inc"
        .include "nes.inc"
        .include "scrolling.inc"
        .include "sprites.inc"
        .include "word_util.inc"
        .include "zeropage.inc"

        

.scope PRGLAST_E000
        .segment "PRGRAM"

; old dead pointer, remove when you are done refactoring
MetatileAttributes:

NavMapData: .res 1536
.export NavMapData

        .zeropage
NavLutPtrLow: .res 2
NavLutPtrHigh: .res 2
.exportzp NavLutPtrLow, NavLutPtrHigh

        .segment "PRGLAST_C000"

.include "debug_maps/collision_tileset.incs"

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

.export update_nav_lut_ptr
.proc update_nav_lut_ptr
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

.macro tile_offset OffsetX, OffsetY, DestX, DestY
        ldy CurrentEntityIndex
        ; Calculate the tile coordinates for the X axis:
        clc
        lda entity_table + EntityState::PositionX, y
        adc OffsetX ; and throw it away; we just need the carry
        sta DestX
        lda entity_table + EntityState::PositionX+1, y
        adc #0
        sta DestX+1 ; now contains map tile for top-left
        
        ; now repeat this for the Y axis
        clc
        lda entity_table + EntityState::PositionY, y
        adc OffsetY ; and throw it away; we just need the carry
        sta DestY
        lda entity_table + EntityState::PositionY+1, y
        adc #0
        sta DestY+1 ; now contains map tile for top-left
.endmacro

.macro if_solid TileAddr, HandleResponse
.scope
ColFlags := R14
ColHeights := R15
        ldy #0
        lda (TileAddr), y ; now contains collision index
        tay
        lda collision_heights, y
        sta ColHeights
        lda collision_flags, y
        sta ColFlags
        bpl check_hidden_surface
check_surface:
        lda #$0F
        and ColHeights ; A now contains visible surface height, from 0-15
        ; FOR TESTING, only consider a ground level of 0 to be solid
        beq no_response
check_hidden_surface:
        ; FOR TESTING, hidden surfaces are not collidable at all
        jsr HandleResponse
no_response:
.endscope
.endmacro

.proc collision_response_push_down
SubtileX := R4
TileX := R5
SubtileY := R6
TileY := R7
        ; todo: this
        ; movement? Nah, *highlight*
        ldy CurrentEntityIndex
        lda entity_table + EntityState::MetaSpriteIndex, y
        tay
        lda #1
        sta metasprite_table + MetaSpriteState::PaletteOffset, y

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
        ; todo: this
        ; movement? Nah, *highlight*
        ldy CurrentEntityIndex
        lda entity_table + EntityState::MetaSpriteIndex, y
        tay
        lda #2
        sta metasprite_table + MetaSpriteState::PaletteOffset, y

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
        ; todo: this
        ; movement? Nah, *highlight*
        ldy CurrentEntityIndex
        lda entity_table + EntityState::MetaSpriteIndex, y
        tay
        lda #3
        sta metasprite_table + MetaSpriteState::PaletteOffset, y

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
        ; todo: this
        ; movement? Nah, *highlight*
        ldy CurrentEntityIndex
        lda entity_table + EntityState::MetaSpriteIndex, y
        tay
        lda #3
        sta metasprite_table + MetaSpriteState::PaletteOffset, y

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

; Handles collision response of an AABB against map tiles which are exclusively
; fully solid, or fully impassable.
; Restrictions: AABB maximum size is 16px x 16px
; Inputs:
;   - CurrentEntityIndex
;   - R0 - X Offset in subtiles (4.4 pixels)
;   - R1 - Y Offset in subtiles
;   - R2 - width in subtiles
;   - R3 - height in subtiles
; Clobbers:
;   - yes
.export collide_up_with_map_3d
.proc collide_up_with_map_3d
LeftX := R1
RightX := R2
VerticalOffset := R3
SubtileX := R4
TileX := R5
SubtileY := R6
TileY := R7
TileAddr := R8
        tile_offset LeftX, VerticalOffset, SubtileX, SubtileY
        nav_map_index TileX, TileY, TileAddr
        if_solid TileAddr, collision_response_push_down

        tile_offset RightX, VerticalOffset, SubtileX, SubtileY
        nav_map_index TileX, TileY, TileAddr
        if_solid TileAddr, collision_response_push_down

        rts
.endproc

.export collide_down_with_map_3d
.proc collide_down_with_map_3d
LeftX := R1
RightX := R2
VerticalOffset := R3
SubtileX := R4
TileX := R5
SubtileY := R6
TileY := R7
TileAddr := R8
        tile_offset LeftX, VerticalOffset, SubtileX, SubtileY
        nav_map_index TileX, TileY, TileAddr
        if_solid TileAddr, collision_response_push_up

        tile_offset RightX, VerticalOffset, SubtileX, SubtileY
        nav_map_index TileX, TileY, TileAddr
        if_solid TileAddr, collision_response_push_up

        rts
.endproc

.export collide_left_with_map_3d
.proc collide_left_with_map_3d
LeftX := R1
RightX := R2
VerticalOffset := R3
SubtileX := R4
TileX := R5
SubtileY := R6
TileY := R7
TileAddr := R8
        tile_offset LeftX, VerticalOffset, SubtileX, SubtileY
        nav_map_index TileX, TileY, TileAddr
        if_solid TileAddr, collision_response_push_right

        tile_offset RightX, VerticalOffset, SubtileX, SubtileY
        nav_map_index TileX, TileY, TileAddr
        if_solid TileAddr, collision_response_push_right

        rts
.endproc

.export collide_right_with_map_3d
.proc collide_right_with_map_3d
LeftX := R1
RightX := R2
VerticalOffset := R3
SubtileX := R4
TileX := R5
SubtileY := R6
TileY := R7
TileAddr := R8
        tile_offset LeftX, VerticalOffset, SubtileX, SubtileY
        nav_map_index TileX, TileY, TileAddr
        if_solid TileAddr, collision_response_push_left

        tile_offset RightX, VerticalOffset, SubtileX, SubtileY
        nav_map_index TileX, TileY, TileAddr
        if_solid TileAddr, collision_response_push_left

        rts
.endproc

.endscope
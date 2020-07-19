        .setcpu "6502"
        .include "entity.inc"
        .include "nes.inc"
        .include "scrolling.inc"
        .include "sprites.inc"
        .include "word_util.inc"
        .include "zeropage.inc"

        

.scope PRGLAST_E000
        .segment "PRGRAM"
MetatileAttributes: .res 256        

        .segment "PRGLAST_E000"

.export load_tileset_attributes

; Load tile attributes into memory; these always have a fixed size of 256 bytes
; Inputs:
;   R0: 16bit address of the tileset data to load
.proc load_tileset_attributes
        ldy #$00
loop:
        lda (R0),y
        sta MetatileAttributes,y
        iny
        bne loop
        rts
.endproc

.macro map_index TileX, TileY, DestAddr
        ; goal is to turn TileY into %00111111 11000000
        lda TileY
        ror
        ror
        tax ; stash high byte here
        ror
        and #%11000000
        clc
        adc TileX ; which has the top two bits of 0; this will not carry
        adc #<MapData ; this *might* carry
        sta DestAddr
        txa
        and #%00111111
        adc #>MapData
        sta DestAddr+1
        ; and done!
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
        ldy #0
        lda (TileAddr), y ; now contains collision index
        tay
        lda MetatileAttributes, y; a now contains tile type
        bpl no_response
        jsr HandleResponse
no_response:
.endscope
.endmacro

.proc collision_response_push_down
SubtileX := R5
TileX := R6
SubtileY := R7
TileY := R8
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
SubtileX := R5
TileX := R6
SubtileY := R7
TileY := R8
        ; todo: this
        ; movement? Nah, *highlight*
        ldy CurrentEntityIndex
        lda entity_table + EntityState::MetaSpriteIndex, y
        tay
        lda #2
        sta metasprite_table + MetaSpriteState::PaletteOffset, y


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
SubtileX := R5
TileX := R6
SubtileY := R7
TileY := R8
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

.proc collision_response_push_left
SubtileX := R5
TileX := R6
SubtileY := R7
TileY := R8
        ; todo: this
        ; movement? Nah, *highlight*
        ldy CurrentEntityIndex
        lda entity_table + EntityState::MetaSpriteIndex, y
        tay
        lda #3
        sta metasprite_table + MetaSpriteState::PaletteOffset, y


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
.export collide_up_with_map
.proc collide_up_with_map
LeftX := R1
TopY := R2
RightX := R3
BottomY := R4
SubtileX := R5
TileX := R6
SubtileY := R7
TileY := R8
TileAddr := R9
        tile_offset LeftX, TopY, SubtileX, SubtileY
        map_index TileX, TileY, TileAddr
        if_solid TileAddr, collision_response_push_down

        tile_offset RightX, TopY, SubtileX, SubtileY
        map_index TileX, TileY, TileAddr
        if_solid TileAddr, collision_response_push_down

        rts
.endproc

.export collide_down_with_map
.proc collide_down_with_map
LeftX := R1
TopY := R2
RightX := R3
BottomY := R4
SubtileX := R5
TileX := R6
SubtileY := R7
TileY := R8
TileAddr := R9
        tile_offset LeftX, BottomY, SubtileX, SubtileY
        map_index TileX, TileY, TileAddr
        if_solid TileAddr, collision_response_push_up

        tile_offset RightX, BottomY, SubtileX, SubtileY
        map_index TileX, TileY, TileAddr
        if_solid TileAddr, collision_response_push_up

        rts
.endproc

.export collide_left_with_map
.proc collide_left_with_map
LeftX := R1
TopY := R2
RightX := R3
BottomY := R4
SubtileX := R5
TileX := R6
SubtileY := R7
TileY := R8
TileAddr := R9
        tile_offset LeftX, TopY, SubtileX, SubtileY
        map_index TileX, TileY, TileAddr
        if_solid TileAddr, collision_response_push_right

        tile_offset LeftX, BottomY, SubtileX, SubtileY
        map_index TileX, TileY, TileAddr
        if_solid TileAddr, collision_response_push_right

        rts
.endproc

.export collide_right_with_map
.proc collide_right_with_map
LeftX := R1
TopY := R2
RightX := R3
BottomY := R4
SubtileX := R5
TileX := R6
SubtileY := R7
TileY := R8
TileAddr := R9
        tile_offset RightX, TopY, SubtileX, SubtileY
        map_index TileX, TileY, TileAddr
        if_solid TileAddr, collision_response_push_left

        tile_offset RightX, BottomY, SubtileX, SubtileY
        map_index TileX, TileY, TileAddr
        if_solid TileAddr, collision_response_push_left

        rts
.endproc

.endscope
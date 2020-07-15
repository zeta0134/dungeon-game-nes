.ifndef _SPRITES_INC
_SPRITES_INC := 1

.import initialize_oam, draw_metasprite, metasprite_table, update_animations, draw_metasprites
.importzp OAMTableLength, OAMEntryIndex, OAMTableAddr, MetaspritePosX, MetaspritePosY, ScratchSpritePtr

.struct AnimationHeader
        FrameTableAddr .word
        Length .byte
.endstruct

.struct AnimationFrame
        OAMTableAddr .word
        OAMLength .byte
        MapperBank .byte
        DelayFrames .byte
.endstruct

.struct OAMEntry
        YOffset .byte
        TileIndex .byte
        Attributes .byte
        XOffset .byte
.endstruct

.struct MetaSpriteState
        PositionX .word
        PositionY .word
        AnimationAddr .word
        AnimationFrameAddr .word
        FrameCounter .byte
        DelayCounter .byte
        TileOffset .byte
        PaletteOffset .byte
.endstruct

; note: these posisions should be in 8.8 format describing
; the pixel position of the sprite within the world map.
; scrolling is handled automatically.

.macro set_metasprite_x MetaSpriteOffset, PosX
        ldy MetaSpriteOffset
        lda PosX
        sta metasprite_table + MetaSpriteState::PositionX, y
        lda PosX+1
        sta metasprite_table + MetaSpriteState::PositionX+1, y
.endmacro

.macro set_metasprite_y MetaSpriteOffset, PosY
        ldy MetaSpriteOffset
        lda PosY
        sta metasprite_table + MetaSpriteState::PositionY, y
        lda PosY+1
        sta metasprite_table + MetaSpriteState::PositionY+1, y
.endmacro

.macro set_metasprite_tile_offset MetaSpriteOffset, TileIndex
        ldy MetaSpriteOffset
        lda TileIndex
        sta metasprite_table + MetaSpriteState::TileOffset, y
.endmacro

.macro set_metasprite_palette_offset MetaSpriteOffset, PaletteIndex
        ldy MetaSpriteOffset
        lda PaletteIndex
        sta metasprite_table + MetaSpriteState::PaletteOffset, y
.endmacro

.macro set_metasprite_animation MetaSpriteOffset, AnimationHeaderAddr
        ; load the AnimationHeader address into our scratch pointer,
        ; and also write it to the metasprite state
        ldx MetaSpriteOffset
        lda #<AnimationHeaderAddr
        sta ScratchSpritePtr
        sta metasprite_table + MetaSpriteState::AnimationAddr, x
        lda #>AnimationHeaderAddr
        sta ScratchSpritePtr+1
        sta metasprite_table + MetaSpriteState::AnimationAddr + 1, x
        ; initialize the FrameCounter to the animation length; it counts
        ; down and will reset the animation when it reaches zero
        ldy #AnimationHeader::Length
        lda (ScratchSpritePtr),y
        sta metasprite_table + MetaSpriteState::FrameCounter, x
        ; read the starting frame index to complete initialization
        ldy #AnimationHeader::FrameTableAddr
        lda (ScratchSpritePtr),y
        tax ; stash
        iny
        lda (ScratchSpritePtr),y
        ; a,x now contains the high,low byte of the frame index
        ; stash this as the AnimationFrameAddr, and also write it to ScratchSpritePtr
        ldy MetaSpriteOffset
        sta metasprite_table + MetaSpriteState::AnimationFrameAddr + 1, y
        sta ScratchSpritePtr+1
        txa
        sta metasprite_table + MetaSpriteState::AnimationFrameAddr, y
        sta ScratchSpritePtr
        ; use the AnimationFrameAddr to initialize the delay counter
        ldy #AnimationFrame::DelayFrames
        lda (ScratchSpritePtr),y
        ldy MetaSpriteOffset
        sta metasprite_table + MetaSpriteState::DelayCounter, y
.endmacro

.endif
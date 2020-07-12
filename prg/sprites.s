        .setcpu "6502"
        .include "sprites.inc"
        .include "scrolling.inc"
        .include "word_util.inc"
        .include "zeropage.inc"

.scope PRGLAST_E000
        .zeropage
.exportzp OAMTableLength, OAMEntryIndex, OAMTableAddr, MetaspritePosX, MetaspritePosY, ScratchSpritePtr
ScratchSpritePtr: .word $0000
OAMTableLength: .byte $00
OAMEntryIndex: .byte $00
OAMTableAddr: .word $0000
MetaspritePosX: .word $0000
MetaspritePosY: .word $0000
MetaspriteTileOffset: .byte $00
MetaspritePaletteOffset: .byte $00
CameraScrollPixelsX: .word $0000
CameraScrollPixelsY: .word $0000
        .segment "RAM"
        .export metasprite_table
metasprite_table:
        .repeat 21
        .tag MetaSpriteState
        .endrepeat

        .segment "PRGLAST_E000"
        ;.org $e000

.export initialize_oam, draw_metasprite, update_animations, draw_metasprites

SHADOW_OAM = $0200
; offsets
OAM_Y_POS = 0
OAM_TILE = 1
OAM_ATTRIBUTES = 2
OAM_X_POS = 3

.proc initialize_oam
        st16 R0, (SHADOW_OAM)
        ldy #$0
loop:
        lda #$FF   ; y-position off screen
        sta (R0),y
        iny
        lda #$00   ; tile index = 0
        sta (R0),y
        iny
        sta (R0),y ; first palette, no attributes enabled
        iny
        sta (R0),y ; x-position: far left
        iny
        bne loop ; Continue until Y rolls back around to 0
        rts
.endproc

; needs: oamtable addr, length, position, oamentry index
.proc draw_metasprite
calculate_oam_position:
        ; calculate the on-screen X position of this 8x8 sprite
        clc
        ldy #OAMEntry::XOffset
        lda (OAMTableAddr),y ; note: OAMTableAddr must reside in zero page
        pha
        adc MetaspritePosX
        tax ; stash OamX for now
        ; sign extend for the high byte
        pla
        and #$80 ;extract the high bit
        beq x_positive
        lda #$FF
x_positive:
        adc MetaspritePosX+1
        ; a now contains the modified high byte of the X position
        ; sanity check: is this sprite onscreen horizontally?
        bne skip_oam_entry
        ; calculate the on-screen Y position too
        clc
        ldy #OAMEntry::YOffset
        lda (OAMTableAddr),y
        pha
        adc MetaspritePosY
        tay ; stash OamY for now
        ; sign extend for the high byte
        pla
        and #$80 ;extract the high bit
        beq y_positive
        lda #$FF
y_positive:
        adc MetaspritePosY+1
        ; a now contains the modified high byte of the Y position
        ; sanity check: is this sprite onscreen vertically?
        bne skip_oam_entry
draw_oam_fragment:
        ; the low bytes we stashed earlier are the on-screen position for this sprite
        txa ; we need to use x for the index here, so grab our value out of X first thing
        ldx OAMEntryIndex
        sta SHADOW_OAM + OAM_X_POS, x
        ; similar deal for Y, though we'll reuse the index in x:
        tya
        sta SHADOW_OAM + OAM_Y_POS, x
        ; now we just need the tile index and the attributes, this time
        ; using y so we don't need to shuffle the two indices around
        ldy #OAMEntry::TileIndex
        lda (OAMTableAddr),y
        clc
        adc MetaspriteTileOffset
        sta SHADOW_OAM + OAM_TILE, x
        ldy #OAMEntry::Attributes
        lda (OAMTableAddr),y
        clc
        adc MetaspritePaletteOffset
        sta SHADOW_OAM + OAM_ATTRIBUTES, x
skip_oam_fragment:
        clc
        lda #4
        adc OAMEntryIndex
        sta OAMEntryIndex
skip_oam_entry:
        clc 
        add16 OAMTableAddr, #.sizeof(OAMEntry)
        dec OAMTableLength
        bne calculate_oam_position
done:
        rts
.endproc

.proc update_animations
MetaSpriteCount := R0
MetaSpriteIndex := R1
        lda #21
        sta MetaSpriteCount
        lda #0
        sta MetaSpriteIndex
metasprite_loop:
        ; sanity check: is this animation enabled? ie, is the high byte
        ; of the animation data non-zero?
        ldx MetaSpriteIndex
        lda metasprite_table + MetaSpriteState::AnimationAddr + 1, x
        beq next_metasprite

        ; if our delay is not currently zero, decrement it and move on
        lda metasprite_table + MetaSpriteState::DelayCounter, x
        bne decrement_delay_counter

        ; decrement the frame counter
        dec metasprite_table + MetaSpriteState::FrameCounter, x
        ; if it is now zero, reload the animation frame, otherwise increment the animation frame
        beq reload_animation_frame
        clc
        lda #.sizeof(AnimationFrame)
        adc metasprite_table + MetaSpriteState::AnimationFrameAddr, x
        sta metasprite_table + MetaSpriteState::AnimationFrameAddr, x
        lda #0
        adc metasprite_table + MetaSpriteState::AnimationFrameAddr+1, x
        sta metasprite_table + MetaSpriteState::AnimationFrameAddr+1, x
        ; in either case, reload the delay counter
        jmp reload_delay_counter
reload_animation_frame:
        ; prepare the scratch pointer for reading the animation header
        lda metasprite_table + MetaSpriteState::AnimationAddr, x
        sta ScratchSpritePtr
        lda metasprite_table + MetaSpriteState::AnimationAddr + 1, x
        sta ScratchSpritePtr+1
        ; reload the first frame of animation
        ldy #AnimationHeader::FrameTableAddr
        lda (ScratchSpritePtr),y
        sta metasprite_table + MetaSpriteState::AnimationFrameAddr, x
        iny
        lda (ScratchSpritePtr),y
        sta metasprite_table + MetaSpriteState::AnimationFrameAddr+1, x
        ; reload the frame counter
        ldy #AnimationHeader::Length
        lda (ScratchSpritePtr),y
        sta metasprite_table + MetaSpriteState::FrameCounter, x
reload_delay_counter:
        ; prepare scratch pointer to read the current frame data
        lda metasprite_table + MetaSpriteState::AnimationFrameAddr, x
        sta ScratchSpritePtr
        lda metasprite_table + MetaSpriteState::AnimationFrameAddr + 1, x
        sta ScratchSpritePtr+1
        ; use this data to reset the delay counter (we don't need any of the rest of it yet)
        ldy #AnimationFrame::DelayFrames
        lda (ScratchSpritePtr),y
        sta metasprite_table + MetaSpriteState::DelayCounter, x
        jmp next_metasprite
decrement_delay_counter:
        dec metasprite_table + MetaSpriteState::DelayCounter, x
next_metasprite:
        clc
        lda #.sizeof(MetaSpriteState)
        adc MetaSpriteIndex
        sta MetaSpriteIndex 
        dec MetaSpriteCount
        bne metasprite_loop
        rts
.endproc

.proc update_camera_scroll
        lda CameraXScrollTarget
        sta R0
        lda CameraXTileTarget
        .repeat 5
        lsr a
        ror R0
        .endrep
        ; a now contains low 5 bits of scroll tile, and upper 3 bits of sub-tile scroll
        sta CameraScrollPixelsX+1
        lda R0
        sta CameraScrollPixelsX
        ; now do the same for Y scroll
        lda CameraYScrollTarget
        sta R0
        lda CameraYTileTarget
        .repeat 5
        lsr a
        ror R0
        .endrep
        sta CameraScrollPixelsY+1
        lda R0
        sta CameraScrollPixelsY
        rts
.endproc

.proc hide_all_sprites
        ldx #16 ; actually don't hide sprite zero and friends
        lda #$F8
loop:
        sta SHADOW_OAM + OAM_Y_POS, x
        inx
        inx
        inx
        inx
        bne loop
        rts
.endproc

.proc draw_metasprites
MetaSpriteCount := R0
MetaSpriteIndex := R1
        jsr update_camera_scroll
        jsr hide_all_sprites
        lda #21
        sta MetaSpriteCount
        lda #0
        sta MetaSpriteIndex
        ; note: for now, jump over the test sprite
        ; TODO: something smarter than this
        lda #16
        sta OAMEntryIndex
metasprite_loop:
        ; sanity check: is this animation enabled? ie, is the high byte
        ; of the animation data non-zero?
        ldx MetaSpriteIndex
        lda metasprite_table + MetaSpriteState::AnimationAddr + 1, x
        beq next_metasprite

        ; we will at least attempt to draw this metasprite's parts.
        ; most of this data is a straight copy from the state struct
        lda metasprite_table + MetaSpriteState::PositionX, x
        sta MetaspritePosX
        lda metasprite_table + MetaSpriteState::PositionX + 1, x
        sta MetaspritePosX+1
        lda metasprite_table + MetaSpriteState::PositionY, x
        sta MetaspritePosY
        lda metasprite_table + MetaSpriteState::PositionY + 1, x
        sta MetaspritePosY+1
        lda metasprite_table + MetaSpriteState::TileOffset, x
        sta MetaspriteTileOffset
        lda metasprite_table + MetaSpriteState::PaletteOffset, x
        sta MetaspritePaletteOffset

        ; now we need the details from this animation frame
        lda metasprite_table + MetaSpriteState::AnimationFrameAddr, x
        sta ScratchSpritePtr
        lda metasprite_table + MetaSpriteState::AnimationFrameAddr + 1, x
        sta ScratchSpritePtr+1

        ldy #AnimationFrame::OAMTableAddr
        lda (ScratchSpritePtr),y
        sta OAMTableAddr
        ldy #AnimationFrame::OAMTableAddr+1
        lda (ScratchSpritePtr),y
        sta OAMTableAddr+1
        ldy #AnimationFrame::OAMLength
        lda (ScratchSpritePtr),y
        sta OAMTableLength

        ; apply the camera scroll amount to the sprite's meta position
        sec
        lda MetaspritePosX
        sbc CameraScrollPixelsX
        sta MetaspritePosX
        lda MetaspritePosX+1
        sbc CameraScrollPixelsX+1
        sta MetaspritePosX+1

        sec
        lda MetaspritePosY
        sbc CameraScrollPixelsY
        sta MetaspritePosY
        lda MetaspritePosY+1
        sbc CameraScrollPixelsY+1
        sta MetaspritePosY+1

        ; finally
        jsr draw_metasprite
next_metasprite:
        clc
        lda #.sizeof(MetaSpriteState)
        adc MetaSpriteIndex
        sta MetaSpriteIndex 
        dec MetaSpriteCount
        bne metasprite_loop
all_done:
        rts
.endproc

.endscope
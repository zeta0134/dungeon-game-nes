        .setcpu "6502"
        .include "sprites.inc"
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
        .segment "RAM"
        .export metasprite_table
metasprite_table:
        .repeat 21
        .tag MetaSpriteState
        .endrepeat

        .segment "PRGLAST_E000"
        ;.org $e000

.export initialize_oam, draw_metasprite, update_animations

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
        adc MetaspritePosX
        tax ; stash OamX for now
        lda MetaspritePosX+1
        adc #0
        ; a now contains the modified high byte of the X position
        ; sanity check: is this sprite onscreen horizontally?
        bne skip_oam_entry
        ; calculate the on-screen Y position too
        clc
        ldy #OAMEntry::YOffset
        lda (OAMTableAddr),y
        adc MetaspritePosY
        tay ; stash OamY for now
        lda MetaspritePosY+1
        adc #0
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
        ; TODO: If we want to use a custom bank offset, this is the place to do it
        sta SHADOW_OAM + OAM_TILE, x
        ldy #OAMEntry::Attributes
        lda (OAMTableAddr),y
        ; TODO: If we want to alter the palette index, this is the place to do it
        sta SHADOW_OAM + OAM_ATTRIBUTES, x
skip_oam_fragment:
        clc
        add16 OAMEntryIndex, #4
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

.endscope
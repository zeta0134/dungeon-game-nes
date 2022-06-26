        .setcpu "6502"
        .include "entity.inc"
        .include "sprites.inc"
        .include "scrolling.inc"
        .include "word_util.inc"
        .include "zeropage.inc"

        .zeropage
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
metasprite_table:
        .repeat 16
        .tag MetaSpriteState
        .endrepeat

sorted_entity_table:
        .res 16
high_priority_table:
        .res 16
low_priority_table:
        .res 16

HighPriorityCount: .res 1
LowPriorityCount: .res 1
SortedEntityCount: .res 1
        .segment "ENTITIES_A000"
        ;.org $e000


.proc FAR_initialize_oam
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

; when called, R0 is updated with the first free
; metasprite slot. Upon failure (full table), R0
; will be set to $FF, so check for this condition in the calling
; code to handle the error.
.proc find_unused_metasprite
MetaSpriteIndex := R0
        lda #0
        sta MetaSpriteIndex
loop:
        ldx MetaSpriteIndex
        lda metasprite_table + MetaSpriteState::AnimationAddr + 1, x
        beq found
        lda #.sizeof(MetaSpriteState)
        clc
        adc MetaSpriteIndex
        bcs table_is_full
        sta MetaSpriteIndex
        jmp loop
table_is_full:
        lda #$FF
        sta MetaSpriteIndex
found:
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
        ; TODO: also skip fragments that are below the HUD line at 192+8px
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

.proc FAR_update_animations
MetaSpriteCount := R0
MetaSpriteIndex := R1
        lda #16
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

.proc draw_one_metasprite
MetaSpriteIndex := R1
        ; sanity check: is this animation enabled? ie, is the high byte
        ; of the animation data non-zero?
        ldx MetaSpriteIndex
        lda metasprite_table + MetaSpriteState::AnimationAddr + 1, x
        beq next_metasprite

        ; is this metasprite disabled with a flag?
        metasprite_check_flag FLAG_VISIBILITY
        bne next_metasprite

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

        ; sanity check: if this OAM Table length is 0, there is nothing to draw.
        beq next_metasprite

        ; apply the camera scroll amount to the sprite's meta position
        sec
        lda MetaspritePosX
        sbc CameraScrollPixelsX
        sta MetaspritePosX
        lda MetaspritePosX+1
        sbc CameraScrollPixelsX+1
        sta MetaspritePosX+1

        ; the Y coordinate must additionally be offset by 8px to account for the
        ; top segment of the screen, which is blanked
        ; TODO: If we make this user configurable, we should use that value here
        clc
        add16 MetaspritePosY, #8

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
        rts
.endproc

; call this with the index to register in A
.proc register_high_priority_metasprite
        ldx HighPriorityCount
        sta high_priority_table, x
        inc HighPriorityCount
        rts
.endproc

; call this with the index to register in A
; please don't call this while the table is empty >_<
.proc unregister_high_priority_metasprite
        ; first find the entry to remove
        ldx #0
loop:
        cmp high_priority_table, x
        beq found_it
        inx
        cpx HighPriorityCount
        bne loop
not_found:
        ; oh well
        rts
found_it:
        ; shift the entire list down to fill the space
        txa
        tay
        iny
shift_loop:
        lda high_priority_table, y
        sta high_priority_table, x
        inx
        iny
        cpy #16
        beq done_shifting
        jmp shift_loop
done_shifting:
        dec HighPriorityCount
        rts
.endproc

.proc draw_high_priority_metasprites
MetaSpriteIndex := R1
HighPriorityIndex := R2
        lda #0
        sta HighPriorityIndex
        cmp HighPriorityCount
        beq all_done ; if there's nothing to draw here, bail

metasprite_loop:
        ldx HighPriorityIndex
        lda high_priority_table, x
        sta MetaSpriteIndex
        ; note: for now, jump over the test sprite
        ; TODO: something smarter than this
        jsr draw_one_metasprite
        inc HighPriorityIndex
        lda HighPriorityIndex
        cmp HighPriorityCount
        bne metasprite_loop
all_done:
        rts
.endproc

; call this with the index to register in A
.proc register_low_priority_metasprite
        ldx LowPriorityCount
        sta low_priority_table, x
        inc LowPriorityCount
        rts
.endproc

; call this with the index to register in A
; please don't call this while the table is empty >_<
.proc unregister_low_priority_metasprite
        ; first find the entry to remove
        ldx #0
loop:
        cmp low_priority_table, x
        beq found_it
        inx
        cpx LowPriorityCount
        bne loop
not_found:
        ; oh well
        rts
found_it:
        ; shift the entire list down to fill the space
        txa
        tay
        iny
shift_loop:
        lda low_priority_table, y
        sta low_priority_table, x
        inx
        iny
        cpy #16
        beq done_shifting
        jmp shift_loop
done_shifting:
        dec LowPriorityCount
        rts
.endproc

.proc draw_low_priority_metasprites
MetaSpriteIndex := R1
LowPriorityIndex := R2
        lda #0
        sta LowPriorityIndex
        cmp LowPriorityCount
        beq all_done ; if there's nothing to draw here, bail

metasprite_loop:
        ldx LowPriorityIndex
        lda low_priority_table, x
        sta MetaSpriteIndex
        ; note: for now, jump over the test sprite
        ; TODO: something smarter than this
        jsr draw_one_metasprite
        inc LowPriorityIndex
        lda LowPriorityIndex
        cmp LowPriorityCount
        bne metasprite_loop
all_done:
        rts
.endproc

; call this with the index to register in A
.proc register_sorted_entity
        ldx SortedEntityCount
        sta sorted_entity_table, x
        inc SortedEntityCount
        rts
.endproc

; call this with the index to register in A
; please don't call this while the table is empty >_<
.proc unregister_sorted_entity
        ; first find the entry to remove
        ldx #0
loop:
        cmp sorted_entity_table, x
        beq found_it
        inx
        cpx SortedEntityCount
        bne loop
not_found:
        ; oh well
        rts
found_it:
        ; shift the entire list down to fill the space
        txa
        tay
        iny
shift_loop:
        lda sorted_entity_table, y
        sta sorted_entity_table, x
        inx
        iny
        cpy #16
        beq done_shifting
        jmp shift_loop
done_shifting:
        dec SortedEntityCount
        rts
.endproc

.proc draw_sorted_entities
MetaSpriteIndex := R1
EntityIndex := R0
        ; bail if there is nothing to draw
        lda SortedEntityCount
        beq all_done

        lda #0
        sta EntityIndex
loop:
        ; Draw the entity's main sprite
        ldx EntityIndex
        ldy sorted_entity_table, x
        lda entity_table + EntityState::MetaSpriteIndex, y
        sta MetaSpriteIndex
        jsr draw_one_metasprite
        ; Now draw the shadow sprite
        ; (assume all registers were clobbered)
        ldx EntityIndex
        ldy sorted_entity_table, x
        lda entity_table + EntityState::ShadowSpriteIndex, y
        sta MetaSpriteIndex
        jsr draw_one_metasprite
        ; iterate
        inc EntityIndex
        lda EntityIndex
        cmp SortedEntityCount
        bne loop
all_done:
        rts
.endproc


.proc sort_entities
EntityIndex := R0
AdjustedDepthA := R1
AdjustedDepthB := R3
        ; bail if there are fewer than 2 entities
        lda SortedEntityCount
        cmp #2
        bcc all_done

        lda #1
        sta EntityIndex
loop:
        ; compute AdjustedDepth for the first object
        ldx EntityIndex
        ldy sorted_entity_table - 1, x
        lda entity_table + EntityState::PositionY, y
        sta AdjustedDepthA
        lda entity_table + EntityState::PositionY+1, y
        clc
        adc entity_table + EntityState::GroundLevel, y
        sta AdjustedDepthA+1

        ; compute AdjustedDepth for the second object
        ldx EntityIndex
        ldy sorted_entity_table, x
        lda entity_table + EntityState::PositionY, y
        sta AdjustedDepthB
        lda entity_table + EntityState::PositionY+1, y
        clc
        adc entity_table + EntityState::GroundLevel, y
        sta AdjustedDepthB+1

        ; if A is less than B, perform a swap
        cmp16 AdjustedDepthA, AdjustedDepthB
        bcc swap_needed
no_swap:
        inc EntityIndex
        lda EntityIndex
        cmp SortedEntityCount
        bne loop
        ; all done
        rts

swap_needed:
        ldx EntityIndex
        lda sorted_entity_table-1, x
        ldy sorted_entity_table, x
        sta sorted_entity_table, x
        tya
        sta sorted_entity_table-1, x
        ; do NOT loop! exit immediately, we're done
all_done:
        rts
.endproc

.proc FAR_draw_metasprites
        ; setup
        jsr update_camera_scroll
        jsr hide_all_sprites
        ; start drawing at OAM entry 4 for now
        ; (maybe later we draw particles first?)
        lda #16
        sta OAMEntryIndex

        jsr draw_high_priority_metasprites
        jsr draw_sorted_entities
        jsr draw_low_priority_metasprites

        ; perform entity sorting
        jsr sort_entities
        rts
.endproc

.proc old_draw_metasprites
MetaSpriteCount := R0
MetaSpriteIndex := R1
        jsr update_camera_scroll
        jsr hide_all_sprites
        lda #16
        sta MetaSpriteCount
        lda #0
        sta MetaSpriteIndex
        ; note: for now, jump over the test sprite
        ; TODO: something smarter than this
        lda #16
        sta OAMEntryIndex
metasprite_loop:
        jsr draw_one_metasprite
        clc
        lda #.sizeof(MetaSpriteState)
        adc MetaSpriteIndex
        sta MetaSpriteIndex 
        dec MetaSpriteCount
        bne metasprite_loop
all_done:
        rts
.endproc

.proc FAR_despawn_all_metasprites
MetaSpriteCount := R0
MetaSpriteIndex := R1
        lda #0
        sta MetaSpriteIndex
        lda #16
        sta MetaSpriteCount
loop:
        ldx MetaSpriteIndex
        ; Disable metasprite by setting its animation high byte to 0
        lda #0
        sta metasprite_table + MetaSpriteState::AnimationAddr + 1, x
next_metasprite:
        clc
        lda #.sizeof(MetaSpriteState)
        adc MetaSpriteIndex
        sta MetaSpriteIndex 
        dec MetaSpriteCount
        bne loop
done:

        ; also clear out our lists, since we just invalidated them completely
        lda #0
        sta HighPriorityCount
        sta LowPriorityCount
        sta SortedEntityCount
        lda #$FF
        ldx #0
object_despawn_loop:
        sta sorted_entity_table, x
        inx
        cpx #16
        bne object_despawn_loop

        rts
.endproc
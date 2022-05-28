        .setcpu "6502"
        .include "nes.inc"
        .include "entity.inc"
        .include "scrolling.inc"
        .include "zeropage.inc"


.scope SCROLLING_A000
        .segment "RAM"
DesiredX: .word $0000
DesiredY: .word $0000
        .segment "SCROLLING_A000"

.export FAR_update_camera

.proc find_desired_follow_camera
        ; start with the position of the entity in slot #0

        ; load player coordinates
        lda entity_table + EntityState::PositionX
        sta DesiredX
        lda entity_table + EntityState::PositionX + 1
        sta DesiredX + 1
        lda entity_table + EntityState::PositionY
        sta DesiredY
        lda entity_table + EntityState::PositionY + 1
        sta DesiredY + 1

        ; subtract the entity's current 3D height from the desired Y
        sec
        lda DesiredY
        sbc entity_table + EntityState::PositionZ
        sta DesiredY
        lda DesiredY+1
        sbc entity_table + EntityState::PositionZ + 1
        sta DesiredY+1

        ; convert from 16x16 metatiles to 8x8 hardware tiles
        clc
        rol DesiredX
        rol DesiredX+1
        clc
        rol DesiredY
        rol DesiredY+1

        ; substract half of screen width
        lda DesiredX+1
        sec
        sbc #16 ; in 8x8 tiles
        sta DesiredX+1
        ; subtract half of the screen height
        lda DesiredY+1
        sec
        sbc #12 ; in 8x8 tiles
        sta DesiredY+1

        ; FOR NOW this is our target. Do nothing else.
        rts
.endproc

.proc clamp_to_map_edges
        ; if camera would be outside of map bounds, set it there instead
        ; if x < 0, fix it
        lda DesiredX+1
        bpl x_not_negative
        lda #0
        sta DesiredX
        sta DesiredX+1
x_not_negative:
        ; if y < 0, fix it
        lda DesiredY+1
        bpl y_not_negative
        lda #0
        sta DesiredY
        sta DesiredY+1
y_not_negative:
        ; if x > map_width, fix it
        ; first, calculate the map width in HW tiles
        lda MapWidth
        asl a
        ; now subtract screen width
        sbc #32
        ; stash in x temporarily
        tax
        ; a now contains our maximum scroll amount to the right
        ; compare with the high byte
        ; of our desired X
        sbc DesiredX+1
        ; if we overflowed, clamp DesiredX to the maximum
        bcs x_less_than_maximum
        txa
        sta DesiredX+1
        lda #0
        sta DesiredX
x_less_than_maximum:
        ; if x > map_width, fix it
        ; first, calculate the map width in HW tiles
        lda MapHeight
        asl a
        ; now subtract *playfield* height (ignoring the status area)
        sec
        sbc #24
        ; stash in x temporarily
        tax
        ; a now contains our maximum scroll amount downward
        ; compare with the high byte
        ; of our desired Y
        sbc DesiredY+1
        ; if we overflowed, clamp DesiredY to the maximum
        bcs y_less_than_maximum
        txa
        sta DesiredY+1
        lda #0
        sta DesiredY
y_less_than_maximum:
        ; all done!
        rts
.endproc

.proc lerp_target_to_desired
Distance := R0
        ; calculate some percentage of travel distance from target to desired
        ; first calculate the travel distance from our current scroll position
        ; to the target:
        sec
        lda DesiredX
        sbc CameraXScrollTarget
        sta Distance
        lda DesiredX+1
        sbc CameraXTileTarget
        sta Distance+1
        ; sanity check: are we already AT the target? If so, bail now
        ora Distance
        beq done_with_x
        ; this is a signed comparison, and it's much easier to simply split the code here
        lda Distance+1
        bmi negative_x
positive_x:
        ; divide the distance by... oh, 16 sounds good
.repeat 4
        lsr Distance+1
        ror Distance
.endrepeat
        ; this would be our travel distance, but we'll be in trouble if it exceeds +4 px, which
        ; happens to be $0080 in this representation. So, if the high byte is nonzero:
        lda Distance+1
        bne clamp_x_pos
        ; ... or the low byte is >= $80
        lda Distance
        bpl store_result_x
clamp_x_pos:
        ; then set X to the maximum right scroll
        lda #0
        sta Distance+1
        lda #$80
        sta Distance
        jmp store_result_x
negative_x:
        ; divide the distance by... oh, 16 sounds good
.repeat 4
        sec
        ror Distance+1
        ror Distance
.endrepeat
        ; this would be our final travel distance, but if it exceeds -4px we need to clamp it.
        ; this happens to be $FF80. So if the high byte is NOT $FF:
        lda Distance+1
        cmp #$FF
        bne clamp_x_neg
        ; or the low byte is LESS than (or equal to is fine) $80
        lda Distance
        bmi store_result_x
clamp_x_neg:
        ; then set X to the maximum left scroll
        lda #$FF
        sta Distance+1
        lda #$80
        sta Distance
store_result_x:
        ; apply the computed distance to the camera's target position
        clc
        lda CameraXScrollTarget
        adc Distance
        sta CameraXScrollTarget
        lda CameraXTileTarget
        adc Distance+1
        sta CameraXTileTarget
done_with_x:
        
        ; do all of that again, for the Y coordinate
        sec
        lda DesiredY
        sbc CameraYScrollTarget
        sta Distance
        lda DesiredY+1
        sbc CameraYTileTarget
        sta Distance+1
        ; sanity check: are we already AT the target? If so, bail now
        ora Distance
        beq done_with_y
        ; this is a signed comparison, and it's much easier to simply split the code here
        lda Distance+1
        bmi negative_y
positive_y:
        ; divide the distance by... oh, 16 sounds good
.repeat 4
        lsr Distance+1
        ror Distance
.endrepeat
        ; this would be our travel distance, but we'll be in trouble if it exceeds +4 px, which
        ; happens to be $0080 in this representation. So, if the high byte is nonzero:
        lda Distance+1
        bne clamp_y_pos
        ; ... or the low byte is >= $80
        lda Distance
        bpl store_result_y
clamp_y_pos:
        ; then set X to the maximum right scroll
        lda #0
        sta Distance+1
        lda #$80
        sta Distance
        jmp store_result_y
negative_y:
        ; divide the distance by... oh, 16 sounds good
.repeat 4
        sec
        ror Distance+1
        ror Distance
.endrepeat
        ; this would be our final travel distance, but if it exceeds -4px we need to clamp it.
        ; this happens to be $FF80. So if the high byte is NOT $FF:
        lda Distance+1
        cmp #$FF
        bne clamp_y_neg
        ; or the low byte is LESS than (or equal to is fine) $80
        lda Distance
        bmi store_result_y
clamp_y_neg:
        ; then set X to the maximum left scroll
        lda #$FF
        sta Distance+1
        lda #$80
        sta Distance
store_result_y:
        ; apply the computed distance to the camera's target position
        clc
        lda CameraYScrollTarget
        adc Distance
        sta CameraYScrollTarget
        lda CameraYTileTarget
        adc Distance+1
        sta CameraYTileTarget
done_with_y:

        ; and done!
        rts
.endproc

.proc FAR_update_camera
        jsr find_desired_follow_camera
        jsr clamp_to_map_edges
        jsr lerp_target_to_desired
        rts
.endproc

.endscope




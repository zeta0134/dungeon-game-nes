        .setcpu "6502"
        .include "branch_util.inc"
        .include "camera.inc"
        .include "nes.inc"
        .include "entity.inc"
        .include "prng.inc"
        .include "scrolling.inc"
        .include "word_util.inc"
        .include "zeropage.inc"

        .segment "RAM"
FollowCameraDesiredX: .word $0000
FollowCameraDesiredY: .word $0000

CameraShakeStrength: .byte $00
CameraShakeSpeed: .byte $00
CameraShakeSpeedCounter: .byte $00
CameraShakeDecay: .byte $00
CameraShakeDecayCounter: .byte $00
CameraShakeX: .word $00
CameraShakeY: .word $00
        .segment "SCROLLING_A000"

.proc find_desired_follow_camera
        ; start with the position of the entity in slot #0

        ; load player coordinates
        lda entity_table + EntityState::PositionX
        sta FollowCameraDesiredX
        lda entity_table + EntityState::PositionX + 1
        sta FollowCameraDesiredX + 1
        lda entity_table + EntityState::PositionY
        sta FollowCameraDesiredY
        lda entity_table + EntityState::PositionY + 1
        sta FollowCameraDesiredY + 1

        ; subtract the entity's current 3D height from the desired Y
        sec
        lda FollowCameraDesiredY
        sbc entity_table + EntityState::PositionZ
        sta FollowCameraDesiredY
        lda FollowCameraDesiredY+1
        sbc entity_table + EntityState::PositionZ + 1
        sta FollowCameraDesiredY+1

        ; convert from 16x16 metatiles to 8x8 hardware tiles
        clc
        rol FollowCameraDesiredX
        rol FollowCameraDesiredX+1
        clc
        rol FollowCameraDesiredY
        rol FollowCameraDesiredY+1

        ; substract half of screen width
        lda FollowCameraDesiredX+1
        sec
        sbc #16 ; in 8x8 tiles
        sta FollowCameraDesiredX+1
        ; subtract half of the screen height
        lda FollowCameraDesiredY+1
        sec
        sbc #12 ; in 8x8 tiles
        sta FollowCameraDesiredY+1

        ; FOR NOW this is our target. Do nothing else.
        rts
.endproc

.proc clamp_to_map_edges
        ; if camera would be outside of map bounds, set it there instead
        ; if x < 0, fix it
        lda FollowCameraDesiredX+1
        bpl x_not_negative
        lda #0
        sta FollowCameraDesiredX
        sta FollowCameraDesiredX+1
x_not_negative:
        ; if y < 0, fix it
        lda FollowCameraDesiredY+1
        bpl y_not_negative
        lda #0
        sta FollowCameraDesiredY
        sta FollowCameraDesiredY+1
y_not_negative:
        ; if x > map_width, fix it
        ; first, calculate the map width in HW tiles
        lda MapWidth
        asl a
        ; now subtract screen width
        sec
        sbc #32
        ; stash in x temporarily
        ; a now contains our maximum scroll amount to the right
        ; compare with the high byte
        ; of our desired X
        cmp FollowCameraDesiredX+1
        ; if we overflowed, clamp FollowCameraDesiredX to the maximum
        bcc x_adjustment
        beq x_adjustment
        jmp x_less_than_maximum
x_adjustment:
        sta FollowCameraDesiredX+1
        lda #0
        sta FollowCameraDesiredX
x_less_than_maximum:
        ; if x > map_width, fix it
        ; first, calculate the map width in HW tiles
        lda MapHeight
        asl a
        ; now subtract *playfield* height (ignoring the status area)
        sec
        sbc #24
        ; stash in x temporarily

        ; a now contains our maximum scroll amount downward
        ; compare with the high byte
        ; of our desired Y
        cmp FollowCameraDesiredY+1
        ; if we overflowed, clamp FollowCameraDesiredY to the maximum
        bcc y_adjustment
        beq y_adjustment
        jmp y_less_than_maximum
y_adjustment:
        sta FollowCameraDesiredY+1
        lda #0
        sta FollowCameraDesiredY
y_less_than_maximum:
        ; all done!
        rts
.endproc

.proc update_camera_shake
        lda CameraShakeStrength
        beq no_camera_shake

        dec CameraShakeSpeedCounter
        bmi apply_camera_shake
        rts
apply_camera_shake:
        ; first, reset our speed counter
        lda CameraShakeSpeed
        sta CameraShakeSpeedCounter

        ; now process strength decay
        dec CameraShakeDecayCounter
        bpl no_decay
        lsr CameraShakeStrength
        lda CameraShakeDecay
        sta CameraShakeDecayCounter

no_decay:
        ; pick random numbers for the camera shake amount
        jsr next_rand
        and CameraShakeStrength
        sta CameraShakeX
        lda CameraShakeStrength
        lsr
        eor #$FF
        adc CameraShakeX
        sta CameraShakeX


        jsr next_rand
        and CameraShakeStrength
        sta CameraShakeY
        lda CameraShakeStrength
        lsr
        eor #$FF
        adc CameraShakeY
        sta CameraShakeY

        ; all done
        rts

no_camera_shake:
        lda #0
        sta CameraShakeX
        sta CameraShakeX+1
        sta CameraShakeY
        sta CameraShakeY+1
        rts
.endproc

.proc lerp_target_to_desired
Distance := R0
        jsr update_camera_shake
        ; calculate some percentage of travel distance from target to desired
        ; first calculate the travel distance from our current scroll position
        ; to the target:
        sec
        lda FollowCameraDesiredX
        sbc CameraXScrollTarget
        sta Distance
        lda FollowCameraDesiredX+1
        sbc CameraXTileTarget
        sta Distance+1

        ; would applying camera shake make the follow target negative?
        clc
        lda FollowCameraDesiredX+1
        adc CameraShakeX
        bmi no_x_shake

        ; apply camera shake to the high byte
        clc
        lda Distance+1
        adc CameraShakeX
        sta Distance+1

no_x_shake:
        ; sanity check: are we already AT the target? If so, bail now
        ora Distance
        jeq done_with_x
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
        lda FollowCameraDesiredY
        sbc CameraYScrollTarget
        sta Distance
        lda FollowCameraDesiredY+1
        sbc CameraYTileTarget
        sta Distance+1

        ; would applying camera shake make the follow target negative?
        clc
        lda FollowCameraDesiredY+1
        adc CameraShakeY
        bmi no_y_shake

        ; apply camera shake to the high byte
        clc
        lda Distance+1
        adc CameraShakeY
        sta Distance+1

no_y_shake:
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

.proc FAR_update_desired_pos_only
        jsr find_desired_follow_camera
        jsr clamp_to_map_edges
        rts
.endproc

.proc FAR_update_camera
        jsr find_desired_follow_camera
        jsr clamp_to_map_edges
        jsr lerp_target_to_desired
        rts
.endproc

.proc FAR_init_camera
        lda #0
        sta CameraXTileCurrent
        sta CameraXScrollCurrent
        sta CameraYTileCurrent
        sta CameraYScrollCurrent
        sta CameraXTileTarget
        sta CameraXScrollTarget
        sta CameraYTileTarget
        sta CameraYScrollTarget
        sta PpuXTileTarget
        sta PpuYTileTarget
        rts
.endproc



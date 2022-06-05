.global FAR_apply_standard_entity_speed
.global FAR_standard_entity_vertical_acceleration
.global FAR_sense_ground

GRAVITY_ACCEL = ($FF - 2)
TERMINAL_VELOCITY = ($FF - 60)

; what could *possibly* go wrong?
; note: all of these are meant to operate on items in an
; entity table, so speed_addr is indexed with x in all cases

.macro accelerate SpeedAddr, Acceleration
        clc
        lda Acceleration
        adc SpeedAddr, x
        sta SpeedAddr, x
.endmacro

.macro max_speed SpeedAddr, SpeedLimit
.scope
        lda SpeedAddr, x
        sbc SpeedLimit
        bvc no_overflow
        eor #$80 ; flip the high bit
no_overflow:
        ; the high bit is now V EOR N
        ; if SpeedAddr < SpeedLimit
        bmi no_change
        ; otherwise, make it so!
        lda SpeedLimit
        sta SpeedAddr, x
no_change:
.endscope
.endmacro

.macro min_speed SpeedAddr, SpeedLimit
.scope
        lda SpeedLimit
        sbc SpeedAddr, x
        bvc no_overflow
        eor #$80 ; flip the high bit
no_overflow:
        ; the high bit is now V EOR N
        ; if SpeedLimit < SpeedAddr
        bmi no_change
        ; otherwise, make it so!
        lda SpeedLimit
        sta SpeedAddr, x
no_change:
.endscope
.endmacro

.macro apply_friction SpeedAddr, Slipperiness
.scope
        lda SpeedAddr, x
        beq done ; bail if speed is 0
        ; the 7th bit needs to be preserved, we branch to handle both cases
        bmi negative
positive:
        .repeat Slipperiness
        lsr SpeedAddr, x
        .endrepeat
        ; at this point, a still contains the original speed
        clc ; effectively force a min dampening value of 1
        sbc SpeedAddr, x
        ; and now it contains the dampened speed
        sta SpeedAddr, x
        jmp done
negative:
        .repeat Slipperiness
        sec
        ror SpeedAddr, x
        .endrepeat
        ; at this point, a still contains the original speed
        sec
        sbc SpeedAddr, x
        ; now it contains the dampened speed
        sta SpeedAddr, x
done:
.endscope
.endmacro

.ifndef _PHYSICS_INC
_PHYSICS_INC := 1
; what could *possibly* go wrong?
; note: all of these are meant to operate on items in an
; entity table, so speed_addr is indexed with x in all cases

.macro accelerate speed_addr, acceleration
        clc
        lda acceleration
        adc speed_addr, x
        sta speed_addr, x
.endmacro

.macro max_speed speed_addr, speed_limit
.scope
        lda speed_addr, x
        cmp speed_limit
        bcc no_change
        lda speed_limit
        sta speed_addr, x
no_change:
.endscope
.endmacro

.macro min_speed speed_addr, speed_limit
.scope
        lda speed_limit
        cmp speed_addr, x
        bcc no_change
        sta speed_addr, x
no_change:
.endscope
.endmacro

.macro apply_friction speed_addr, slipperiness
.scope
        lda speed_addr, x
        beq done ; bail if speed is 0
        ; the 7th bit needs to be preserved, we branch to handle both cases
        bmi negative
positive:
        .repeat slipperiness
        lsr speed_addr, x
        .endrepeat
        ; at this point, a still contains the original speed
        clc ; effectively force a min dampening value of 1
        sbc speed_addr, x
        ; and now it contains the dampened speed
        sta speed_addr, x
        jmp done
negative:
        .repeat slipperiness
        sec
        ror speed_addr, x
        .endrepeat
        ; at this point, a still contains the original speed
        sec
        sbc speed_addr, x
        ; now it contains the dampened speed
        sta speed_addr, x
done:
.endscope
.endmacro

.endif
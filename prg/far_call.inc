.ifndef FAR_CALL_INC
.define FAR_CALL_INC 1

.import launch_far_call
.importzp TargetBank, CurrentBank, JumpTarget

.macro far_call label
.scope
        lda #<.BANK(label)
        sta TargetBank
        lda #<(label)
        sta JumpTarget
        lda #>(label)
        sta JumpTarget+1
        jsr launch_far_call
.endscope
.endmacro



.endif
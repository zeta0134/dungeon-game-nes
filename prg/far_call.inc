.global launch_far_call
.globalzp TargetBank, CurrentBank, JumpTarget

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



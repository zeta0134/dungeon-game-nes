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

.macro access_data_bank TargetBank
        lda CurrentBank
        pha
        mmc3_select_bank 7, TargetBank
        lda TargetBank
        sta CurrentBank
.endmacro

.macro restore_previous_bank
        pla
        sta CurrentBank
        mmc3_select_bank 7, CurrentBank
.endmacro
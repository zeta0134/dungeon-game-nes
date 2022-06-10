.global launch_far_call
.globalzp TargetBank, CurrentBank, JumpTarget

; for calls from banked code to other banked code
.macro far_call label
.scope
        .assert .bank(*) <> .bank(label), error, "unnecessary far call"
        lda #<.BANK(label)
        sta TargetBank
        lda #<(label)
        sta JumpTarget
        lda #>(label)
        sta JumpTarget+1
        jsr launch_far_call
.endscope
.endmacro

; for calls from banked code to other code within the same bank only
; try to use this instead of jsr for banked routines
.macro near_call label
.scope
        .assert .bank(*) = .bank(label), error, "unsafe near call"
        jsr label
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
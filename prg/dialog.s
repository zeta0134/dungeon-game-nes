        .setcpu "6502"
        .include "dialog.inc"

        .segment "PRGFIXED_E000"

.proc update_dialog_engine
        ; for now, do absolutely nothing
        rts
.endproc
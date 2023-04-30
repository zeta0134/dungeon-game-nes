        .setcpu "6502"

        .include "level_logic.inc"

        .segment "PRGRAM"
maplogic_ptr: .res 2

        .segment "MAPS_0_A000"

.proc FAR_init_maplogic
        lda #<do_absolutely_nothing
        sta maplogic_ptr+0
        lda #>do_absolutely_nothing
        sta maplogic_ptr+1

        ; TODO: initialize any room-specific variables to 0 here
        ; (we don't yet have any)

        rts
.endproc

.proc FAR_run_map_logic
        jmp (maplogic_ptr)
        ; tail call
.endproc

.proc do_absolutely_nothing
        ; does just that
        rts
.endproc

.proc maplogic_default
        

        rts
.endproc
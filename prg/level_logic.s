        .setcpu "6502"

        .include "kernel.inc"
        .include "level_logic.inc"
        .include "nes.inc"

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
        ; safety
        lda maplogic_ptr+1 ; please don't put maplogic functions in zero page
        bne perform_call
        rts ; bail
perform_call:
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
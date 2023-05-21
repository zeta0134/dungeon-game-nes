        .setcpu "6502"

        .include "actions.inc"
        .include "event_queue.inc"
        .include "far_call.inc"
        .include "input.inc"
        .include "kernel.inc"
        .include "level_logic.inc"
        .include "map.inc"
        .include "nes.inc"
        .include "overlays.inc"
        .include "sound.inc"
        .include "tilebuffer.inc"
        .include "word_util.inc"
        .include "zeropage.inc"

        .segment "RAM"
maplogic_ptr: .res 2

        .segment "MAPS_0_A000"

.proc FAR_init_maplogic
        lda #<do_absolutely_nothing
        sta maplogic_ptr+0
        lda #>do_absolutely_nothing
        sta maplogic_ptr+1

        lda #0
        sta event_next
        sta event_current

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

.proc handle_debug_key
        lda #KEY_SELECT
        bit ButtonsHeld
        beq no_debug
        lda #KEY_START
        bit ButtonsDown
        beq no_debug   

        ; DEBUG KEY PRESSED! Do debug things here
        
        ;activate the dialog system!
        st16 GameMode, dialog_init
        
        ; Un-break the action button state, in case we have just switched modes
        lda #0
        sta action_flags
no_debug:

        rts
.endproc

.proc maplogic_default
TilePosX := R0
TilePosY := R1
        jsr handle_debug_key
        
        ldx event_current
        cpx event_next
        beq done_with_events
event_loop:
        lda events_type, x
        cmp #SWITCH_UNPRESSED
        bne unrecognized_event

        ; For now, when pressing a switch, Data0 indicates whether this is a SET or an UNSET
        lda events_data0, x
        beq switch_unset
switch_set:
        lda events_id, x
        jsr find_overlay_to_set ; result in A, which will be $FF on error
        cmp #0
        bmi unrecognized_event
        jmp apply_overlay
switch_unset:
        lda events_id, x
        jsr find_overlay_to_unset ; result in A, which will be $FF on error
        cmp #0
        bmi unrecognized_event
apply_overlay:
        jsr apply_overlay_by_index
        jmp done_dispatching_event

unrecognized_event:
        ; how did we get here? yay! play an error and panic
        st16 R0, sfx_error_buzz
        jsr play_sfx_noise

        ; fall through and continue the loop
done_dispatching_event:
        jsr consume_event
        ldx event_current
        cpx event_next
        bne event_loop        

done_with_events:
        rts
.endproc
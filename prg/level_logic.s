        .setcpu "6502"

        .include "actions.inc"
        .include "dialog.inc"
        .include "event_queue.inc"
        .include "far_call.inc"
        .include "input.inc"
        .include "kernel.inc"
        .include "level_logic.inc"
        .include "map.inc"
        .include "nes.inc"
        .include "overlays.inc"
        .include "saves.inc"
        .include "sound.inc"
        .include "text.inc"
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
        st16 TextPtr, lorem_ipsum
        st16 GameMode, dialog_init
        
        ; Un-break the action button state, in case we have just switched modes
        lda #0
        sta action_flags
no_debug:

        rts
.endproc

.proc _preserve_old_event_state
PreviousEventState := R30
NewEventState := R31
        ; First, preserve the current state of the event flag, we'll need it to compare with
        ; in a moment
        ldx event_current
        lda events_id, x
        jsr check_area_flag ; result in Z, technically, but usefully the masked result is in A
        sta PreviousEventState
        rts
.endproc

.proc _react_to_new_event_state
PreviousEventState := R30
NewEventState := R31
        ; If the new state is DIFFERENT, we need to apply an overlay, otherwise we're done
        ldx event_current
        lda events_id, x
        jsr check_area_flag ; masked result in A
        sta NewEventState
        eor PreviousEventState
        bne find_matching_overlay
        rts
find_matching_overlay:
        lda NewEventState
        beq unset_overlay
set_overlay:
        ldx event_current
        lda events_id, x
        jsr find_overlay_to_set ; result in A, which will be $FF on error
        cmp #0
        bmi unrecognized_overlay
        jmp apply_overlay
unset_overlay:
        ldx event_current
        lda events_id, x
        jsr find_overlay_to_unset ; result in A, which will be $FF on error
        cmp #0
        bmi unrecognized_overlay
apply_overlay:
        jsr apply_overlay_by_index
        rts

        ; For now, consider any overlay we cannot find to be an audible error
        ; (oh no!) But since we set the overlay, we should only do this once.
unrecognized_overlay:
        ; how did we get here? yay! play an error and panic
        st16 R0, sfx_error_buzz
        jsr play_sfx_noise
        rts        
.endproc

.proc _set_event_and_apply_overlay
        jsr _preserve_old_event_state

        ldx event_current
        lda events_id, x
        jsr set_area_flag

        jsr _react_to_new_event_state
        rts
.endproc

.proc _unset_event_and_apply_overlay
        jsr _preserve_old_event_state

        ldx event_current
        lda events_id, x
        jsr clear_area_flag

        jsr _react_to_new_event_state
        rts
.endproc

.proc _toggle_event_and_apply_overlay
        jsr _preserve_old_event_state

        ldx event_current
        lda events_id, x
        jsr toggle_area_flag

        jsr _react_to_new_event_state
        rts
.endproc

.proc maplogic_default
TilePosX := R0
TilePosY := R1
PreviousEventState := R30
NewEventState := R31
        jsr handle_debug_key
        
        ldx event_current
        cpx event_next
        beq done_with_events
event_loop:
        lda events_type, x
check_unpressed_switch:
        cmp #SWITCH_UNPRESSED
        bne check_interactable

        ; For now, when pressing a switch, Data0 indicates whether this is a SET or an UNSET
        lda events_data1, x
        beq switch_unset
switch_set:
        jsr _set_event_and_apply_overlay
        jmp done_dispatching_event
switch_unset:
        jsr _unset_event_and_apply_overlay
        jmp done_dispatching_event

check_interactable:
        cmp #INTERACTABLE
        bne unrecognized_event
        
        lda events_data4, x
        sta TextPtr
        lda events_data5, x
        sta TextPtr+1
        st16 GameMode, dialog_init

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
        .setcpu "6502"

        .include "actions.inc"
        .include "far_call.inc"
        .include "input.inc"
        .include "kernel.inc"
        .include "level_logic.inc"
        .include "nes.inc"
        .include "overlays.inc"
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
TilePosX := R0
TilePosY := R1

        ; DEBUG STUFF
        lda #KEY_SELECT
        bit ButtonsHeld
        beq no_debug
        lda #KEY_START
        bit ButtonsDown
        beq no_debug   

        ; DEBUG KEY PRESSED! Do debug things here
        
        ; activate the dialog system!
        ; st16 GameMode, dialog_init

        ; queue up overlay 0, if this map has one!
        lda #0
        jsr apply_overlay
        
        ; Un-break the action button state, in case we have just switched modes
        lda #0
        sta action_flags
no_debug:

        rts
.endproc
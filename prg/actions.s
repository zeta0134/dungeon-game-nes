        .setcpu "6502"
        .include "actions.inc"
        .include "branch_util.inc"
        .include "far_call.inc"
        .include "input.inc"
        .include "nes.inc"
        .include "ppu.inc"
        .include "saves.inc"
        .include "sound.inc"
        .include "vram_buffer.inc"
        .include "word_util.inc"
        .include "zeropage.inc"

        .segment "RAM"
actions_down_low: .res 1
actions_down_high: .res 1
actions_held_low: .res 1
actions_held_high: .res 1
actions_up_low: .res 1
actions_up_high: .res 1

action_a_slot: .res 1
action_a_id: .res 1
action_a_low_mask: .res 1
action_a_high_mask: .res 1
action_b_slot: .res 1
action_b_id: .res 1
action_b_low_mask: .res 1
action_b_high_mask: .res 1
total_action_slots: .res 1

action_a_button_suppressed: .res 1

; used to manage state for action switching
action_flags: .res 1
desync_counter: .res 1

SWITCH_INITIATED      = %00000001
SWITCH_DESYNC_PRESSED = %00000010


        .segment "SUBSCREEN_A000"

ability_icons_tiles:
        .byte 0, 0, 0, 0
        .byte 128, 129, 130, 131
        .byte 132, 133, 134, 135
        .byte 136, 137, 138, 139
        .byte 140, 141, 142, 143
        .byte 144, 145, 146, 147
        .byte 148, 149, 150, 151

.proc FAR_initialize_actions
        lda #0
        sta action_flags
        sta desync_counter
        sta action_a_button_suppressed
        lda #3
        sta total_action_slots

        lda #0
        sta action_a_slot
        sta action_b_slot
        near_call FAR_update_action_masks
        rts
.endproc

; Meant to be used only during init. Only valid when called with the RegionId of an
; ability icon, as it will draw a 2x2 bit of tiles at that region's top-left corner.
.proc FAR_draw_ability_icon_immediate
AbilityIndex := R1
DestPpuAddr := R2
        set_ppuaddr DestPpuAddr

        ; Ability Index * 4 gives us the index into the tile LUT
        lda AbilityIndex
        asl
        asl
        tax
        ; First draw the upper row
        lda ability_icons_tiles, x
        sta PPUDATA
        lda ability_icons_tiles + 1, x
        sta PPUDATA
        ; Now move PPUADDR one row down...
        add16b DestPpuAddr, #32
        set_ppuaddr DestPpuAddr
        ; and draw the second row of tiles
        lda ability_icons_tiles + 2, x
        sta PPUDATA
        lda ability_icons_tiles + 3, x
        sta PPUDATA

        ; TODO: compute and set the attribute byte here

        rts
.endproc

; Safe to call nearly any time. Only valid when called with the RegionId of an
; ability icon, as it will draw a 2x2 bit of tiles at that region's top-left corner.
.proc FAR_draw_ability_icon_buffered
AbilityIndex := R1
DestPpuAddr := R2
        near_call FAR_draw_ability_icon_buffered_top_row   
        ; Now move PPUADDR one row down...
        add16b DestPpuAddr, #32
        near_call FAR_draw_ability_icon_buffered_bottom_row
        ; TODO: compute and set the attribute byte here
        rts
.endproc


.proc FAR_draw_ability_icon_buffered_top_row
AbilityIndex := R1
DestPpuAddr := R2
        write_vram_header_ptr DestPpuAddr, #2, VRAM_INC_1
        ldy VRAM_TABLE_INDEX

        ; Ability Index * 4 gives us the index into the tile LUT
        lda AbilityIndex
        asl
        asl
        tax
        ; First draw the upper row
        lda ability_icons_tiles, x
        sta VRAM_TABLE_START, y
        iny
        lda ability_icons_tiles + 1, x
        sta VRAM_TABLE_START, y
        iny

        sty VRAM_TABLE_INDEX
        inc VRAM_TABLE_ENTRIES
        rts
.endproc

.proc FAR_draw_ability_icon_buffered_bottom_row
AbilityIndex := R1
DestPpuAddr := R2
        write_vram_header_ptr DestPpuAddr, #2, VRAM_INC_1
        ldy VRAM_TABLE_INDEX

        ; (We need to do this again because writing the vram header clobbered X)
        lda AbilityIndex
        asl
        asl
        tax

        ; and draw the second row of tiles
        lda ability_icons_tiles + 2, x
        sta VRAM_TABLE_START, y
        iny
        lda ability_icons_tiles + 3, x
        sta VRAM_TABLE_START, y
        iny

        sty VRAM_TABLE_INDEX
        inc VRAM_TABLE_ENTRIES
        rts
.endproc

.proc FAR_update_action_masks
ScratchWord := R0
        lda action_a_slot
        asl
        tax
        lda working_save + SaveFile::ActionSetMemory + 1, x
        sta action_a_id

        lda action_b_slot
        asl
        tax
        lda working_save + SaveFile::ActionSetMemory + 0, x
        sta action_b_id

        st16 ScratchWord, $0000
        sec
        ldy action_a_id
        beq done_with_loop_a
loop_a: 
        rol ScratchWord
        rol ScratchWord+1
        dey
        bne loop_a
done_with_loop_a:
        lda ScratchWord
        sta action_a_low_mask
        lda ScratchWord+1
        sta action_a_high_mask

        st16 ScratchWord, $0000
        sec
        ldy action_b_id
        beq done_with_loop_b
loop_b: 
        rol ScratchWord
        rol ScratchWord+1
        dey
        bne loop_b
done_with_loop_b:
        lda ScratchWord
        sta action_b_low_mask
        lda ScratchWord+1
        sta action_b_high_mask
        rts
.endproc

.proc FAR_update_action_buttons
        near_call FAR_handle_action_switching

        lda #0
        sta actions_down_low
        sta actions_down_high
        sta actions_held_low
        sta actions_held_high
        sta actions_up_low
        sta actions_up_high

        ; If we are currently mid-switch, suppress all action behavior
        lda #SWITCH_INITIATED
        and action_flags
        jne done

        lda action_a_button_suppressed
        bne check_button_b_down

check_button_a_down:
        lda #KEY_A
        and ButtonsDown
        beq check_button_a_held

        lda action_a_low_mask
        sta actions_down_low
        lda action_a_high_mask
        sta actions_down_high

check_button_a_held:
        lda #KEY_A
        and ButtonsHeld
        beq check_button_a_up

        lda action_a_low_mask
        sta actions_held_low
        lda action_a_high_mask
        sta actions_held_high

check_button_a_up:
        lda #KEY_A
        and ButtonsUp
        beq check_button_b_down

        lda action_a_low_mask
        sta actions_up_low
        lda action_a_high_mask
        sta actions_up_high

check_button_b_down:
        lda #KEY_B
        and ButtonsDown
        beq check_button_b_held

        lda action_b_low_mask
        ora actions_down_low
        sta actions_down_low
        lda action_b_high_mask
        ora actions_down_high
        sta actions_down_high

check_button_b_held:
        lda #KEY_B
        and ButtonsHeld
        beq check_button_b_up

        lda action_b_low_mask
        ora actions_held_low
        sta actions_held_low
        lda action_b_high_mask
        ora actions_held_high
        sta actions_held_high

check_button_b_up:
        lda #KEY_B
        and ButtonsUp
        beq done

        lda action_b_low_mask
        ora actions_up_low
        sta actions_up_low
        lda action_b_high_mask
        ora actions_up_high
        sta actions_up_high

done:
        rts
.endproc

.proc FAR_handle_action_switching
        ; First: if we just pressed select, then initiate a switch. This suppresses all activity
        ; for the other actions
        lda #KEY_SELECT
        bit ButtonsDown
        beq select_not_down

        ; sanity check: if ANY action button is currently pressed, do not initiate a switch
        lda #(KEY_A | KEY_B)
        bit ButtonsHeld
        jne done_with_switch

        lda #SWITCH_INITIATED
        sta action_flags

select_not_down:
        
        ; If select is held, then check both A and B for a desync
        lda #KEY_SELECT
        bit ButtonsHeld
        beq done_with_desyncs

check_a:
        lda #KEY_A
        bit ButtonsDown
        beq check_b

        jsr advance_a_action

        ; TODO: have a specific SFX for advancing a single action?
        st16 R0, sfx_equip_ability_pulse1
        jsr play_sfx_pulse1
        st16 R0, sfx_equip_ability_pulse2
        jsr play_sfx_pulse2

check_b:
        lda #KEY_B
        bit ButtonsDown
        beq done_with_desyncs

        jsr advance_b_action

        ; TODO: have a specific SFX for advancing a single action?
        st16 R0, sfx_equip_ability_pulse1
        jsr play_sfx_pulse1
        st16 R0, sfx_equip_ability_pulse2
        jsr play_sfx_pulse2

done_with_desyncs:
        ; If select is released...
        lda #KEY_SELECT
        bit ButtonsUp
        beq done_with_switch

        ; Sanity check: were we actually in the middle of a switch?
        ; We might not be, if it was canceled or we somehow got into a play state
        ; with select already held; in this case, do nothing.
        lda #SWITCH_INITIATED
        bit action_flags
        beq done_with_switch

        ; If we did a desync during this session, then take no additional action
        lda #SWITCH_DESYNC_PRESSED
        bit action_flags
        bne clear_switch_flags

        ; Otherwise, we process this like a SELECT press then release.
        ; If we are NOT currently desynced...
        lda desync_counter
        bne resync_action_sets
        ; Then we merely advance both A and B to the next action set
        jsr advance_a_action
        jsr advance_b_action

        ; TODO: have a specific SFX for advancing both sets at once?
        st16 R0, sfx_equip_ability_pulse1
        jsr play_sfx_pulse1
        st16 R0, sfx_equip_ability_pulse2
        jsr play_sfx_pulse2

        jmp clear_switch_flags
resync_action_sets:
        ; Otherwise we now need to *fix* the desync. Whichever side is ahead, the other side
        ; will have its slot set to match

        ; TODO: have a specific SFX for re-syncing sets?
        st16 R0, sfx_equip_ability_pulse1
        jsr play_sfx_pulse1
        st16 R0, sfx_equip_ability_pulse2
        jsr play_sfx_pulse2

        lda desync_counter
        bmi b_is_ahead
a_is_ahead:
        lda action_a_slot
        sta action_b_slot
        near_call FAR_update_action_masks
        lda #0
        sta desync_counter
        jmp clear_switch_flags
b_is_ahead:
        lda action_b_slot
        sta action_a_slot
        lda #0
        sta desync_counter
        near_call FAR_update_action_masks
        ; fall through
clear_switch_flags:
        lda #0
        sta action_flags

done_with_switch:
        rts
.endproc

.proc advance_a_action
        ; advance the action slot and the desync counter
        inc action_a_slot
        inc desync_counter
        ; correct overflow if necessary
        lda action_a_slot
        cmp total_action_slots
        bne no_a_overflow
        lda #0
        sta action_a_slot
no_a_overflow:
        ; make note that a desync occured
        lda #SWITCH_DESYNC_PRESSED
        ora action_flags
        sta action_flags
        ; update action icon details
        near_call FAR_update_action_masks
        rts
.endproc

.proc advance_b_action
        ; advance the action slot and the desync counter
        inc action_b_slot
        dec desync_counter
        ; correct overflow if necessary
        lda action_b_slot
        cmp total_action_slots
        bne no_b_overflow
        lda #0
        sta action_b_slot
no_b_overflow:
        ; make note that a desync occured
        lda #SWITCH_DESYNC_PRESSED
        ora action_flags
        sta action_flags
        ; update action icon details
        near_call FAR_update_action_masks
        rts
.endproc
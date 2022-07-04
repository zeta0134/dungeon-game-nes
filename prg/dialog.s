        .setcpu "6502"
        .include "dialog.inc"
        .include "input.inc"
        .include "kernel.inc"
        .include "nes.inc"
        .include "vram_buffer.inc"
        .include "word_util.inc"
        .include "zeropage.inc"

        .zeropage
DialogMode: .res 2
TextPtr: .res 2
        .segment "RAM"
CurrentPpuAddr: .res 2
StateCounter: .res 1 
CurrentLine: .res 1
        .segment "PRGFIXED_E000"

; commands
D_LF =    $80
D_WAIT =  $81
D_EXIT =  $82
D_CLEAR = $83

; useful defines
BORDER_PPU =      $2380
FIRST_LINE_PPU =  $23A0
SECOND_LINE_PPU = $2780
THIRD_LINE_PPU =  $27A0

DIALOG_LEFT_MARGIN = 9
DIALOG_RIGHT_MARGIN = 3
DIALOG_MAX_LINE_LENGTH = (32 - DIALOG_RIGHT_MARGIN - DIALOG_LEFT_MARGIN)

test_message:
        ;    |01234567890123456789|
        ;    |     safe width     |
        ;    |--------------------|
        .byte "Hello world!"
        .byte D_WAIT, D_CLEAR
        .byte "Several screens!"
        .byte D_WAIT, D_CLEAR
        .byte "Several lines of", D_LF
        .byte "text, separated by", D_LF
        .byte "line breaks."
        .byte D_WAIT, D_EXIT


; === External Functions ===

.proc init_dialog_engine
        st16 DialogMode, dialog_state_init
        ; debug: manually set a dialog message for testing
        ; later we should not do this, and allow the calling code to set the pointer instead
        st16 TextPtr, test_message
        rts
.endproc

.proc update_dialog_engine
        inc StateCounter
        jmp (DialogMode)
.endproc

; === High level Dialog State functions ===

.proc dialog_state_init
        ; clear the dialog window, and initialize the text to the first line, all in one fell swoop
        jsr clear_text_command
        ; we *should* do a bunch of other stuff here, but we're still bootstrapping.
        ; For now, merely transition into text commands
        st16 DialogMode, dialog_state_process_commands
        rts
.endproc

.proc dialog_state_wait_for_user_input
        lda #KEY_A
        bit ButtonsDown
        beq still_waiting

        ; Todo: maybe display / animate the chevron here?

        st16 DialogMode, dialog_state_process_commands

still_waiting:
        rts
.endproc

.proc dialog_state_process_commands
        ; TODO: this is where text speed should be handled.
        ; In skip mode, we might wish to process several commands at once, though
        ; we'll need to guard that against state changes
        jsr process_one_command
        rts
.endproc

.proc dialog_state_inactive
        ; do absolutely nothing! we use this when closing the window, for safety
        rts
.endproc

; === Command Processing ===

.proc process_one_command
CommandPtr := R0
        ldy #0
        lda (TextPtr), y
        bmi extended_command
        inc16 TextPtr
        jsr draw_one_character
        rts
extended_command:
        inc16 TextPtr
        asl ; kill high bit, and also format for LUT usage
        tax
        lda commands_table, x
        sta CommandPtr
        lda commands_table+1, x
        sta CommandPtr+1
        jmp (CommandPtr) ; will rts
.endproc

commands_table:
        .word line_feed_command
        .word wait_command
        .word exit_command
        .word clear_text_command

.proc draw_one_character
        ; A still contains the character to draw, but it's in ASCII, and we need to
        ; subtract 32 here to get it lined up with our tile indices
        sec
        sbc #32
        pha ; preserve that result

        write_vram_header_ptr CurrentPpuAddr, #1, VRAM_INC_1
        ldx VRAM_TABLE_INDEX
        pla ; restore the character tile to draw
        sta VRAM_TABLE_START, x
        inc VRAM_TABLE_INDEX 
        inc VRAM_TABLE_ENTRIES

        inc16 CurrentPpuAddr

        ; That should be it. We don't check for or handle running off the edge
        ; of the dialog window, right now that is assumed to not be a property
        ; of the message data.
        ; (Later we might want to care slightly)

        rts
.endproc

.proc line_feed_command
check_first_line:
        lda CurrentLine
        cmp #0
        bne check_second_line
        st16 CurrentPpuAddr, (SECOND_LINE_PPU + DIALOG_LEFT_MARGIN)
        inc CurrentLine
        rts
check_second_line:
        lda CurrentLine
        cmp #1
        bne handle_last_line
        st16 CurrentPpuAddr, (THIRD_LINE_PPU + DIALOG_LEFT_MARGIN)
        inc CurrentLine
        rts
handle_last_line:
        ; uhh... clear the screen, sure?
        jsr clear_text_command
        ; TODO: we *could* implement a fancy "scroll the text up by one line"
        ; behavior here, but doing so requires us to buffer drawn text in RAM
        ; somewhere, so we can re-draw it on the upper rows. For now let's not
        ; do anything that crazy.
        rts
.endproc

.proc wait_command
        st16 DialogMode, dialog_state_wait_for_user_input
        rts
.endproc

.proc exit_command
        st16 DialogMode, dialog_state_inactive
        st16 GameMode, dialog_closing
        rts
.endproc

.proc clear_text_command
        ; queue up a VRAM transfer to fill the first line with space characters (tile 0)
        write_vram_header_imm (FIRST_LINE_PPU + DIALOG_LEFT_MARGIN), #DIALOG_MAX_LINE_LENGTH, VRAM_INC_1
        ldy #DIALOG_MAX_LINE_LENGTH
first_line_loop:
        ldx VRAM_TABLE_INDEX
        lda #0
        sta VRAM_TABLE_START, x
        inc VRAM_TABLE_INDEX
        dey
        bne first_line_loop
        inc VRAM_TABLE_ENTRIES

        ; queue up a VRAM transfer to fill the second line with space characters (tile 0)
        write_vram_header_imm (SECOND_LINE_PPU + DIALOG_LEFT_MARGIN), #DIALOG_MAX_LINE_LENGTH, VRAM_INC_1
        ldy #DIALOG_MAX_LINE_LENGTH
second_line_loop:
        ldx VRAM_TABLE_INDEX
        lda #0
        sta VRAM_TABLE_START, x
        inc VRAM_TABLE_INDEX
        dey
        bne second_line_loop
        inc VRAM_TABLE_ENTRIES

        ; queue up a VRAM transfer to fill the first line with space characters (tile 0)
        write_vram_header_imm (THIRD_LINE_PPU + DIALOG_LEFT_MARGIN), #DIALOG_MAX_LINE_LENGTH, VRAM_INC_1
        ldy #DIALOG_MAX_LINE_LENGTH
third_line_loop:
        ldx VRAM_TABLE_INDEX
        lda #0
        sta VRAM_TABLE_START, x
        inc VRAM_TABLE_INDEX
        dey
        bne third_line_loop
        inc VRAM_TABLE_ENTRIES

        ; finally, reset the text pointer to the start of the first line
        st16 CurrentPpuAddr, (FIRST_LINE_PPU + DIALOG_LEFT_MARGIN)
        lda #0
        sta CurrentLine
        rts
.endproc


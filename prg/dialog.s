        .setcpu "6502"
        .include "dialog.inc"
        .include "input.inc"
        .include "irq_table.inc"
        .include "kernel.inc"
        .include "nes.inc"
        .include "prng.inc"
        .include "statusbar.inc"
        .include "sound.inc"
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
CurrentTimbre: .res 1
        .segment "PRGFIXED_E000"

; commands
D_LF =    $80
D_WAIT =  $81
D_EXIT =  $82
D_CLEAR = $83
D_PORTRAIT = $84
D_TIMBRE = $85

; useful defines
BORDER_PPU =      $2380
FIRST_LINE_PPU =  $23A0
SECOND_LINE_PPU = $2780
THIRD_LINE_PPU =  $27A0

DIALOG_LEFT_MARGIN = 9
DIALOG_RIGHT_MARGIN = 1
DIALOG_MAX_LINE_LENGTH = (32 - DIALOG_RIGHT_MARGIN - DIALOG_LEFT_MARGIN)

DIALOG_PORTRAIT_X = 2
DIALOG_PORTRAIT_WIDTH_TILES = 6

test_message:
        ;     |0123456789012345678901|
        ;     |     safe width       |
        ;     |----------------------|
        .byte D_PORTRAIT, 16, 0
        .byte D_TIMBRE, $1
        .byte "Hello world!"
        .byte D_WAIT, D_CLEAR
        .byte "Several screens!"
        .byte D_WAIT, D_CLEAR
        .byte "Several lines of", D_LF
        .byte "text, separated by", D_LF
        .byte "line breaks."
        .byte D_WAIT, D_EXIT

lorem_ipsum:
        .byte D_PORTRAIT, 16, 0
        .byte D_TIMBRE, $0
        ;     |----------------------|
        .byte "Lorem ipsum dolor sit", D_LF
        .byte "amet, consectetur", D_LF
        .byte "adipiscing elit, sed"
        .byte D_WAIT, D_CLEAR
        ;     |----------------------|
        .byte "do eiusmod tempor", D_LF
        .byte "incididunt ut labore", D_LF
        .byte "et dolore magna"
        .byte D_WAIT, D_CLEAR
        ;     |----------------------|
        .byte "aliqua."
        .byte D_WAIT, D_CLEAR

        .byte D_PORTRAIT, 16, 18
        .byte D_TIMBRE, $1
        ;     |----------------------|
        .byte "Ut enim ad minim", D_LF
        .byte "veniam, quis nostrud", D_LF
        .byte "exercitation ullamco"
        .byte D_WAIT, D_CLEAR
        ;     |----------------------|
        .byte "laboris nisi ut", D_LF
        .byte "aliquip ex ea commodo", D_LF
        .byte "consequat."
        .byte D_WAIT, D_EXIT

; === External Functions ===

.proc init_dialog_engine
        st16 DialogMode, dialog_state_init
        ; debug: manually set a dialog message for testing
        ; later we should not do this, and allow the calling code to set the pointer instead
        st16 TextPtr, lorem_ipsum
        ; debug: manually set up a dialog portrait's bank numbers
        ; later, this should be part of a command, I think, or maybe part
        ; of the message header or something
        lda #16
        sta EvenChr1Bank
        lda #18
        sta OddChr1Bank

        lda #4
        sta CurrentTimbre
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
        jsr write_active_hud_palette
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
        .word dialog_portrait_command
        .word timbre_command

.proc draw_one_character
CharacterIndex := R0
        ; A still contains the character to draw
        sta CharacterIndex
        ; it's in ASCII, and we need to
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

        jsr play_chirp

        ; That should be it. We don't check for or handle running off the edge
        ; of the dialog window, right now that is assumed to not be a property
        ; of the message data.
        ; (Later we might want to care slightly)

        rts
.endproc

.proc play_chirp
CharacterIndex := R0
        lda CharacterIndex
check_a:
        ; if that was one of our vowel sounds, play an appropriate chirp sfx
        cmp #'a'
        bne check_A
        jmp chirp_ae
check_A:
        cmp #'A'
        bne check_e
        jmp chirp_ae
check_e:
        cmp #'e'
        bne check_E
        jmp chirp_ae
check_E:
        cmp #'E'
        bne check_i
        jmp chirp_ae
check_i:
        cmp #'i'
        bne check_I
        jmp chirp_iy
check_I:
        cmp #'i'
        bne check_o
        jmp chirp_iy
check_o:
        cmp #'o'
        bne check_O
        jmp chirp_ou
check_O:
        cmp #'O'
        bne check_u
        jmp chirp_ou
check_u:
        cmp #'u'
        bne check_U
        jmp chirp_ou
check_U:
        cmp #'U'
        bne check_y
        jmp chirp_ou
check_y:
        cmp #'y'
        bne check_Y
        jmp chirp_iy
check_Y:
        cmp #'y'
        bne no_chirp
        jmp chirp_iy

no_chirp:
        rts
.endproc

chirp_lut_ae:
        .word sfx_dialog_ae_low_variant_1
        .word sfx_dialog_ae_low_variant_2
        .word sfx_dialog_ae_low_variant_3
        .word sfx_dialog_ae_low_variant_4
        .word sfx_dialog_ae_mid_variant_1
        .word sfx_dialog_ae_mid_variant_2
        .word sfx_dialog_ae_mid_variant_3
        .word sfx_dialog_ae_mid_variant_4
chirp_lut_iy:
        .word sfx_dialog_iy_low_variant_1
        .word sfx_dialog_iy_low_variant_2
        .word sfx_dialog_iy_low_variant_3
        .word sfx_dialog_iy_low_variant_4
        .word sfx_dialog_iy_mid_variant_1
        .word sfx_dialog_iy_mid_variant_2
        .word sfx_dialog_iy_mid_variant_3
        .word sfx_dialog_iy_mid_variant_4
chirp_lut_ou:
        .word sfx_dialog_ou_low_variant_1
        .word sfx_dialog_ou_low_variant_2
        .word sfx_dialog_ou_low_variant_3
        .word sfx_dialog_ou_low_variant_4
        .word sfx_dialog_ou_mid_variant_1
        .word sfx_dialog_ou_mid_variant_2
        .word sfx_dialog_ou_mid_variant_3
        .word sfx_dialog_ou_mid_variant_4

.proc chirp_ae
SfxPtr := R0
        jsr next_rand
        and #%00000011
        asl
        clc
        adc CurrentTimbre
        tax
        lda chirp_lut_ae, x
        sta SfxPtr
        lda chirp_lut_ae+1, x
        sta SfxPtr+1
        jsr play_sfx_pulse2
        rts
.endproc

.proc chirp_iy
SfxPtr := R0
        jsr next_rand
        and #%00000011
        asl
        clc
        adc CurrentTimbre
        tax
        lda chirp_lut_iy, x
        sta SfxPtr
        lda chirp_lut_iy+1, x
        sta SfxPtr+1
        jsr play_sfx_pulse2
        rts
.endproc

.proc chirp_ou
SfxPtr := R0
        jsr next_rand
        and #%00000011
        asl
        clc
        adc CurrentTimbre
        tax
        lda chirp_lut_ou, x
        sta SfxPtr
        lda chirp_lut_ou+1, x
        sta SfxPtr+1
        jsr play_sfx_pulse2
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

.proc dialog_portrait_command
DialogBank := R0
DialogTileIndex := R1
        ; read the dialog portrait parameter
        ; note: y is still zero out of process_command
        lda (TextPtr), y
        sta DialogBank
        inc16 TextPtr
        lda (TextPtr), y
        sta DialogTileIndex
        inc16 TextPtr

        ; set up the banks to display this portrait
        lda DialogBank
        sta EvenChr1Bank
        clc
        adc #2
        sta OddChr1Bank

        ; queue up the portrait graphics, starting with our
        ; index in the bank. First add 128 to it, because the
        ; graphics will end up in CHR1
        clc
        lda #128
        adc DialogTileIndex
        sta DialogTileIndex

        ; Now spit out a vram buffer update for each row of the portrait graphics
        write_vram_header_imm (FIRST_LINE_PPU + DIALOG_PORTRAIT_X), #DIALOG_PORTRAIT_WIDTH_TILES, VRAM_INC_1
        ldy #0
first_line_loop:
        ldx VRAM_TABLE_INDEX
        tya
        clc
        adc DialogTileIndex
        sta VRAM_TABLE_START, x
        inc VRAM_TABLE_INDEX
        iny
        cpy #(DIALOG_PORTRAIT_WIDTH_TILES * 1)
        bne first_line_loop
        inc VRAM_TABLE_ENTRIES

        write_vram_header_imm (SECOND_LINE_PPU + DIALOG_PORTRAIT_X), #DIALOG_PORTRAIT_WIDTH_TILES, VRAM_INC_1
second_line_loop:
        ldx VRAM_TABLE_INDEX
        tya
        clc
        adc DialogTileIndex
        sta VRAM_TABLE_START, x
        inc VRAM_TABLE_INDEX
        iny
        cpy #(DIALOG_PORTRAIT_WIDTH_TILES * 2)
        bne second_line_loop
        inc VRAM_TABLE_ENTRIES

        write_vram_header_imm (THIRD_LINE_PPU + DIALOG_PORTRAIT_X), #DIALOG_PORTRAIT_WIDTH_TILES, VRAM_INC_1
third_line_loop:
        ldx VRAM_TABLE_INDEX
        tya
        clc
        adc DialogTileIndex
        sta VRAM_TABLE_START, x
        inc VRAM_TABLE_INDEX
        iny
        cpy #(DIALOG_PORTRAIT_WIDTH_TILES * 3)
        bne third_line_loop
        inc VRAM_TABLE_ENTRIES

        rts
.endproc

.proc timbre_command
TimbreParam := R0
        lda (TextPtr), y
        sta TimbreParam
        inc16 TextPtr

        lda TimbreParam
        asl
        asl
        asl
        sta CurrentTimbre
        
        rts
.endproc
        .setcpu "6502"
        ; for player variables and whatnot
        .include "actions.inc"
        .include "branch_util.inc"
        .include "boxgirl.inc"
        .include "far_call.inc"
        .include "statusbar.inc"
        .include "nes.inc"
        .include "palette.inc"
        .include "ppu.inc"
        .include "tilebuffer.inc"
        .include "word_util.inc"
        .include "vram_buffer.inc"
        .include "zeropage.inc"

        .zeropage
HudState: .res 2

        .segment "RAM"

HealthDisplayed: .res 1
HealthCooldown: .res 1
HudStateCounter: .res 1
ActionDisplayedLeft: .res 1
ActionDisplayedRight: .res 1

        .segment "UTILITIES_A000"

hud_base_pal:
        .incbin "../art/palettes/hud_base.pal"

BLANK = $00
FILL = $00
BORDER_ML = $73
BORDER_BL = $70
BORDER_BM = $72
BORDER_MR = $63
BORDER_BR = $71
BORDER_TL = $60
BORDER_TM = $62
BORDER_TR = $61

HEART_FULL = $64
HEART_HALF = $65

HEALTH_DISP_BASE = $23A4
HEALTH_UPDATE_COOLDOWN = 2

basic_hud:
        .incbin "../art/raw_chr/basic_hud.map"

; === External Functions ===

.proc FAR_init_statusbar
        st16 HudState, hud_state_initial
        rts
.endproc

.proc FAR_update_statusbar
        inc HudStateCounter
        jmp (HudState)
        rts
.endproc

; === Various States for HUD updates ===

.proc hud_state_initial
        near_call FAR_write_blank_hud_palette
        st16 HudState, hud_cold_draw
        lda #0
        sta HudStateCounter
        sta ActionDisplayedLeft
        sta ActionDisplayedRight
        rts
.endproc

.proc hud_cold_draw
        ; TODO: we really need to break this up into several states, so we aren't
        ; trying to draw the *entire* HUD in a single frame. That's not just lag frame
        ; dangerous, that's "might smash the stack" dangerous
        lda #0
        sta tile_budget
top_border:
        lda HudStateCounter
        cmp #1
        bne first_side_border

        write_vram_header_imm $2380, #32, VRAM_INC_1
        ldx VRAM_TABLE_INDEX
        ldy #0
top_border_loop:
        lda basic_hud + 0, y
        sta VRAM_TABLE_START, x
        inx
        iny
        cpy #32
        bne top_border_loop
        stx VRAM_TABLE_INDEX
        inc VRAM_TABLE_ENTRIES

        rts
first_side_border:
        lda HudStateCounter
        cmp #2
        bne second_side_border

        write_vram_header_imm $23A0, #32, VRAM_INC_1
        ldx VRAM_TABLE_INDEX
        ldy #0
first_side_border_loop:
        lda basic_hud + 32, y
        sta VRAM_TABLE_START, x
        inx
        iny
        cpy #32
        bne first_side_border_loop
        stx VRAM_TABLE_INDEX
        inc VRAM_TABLE_ENTRIES

        ; here, initialize the hearts display in the vram buffer we just wrote into
        lda VRAM_TABLE_INDEX
        sec
        sbc #(32  - 4)
        tax
        ldy #0
health_update_loop:
        cpy PlayerHealth
        bcs empty_heart
        iny
        cpy PlayerHealth
        beq half_heart
full_heart:
        lda #HEART_FULL
        sta VRAM_TABLE_START, x
        iny
        jmp health_converge
half_heart:
        lda #HEART_HALF
        sta VRAM_TABLE_START, x
        iny
        jmp health_converge
empty_heart:
        iny
        iny
health_converge:
        inx
        cpy #20
        bne health_update_loop

        lda PlayerHealth
        sta HealthDisplayed
        
        rts
second_side_border:
        lda HudStateCounter
        cmp #3
        bne bottom_border

        write_vram_header_imm $2780, #32, VRAM_INC_1
        ldx VRAM_TABLE_INDEX
        ldy #0
second_side_border_loop:
        lda basic_hud + 64, y
        sta VRAM_TABLE_START, x
        inx
        iny
        cpy #32
        bne second_side_border_loop
        stx VRAM_TABLE_INDEX
        inc VRAM_TABLE_ENTRIES

        rts
bottom_border:
        lda HudStateCounter
        cmp #4
        bne attributes

        write_vram_header_imm $27A0, #32, VRAM_INC_1
        ldx VRAM_TABLE_INDEX
        ldy #0
bottom_border_loop:
        lda basic_hud + 96, y
        sta VRAM_TABLE_START, x
        inx
        iny
        cpy #32
        bne bottom_border_loop
        stx VRAM_TABLE_INDEX
        inc VRAM_TABLE_ENTRIES

        rts
attributes:
        write_vram_header_imm $23F8, #8, VRAM_INC_1
        ldx VRAM_TABLE_INDEX
        ldy #8
attribute_loop_1:
        lda #$FF
        sta VRAM_TABLE_START, x
        inx
        dey
        bne attribute_loop_1
        stx VRAM_TABLE_INDEX
        inc VRAM_TABLE_ENTRIES

        write_vram_header_imm $27F8, #8, VRAM_INC_1
        ldx VRAM_TABLE_INDEX
        ldy #8
attribute_loop_2:
        lda #$FF
        sta VRAM_TABLE_START, x
        inx
        dey
        bne attribute_loop_2
        stx VRAM_TABLE_INDEX
        inc VRAM_TABLE_ENTRIES

        near_call FAR_write_active_hud_palette
        st16 HudState, hud_active

        rts
.endproc

; TODO: We may wish to limit this functions VRAM buffer queues when there is a lot
; going on. Consider giving health higher priority, since it has a cooldown, and also
; consider only queueing up a single ability icon change at a time.
.proc hud_active
TileAddr := R0
        ; First check to see if we need to update the heart indicator. We use a cooldown
        ; here to subtly animate big health changes, and this also ensures that health
        ; updates will never exceed 1 byte
        lda HealthCooldown
        beq check_health
        dec HealthCooldown
        jmp done_with_health_change
check_health:
        lda PlayerHealth
        cmp HealthDisplayed
        jeq done_with_health_change
        bcs health_increase
health_decrease:
        dec tile_budget
        dec HealthDisplayed
        lda HealthDisplayed
        lsr
        clc
        adc #<HEALTH_DISP_BASE
        sta TileAddr
        lda #>HEALTH_DISP_BASE
        sta TileAddr+1
        write_vram_header_ptr TileAddr, #1, VRAM_INC_1
        lda HealthDisplayed
        and #%00000001
        eor #%00000001
        beq decrease_half_heart
decrease_empty_heart:
        lda #BLANK
        jmp write_heart_decrease
decrease_half_heart:
        lda #HEART_HALF
write_heart_decrease:
        ldx VRAM_TABLE_INDEX
        sta VRAM_TABLE_START,x
        inc VRAM_TABLE_INDEX
        inc VRAM_TABLE_ENTRIES
        lda #HEALTH_UPDATE_COOLDOWN
        sta HealthCooldown
        jmp done_with_health_change
health_increase:
        dec tile_budget
        lda HealthDisplayed
        lsr
        clc
        adc #<HEALTH_DISP_BASE
        sta TileAddr
        lda #>HEALTH_DISP_BASE
        sta TileAddr+1
        write_vram_header_ptr TileAddr, #1, VRAM_INC_1
        inc HealthDisplayed
        lda HealthDisplayed
        and #%00000001
        beq increase_full_heart
increase_half_heart:
        lda #HEART_HALF
        jmp write_heart_increase
increase_full_heart:
        lda #HEART_FULL
write_heart_increase:
        ldx VRAM_TABLE_INDEX
        sta VRAM_TABLE_START,x
        inc VRAM_TABLE_INDEX
        inc VRAM_TABLE_ENTRIES
        lda #HEALTH_UPDATE_COOLDOWN
        sta HealthCooldown
        ; fall through
done_with_health_change:
        ; check to see if any of our abilities need to be redrawn
check_left_action:
        lda action_b_id
        cmp ActionDisplayedLeft
        beq check_right_action

        dec tile_budget

        sta ActionDisplayedLeft
        sta R1 ; ability index
        st16 R2, $23B7 ; DestPpuAddr
        far_call FAR_draw_ability_icon_buffered_top_row
        st16 R2, $2797 ; DestPpuAddr
        far_call FAR_draw_ability_icon_buffered_bottom_row
        ; TODO: jump away?
        ; for now, fall through
check_right_action:
        lda action_a_button_suppressed
        beq normal_right_action
        lda #ACTION_INTERACTABLE
        jmp right_action_converge
normal_right_action:
        lda action_a_id
right_action_converge:
        cmp ActionDisplayedRight
        beq done_with_actions

        dec tile_budget

        sta ActionDisplayedRight
        sta R1 ; ability index
        st16 R2, $23BB ; DestPpuAddr
        far_call FAR_draw_ability_icon_buffered_top_row
        st16 R2, $279B ; DestPpuAddr
        far_call FAR_draw_ability_icon_buffered_bottom_row
done_with_actions:
        rts
.endproc

; === Utility Functions ===

.proc FAR_write_blank_hud_palette
        lda #$0F ; black
        sta HudPaletteBuffer + 0
        ldx #0
loop:
        ; skip
        inx
        sta HudPaletteBuffer, x
        inx
        sta HudPaletteBuffer, x
        inx
        sta HudPaletteBuffer, x
        inx
        cpx #16
        bne loop
        rts
.endproc

.proc FAR_write_active_hud_palette
        ; for now, this is a static (and quite ugly) palette for testing
        ; The global background is always black
        lda #$0F
        sta HudPaletteBuffer + 0
        
        lda hud_base_pal+1
        sta HudPaletteBuffer + 1
        lda hud_base_pal+2
        sta HudPaletteBuffer + 2
        lda hud_base_pal+3
        sta HudPaletteBuffer + 3

        lda hud_base_pal+5
        sta HudPaletteBuffer + 5
        lda hud_base_pal+6
        sta HudPaletteBuffer + 6
        lda hud_base_pal+7
        sta HudPaletteBuffer + 7

        lda hud_base_pal+9
        sta HudPaletteBuffer + 9
        lda hud_base_pal+10
        sta HudPaletteBuffer + 10
        lda hud_base_pal+11
        sta HudPaletteBuffer + 11

        lda hud_base_pal+13
        sta HudPaletteBuffer + 13
        lda hud_base_pal+14
        sta HudPaletteBuffer + 14
        lda hud_base_pal+15
        sta HudPaletteBuffer + 15
        rts
.endproc


.proc init_statusbar_old
        ; top row
        lda #(OBJ_0000 | BG_1000)
        sta PPUCTRL
        set_ppuaddr #$2380
        ldx #0
top_row_loop:
        lda basic_hud, x
        sta PPUDATA
        inx
        cpx #64
        bne top_row_loop
        set_ppuaddr #$2780
bottom_row_loop:
        lda basic_hud, x
        sta PPUDATA
        inx
        cpx #128
        bne bottom_row_loop
        ; finally, set the attribute for this whole status region to palette 3
        set_ppuaddr #$23F8
        lda #$FF
        .repeat 8
        sta PPUDATA
        .endrepeat

        set_ppuaddr #$27F8
        lda #$FF
        .repeat 8
        sta PPUDATA
        .endrepeat

        ; initialize variables to track the HUD's current state
        ; right now that's just health
        lda #0
        sta HealthDisplayed
        sta HealthCooldown

        ; done with basic setup
        rts
.endproc

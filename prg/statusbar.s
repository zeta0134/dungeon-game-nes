        .setcpu "6502"
        ; for player variables and whatnot
        .include "branch_util.inc"
        .include "boxgirl.inc"
        .include "statusbar.inc"
        .include "nes.inc"
        .include "ppu.inc"
        .include "vram_buffer.inc"
        .include "zeropage.inc"

        .segment "RAM"

HealthDisplayed: .res 1
HealthCooldown: .res 1

        .segment "PRGFIXED_E000"


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

basic_hud:
        .incbin "../art/raw_chr/basic_hud.map"

.proc init_statusbar
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

HEALTH_DISP_BASE = $23A4
HEALTH_UPDATE_COOLDOWN = 2

.proc update_statusbar
TileAddr := R0
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
        rts
.endproc

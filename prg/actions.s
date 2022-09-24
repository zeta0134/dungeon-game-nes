        .setcpu "6502"
        .include "actions.inc"
        .include "far_call.inc"
        .include "nes.inc"
        .include "ppu.inc"
        .include "vram_buffer.inc"
        .include "word_util.inc"
        .include "zeropage.inc"

        .segment "RAM"
; Ability memory, TODO: move this somewhere more shared
action_memory:
actionset_a: .res 2
actionset_b: .res 2
actionset_c: .res 2
action_inventory: .res 12

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
        ; TODO: Once we know the player's starting inventory set, we should
        ; initialize that here. For now, this contains the DEBUG set, for
        ; rapid testing of game mechanics.
        lda #2
        sta actionset_a + 0
        lda #1
        sta actionset_a + 1
        lda #0
        sta actionset_b + 0
        sta actionset_b + 1
        sta actionset_c + 0
        sta actionset_c + 1

        lda #3
        sta action_inventory + 0
        lda #4
        sta action_inventory + 1
        lda #5
        sta action_inventory + 2
        lda #0
        .repeat 9, i
        sta action_inventory + 6 + i
        .endrepeat
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
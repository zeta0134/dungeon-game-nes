        .setcpu "6502"
        .include "input.inc"
        .include "kernel.inc"
        .include "nes.inc"
        .include "palette.inc"
        .include "ppu.inc"
        .include "subscreen.inc"
        .include "word_util.inc"
        .include "vram_buffer.inc"
        .include "zeropage.inc"

        .zeropage
SubScreenState: .res 2

        .segment "RAM"
FadeCounter: .res 1

        .segment "SUBSCREEN_A000"

subscreen_base_nametable:
        .incbin "art/raw_nametables/subscreen_base.nam"
subscreen_palette:
        .incbin "art/palettes/subscreen.pal"

; === External Functions ===

.proc FAR_init_subscreen
        st16 SubScreenState, subscreen_state_initial
        rts
.endproc

.proc FAR_update_subscreen
        jmp (SubScreenState)
        rts
.endproc

.proc subscreen_state_initial
NametableAddr := R0
NametableLength := R2
        ; Note: upon entering this function, the BG palette set has been faded out to black.

        ; we are about to fully initialize the nametable, so disable all interrupts and rendering,
        ; but not NMI, similar to a map load
        sei

         ; disable rendering
        lda #$00
        sta PPUMASK

        ; soft-disable NMI (sound engine updates only)
        lda #1
        sta NmiSoftDisable
        ; Reset PPUCTRL, but leave NMI enabled
        lda #(VBLANK_NMI)
        sta PPUCTRL

        ; Copy in the base nametable
        set_ppuaddr #$2000
        st16 NametableAddr, subscreen_base_nametable
        st16 NametableLength, $400
        ldx #0
        ldy #0
loop:
        lda (NametableAddr), y
        sta PPUDATA
        inc16 NametableAddr
        dec16 NametableLength
        lda NametableLength
        ora NametableLength+1
        bne loop

        ; TODO: other setup!

        ; Now, fully re-enable rendering

        ; reset PPUADDR to top-left
        set_ppuaddr #$2000

        lda #$00
        sta GameloopCounter
        sta LastNmi

        ; re-enable graphics
        lda #$1E
        sta PPUMASK
        lda #(VBLANK_NMI | BG_0000 | OBJ_1000 | OBJ_8X16)
        sta PPUCTRL

        ; un-soft-disable NMI
        lda #0
        sta NmiSoftDisable

        ; immediately wait for one vblank, for sync purposes
        jsr wait_for_next_vblank

        ; now we may safely enable interrupts
        cli

        ; Proceed to fade in the hud palete
        lda #0
        sta FadeCounter
        st16 SubScreenState, subscreen_fade_in

        rts
.endproc

.proc subscreen_fade_in
; parameters to the palette set functions
BasePaletteAddr := R0
Brightness := R2

        inc FadeCounter

        lda #20
        cmp FadeCounter
        beq done_with_fadein

        lda FadeCounter
        lsr
        lsr
        sta Brightness
        st16 BasePaletteAddr, subscreen_palette
        jsr queue_arbitrary_bg_palette
        rts

done_with_fadein:
        st16 SubScreenState, subscreen_active

        ; (for now, do nothing!)
        rts
.endproc

.proc subscreen_active
        ; for now, the only thing we need to do is detect a press of the START
        ; key, and trigger the closing sequence

        lda #KEY_START
        bit ButtonsDown
        beq subscreen_still_active
        lda #20
        sta FadeCounter
        st16 SubScreenState, subscreen_fade_out
        rts

subscreen_still_active:
        rts
.endproc

.proc subscreen_fade_out
; parameters to the palette set functions
BasePaletteAddr := R0
Brightness := R2
        dec FadeCounter
        beq done_with_fadeout

        lda FadeCounter
        lsr
        lsr
        sta Brightness
        st16 BasePaletteAddr, subscreen_palette
        jsr queue_arbitrary_bg_palette
        rts

done_with_fadeout:
        st16 SubScreenState, subscreen_terminal
        st16 GameMode, return_from_subscreen
        rts
.endproc

.proc subscreen_terminal
        ; Do nothing! Wait for the kernel to clean things up.
        rts
.endproc
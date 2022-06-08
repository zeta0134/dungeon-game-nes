; Collections of various routines that can fill an IRQ table with scanlines. Highly
; project specific.

        .setcpu "6502"

        .include "generators.inc"
        .include "nes.inc"
        .include "irq_table.inc"
        .include "scrolling.inc"
        .include "word_util.inc"
        .include "zeropage.inc"

        .segment "SCROLLING_A000"

; various useful constants
SCROLL_SEAM = 224 ; in pixels from the top of the nametable
LEFT_NAMETABLE = %0000
RIGHT_NAMETABLE = %0100
HUD_BANK = 2

; Side note: the initial blank 8px region is configured globally for the project. 
; Each generator here is concerned with the very first *visible* split.

; ALL generators expect their starting index in R0; this enables several generators
; to be used in the same frame without conflict.
; ALL generators leave R0 pointing at the next valid entry in the table.

.proc FAR_generate_basic_playfield
IrqGenerationIndex := R0
ChrBank := R1
ScratchByte := R2
ScratchWord := R3
; DEBUG: lock the playfield height here to 192. Eventually to support the dialog
; system, we'll want this to be a parameter instead of an immediate.
PlayfieldHeight := 192
; DEBUG: fix the CHR0 bank to $0 for the playfield. Later we'll want this to
; be configurable as a generator argument
; In theory we could allow making this a parameter as well, so the basic generator
; gains access to screen tinting abilities affecting the whole playfield. Might be
; useful for magic effects.
PpuMaskSetting = $1E
        ldx IrqGenerationIndex
        ; First, set the nametable based on the 6th bit of the X tile position
        lda #%00100000
        ;bit CameraXTileTarget
        bit PpuXTileTarget
        beq left_nametable
right_nametable:
        ;lda #(VBLANK_NMI | OBJ_1000 | BG_0000 | NT_2400)
        ;sta PPUCTRL
        lda #RIGHT_NAMETABLE
        sta irq_table_nametable_high, x
        jmp done_with_nametables
left_nametable:
        ;lda #(VBLANK_NMI | OBJ_1000 | BG_0000 | NT_2000)
        ;sta PPUCTRL
        lda #LEFT_NAMETABLE
        sta irq_table_nametable_high, x
done_with_nametables:
        ; now set the scroll properly, using the camera's position
        lda CameraXScrollTarget
        sta ScratchByte
        ;lda CameraXTileTarget
        lda PpuXTileTarget
        .repeat 3
        rol ScratchByte
        rol a
        .endrep
        ; a now contains low 5 bits of scroll tile, and upper 3 bits of sub-tile scroll
        ; (lower 5 bits of that are sub-pixels, and discarted)
        ;sta PPUSCROLL
        sta irq_table_scroll_x, x
        ; now do the same for Y scroll
        lda CameraYScrollTarget
        sta ScratchByte
        lda PpuYTileTarget
        .repeat 3
        rol ScratchByte
        rol a
        .endrep
        ;sta PPUSCROLL
        sta irq_table_scroll_y, x
        ; we'll use this for scanline calculations in a moment
        sta ScratchWord

        ; This is a normal playfield, so use standard PPUMASK
        lda #PpuMaskSetting
        sta irq_table_ppumask, x
        lda ChrBank
        sta irq_table_chr0_bank, x

        ; Okay now for the split.
        ; Determine the Y coordinate of the bottom of the playfield, based on the Y scroll position we saved earlier
        lda #0
        sta ScratchWord+1
        clc
        add16 ScratchWord, #PlayfieldHeight
        ; If this would exceed the scroll seam...
        cmp16 #SCROLL_SEAM, ScratchWord
        bcc hud_split
single_split:
        ; There is no need to generate a second split. Finalize this one with the full
        ; playfield height and bail
        lda #PlayfieldHeight
        sta irq_table_scanlines, x
        inc IrqGenerationIndex
        rts
hud_split:
        ; First compute the number of pixels by which we have exceeded the SCROLL_SEAM
        sec
        sub16 ScratchWord, #SCROLL_SEAM
        ; Scratch word now contains the height of our *second* split. The height of the
        ; first is the size of our playfield minus this height
        lda #PlayfieldHeight
        sec
        sbc ScratchWord ; if we somehow have nonzero in the high byte at this point
                        ; then something has gone terribly, terribly wrong
        sta irq_table_scanlines, x
        inc IrqGenerationIndex
        ; Now set up the second split point. We'll use the same X coordinate as before,
        ; but set the Y coordinate to 0
        ; note: x still points to our old value, which is convenient
        lda irq_table_scroll_x, x
        inx
        sta irq_table_scroll_x, x
        ; we need the old nametable too
        dex
        lda irq_table_nametable_high, x
        inx
        sta irq_table_nametable_high, x 
        lda #0
        sta irq_table_scroll_y, x
        ; ppumask and chr are the same as before
        lda #PpuMaskSetting
        sta irq_table_ppumask, x
        lda ChrBank
        sta irq_table_chr0_bank, x
        ; finally, the size of the second split is the lower byte of ScratchWord
        lda ScratchWord
        sta irq_table_scanlines, x
        ; and we're done with the second split
        inc IrqGenerationIndex
        rts
.endproc

.proc FAR_generate_standard_hud
IrqGenerationIndex := R0
        ldx IrqGenerationIndex
        ; the standard HUD consists of two simple splits, showing the bottom-most metatile
        ; in each nametable, left to right.
        lda #0
        sta irq_table_scroll_x, x
        lda #224
        sta irq_table_scroll_y, x
        lda #LEFT_NAMETABLE
        sta irq_table_nametable_high, x
        lda #HUD_BANK
        sta irq_table_chr0_bank, x
        ; the HUD should not show sprites in the first 16px, which is the entire first segment
        lda #(BG_ON)
        sta irq_table_ppumask, x
        lda #16
        sta irq_table_scanlines, x
        inc IrqGenerationIndex
        inx
        ; now do it all again for the second segment
        lda #0
        sta irq_table_scroll_x, x
        lda #224
        sta irq_table_scroll_y, x
        lda #RIGHT_NAMETABLE
        sta irq_table_nametable_high, x
        lda #HUD_BANK
        sta irq_table_chr0_bank, x
        lda #(BG_ON)
        sta irq_table_ppumask, x
        lda #16
        sta irq_table_scanlines, x
        inc IrqGenerationIndex
        inx
        ; Finally, generate a terminal segment with the CHR bank switched to blank tiles
        lda #(BG_ON)
        sta irq_table_ppumask, x
        lda #$FF
        sta irq_table_scanlines, x
        lda #0
        sta irq_table_scroll_x, x
        lda #224
        sta irq_table_scroll_y, x
        lda #0
        sta irq_table_nametable_high, x
        sta irq_table_chr0_bank, x ; index 0 is blank
        ; Also not strictly necessary, but we should conform to our own guidelines
        inc IrqGenerationIndex 
        rts
.endproc

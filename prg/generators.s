; Collections of various routines that can fill an IRQ table with scanlines. Highly
; project specific.

        .setcpu "6502"

        .include "far_call.inc"
        .include "generators.inc"
        .include "nes.inc"
        .include "irq_table.inc"
        .include "scrolling.inc"
        .include "word_util.inc"
        .include "zeropage.inc"

        .zeropage
fx_scanline_table_ptr: .res 2
fx_pattern_table_ptr: .res 2
        .segment "RAM"
fx_table_size: .res 1
fx_offset: .res 1
initial_pixel_offset: .res 1

CurrentDistortion: .res 1

        .segment "SCROLLING_A000"

; various useful constants
SCROLL_SEAM = 224 ; in pixels from the top of the nametable
LEFT_NAMETABLE = %0000
RIGHT_NAMETABLE = %0100
HUD_BANK = 4

; Side note: the initial blank 8px region is configured globally for the project. 
; Each generator here is concerned with the very first *visible* split.

; ALL generators expect their starting index in R0; this enables several generators
; to be used in the same frame without conflict.
; ALL generators leave R0 pointing at the next valid entry in the table.

.proc FAR_generate_playfield
IrqGenerationIndex := R0
ChrBank := R1
ScratchByte := R2
ScratchWord := R3
PlayfieldHeight := R5
PpuMaskSetting = R6
        ; Dispatch function; if there is a special effect active, generate that. Otherwise
        ; generate a basic playfield instead.
        lda CurrentDistortion
        cmp #DISTORTION_UNDERWATER
        bne basic
        near_call FAR_generate_underwater_distortion
        rts
basic:
        near_call FAR_generate_basic_playfield
        rts
.endproc

.proc FAR_initialize_playfield_fx
        lda #0
        sta initial_pixel_offset
        sta fx_offset
        rts
.endproc

.proc FAR_generate_basic_playfield
IrqGenerationIndex := R0
ChrBank := R1
ScratchByte := R2
ScratchWord := R3
PlayfieldHeight := R5
PpuMaskSetting = R6
        ldx IrqGenerationIndex
        ; First, set the nametable based on the 6th bit of the X tile position
        lda #%00100000
        bit PpuXTileTarget
        beq left_nametable
right_nametable:
        lda #RIGHT_NAMETABLE
        sta irq_table_nametable_high, x
        jmp done_with_nametables
left_nametable:
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
        lda PpuMaskSetting
        sta irq_table_ppumask, x
        lda ChrBank
        sta irq_table_chr0_bank, x

        ; Okay now for the split.
        ; Determine the Y coordinate of the bottom of the playfield, based on the Y scroll position we saved earlier
        lda #0
        sta ScratchWord+1
        clc
        add16 ScratchWord, PlayfieldHeight
        ; If this would exceed the scroll seam...
        cmp16 #SCROLL_SEAM, ScratchWord
        bcc hud_split
single_split:
        ; There is no need to generate a second split. Finalize this one with the full
        ; playfield height and bail
        lda PlayfieldHeight
        sta irq_table_scanlines, x
        inc IrqGenerationIndex
        rts
hud_split:
        ; First compute the number of pixels by which we have exceeded the SCROLL_SEAM
        sec
        sub16 ScratchWord, #SCROLL_SEAM
        ; Scratch word now contains the height of our *second* split. The height of the
        ; first is the size of our playfield minus this height
        lda PlayfieldHeight
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
        lda PpuMaskSetting
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

.proc FAR_generate_hud_palette_swap
IrqGenerationIndex := R0
        ldx IrqGenerationIndex
        ; Here we generate a "blank" scanline, similar to the bottom of the HUD, but
        ; with the "scanline" counter set to the magic value #$FE
        lda #(BG_ON)
        sta irq_table_ppumask, x
        lda #$FE
        sta irq_table_scanlines, x
        lda #0
        sta irq_table_scroll_x, x
        lda #224
        sta irq_table_scroll_y, x
        lda #0
        sta irq_table_nametable_high, x
        lda #2
        sta irq_table_chr0_bank, x ; index 2 is "blank" for this purpose
        inc IrqGenerationIndex 
        ; Note that this MUST now be followed with some other split, as the
        ; palette swap terminates by applying that split.
        ; Typically this will be either the HUD or the Dialog area.
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
        ; the HUD should not show sprites
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
        ; Finally, generate a terminal segment with a "blank" background, this time using
        ; the index filled with $00 bytes
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

.proc FAR_generate_dialog_hud
IrqGenerationIndex := R0
FontChrBase := R1
; TODO: DialogChrBase
        ldx IrqGenerationIndex
        ; the dialog region consists of 8 splits in total, each spaced 8px apart, followed
        ; by a forced blanking region to cap off the frame.

        ; There are only 4 rows of tiles available, so we'll be drawing each one twice, with
        ; different CHR banks loaded each time. The starting CHR banks are provided to this
        ; function as arguments

        ; The dialog region, like the HUD region, displays backgrounds but not sprites.

        ; === Top Border Graphics ===
        lda #0
        sta irq_table_scroll_x, x
        lda #224
        sta irq_table_scroll_y, x
        lda #LEFT_NAMETABLE
        sta irq_table_nametable_high, x
         ; top border graphics are also stored in the top font bank
        lda FontChrBase
        sta irq_table_chr0_bank, x
        lda #(BG_ON)
        sta irq_table_ppumask, x
        lda #8
        sta irq_table_scanlines, x
        inc IrqGenerationIndex
        inx

        ; === First Dialog Line - Top Half ===
        lda #0
        sta irq_table_scroll_x, x
        lda #232
        sta irq_table_scroll_y, x
        lda #LEFT_NAMETABLE
        sta irq_table_nametable_high, x
        lda FontChrBase
        sta irq_table_chr0_bank, x
        lda #(BG_ON)
        sta irq_table_ppumask, x
        lda #$FD
        sta irq_table_scanlines, x
        inc IrqGenerationIndex
        inx

        ; === First Dialog Line - Bottom Half ===
        lda #0
        sta irq_table_scroll_x, x
        lda #232
        sta irq_table_scroll_y, x
        lda #LEFT_NAMETABLE
        sta irq_table_nametable_high, x
        lda FontChrBase
        clc
        adc #2
        sta irq_table_chr0_bank, x
        lda #(BG_ON)
        sta irq_table_ppumask, x
        lda #$FD
        sta irq_table_scanlines, x
        inc IrqGenerationIndex
        inx

        ; === Second Dialog Line - Top Half ===
        lda #0
        sta irq_table_scroll_x, x
        lda #224
        sta irq_table_scroll_y, x
        lda #RIGHT_NAMETABLE
        sta irq_table_nametable_high, x
        lda FontChrBase
        sta irq_table_chr0_bank, x
        lda #(BG_ON)
        sta irq_table_ppumask, x
        lda #$FD
        sta irq_table_scanlines, x
        inc IrqGenerationIndex
        inx

        ; === Second Dialog Line - Bottom Half ===
        lda #0
        sta irq_table_scroll_x, x
        lda #224
        sta irq_table_scroll_y, x
        lda #RIGHT_NAMETABLE
        sta irq_table_nametable_high, x
        lda FontChrBase
        clc
        adc #2
        sta irq_table_chr0_bank, x
        lda #(BG_ON)
        sta irq_table_ppumask, x
        lda #$FD
        sta irq_table_scanlines, x
        inc IrqGenerationIndex
        inx

        ; === Third Dialog Line - Top Half ===
        lda #0
        sta irq_table_scroll_x, x
        lda #232
        sta irq_table_scroll_y, x
        lda #RIGHT_NAMETABLE
        sta irq_table_nametable_high, x
        lda FontChrBase
        sta irq_table_chr0_bank, x
        lda #(BG_ON)
        sta irq_table_ppumask, x
        lda #$FD
        sta irq_table_scanlines, x
        inc IrqGenerationIndex
        inx

        ; === Third Dialog Line - Bottom Half ===
        lda #0
        sta irq_table_scroll_x, x
        lda #232
        sta irq_table_scroll_y, x
        lda #RIGHT_NAMETABLE
        sta irq_table_nametable_high, x
        lda FontChrBase
        clc
        adc #2
        sta irq_table_chr0_bank, x
        lda #(BG_ON)
        sta irq_table_ppumask, x
        lda #$FD
        sta irq_table_scanlines, x
        inc IrqGenerationIndex
        inx

        ; === Bottom Border Graphics ===
        lda #0
        sta irq_table_scroll_x, x
        lda #224
        sta irq_table_scroll_y, x
        lda #LEFT_NAMETABLE
        sta irq_table_nametable_high, x
         ; bottom border graphics are stored in the bottom font bank
        lda FontChrBase
        clc
        adc #2
        sta irq_table_chr0_bank, x
        lda #(BG_ON)
        sta irq_table_ppumask, x
        lda #8
        sta irq_table_scanlines, x
        inc IrqGenerationIndex
        inx

        ; Finally, generate a terminal segment with rendering disabled
        lda #0
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

.proc FAR_generate_blank_hud
IrqGenerationIndex := R0
        ; Generate a terminal segment with rendering disabled
        ; (this is primarily useful when we are animating the palette swap border,
        ; since we need one valid split to follow it. This is that valid row.)
        ldx IrqGenerationIndex
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

UNDERWATER_HEIGHT = 160
UNDERWATER_ENTRIES = 13

.proc FAR_generate_underwater_distortion
        st16 fx_scanline_table_ptr, underwater_scanlines
        st16 fx_pattern_table_ptr, underwater_pattern
        lda #UNDERWATER_ENTRIES
        sta fx_table_size
        lda fx_offset
        sta initial_pixel_offset

        near_call FAR_generate_y_distortion
        inc fx_offset
        lda fx_offset
        cmp #UNDERWATER_HEIGHT
        bne no_wrap
        lda #0
        sta fx_offset
no_wrap:
        rts
        
.endproc

underwater_pattern:
  .lobytes 0
  .lobytes 1
  .lobytes 2
  .lobytes 3
  .lobytes 2
  .lobytes 1
  .lobytes 0
  .lobytes -1
  .lobytes -2
  .lobytes -3
  .lobytes -2
  .lobytes -1
  .lobytes 0
  
underwater_scanlines:
  .byte 5
  .byte 9
  .byte 12
  .byte 29
  .byte 12
  .byte 9
  .byte 9
  .byte 9
  .byte 12
  .byte 29
  .byte 12
  .byte 9
  .byte 4

.proc FAR_generate_y_distortion
IrqGenerationIndex := R0
ChrBank := R1
ScratchByte := R2
ScratchWord := R3
; DEBUG: lock the playfield height here to 192. Eventually to support the dialog
; system, we'll want this to be a parameter instead of an immediate.
PlayfieldHeight := R5
; In theory we could allow making this a parameter as well, so the basic generator
; gains access to screen tinting abilities affecting the whole playfield. Might be
; useful for magic effects.
PpuMaskSetting := R6

PixelsGenerated := R9
TempOffset := R10
TempX := R11
TempNametable := R12
BaseY := R13
TempY := R14
TempYOverflow := R15

        ; Our X position stays static, so set this up the same way we do
        ; for the basic playfield, but store the values in a temp; we'll need
        ; them a bunch of times later
        lda #%00100000
        bit PpuXTileTarget
        beq left_nametable
right_nametable:
        lda #RIGHT_NAMETABLE
        sta TempNametable
        jmp done_with_nametables
left_nametable:
        lda #LEFT_NAMETABLE
        sta TempNametable
done_with_nametables:
        lda CameraXScrollTarget
        sta ScratchByte
        lda PpuXTileTarget
        .repeat 3
        rol ScratchByte
        rol a
        .endrep
        ; a now contains low 5 bits of scroll tile, and upper 3 bits of sub-tile scroll
        ; (lower 5 bits of that are sub-pixels, and discarted)
        sta TempX
        
        ; Set our *initial* Y position based on the camera
        lda CameraYScrollTarget
        sta ScratchByte
        lda PpuYTileTarget
        .repeat 3
        rol ScratchByte
        rol a
        .endrep
        sta BaseY

        lda #$0
        sta PixelsGenerated
        ldy #$0

        ; to apply the pixel offset, skip over any initial entries that are
        ; smaller than the offset
        lda initial_pixel_offset
pixel_offset_loop:
        sec
        sbc (fx_scanline_table_ptr), y
        bcc done_skipping_entries
        sta initial_pixel_offset
        iny
        cpy fx_table_size
        bne no_wraparound
        ldy #$0
no_wraparound:
        jmp pixel_offset_loop
done_skipping_entries:
        ; initial_pixel_offset has been reduced to the remainder, the number of pixels
        ; we should skip in the *current* entry, which y points to

        ; for each entry in the table (16 entries):
        ; - compute the new scroll coordinates and nametable bit
        ; - use these values to generate one entry in the IRQ table
        ; note: later we'll want to be able to specify the number of entries to generate,
        ; and wrap the table around its end with a mask

loop:
        ; reset the temp Y coordinate
        lda BaseY
        sta TempY
        lda #0
        sta TempYOverflow

        ; calculate the new y offset
        lda (fx_pattern_table_ptr), y
        ; TODO: can TempOffset instead use ScratchByte?
        sta TempOffset
        sadd16 TempY, TempOffset


        ; if the Y offset is between 224-255 we'll have a glitch, so wrap this around
        lda TempYOverflow
        bmi fix_negative_temp_y
        cmp #1
        beq fix_positive_temp_y

        lda TempY
        cmp #224
        bcc temp_y_is_fine

fix_temp_y:
        lda TempOffset
        bmi fix_negative_temp_y
fix_positive_temp_y:
        lda TempY
        clc
        adc #32
        jmp temp_y_is_fine
fix_negative_temp_y:
        lda TempY
        sec
        sbc #32
temp_y_is_fine:
        sta TempY


        ; generate a new entry in the table
        ldx IrqGenerationIndex

        ; mask the low bit of the nametable, and shift it into position
        lda TempNametable
        sta irq_table_nametable_high, x

        ; the two scroll coordinates can be used directly
        lda TempX
        sta irq_table_scroll_x, x
        lda TempY
        sta irq_table_scroll_y, x

        ; these distortions don't modify chr or ppumask, so we'll always use the base value here
        lda PpuMaskSetting
        sta irq_table_ppumask, x
        lda ChrBank
        sta irq_table_chr0_bank, x

        ; finally the scanline count
        lda (fx_scanline_table_ptr), y
        ; if there is an initial pixel offset, subtract it here
        sec
        sbc initial_pixel_offset
        sta irq_table_scanlines, x
        
        ; add this to base_y for the next section
        clc
        adc BaseY
        ; if the Y offset is between 224-255 we'll have a glitch, so wrap this around
        cmp #224
        bcc base_y_is_fine
        sbc #224
base_y_is_fine:
        sta BaseY

        ; now clear the pixel offset (if any) so that it does not apply
        ; to any entries beyond the first
        lda #0
        sta initial_pixel_offset

        ; If we have just generated a split which will cross the scroll seam, we must
        ; fix this by turning it into two splits, one of which wraps us back around to
        ; Y=0. Do that here
        clc
        lda TempY
        adc irq_table_scanlines, x
        ; if this exceeds #224, we have a problem
        cmp #(224+1)
        bcc split_does_not_cross_scroll_seam
        sbc #224 ; A now contains the amount we have overflowed into the scroll seam
        sta ScratchByte
        lda irq_table_scanlines, x
        sec
        sbc ScratchByte
        sta irq_table_scanlines, x

        ; accumulate this smaller scanline against our running total
        lda irq_table_scanlines, x
        clc
        adc PixelsGenerated
        sta PixelsGenerated
        ; are we through generating pixels? If so, cleanup is in order
        cmp PlayfieldHeight
        bcs cleanup

        ; now generate an entirely new entry with Y=0
        inc IrqGenerationIndex
        ldx IrqGenerationIndex

        lda TempNametable
        sta irq_table_nametable_high, x
        lda TempX
        sta irq_table_scroll_x, x
        lda #0 ; top of the nametable for the second split
        sta irq_table_scroll_y, x
        lda PpuMaskSetting
        sta irq_table_ppumask, x
        lda ChrBank
        sta irq_table_chr0_bank, x
        ; for the scanline count, use that overflow value
        lda ScratchByte
        sta irq_table_scanlines, x
split_does_not_cross_scroll_seam:

        ; accumulate this against our running total
        lda irq_table_scanlines, x
        clc
        adc PixelsGenerated
        sta PixelsGenerated

        ; are we through generating pixels? If so, cleanup is in order
        cmp PlayfieldHeight
        bcs cleanup

        ; advance to the next irq table entry:
        inc IrqGenerationIndex

        ; advance to the next offset entry; if we reach the end of the table,
        ; wrap around to the beginning
        iny 
        cpy fx_table_size
        bne no_table_wrap
        ldy #$0
        no_table_wrap:

        ; this entry is complete, advance to the next entry
        jmp loop
cleanup:
        ; a holds our total generated pixels; we need to fix the scanline count for the last
        ; entry so that it doesn't overrun the requested size
        sec
        sbc PlayfieldHeight
        ; now a holds the "extra" pixels that the current scanline encodes for
        sta TempOffset
        lda irq_table_scanlines, x ; still points to the last scanline entry
        sec
        sbc TempOffset
        sta irq_table_scanlines, x ; should now contain the correct final value

        ; incremenet the generation index here, so that any future generators called after this one start
        ; in the right place and don't clobber our last entry
        inc IrqGenerationIndex

        ; ... and we're done?
        rts
.endproc
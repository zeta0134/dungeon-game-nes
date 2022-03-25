; Collections of various routines that can fill an IRQ table with scanlines. Highly
; project specific.

        .setcpu "6502"

        .include "nes.inc"
        .include "irq_table.inc"
        .include "scrolling.inc"
        .include "word_util.inc"
        .include "zeropage.inc"

        .segment "PRGLAST_E000"

; Side note: the initial blank 8px region is configured globally for the project. 
; Each generator here is concerned with the very first *visible* split.

; ALL generators expect their starting index in R0; this enables several generators
; to be used in the same frame without conflict.
; ALL generators leave R0 pointing at the next valid entry in the table.

.export generate_basic_playfield
.proc generate_basic_playfield
IrqGenerationIndex = R0
        ldx IrqGenerationIndex
        ; First, set the nametable based on the 6th bit of the X tile position
        lda #%00100000
        bit CameraXTileTarget
        beq left_nametable
right_nametable:
        ;lda #(VBLANK_NMI | OBJ_1000 | BG_0000 | NT_2400)
        ;sta PPUCTRL
        lda #%01
        sta irq_table_nametable_high, x
        jmp done_with_nametables
left_nametable:
        ;lda #(VBLANK_NMI | OBJ_1000 | BG_0000 | NT_2000)
        ;sta PPUCTRL
        lda #%00
        sta irq_table_nametable_high, x
done_with_nametables:
        ; now set the scroll properly, using the camera's position
        lda CameraXScrollTarget
        sta R0
        lda CameraXTileTarget
        .repeat 3
        rol R0
        rol a
        .endrep
        ; a now contains low 5 bits of scroll tile, and upper 3 bits of sub-tile scroll
        ; (lower 5 bits of that are sub-pixels, and discarted)
        ;sta PPUSCROLL
        sta irq_table_scroll_x, x
        ; now do the same for Y scroll
        lda CameraYScrollTarget
        sta R0
        lda PpuYTileTarget
        .repeat 3
        rol R0
        rol a
        .endrep
        ;sta PPUSCROLL
        sta irq_table_scroll_y, x

        ; This is a normal playfield, so use standard PPUMASK
        lda #$1E
        sta irq_table_ppumask, x
        ; DEBUG: use all 255 scanlines, so this becomes our final entry in the table
        lda #$FF
        sta irq_table_scanlines, x
        ; DEBUG: fix the CHR0 bank to $0 for the playfield. Later we'll want this to
        ; be configurable as a generator argument
        lda #0
        sta irq_table_chr0_bank, x

        ; TODO: Split the playfield over the HUD region
        inc IrqGenerationIndex

        ; Done for now?
        rts
.endproc
        .setcpu "6502"
        .include "nes.inc"
        .include "word_util.inc"
        .include "zeropage.inc"
        .include "vram_buffer.inc"

.scope PRGLAST_E000
        .zeropage
PopSlideAddress: .word $0000

        .segment "PRGLAST_E000"
.export vram_zipper


; Applies a buffer of PPUDATA writes stored in the stack area, and
; rapidly copies this data. The list should begin with a length byte,
; indicating the number of runs, followed by this 3 byte header:
; - target address (16bit)
; - vram direction and length (1 bit + 7 bits)
; A 1 for vram direction signals +32 mode, otherwise +1 mode is used.

; Note that this function assumes a complete table has been written.
; For safety, the functions which manipulate this table increment length
; last, however it's probably best to avoid calling this function at all
; unless the game loop is complete, otherwise partial transfers may be
; skipped entirely.

; Inputs:
;   Length at $100
;   VRAM Table at $108
;   Fresh brewed Coffee (stronest available)

; Clobbers: A, X PPUCTRL

; By aligning this to 256, we force the pop slide to
; both be on a four byte boundary, and begin at a $xx00 address, which lets us
; use the low byte directly as an offset into the table. We're placing this first
; in the file, to hopefully avoid wasting unnecessary space.
.align 256
vram_pop_slide:
        .repeat 64
        pla
        sta PPUDATA
        .endrepeat
        jmp done_with_transfer

vram_zipper:
        ; first off, is our table nonzero? if so, bail
        lda VRAM_TABLE_ENTRIES
        beq all_done

        ; setup the high byte of our jump address
        lda #>vram_pop_slide
        sta PopSlideAddress+1

        ; Preserve the stack pointer into memory
        tsx
        stx VRAM_TABLE_INDEX
        ; set the stack to the start of the table
        ldx #<(VRAM_TABLE_START - 1)
        txs
        lda PPUSTATUS ; reset the PPUADDR latch (throw this byte away)
section_loop:
        ; the first two bytes are always the target address
        pla
        sta PPUADDR
        pla
        sta PPUADDR
        ; the high bit of the third byte is our VRAM increment mode
        pla
        asl
        sta PopSlideAddress
        bcs vram_32
vram_1:
        lda #$00
        sta PPUCTRL
        jmp converge
vram_32:
        lda #VRAM_DOWN
        sta PPUCTRL
converge:
        jmp (PopSlideAddress)
done_with_transfer:
        dec VRAM_TABLE_ENTRIES
        bne section_loop
        ; restore the original stack pointer from memory
        ldx VRAM_TABLE_INDEX
        txs
        ; zero out our table to reset it for the next frame
        lda #0
        sta VRAM_TABLE_ENTRIES
        sta VRAM_TABLE_INDEX
all_done:
        rts
.endscope
; Generic routines to deal with compressed data, and decompress it
; into RAM for use. All compressed data begins with a 1-byte header
; indicating the type. Implemented types so far include:

; $00 - uncompressed data: 2 byte length, followed by those bytes

        .setcpu "6502"
        .include "compression.inc"
        .include "scrolling.inc"
        .include "word_util.inc"
        .include "zeropage.inc"

.scope PRGLAST_E000
        .segment "PRGLAST_E000"
        ;.org $e000

; asssumes y is already 0
.macro fetch_one_byte addr
.scope
        lda (addr), y
        inc16 addr
.endscope
.endmacro

; Given a source pointer to the start of a compression block with a valid header,
; decompress that data into the destination address.
; Clobbers: a, x, y
; Note: Decompression is usually quite slow, don't expect this to complete in a
; single frame. Plan accordingly.
.proc decompress
SourceAddr := R0
TargetAddr := R2
JumpTarget := R14
        ldy #0
        ; nab the compression type
        fetch_one_byte SourceAddr
        ; use this to index into our jump table and pick the decompression routine
        asl ; sets carry to 0 (we don't have more than 127 compression types)
        tax
        lda decompression_type_table, x
        sta JumpTarget
        lda decompression_type_table+1, x
        sta JumpTarget+1
        jmp (JumpTarget)
        ; tail call, target will rts
.endproc
.export decompress

decompression_type_table:
        .word uncompressed

; Data is not compressed, but does have a standard length header. All bytes in the
; data block will be copied to the destination. This is inefficient, but might be
; useful if we have a data block that does not compress well using the other
; routines.
.proc uncompressed
SourceAddr := R0
TargetAddr := R2
Length := R14
        fetch_one_byte SourceAddr
        sta Length
        fetch_one_byte SourceAddr
        sta Length+1
        ; y is already 0 from the parent routine
loop:
        fetch_one_byte SourceAddr
        sta (TargetAddr), y
        inc16 TargetAddr
        dec16 Length
        cmp16 Length, #0
        bne loop

        rts
.endproc

.endscope
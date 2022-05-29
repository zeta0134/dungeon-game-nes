; Generic routines to deal with compressed data, and decompress it
; into RAM for use. All compressed data begins with a 1-byte header
; indicating the type. Implemented types so far include:

; $00 - uncompressed data: 2 byte length, followed by those bytes

        .setcpu "6502"
        .include "compression.inc"
        .include "scrolling.inc"
        .include "word_util.inc"
        .include "zeropage.inc"

        .segment "PRGFIXED_E000"
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

decompression_type_table:
        .word uncompressed
        .word lz77_53 ; no! this should be plain lz77!

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

; Data is compressed using a variant on lz77. Data is broken up into packets,
; with each packet containing the following header:
; 7  bit  0
; ---- ----
; PPPP PLLL
; |||| ||||
; |||| |+++- length = (L + 1)
; |||| |     
; ++++-+---  offset = P
;
; If offset = 0, then the packet is followed by L+1 uncompressed data bytes
; Otherwise, data reading begins at (output_ptr - P)
.proc lz77_53
        SourceAddr := R0
        TargetAddr := R2
        PacketOffset := R10
        PacketLength := R11
        PointerAddr := R12
        UncompressedLength := R14

        ; setup
        fetch_one_byte SourceAddr
        sta UncompressedLength
        fetch_one_byte SourceAddr
        sta UncompressedLength+1
        ; y is already 0 from the parent routine
        
packet_loop:
        ; load and decode one data packet
        lda (SourceAddr), y
        and #%00000111
        sta PacketLength ; L
        inc PacketLength ; L + 1
        lda (SourceAddr), y
        and #%11111000
        lsr
        lsr
        lsr
        sta PacketOffset
        inc16 SourceAddr
        ; if PacketOffset is 0, then this is a DataPacket
        lda PacketOffset
        beq data_packet
pointer_packet:
        ; starting at our write address, subtract PacketOffset. This becomes
        ; PointerAddr, from which we will begin reading data
        sec
        lda TargetAddr
        sbc PacketOffset
        sta PointerAddr
        lda TargetAddr+1
        sbc #0
        sta PointerAddr+1
        ; From here, read up to PacketOffset bytes, and write those to TargetAddr
pointer_loop:
        lda (PointerAddr), y
        sta (TargetAddr), y
        inc16 PointerAddr
        inc16 TargetAddr
        dec16 UncompressedLength
        ; if at any time we reach the end of our data, stop and exit
        cmp16 UncompressedLength, #0
        beq all_done
        dec PacketLength
        bne pointer_loop
        ; we are done with this pointer packet; onward to the next
        jmp packet_loop

data_packet:
data_packet_loop:
        ; Starting immediately after the DataPacket header, copy PacketLength bytes
        ; to the TargetAddr
        lda (SourceAddr), y
        sta (TargetAddr), y
        inc16 SourceAddr
        inc16 TargetAddr
        dec16 UncompressedLength
        ; if at any time we reach the end of our data, stop and exit
        cmp16 UncompressedLength, #0
        beq all_done
        dec PacketLength
        bne data_packet_loop
        ; we are done with this data packet; onwards to the next
        jmp packet_loop

all_done:
        rts
.endproc
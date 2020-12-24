.ifndef _VRAM_BUFFER_INC
_VRAM_BUFFER_INC := 1

VRAM_TABLE_ENTRIES := $100
VRAM_TABLE_INDEX := $101
VRAM_TABLE_START := $108 ; 7 bytes of breathing room, in case any part
                         ; of table processing gets interrupted

VRAM_INC_1  := $00
VRAM_INC_32 := $80

.import vram_zipper

; Each entry in the VRAM table begins with a 2-byte target address in PPU
; memory space, high byte first, followed by a length and mode byte:
; 
; 7  bit  0
; ---- ----
; Vlll lll.
; |||| |||
; | +++-+++- 64 - number of bytes to copy
; +--------- VRAM increment mode
; 
; This effectively performs a << on the negated length, which will be shifted
; again by the decoding routine, resulting in a 4x operation on the length,
; exactly the size of one step through the pop slide.

.macro write_vram_header address, length, mode
        ldx VRAM_TABLE_INDEX
.if (.match (.left (1, {address}), #))
        ; immediate address provided, so just write the bytes out
        lda #>address
        sta VRAM_TABLE_START,x
        lda #<address
        sta VRAM_TABLE_START,x
.else
        ; memory address provided, read the value out of memory
        lda address
        sta VRAM_TABLE_START,x
        lda address+1
        sta VRAM_TABLE_START,x
.endif
        inx
        inx
        ; the mode and length combine into a single byte
        ; for length we need to massage it into a pop slide offset
        lda #(((64 - length) << 1) + mode)
        sta VRAM_TABLE_START+2,x
        ; finally, add 3 to our index
        inx
        stx VRAM_TABLE_INDEX
.endmacro

.macro vramcpy source_address, length
.scope
        ldx VRAM_TABLE_INDEX
        ldy #0
loop:
        lda source_address,y
        sta VRAM_TABLE_START,x
        inx
        iny
        cpy #length
        bne loop
        stx VRAM_TABLE_INDEX
.endscope
.endmacro

.endif
; Pulled directly from https://www.nesdev.org/wiki/Calculate_CRC32
; Assumed public domain due to wiki license. Credit to Kevin Horton for the implementation

	.include "crc.inc"

.zeropage
testcrc: .res 4

	.segment "UTILITIES_A000"

;usage:
;
;initialize by calling crc32init
;feed bytes to crc32
;finish by calling crc32end
;result is in testcrc0-3


.proc crc32init
	ldx #3
    lda #$ff

c3il:
    sta testcrc+0,x
    dex
    bpl c3il
    rts
.endproc

.proc crc32    
	ldx #8
	eor testcrc+0
	sta testcrc+0

c32l:        
	lsr testcrc+3
	ror testcrc+2
	ror testcrc+1
	ror testcrc+0
	bcc dc32
	lda #$ed
	eor testcrc+3
	sta testcrc+3
	lda #$b8
	eor testcrc+2
	sta testcrc+2
	lda #$83
	eor testcrc+1
	sta testcrc+1
	lda #$20
	eor testcrc+0
	sta testcrc+0

dc32:        
	dex
	bne c32l
	rts
.endproc

.proc crc32end
	ldx #3

c3el:        
	lda #$ff
	eor testcrc+0,x
	sta testcrc+0,x
	dex
	bpl c3el
	rts
.endproc
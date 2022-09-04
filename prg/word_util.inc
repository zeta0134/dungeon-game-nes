.ifndef _WORD_UTIL_INC
_WORD_UTIL_INC := 1

.macro st16 addr, value
        lda #<value
        sta addr
        lda #>value
        sta addr+1
.endmacro

.macro inc16 addr
.scope
        inc addr
        bne no_carry
        inc addr+1
no_carry:
.endscope
.endmacro

.macro dec16 addr
.scope
        bit addr 
        dec addr
        lda #$FF
        cmp addr
        bne no_carry
        dec addr+1
no_carry:
.endscope
.endmacro

.macro mov16 destination, source
        lda source
        sta destination
        lda source+1
        sta destination+1
.endmacro

; unsigned
.macro adc16b addr, value
        lda value ; 2
        adc addr ; 3
        sta addr ; 3
        lda #0 ; 2
        adc 1+addr ; 3
        sta 1+addr ; 3
.endmacro

; unsigned, explicitly clears carry
.macro add16b addr, value
        clc
        adc16b addr, value
.endmacro

; unsigned word
.macro adc16w addr, value
.if (.match (.left (1, {value}), #))
        lda #>(.right (.tcount ({value})-1, {value}))
        adc addr
        sta addr
        lda #<(.right (.tcount ({value})-1, {value}))
        adc 1+addr
        sta 1+addr
.else
        lda value
        adc addr
        sta addr
        lda 1+value
        adc 1+addr
        sta 1+addr   
.endmacro

; unsigned word, explicitly clears carry
.macro add16w addr, value
        clc
        adc16w addr, value
.endmacro

; quicker variant using a branch
; note: carry output will always respect low byte, which
; may be incorrect. Unsuitable for chaining!
.macro fadc16b addr, value
.scope
        lda value ; 2
        adc addr  ; 3z
        sta addr  ; 3z
        bcc skip  ; 3 (taken) 2 (not taken)
        inc 1+addr ; 5z
skip:
; with zp addr and imm value:
; original: 16
; new total (taken): 11
; new total (not taken): 15
; saves: 1 cycle worst case, 5 cycles best case
.endscope
.endmacro

; quicker variant with explicit carry clear
.macro fadd16b addr, value
        clc
        fadc16b addr, value
.endmacro

; signed
.macro sadd16 addr, value
.scope
        ; handle the low byte normally
        clc
        lda value
        adc addr
        sta addr
        ; sign-extend the high bit into the high byte
        lda value
        and #$80 ;extract the high bit
        beq positive
        lda #$FF ; the high bit was high, so set high byte to 0xFF, then add that plus carry 
        ; note: unless a signed overflow occurred, carry will usually be *set* in this case
positive:
        ; the high bit was low; a contains #$00, so add that plus carry
        adc 1+addr
        sta 1+addr
.endscope
.endmacro

; same as above, but the value to add is already in a
; (useful in situations where A came from somewhere unusual)
.macro sadd16a addr
.scope
        ; preserve a
        pha
        ; handle the low byte normally
        clc
        adc addr
        sta addr
        ; sign-extend the high bit into the high byte
        pla
        and #$80 ;extract the high bit
        beq positive
        lda #$FF ; the high bit was high, so set high byte to 0xFF, then add that plus carry 
        ; note: unless a signed overflow occurred, carry will usually be *set* in this case
positive:
        ; the high bit was low; a contains #$00, so add that plus carry
        adc addr+1
        sta addr+1
.endscope
.endmacro

.macro sub16 addr, value
        lda addr
        sbc value
        sta addr
        lda addr+1
        sbc #0
        sta addr+1
.endmacro

.macro cmp16 op_a, op_b
.scope
.if (.match (.left (1, {op_a}), #))
        lda #>(.right (.tcount ({op_a})-1, {op_a}))
        cmp op_b+1
        bne done
        lda #<(.right (.tcount ({op_a})-1, {op_a}))
        cmp op_b
.elseif (.match (.left (1, {op_b}), #))
        lda op_a+1
        cmp #>(.right (.tcount ({op_b})-1, {op_b}))
        bne done
        lda op_a
        cmp #<(.right (.tcount ({op_b})-1, {op_b}))
.else
        lda op_a+1
        cmp op_b+1
        bne done
        lda op_a
        cmp op_b
.endif
done:
.endscope
.endmacro

.endif
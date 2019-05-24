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

.macro mov16 addr1, addr2
        lda addr1
        sta addr2
        lda addr1+1
        sta addr2+1
.endmacro

.macro add16 addr, value
        lda value
        adc addr
        sta addr
        lda #0
        adc addr+1
        sta addr+1
.endmacro

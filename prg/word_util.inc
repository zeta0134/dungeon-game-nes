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



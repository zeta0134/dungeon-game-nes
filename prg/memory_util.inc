.global clear_memory

.macro clear_page ADDR
.scope
        ldy #0
        lda #0
loop:
        dey
        sta ADDR,y
        bne loop
.endscope
.endmacro
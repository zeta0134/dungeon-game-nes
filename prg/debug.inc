.ifndef DEBUG_INC
.define DEBUG_INC 1

.macro debug_color flags
        ;lda #(BG_ON | OBJ_ON | BG_CLIP | OBJ_CLIP | flags)
        ;sta PPUMASK
.endmacro

.endif
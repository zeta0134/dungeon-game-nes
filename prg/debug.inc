DEBUG_MODE = 0
DEBUG_TIME_WASTE = 0
DEBUG_DISABLE_MUSIC = 1

.macro debug_color flags
        .if ::DEBUG_MODE
        lda #(BG_ON | OBJ_ON | BG_CLIP | OBJ_CLIP | flags)
        sta PPUMASK
        .endif
.endmacro

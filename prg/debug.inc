.ifndef DEBUG_INC
.define DEBUG_INC 1

.macro debug_color flags
        ; Disable these for now.
        ; TODO: set up a flag so we can switch these out with PPUMASK changes in the IRQ handler,
        ; trading some bugs in the playfield region (no sprite masking) for profiling data.
        
        ;lda #(BG_ON | OBJ_ON | BG_CLIP | OBJ_CLIP | flags)
        ;sta PPUMASK
.endmacro

.endif
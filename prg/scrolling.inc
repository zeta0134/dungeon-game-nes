.import draw_half_row
.import draw_half_col

.macro incColumn addr
        clc
        lda addr
        adc 1
        and %00011111
        tax ; preserve low 5 bits for later
        bne no_overflow ; taken if A != 0 after mask
        lda addr+1
        eor %00000100 ; flip nametable bit, from base 0x20 <-> 0x24
        sta addr+1
no_overflow:
        lda addr
        and %11100000 ; mask off lower 5 bits
        sta addr
        txa
        clc 
        adc addr ; a now contains original top 3 bits, and incremented lower 5 bits, without carry
        sta addr
.endmacro

.macro decColumn addr
        clc
        lda addr
        sbc 1
        and %00011111
        tax ; preserve low 5 bits for later
        cmp %00011111
        bne no_overflow ; taken if A != 31 after mask
        lda addr+1
        eor %00000100 ; flip nametable bit, from base 0x20 <-> 0x24
        sta addr+1
no_overflow:
        lda addr
        and %11100000 ; mask off lower 5 bits
        sta addr
        txa
        clc 
        adc addr ; a now contains original top 3 bits, and decremented lower 5 bits, without carry
        sta addr
.endmacro


.macro incRow addr
        clc
        lda addr
        adc %00100000
        sta addr
        bvs overflow
        ; check to see if we've reached the magic value 28
        ; lower 3 bits
        and %11100000
        cmp %10000000
        bne done
        ; upper 2 bits
        lda addr+1
        and %00000011
        cmp %00000011
        bne done
        ; we've overflowed into the status area
        ; first zero the lower 3 bits
        lda addr
        and %00011111
        sta addr
        ; then the upper 2 bits
        lda addr+1
        and %11111100
        sta addr+1
        jmp done
overflow:
        inc addr+1        
done:
.endmacro

.macro decRow addr
        clc
        lda addr
        adc %11100000 ;"subtract" 1 from the upper 3 bits
        sta addr
        ; if we *did* overflow the addition in hardware, then we *did not* overflow the 3-bit subtraction: 0x000 -> 0x111
        bvs done
        ; subtract 1 from the upper 2 bits
        lda addr+1
        sbc 1
        ; stash the result in x (it might be wrong)
        tax
        ; check for overflow in *just these two bits*
        and %00000011
        cmp %00000011
        bne no_overflow
        ; for the high byte we need to now *set* the lower 2 bits to 11, without affecting the rest of it
        lda addr+1
        ora %00000011
        sta addr+1
        ; for the low byte, we need to *clear* the high bit; we previously set the upper 3 bits to 111
        lda addr
        eor %10000000
        sta addr
        ; after these operations, the combined Y coordinate should be: 11011, or 27
        jmp done
no_overflow:
        ; actually write the value we stashed to x
        stx addr+1
done:
.endmacro

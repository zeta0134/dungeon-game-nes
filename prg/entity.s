        .setcpu "6502"
        .include "entity.inc"
        .include "sprites.inc"
        .include "scrolling.inc"
        .include "word_util.inc"
        .include "zeropage.inc"


.scope PRGLAST_E000
        .zeropage
CurrentEntityIndex: .byte $00
        .exportzp CurrentEntityIndex
        .segment "RAM"
        .export entity_table, spawn_entity, update_entities
entity_table:
        .repeat 16
        .tag EntityState
        .endrepeat
        .align 2
CurrentEntityFuncPtr: .word $0000
        .segment "PRGLAST_E000"


; Input: R0 - update logic (typically an init function)
; for this entity. Will usually be called next frame, but
; might be called *this* frame if the new entity is created
; in a later slot by an entity function in an earlier slot.

.proc spawn_entity
        ldy #0
loop:
        lda EntityState::UpdateFunc+1, y
        beq found_slot
        clc
        tya
        adc #.sizeof(EntityState)
        bvs spawn_failed	
        tay
        jmp loop
found_slot:
        lda R0
        sta EntityState::UpdateFunc, y
        lda R0+1
        sta EntityState::UpdateFunc+1, y
spawn_failed:
done:
        rts
.endproc

.proc update_entities
        lda #0
        sta CurrentEntityIndex
loop:
        ldy CurrentEntityIndex
        lda EntityState::UpdateFunc+1, y
        beq skip_entity
        sta CurrentEntityFuncPtr+1
        lda EntityState::UpdateFunc, y
        sta CurrentEntityFuncPtr
        lda #<(return_from_indirect-1)
        pha
        lda #>(return_from_indirect-1)
        pha
        jmp (CurrentEntityFuncPtr)
return_from_indirect:
skip_entity:
        clc
        lda .sizeof(EntityState)
        adc CurrentEntityIndex
        bvs done
        sta CurrentEntityIndex
        jmp loop
done:
        rts

.endproc

.endscope
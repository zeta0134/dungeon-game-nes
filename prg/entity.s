        .setcpu "6502"
        .include "entity.inc"
        .include "sprites.inc"
        .include "scrolling.inc"
        .include "word_util.inc"
        .include "zeropage.inc"


        .zeropage
CurrentEntityIndex: .byte $00

        .segment "RAM"
entity_table:
        .repeat 16
        .tag EntityState
        .endrepeat
        .align 2
CurrentEntityFuncPtr: .word $0000

        .segment "PRGFIXED_E000"


; Input: R0 - update logic (typically an init function)
; for this entity. Will usually be called next frame, but
; might be called *this* frame if the new entity is created
; in a later slot by an entity function in an earlier slot.

; upon completion, y will contain the spawned index, or the
; value #$FF to indicate failure.

.proc spawn_entity
        ldy #0
loop:
        lda entity_table + EntityState::UpdateFunc+1, y
        beq found_slot
        clc
        tya
        adc #.sizeof(EntityState)
        bvs spawn_failed	
        tay
        jmp loop
found_slot:
        lda R0
        sta entity_table + EntityState::UpdateFunc, y
        lda R0+1
        sta entity_table + EntityState::UpdateFunc+1, y
        ; all done!
        rts
spawn_failed:
        ldy #$FF
        rts
.endproc

.proc update_entities
        lda #0
        sta CurrentEntityIndex
loop:
        ldy CurrentEntityIndex
        lda entity_table + EntityState::UpdateFunc+1, y
        beq skip_entity
        sta CurrentEntityFuncPtr+1
        lda entity_table + EntityState::UpdateFunc, y
        sta CurrentEntityFuncPtr
        lda #>(return_from_indirect-1)
        pha
        lda #<(return_from_indirect-1)
        pha
        jmp (CurrentEntityFuncPtr)
return_from_indirect:
skip_entity:
        clc
        lda #.sizeof(EntityState)
        adc CurrentEntityIndex
        bvs done
        sta CurrentEntityIndex
        jmp loop
done:
        rts
.endproc

.proc set_metasprite_pos
MetaSpriteIndex := R0
EntityIndex := R1
        ; first, copy the coordinates into place
        ldy EntityIndex
        ldx MetaSpriteIndex
        lda entity_table + EntityState::PositionX, y
        sta metasprite_table + MetaSpriteState::PositionX, x
        lda entity_table + EntityState::PositionX+1, y
        sta metasprite_table + MetaSpriteState::PositionX+1, x
        lda entity_table + EntityState::PositionY, y
        sta metasprite_table + MetaSpriteState::PositionY, x
        lda entity_table + EntityState::PositionY+1, y
        sta metasprite_table + MetaSpriteState::PositionY+1, x
        ; now, shift the metasprite position to the right by 4, taking
        ; the coordinates from *subtile* space to *pixel* space
        .repeat 4
        lsr metasprite_table + MetaSpriteState::PositionX+1, x
        ror metasprite_table + MetaSpriteState::PositionX, x
        .endrepeat
        .repeat 4
        lsr metasprite_table + MetaSpriteState::PositionY+1, x
        ror metasprite_table + MetaSpriteState::PositionY, x
        .endrepeat
        rts
.endproc

        .setcpu "6502"
        .include "branch_util.inc"
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

        .segment "ENTITIES_A000"


; Completely despawn the entity table; used during init and later
; when switching levels. Note that an entity is considered inactive
; if the high byte of its UpdateFunc is exactly #0. This is also how
; an entity may despawn itself at runtime.
.proc FAR_despawn_all_entities
        ldy #0
loop:
        lda #0
        sta entity_table + EntityState::UpdateFunc+1, y
        clc
        tya
        adc #.sizeof(EntityState)
        bcs done
        tay
        jmp loop
done:
        rts
.endproc

; Input: R0 - update logic (typically an init function)
; for this entity. Will usually be called next frame, but
; might be called *this* frame if the new entity is created
; in a later slot by an entity function in an earlier slot.

; upon completion, y will contain the spawned index, or the
; value #$FF to indicate failure.

.proc FAR_spawn_entity
        ldy #0
loop:
        lda entity_table + EntityState::UpdateFunc+1, y
        beq found_slot
        clc
        tya
        adc #.sizeof(EntityState)
        bcs spawn_failed	
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

.proc FAR_update_entities
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

; works out the proper location to display the character and shadow metasprite, based
; on the character's position and current height relative to the ground
.proc set_3d_metasprite_pos
MetaSpriteIndex := R0
        ldy CurrentEntityIndex

        ; We'll work on the main sprite first
        ldx entity_table + EntityState::MetaSpriteIndex, y

        ; first, copy the coordinates into place
        lda entity_table + EntityState::PositionX, y
        sta metasprite_table + MetaSpriteState::PositionX, x
        lda entity_table + EntityState::PositionX+1, y
        sta metasprite_table + MetaSpriteState::PositionX+1, x
        lda entity_table + EntityState::PositionY, y
        sta metasprite_table + MetaSpriteState::PositionY, x
        lda entity_table + EntityState::PositionY+1, y
        sta metasprite_table + MetaSpriteState::PositionY+1, x

        ; Now we need to subtract the player's height from their Y coordinate
        sec
        lda metasprite_table + MetaSpriteState::PositionY, x
        sbc entity_table + EntityState::PositionZ, y
        sta metasprite_table + MetaSpriteState::PositionY, x
        lda metasprite_table + MetaSpriteState::PositionY+1, x
        sbc entity_table + EntityState::PositionZ + 1, y
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

        ; Alright now, repeat most of the above but for the shadow sprite
        ldx entity_table + EntityState::ShadowSpriteIndex, y
        stx MetaSpriteIndex

        ; Shadow check: is our height nonzero?
        lda entity_table + EntityState::PositionZ, y
        ora entity_table + EntityState::PositionZ + 1, y
        jeq no_shadow

        ; x already contains MetaSpriteIndex
        metasprite_set_flag FLAG_VISIBILITY, VISIBILITY_DISPLAYED

        ; copy the coordinates into place
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

        ; done drawing the shadow, get outta here
        rts

no_shadow:
        ; There is no shadow to draw; turn off the shadow animation
        ; x already contains MetaSpriteIndex
        metasprite_set_flag FLAG_VISIBILITY, VISIBILITY_HIDDEN
        ; and done
        rts
.endproc
.ifndef _ENTITY_INC
_ENTITY_INC := 1

.include "sprites.inc"

.import entity_table

.struct EntityState
        UpdateFunc .word
        PositionX .word ; Most entities will have a position, but if not needed, these can be repurposed
        PositionY .word
        MetaSpriteIndex .byte ; Entities without drawables may repurpose this byte
        Data .byte 9 ; arbitrary bytes for any purpose really
.endstruct

.macro despawn_entity EntityIndex
        lda #0
        ldy EntityIndex
        sta entity_table + EntityState::UpdateFunc, y
        sta entity_table + EntityState::UpdateFunc+1, y
.endmacro

.macro set_update_func EntityIndex, FunctionAddr
        ldy EntityIndex
        lda #<FunctionAddr
        sta entity_table + EntityState::UpdateFunc, y
        lda #>FunctionAddr
        sta entity_table + EntityState::UpdateFunc+1, y
.endmacro

.macro set_metasprite_pos EntityIndex, MetaSpriteIndex
        ; first, copy the coordinates into place
        ldy EntityIndex
        ldx MetaSpriteIndex
        lda entity_table +EntityState::PositionX, y
        sta metasprite_table + MetaSpriteState::PositionX, x
        lda entity_table +EntityState::PositionX+1, y
        sta metasprite_table + MetaSpriteState::PositionX+1, x
        lda entity_table +EntityState::PositionY, y
        sta metasprite_table + MetaSpriteState::PoitionY, x
        lda entity_table +EntityState::PositionY+1, y
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
.endmacro

.endif
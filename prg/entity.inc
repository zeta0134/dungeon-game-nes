.ifndef _ENTITY_INC
_ENTITY_INC := 1

.import entity_table, spawn_entity, update_entities, set_metasprite_pos
.importzp CurrentEntityIndex

.struct EntityState
        UpdateFunc .word
        PositionX .word ; Most entities will have a position, but if not needed, these can be repurposed
        PositionY .word
        PositionZ .word
        GroundLevel .byte
        MetaSpriteIndex .byte ; Entities without drawables may repurpose these bytes
        ShadowSpriteIndex .byte
        Data .byte 5 ; arbitrary bytes for any purpose really
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

.endif
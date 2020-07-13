.import entity_table


.struct EntityState
        UpdateFunc .word
        MetaSpriteIndex .byte
        Data .byte 13
.endstruct

.macro despawn_entity EntityIndex
        lda #0
        ldy EntityIndex
        sta EntityState::UpdateFunc, y
        sta EntityState::UpdateFunc+1, y
.endmacro

.macro set_update_func EntityIndex, FunctionAddr
        ldy EntityIndex
        lda #<FunctionAddr
        sta EntityState::UpdateFunc, y
        lda #>FunctionAddr
        sta EntityState::UpdateFunc+1, y
.endmacro
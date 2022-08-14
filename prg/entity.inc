; External, mostly called by the kernel
.global FAR_spawn_entity
.global FAR_update_entities
.global FAR_despawn_all_entities

; Internal, mostly used by entity state machines
.global set_3d_metasprite_pos
.global standard_entity_init

; Variables
.global entity_table
.globalzp CurrentEntityIndex

.struct EntityState
        UpdateFunc .word
        UpdateBank .byte
        PositionX .word ; Most entities will have a position, but if not needed, these can be repurposed
        PositionY .word
        PositionZ .word
        SpeedX .byte
        SpeedY .byte
        SpeedZ .byte
        GroundLevel .byte
        MetaSpriteIndex .byte ; Entities without drawables may repurpose these bytes
        ShadowSpriteIndex .byte
        CollisionMask .byte ; Touch of death, man!
        CollisionResponse .byte ; for entities that need to know when they are bumped, squished, or set on fire
        Data .byte 4 ; arbitrary bytes for any purpose really
.endstruct

MAX_ENTITIES = 12

COLLISION_GROUP_BOUNCE =    %00000001
COLLISION_GROUP_WEAKHIT =   %00000010
COLLISION_GROUP_STRONGHIT = %00000100
COLLISION_GROUP_DAMAGING =  %00000110


.macro despawn_entity EntityIndex
        lda #0
        ldy EntityIndex
        sta entity_table + EntityState::UpdateFunc, y
        sta entity_table + EntityState::UpdateFunc+1, y
        sta entity_table + EntityState::CollisionMask, y
.endmacro

.macro set_update_func EntityIndex, FunctionAddr
        ldy EntityIndex
        lda #<FunctionAddr
        sta entity_table + EntityState::UpdateFunc, y
        lda #>FunctionAddr
        sta entity_table + EntityState::UpdateFunc+1, y
        lda #<.bank(FunctionAddr)
        sta entity_table + EntityState::UpdateBank, y
.endmacro

; note: assumes Y is already set to CurrentEntityIndex
.macro entity_set_flag_y flag_mask, flag_value
        lda entity_table + EntityState::Data + DATA_FLAGS, y
        and #(flag_mask ^ $FF)
        ora #flag_value
        sta entity_table + EntityState::Data + DATA_FLAGS, y
.endmacro

; note: assumes Y is already set to CurrentEntityIndex
.macro entity_check_flag_y flag_mask
        lda entity_table + EntityState::Data + DATA_FLAGS, y
        and #flag_mask
        ; now you can beq for unset, and bne for flag set
.endmacro

; note: assumes X is already set to CurrentEntityIndex
.macro entity_set_flag_x flag_mask, flag_value
        lda entity_table + EntityState::Data + DATA_FLAGS, x
        and #(flag_mask ^ $FF)
        ora #flag_value
        sta entity_table + EntityState::Data + DATA_FLAGS, x
.endmacro

; note: assumes X is already set to CurrentEntityIndex
.macro entity_check_flag_x flag_mask
        lda entity_table + EntityState::Data + DATA_FLAGS, x
        and #flag_mask
        ; now you can beq for unset, and bne for flag set
.endmacro
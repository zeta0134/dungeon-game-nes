        .setcpu "6502"
        .include "nes.inc"
        .include "input.inc"
        .include "sprites.inc"
        .include "entity.inc"
        .include "physics.inc"
        .include "word_util.inc"
        .include "zeropage.inc"

.scope PRGLAST_E000
        .segment "PRGLAST_E000"
        ;.org $e000
        .include "animations/blobby/idle.inc"
        .include "animations/blobby/jump.inc" ;note: currently depends on idle.inc!
        .include "animations/blobby/roll.inc" ;note: currently depends on idle.inc!
        .include "animations/blobby/walk.inc"
        .include "animations/blobby/charge.inc"

        .export blobby_init

DATA_SPEED_X := 0
DATA_SPEED_Y := 1

; mostly performs a whole bunch of one-time setup
; expects the entity position to have been set by whatever did the initial spawning
.proc blobby_init
        jsr find_unused_metasprite
        lda #$FF
        cmp R0
        beq failed_to_spawn
        ldy CurrentEntityIndex
        sty R1 ; used to set entity position in a moment
        lda R0
        sta entity_table + EntityState::MetaSpriteIndex, y
        set_metasprite_animation R0, blobby_anim_idle
        ; uses the EntityIndex in R1 and the MetaSprite index, still in R0 at this point
        jsr set_metasprite_pos
        ; ensure the rest of the metasprite attributes are sensibly defaulted
        set_metasprite_tile_offset R0, #0
        set_metasprite_palette_offset R0, #0
        ; use data bytes 0 and 1 to track speed
        lda #0
        ldy CurrentEntityIndex
        sta entity_table + EntityState::Data + DATA_SPEED_X, y
        sta entity_table + EntityState::Data + DATA_SPEED_Y, y
        ; finally, switch to the idle routine
        set_update_func CurrentEntityIndex, blobby_idle
        rts
failed_to_spawn:
        despawn_entity CurrentEntityIndex
        rts
.endproc

.proc apply_speed
        ; apply speed to position
        ldx CurrentEntityIndex
        lda entity_table + EntityState::Data + DATA_SPEED_X, x
        sta R0
        sadd16x entity_table + EntityState::PositionX, R0
        ;lda entity_table + EntityState::Data + DATA_SPEED_Y, x
        ;sta R0
        ;sadd16x entity_table + EntityState::PositionY, R0
        rts
.endproc

.proc blobby_idle
        ; dampen the current speed
        ldx CurrentEntityIndex
        apply_friction entity_table + EntityState::Data + DATA_SPEED_X, 2
        ;apply_friction entity_table + EntityState::Data + DATA_SPEED_Y, 2
        ; apply physics normally
        jsr apply_speed
        txa
        sta R1
        lda entity_table + EntityState::MetaSpriteIndex, x
        sta R0
        jsr set_metasprite_pos
        ; check for state changes
        lda #KEY_RIGHT
        bit ButtonsHeld
        beq right_not_held
        ; switch to the walk right animation and state
        set_metasprite_animation R0, blobby_anim_walk_right
        set_update_func CurrentEntityIndex, blobby_walk_right
right_not_held:       
        lda #KEY_LEFT
        bit ButtonsHeld
        beq left_not_held
        ; switch to the walk right animation and state
        set_metasprite_animation R0, blobby_anim_walk_left
        set_update_func CurrentEntityIndex, blobby_walk_left
left_not_held:
        rts
.endproc

.proc blobby_walk_right
        ; accelerate to the right
        ldx CurrentEntityIndex
        accelerate entity_table + EntityState::Data + DATA_SPEED_X, #3
        max_speed entity_table + EntityState::Data + DATA_SPEED_X, #16
        ; apply physics normally
        jsr apply_speed
        txa
        sta R1
        lda entity_table + EntityState::MetaSpriteIndex, x
        sta R0
        jsr set_metasprite_pos
        ; check for state changes
        lda #KEY_RIGHT
        bit ButtonsHeld
        bne right_not_held
        ; switch to the idle right animation and state
        set_metasprite_animation R0, blobby_anim_idle
        set_update_func CurrentEntityIndex, blobby_idle
right_not_held:
        rts
.endproc

.proc blobby_walk_left
        ; accelerate to the right
        ldx CurrentEntityIndex
        accelerate entity_table + EntityState::Data + DATA_SPEED_X, #253
        min_speed entity_table + EntityState::Data + DATA_SPEED_X, #240
        ; apply physics normally
        jsr apply_speed
        txa
        sta R1
        lda entity_table + EntityState::MetaSpriteIndex, x
        sta R0
        jsr set_metasprite_pos
        ; check for state changes
        lda #KEY_LEFT
        bit ButtonsHeld
        bne left_not_held
        ; switch to the idle right animation and state
        set_metasprite_animation R0, blobby_anim_idle
        set_update_func CurrentEntityIndex, blobby_idle
left_not_held:
        rts
.endproc

.endscope

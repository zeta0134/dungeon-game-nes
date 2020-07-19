        .setcpu "6502"
        .include "nes.inc"
        .include "collision.inc"
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

WALKING_SPEED = 16
WALKING_ACCEL = 2

; because of how this is used by the macro which applies friction,
; this must be a define and not a numeric constant
.define SLIPPERINESS 4

DATA_SPEED_X = 0
DATA_SPEED_Y = 1

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
; these parameters define the bounds of a collision box around
; the blob's feet, which determines where it exists for wall
; tile purposes
LeftX := R1
TopY := R2
RightX := R3
BottomY := R4
        ; set our palette index to 0 by default, for debugging
        ldy CurrentEntityIndex
        lda entity_table + EntityState::MetaSpriteIndex
        tay
        lda #0
        sta metasprite_table + MetaSpriteState::PaletteOffset, y

        ; load in our bounding box; for now this should perfectly
        ; line up with the sprite edge (of idle, frame 1)

        ; left
        lda #(1 << 4)
        sta LeftX
        ; top
        lda #(4 << 4)
        sta TopY
        ; right
        lda #(14 << 4)
        sta RightX
        ; bottom
        lda #(14 << 4)
        sta BottomY

        ; apply speed to position for each axis, then check the
        ; tilemap and correct for any tile collisions
        ldx CurrentEntityIndex
        lda entity_table + EntityState::Data + DATA_SPEED_X, x
        sta R0
        sadd16x entity_table + EntityState::PositionX, R0
        ; collide with X axis here

        ldx CurrentEntityIndex
        lda entity_table + EntityState::Data + DATA_SPEED_Y, x
        sta R0
        bmi move_up
move_down:
        sadd16x entity_table + EntityState::PositionY, R0
        jsr collide_down_with_map
        jmp done
move_up:
        sadd16x entity_table + EntityState::PositionY, R0
        jsr collide_up_with_map

done:
        rts
.endproc

.proc walking_acceleration
        ldx CurrentEntityIndex
check_right:
        lda #KEY_RIGHT
        bit ButtonsHeld
        beq right_not_held
        ; right is held, so accelerate to the +X
        accelerate entity_table + EntityState::Data + DATA_SPEED_X, #WALKING_ACCEL
        max_speed entity_table + EntityState::Data + DATA_SPEED_X, #WALKING_SPEED
        ; note: we explicitly skip checking for left, to work around
        ; worn controllers and broken emulators; right wins
        jmp check_up
right_not_held:
check_left:
        lda #KEY_LEFT
        bit ButtonsHeld
        beq left_not_held
        ; left is held, so accelerate to the -X
        accelerate entity_table + EntityState::Data + DATA_SPEED_X, #(256-WALKING_ACCEL)
        min_speed entity_table + EntityState::Data + DATA_SPEED_X, #(256-WALKING_SPEED)
        jmp check_up
left_not_held:
        apply_friction entity_table + EntityState::Data + DATA_SPEED_X, SLIPPERINESS
check_up:
        lda #KEY_UP
        bit ButtonsHeld
        beq up_not_held
        ; up is held, so accelerate to the -Y
        accelerate entity_table + EntityState::Data + DATA_SPEED_Y, #(256-WALKING_ACCEL)
        min_speed entity_table + EntityState::Data + DATA_SPEED_Y, #(256-WALKING_SPEED)
        ; note: we explicitly skip checking for down, to work around
        ; worn controllers and broken emulators; up wins
        jmp done
up_not_held:
check_down:
        lda #KEY_DOWN
        bit ButtonsHeld
        beq down_not_held
        ; down is held, so accelerate to the +Y
        accelerate entity_table + EntityState::Data + DATA_SPEED_Y, #WALKING_ACCEL
        max_speed entity_table + EntityState::Data + DATA_SPEED_Y, #WALKING_SPEED
        jmp done
down_not_held:
        apply_friction entity_table + EntityState::Data + DATA_SPEED_Y, SLIPPERINESS
done:
        rts
.endproc

.proc pick_walk_animation
        lda #KEY_RIGHT
        bit ButtonsHeld
        beq right_not_held
        ; switch to the walk right animation and state
        set_metasprite_animation R0, blobby_anim_walk_right
        set_update_func CurrentEntityIndex, blobby_walk_right
        rts
right_not_held:       
        lda #KEY_LEFT
        bit ButtonsHeld
        beq left_not_held
        ; switch to the walk right animation and state
        set_metasprite_animation R0, blobby_anim_walk_left
        set_update_func CurrentEntityIndex, blobby_walk_left
        rts
left_not_held:
        lda #KEY_UP
        bit ButtonsHeld
        beq up_not_held
        ; switch to the walk right animation and state
        set_metasprite_animation R0, blobby_anim_walk_up
        set_update_func CurrentEntityIndex, blobby_walk_up
        rts
up_not_held:
        lda #KEY_DOWN
        bit ButtonsHeld
        beq down_not_held
        ; switch to the walk right animation and state
        set_metasprite_animation R0, blobby_anim_walk_down
        set_update_func CurrentEntityIndex, blobby_walk_down
        rts
down_not_held:
        set_metasprite_animation R0, blobby_anim_idle
        set_update_func CurrentEntityIndex, blobby_idle
        rts
.endproc

.proc blobby_idle
        jsr walking_acceleration
        ; apply physics normally
        jsr apply_speed
        ldx CurrentEntityIndex
        txa
        sta R1
        lda entity_table + EntityState::MetaSpriteIndex, x
        sta R0
        jsr set_metasprite_pos
        ; check for state changes
        lda #(KEY_RIGHT | KEY_LEFT | KEY_UP | KEY_DOWN)
        bit ButtonsHeld
        beq still_idle
        jsr pick_walk_animation
still_idle:
        rts
.endproc

.proc blobby_walk_right
        jsr walking_acceleration
        ; apply physics normally
        jsr apply_speed
        ldx CurrentEntityIndex
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
        jsr pick_walk_animation
right_not_held:
        rts
.endproc

.proc blobby_walk_left
        jsr walking_acceleration
        ; apply physics normally
        jsr apply_speed
        ldx CurrentEntityIndex
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
        jsr pick_walk_animation
left_not_held:
        rts
.endproc

.proc blobby_walk_up
        jsr walking_acceleration
        ; apply physics normally
        jsr apply_speed
        ldx CurrentEntityIndex
        txa
        sta R1
        lda entity_table + EntityState::MetaSpriteIndex, x
        sta R0
        jsr set_metasprite_pos
        ; check for state changes
        lda #KEY_UP
        bit ButtonsHeld
        bne up_not_held
        ; switch to the idle right animation and state
        jsr pick_walk_animation
up_not_held:
        rts
.endproc

.proc blobby_walk_down
        jsr walking_acceleration
        ; apply physics normally
        jsr apply_speed
        ldx CurrentEntityIndex
        txa
        sta R1
        lda entity_table + EntityState::MetaSpriteIndex, x
        sta R0
        jsr set_metasprite_pos
        ; check for state changes
        lda #KEY_DOWN
        bit ButtonsHeld
        bne down_not_held
        ; switch to the idle right animation and state
        jsr pick_walk_animation
down_not_held:
        rts
.endproc


.endscope

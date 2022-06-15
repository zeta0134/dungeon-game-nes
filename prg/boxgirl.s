        .setcpu "6502"
        .include "boxgirl.inc"
        .include "branch_util.inc"
        .include "collision.inc"
        .include "debug.inc"
        .include "entity.inc"
        .include "far_call.inc"
        .include "kernel.inc"
        .include "map.inc"
        .include "mmc3.inc"
        .include "nes.inc"
        .include "input.inc"
        .include "scrolling.inc"
        .include "sound.inc"
        .include "sprites.inc"
        .include "physics.inc"
        .include "word_util.inc"
        .include "zeropage.inc"

        .segment "RAM"
PlayerHealth: .res 1

        .segment "ENTITIES_A000" ; will eventually move to an AI page
        .include "animations/boxgirl/idle.inc"
        .include "animations/boxgirl/move.inc"
        .include "animations/boxgirl/teleport.inc"
        .include "animations/shadow/flicker.inc"

WALKING_SPEED = 16
WALKING_ACCEL = 2

; because of how this is used by the macro which applies friction,
; this must be a define and not a numeric constant
.define SLIPPERINESS 4

; Reminder: Data only goes up to 5
; Some of these probably need to be global
; ... the entity struct is gonna need to be bigger
; (other musings, etc)
DATA_FLAGS = 0

FLAG_FACING =  %00000001
FACING_LEFT =  %00000001
FACING_RIGHT = %00000000

; mostly performs a whole bunch of one-time setup
; expects the entity position to have been set by whatever did the initial spawning
.proc boxgirl_init
MetaSpriteIndex := R0
        ; First perform standard entity init
        jsr standard_entity_init
        ; If spawning fails, it will leave #$FF in MetaSpriteIndex, which
        ; we can check for here
        lda #$FF
        cmp MetaSpriteIndex
        beq failed_to_spawn

        ; Now perform boxgirl specific setup
        ; First the main animation metasprite
        ldy CurrentEntityIndex
        lda entity_table + EntityState::MetaSpriteIndex, y 
        sta MetaSpriteIndex
        set_metasprite_animation MetaSpriteIndex, boxgirl_anim_idle_right
        
        ; set all flag bits to 0
        sta entity_table + EntityState::Data + DATA_FLAGS, y

        ; player init stuff
        ; TODO: if we don't want health maxed when loading into a new
        ; room, we need to not do that here
        lda #10
        sta PlayerHealth

        ;finally, switch boxgirl to the idle routine
        set_update_func CurrentEntityIndex, boxgirl_idle
        
failed_to_spawn:
        rts
.endproc

JUMP_SPEED = 48
BOUNCE_SPEED = 56

.proc apply_jump
        ldx CurrentEntityIndex
        lda #JUMP_SPEED
        sta entity_table + EntityState::SpeedZ, x
        rts
.endproc

.proc walking_acceleration
        ldx CurrentEntityIndex
check_right:
        lda #KEY_RIGHT
        bit ButtonsHeld
        beq right_not_held
        ; right is held, so accelerate to the +X
        accelerate entity_table + EntityState::SpeedX, #WALKING_ACCEL
        max_speed entity_table + EntityState::SpeedX, #WALKING_SPEED
        ; note: we explicitly skip checking for left, to work around
        ; worn controllers and broken emulators; right wins
        jmp check_up
right_not_held:
check_left:
        lda #KEY_LEFT
        bit ButtonsHeld
        beq left_not_held
        ; left is held, so accelerate to the -X
        accelerate entity_table + EntityState::SpeedX, #(256-WALKING_ACCEL)
        min_speed entity_table + EntityState::SpeedX, #(256-WALKING_SPEED)
        jmp check_up
left_not_held:
        apply_friction entity_table + EntityState::SpeedX, SLIPPERINESS
check_up:
        lda #KEY_UP
        bit ButtonsHeld
        beq up_not_held
        ; up is held, so accelerate to the -Y
        accelerate entity_table + EntityState::SpeedY, #(256-WALKING_ACCEL)
        min_speed entity_table + EntityState::SpeedY, #(256-WALKING_SPEED)
        ; note: we explicitly skip checking for down, to work around
        ; worn controllers and broken emulators; up wins
        jmp done
up_not_held:
check_down:
        lda #KEY_DOWN
        bit ButtonsHeld
        beq down_not_held
        ; down is held, so accelerate to the +Y
        accelerate entity_table + EntityState::SpeedY, #WALKING_ACCEL
        max_speed entity_table + EntityState::SpeedY, #WALKING_SPEED
        jmp done
down_not_held:
        apply_friction entity_table + EntityState::SpeedY, SLIPPERINESS
done:
        rts
.endproc

.proc pick_walk_animation
MetaSpriteIndex := R0
        ldy CurrentEntityIndex
        lda entity_table + EntityState::MetaSpriteIndex, y
        sta MetaSpriteIndex

        lda #KEY_RIGHT
        bit ButtonsHeld
        beq right_not_held
        ; switch to the walk right animation and state
        set_metasprite_animation MetaSpriteIndex, boxgirl_anim_move_right
        set_update_func CurrentEntityIndex, boxgirl_walk_right
        rts
right_not_held:       
        lda #KEY_LEFT
        bit ButtonsHeld
        beq left_not_held
        ; switch to the walk right animation and state
        set_metasprite_animation MetaSpriteIndex, boxgirl_anim_move_left
        set_update_func CurrentEntityIndex, boxgirl_walk_left
        rts
left_not_held:
        lda #KEY_UP
        bit ButtonsHeld
        beq up_not_held
        ; switch to the walk right animation and state
        set_metasprite_animation MetaSpriteIndex, boxgirl_anim_move_up
        set_update_func CurrentEntityIndex, boxgirl_walk_up
        rts
up_not_held:
        lda #KEY_DOWN
        bit ButtonsHeld
        beq down_not_held
        ; switch to the walk right animation and state
        set_metasprite_animation MetaSpriteIndex, boxgirl_anim_move_down
        set_update_func CurrentEntityIndex, boxgirl_walk_down
        rts
down_not_held:
        set_update_func CurrentEntityIndex, boxgirl_idle
        ; pick an idle state based on our most recent walking direction
        ldy CurrentEntityIndex
        entity_check_flag FLAG_FACING
        bne facing_left
facing_right:
        set_metasprite_animation MetaSpriteIndex, boxgirl_anim_idle_right
        rts
facing_left:
        set_metasprite_animation MetaSpriteIndex, boxgirl_anim_idle_left
        rts
.endproc

; we probably want to reorganize the states later, and separate the concept of "facing direction"
; out from everything else, as it results in a lot of tedious duplication. Anyway though, for jumping
; we really just need to check if the player is grounded and set their vertical speed, so let's
; do that.
.proc handle_jump
        ; have we pressed the jump button?
        lda #KEY_A
        bit ButtonsDown
        beq jump_not_pressed
        ; are we currently grounded? (height == 0)
        ldx CurrentEntityIndex
        lda entity_table + EntityState::PositionZ, x
        ora entity_table + EntityState::PositionZ + 1, x
        bne not_grounded
        ; set our upwards velocity immediately; gravity will take
        ; care of the rest
        lda #JUMP_SPEED
        sta entity_table + EntityState::SpeedZ, x
        ; play a jump sfx
        st16 R0, sfx_jump
        jsr play_sfx_pulse2
not_grounded:
jump_not_pressed:
        rts
.endproc


.proc handle_ground_tile
GroundType := R0
CollisionFlags := R1
CollisionHeights := R2
        lda GroundType
        beq done

        cmp #(1 << 2) ; MAGIC NUMBER == SURFACE_EXIT
        bne done
        ; surface exits only trigger when we walk on top of them
        ; we need to ignore a match when are not at ground level
        ; (say, we are walking "behind" this exit)
        
        ldx CurrentEntityIndex
        lda CollisionHeights
        and #$0F
        cmp entity_table + EntityState::GroundLevel, x
        bne done
        
        ; valid tile, valid height, WHOOSH
        jsr handle_teleport
done:
        rts
.endproc

.proc collide_with_bouncy
TargetEntity := R0
EntityIndexA := R4
EntityIndexB := R5
CollisionResult = R6
        ; first off, are we airbourne and moving downwards?
        ldx CurrentEntityIndex
        lda entity_table + EntityState::PositionZ, x
        ora entity_table + EntityState::PositionZ + 1, x
        beq grounded
        lda entity_table + EntityState::SpeedZ, x
        bpl moving_upwards

        lda CurrentEntityIndex
        sta EntityIndexA
        lda #.sizeof(EntityState)
        sta TargetEntity
loop:
        ldx TargetEntity
        lda entity_table + EntityState::CollisionMask, x
        and #COLLISION_GROUP_BOUNCE
        beq entity_finished
check_collision:
        lda TargetEntity
        sta EntityIndexB
        far_call FAR_aabb_standard_vs_standard
        lda CollisionResult
        bne bounce_found
entity_finished:
        lda TargetEntity
        clc
        adc #.sizeof(EntityState)
        bcs no_bounce_found        
        sta TargetEntity
        jmp loop
grounded:
moving_upwards:
no_bounce_found:
        ; do nothing!
        rts
bounce_found:
        ; Tell the entity we bounced on it
        ldx TargetEntity
        lda #COLLISION_GROUP_BOUNCE
        sta entity_table + EntityState::CollisionResponse, x
        ; Give ourselves a higher jump than usual
        ldx CurrentEntityIndex
        lda #BOUNCE_SPEED
        sta entity_table + EntityState::SpeedZ, x
        ; play a jump sfx
        ; TODO: make this a bounce-specific sfx
        st16 R0, sfx_bounce
        jsr play_sfx_pulse2

        ; that is all for now :)

        rts
.endproc

; === States ===

.proc boxgirl_idle
        jsr handle_jump
        jsr walking_acceleration
        ; apply physics normally
        far_call FAR_standard_entity_vertical_acceleration
        far_call FAR_apply_standard_entity_speed
        jsr set_3d_metasprite_pos
        ; check for state changes
        lda #(KEY_RIGHT | KEY_LEFT | KEY_UP | KEY_DOWN)
        bit ButtonsHeld
        beq still_idle
        jsr pick_walk_animation
still_idle:
        ; check for special ground tiles
        far_call FAR_sense_ground
        jsr handle_ground_tile
        debug_color TINT_R | TINT_B
        jsr collide_with_bouncy
        debug_color TINT_R | TINT_G
all_done:
        rts
.endproc

.proc boxgirl_walk_right
        jsr handle_jump
        jsr walking_acceleration
        ; apply physics normally
        far_call FAR_standard_entity_vertical_acceleration
        far_call FAR_apply_standard_entity_speed
        jsr set_3d_metasprite_pos
        ; set our "last facing" bit to the right
        ldy CurrentEntityIndex
        entity_set_flag FLAG_FACING, FACING_RIGHT
        ; check for state changes
        lda #KEY_RIGHT
        bit ButtonsHeld
        bne right_not_held
        ; switch to the idle right animation and state
        jsr pick_walk_animation
right_not_held:
        ; check for special ground tiles
        far_call FAR_sense_ground
        jsr handle_ground_tile
        debug_color TINT_R | TINT_B
        jsr collide_with_bouncy
        debug_color TINT_R | TINT_G
        rts
.endproc

.proc boxgirl_walk_left
        jsr handle_jump
        jsr walking_acceleration
        ; apply physics normally
        far_call FAR_standard_entity_vertical_acceleration
        far_call FAR_apply_standard_entity_speed
        jsr set_3d_metasprite_pos
        ; set our "last facing" bit to the left
        ldy CurrentEntityIndex
        entity_set_flag FLAG_FACING, FACING_LEFT
        ; check for state changes
        lda #KEY_LEFT
        bit ButtonsHeld
        bne left_not_held
        ; switch to the idle right animation and state
        jsr pick_walk_animation
left_not_held:
        ; check for special ground tiles
        far_call FAR_sense_ground
        jsr handle_ground_tile
        debug_color TINT_R | TINT_B
        jsr collide_with_bouncy
        debug_color TINT_R | TINT_G
        rts
.endproc

.proc boxgirl_walk_up
        jsr handle_jump
        jsr walking_acceleration
        ; apply physics normally
        far_call FAR_standard_entity_vertical_acceleration
        far_call FAR_apply_standard_entity_speed
        jsr set_3d_metasprite_pos
        ; check for state changes
        lda #KEY_UP
        bit ButtonsHeld
        bne up_not_held
        ; switch to the idle right animation and state
        jsr pick_walk_animation
up_not_held:
        ; check for special ground tiles
        far_call FAR_sense_ground
        jsr handle_ground_tile
        debug_color TINT_R | TINT_B
        jsr collide_with_bouncy
        debug_color TINT_R | TINT_G
        rts
.endproc

.proc boxgirl_walk_down
        jsr handle_jump
        jsr walking_acceleration
        ; apply physics normally
        far_call FAR_standard_entity_vertical_acceleration
        far_call FAR_apply_standard_entity_speed
        jsr set_3d_metasprite_pos
        ; check for state changes
        lda #KEY_DOWN
        bit ButtonsHeld
        bne down_not_held
        ; switch to the idle right animation and state
        jsr pick_walk_animation
down_not_held:
        ; check for special ground tiles
        far_call FAR_sense_ground
        jsr handle_ground_tile
        debug_color TINT_R | TINT_B
        jsr collide_with_bouncy
        debug_color TINT_R | TINT_G
        rts
.endproc

.proc boxgirl_teleport
        ; freeze position, and rise into the air
        ldx CurrentEntityIndex
        lda entity_table + EntityState::SpeedZ, x
        sta R0
        sadd16x entity_table + EntityState::PositionZ, R0
        lda entity_table + EntityState::SpeedZ, x
        adc #10
        bmi no_store
        sta entity_table + EntityState::SpeedZ, x
no_store:
        jsr set_3d_metasprite_pos        

        rts
.endproc

; === Weird stuff that needs to be fixed below === 
; TODO: does all of this need to be in fixed? Surely there's a critical bit of it
; and the rest can go in a banked handler

        .segment "PRGFIXED_E000"
; Note: this needs to bank in the map header, so it lives in fixed memory
.proc handle_teleport
MapAddr := R0
TestPosX := R5
TestTileX := R6
TestPosY := R7
TestTileY := R8
ExitTableAddr := R9
MetaSpriteIndex := R11
        ; helpfully our scratch registers are still set from the physics function,
        ; so we don't need to re-do the lookup here
        
        ; The target registers are our currently loaded map. Use these to locate the
        ; map header
        access_data_bank TargetMapBank
        lda TargetMapAddr
        sta MapAddr
        lda TargetMapAddr+1
        sta MapAddr+1

        ldy #MapHeader::exit_table_ptr
        lda (MapAddr), y
        sta ExitTableAddr
        iny
        lda (MapAddr), y
        sta ExitTableAddr+1


        ; loop through all the exits, stopping if we find a match for our current tile position
        ldy #0
        lda (ExitTableAddr), y ; length byte
        inc16 ExitTableAddr
        jeq done ; sanity check, can't leave a map with no exits defined
        tax ; x is otherwise unused, so it is our counter
loop:
        ldy #ExitTableEntry::tile_x
        lda (ExitTableAddr), y
        cmp TestTileX
        jne no_match
        ldy #ExitTableEntry::tile_y
        lda (ExitTableAddr), y
        cmp TestTileY
        jne no_match

        ; MATCH FOUND (!!!)

        ; Set these map details as our new target map
        ldy #ExitTableEntry::target_map
        lda (ExitTableAddr), y
        sta TargetMapAddr
        ldy #ExitTableEntry::target_map+1
        lda (ExitTableAddr), y
        sta TargetMapAddr+1
        ldy #ExitTableEntry::target_bank
        lda (ExitTableAddr), y
        sta TargetMapBank
        ldy #ExitTableEntry::target_entrance
        lda (ExitTableAddr), y
        sta TargetMapEntrance

        ; Set the new game mode to "load a new map"
        st16 GameMode, blackout_to_new_map

        ; play a nifty "whoosh" sfx
        st16 R0, sfx_teleport
        jsr play_sfx_pulse2

        ; now that we are done with the map, we need to be in our own
        ; bank to manipulate animations, so do that
        restore_previous_bank

        ; switch boxgirl to the teleport state and animation
        ldx CurrentEntityIndex
        lda #0
        sta entity_table + EntityState::SpeedZ, x
        lda entity_table + EntityState::MetaSpriteIndex, x
        sta MetaSpriteIndex
        set_metasprite_animation MetaSpriteIndex, boxgirl_anim_teleport
        set_update_func CurrentEntityIndex, boxgirl_teleport

        ; cleanup and let the kernel handle the rest
        rts

no_match:
        clc
        add16 ExitTableAddr, #.sizeof(ExitTableEntry)
        dex
        jne loop
        ; we did NOT find a valid exit. Do nothing!
done:
        restore_previous_bank
        rts
.endproc


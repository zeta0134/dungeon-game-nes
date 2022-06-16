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
PlayerInvulnerability: .res 1
PlayerPrimaryDirection: .res 1

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
        lda #20
        sta PlayerHealth
        lda #0
        sta PlayerInvulnerability
        sta PlayerPrimaryDirection

        ; default to right-facing for now
        ; (todo: pick a direction based on how we entered the map)
        ldy CurrentEntityIndex
        entity_set_flag FLAG_FACING, FACING_RIGHT

        ;finally, switch boxgirl to the idle routine
        set_update_func CurrentEntityIndex, boxgirl_standard
        
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
        lda PlayerPrimaryDirection
        bit ButtonsHeld
        beq old_direction_no_longer_held
        ; keep our current animation, it's fine
        rts
old_direction_no_longer_held:
        ldy CurrentEntityIndex
        lda entity_table + EntityState::MetaSpriteIndex, y
        sta MetaSpriteIndex

        lda #KEY_RIGHT
        bit ButtonsHeld
        beq right_not_held
        ; switch to the walk right animation and state
        set_metasprite_animation MetaSpriteIndex, boxgirl_anim_move_right
        lda #KEY_RIGHT
        sta PlayerPrimaryDirection
        ldy CurrentEntityIndex
        entity_set_flag FLAG_FACING, FACING_RIGHT
        rts
right_not_held:       
        lda #KEY_LEFT
        bit ButtonsHeld
        beq left_not_held
        ; switch to the walk right animation and state
        set_metasprite_animation MetaSpriteIndex, boxgirl_anim_move_left
        lda #KEY_LEFT
        sta PlayerPrimaryDirection
        ldy CurrentEntityIndex
        entity_set_flag FLAG_FACING, FACING_LEFT
        rts
left_not_held:
        lda #KEY_UP
        bit ButtonsHeld
        beq up_not_held
        ; switch to the walk right animation and state
        set_metasprite_animation MetaSpriteIndex, boxgirl_anim_move_up
        lda #KEY_UP
        sta PlayerPrimaryDirection
        rts
up_not_held:
        lda #KEY_DOWN
        bit ButtonsHeld
        beq down_not_held
        ; switch to the walk right animation and state
        set_metasprite_animation MetaSpriteIndex, boxgirl_anim_move_down
        lda #KEY_DOWN
        sta PlayerPrimaryDirection
        rts
down_not_held:
        lda #0 ; for idle, sure
        sta PlayerPrimaryDirection

        ; pick an idle animation based on our most recent walking direction
        ; (TODO: have an idle animation for all 4 cardinal directions, so we
        ; don't have to cheat like this)
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

.proc handle_bounce
TargetEntity := R0
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
        rts
.endproc

.proc knockback
TargetEntity := R0
DistanceX := R1
DistanceY := R3
SignBits := R5
        lda #0
        sta SignBits
        ldx CurrentEntityIndex
        ldy TargetEntity
        ; first, compute the raw distance between us and the thing we hit
        sec
        lda entity_table + EntityState::PositionX, x
        sbc entity_table + EntityState::PositionX, y
        sta DistanceX
        lda entity_table + EntityState::PositionX+1, x
        sbc entity_table + EntityState::PositionX+1, y
        sta DistanceX+1
        sec
        lda entity_table + EntityState::PositionY, x
        sbc entity_table + EntityState::PositionY, y
        sta DistanceY
        lda entity_table + EntityState::PositionY+1, x
        sbc entity_table + EntityState::PositionY+1, y
        sta DistanceY+1
        ; compute absolute(ish) distance, and retain the sign bits
        lda DistanceX+1
        rol
        rol SignBits
        lda DistanceX+1
        bpl no_sign_adj_x
        eor #$FF
        sta DistanceX+1
        lda DistanceX
        eor #$FF
        sta DistanceX
no_sign_adj_x:
        lda DistanceY+1
        rol
        rol SignBits
        lda DistanceY+1
        bpl no_sign_adj_y
        eor #$FF
        sta DistanceY+1
        lda DistanceY
        eor #$FF
        sta DistanceY
no_sign_adj_y:
        ; now normalize that distance; first shift to the right until we empty the
        ; high byte
decrease_loop:
        lda DistanceX+1
        ora DistanceY+1
        beq high_byte_empty
        lsr DistanceX+1
        ror DistanceX
        lsr DistanceY+1
        ror DistanceY
        jmp decrease_loop
high_byte_empty:
        ; now, shift to the left until either of the two lower bytes has a 1 in
        ; bit 7
        lda DistanceX
        ora DistanceY
        ; sanity check here: if both bytes are zero, we special case
        beq exact_position_match
        ; if the result is negative, we're done with the loop
        bmi normalized
        ; otherwise, shift to the left
        asl DistanceX
        asl DistanceY
        jmp high_byte_empty
exact_position_match:
        ; prefer to move straight down, in this case only
        lda #$80
        sta DistanceY
normalized:
        ; at this point, one of our coordinate bytes specifies +8 - +15,
        ; and the other is around this value or less. This is actually too fast,
        ; so shift to the right by 2 to put it in a sane range (+/- 1px or so, max)
        lsr DistanceX
        lsr DistanceX
        lsr DistanceX
        lsr DistanceY
        lsr DistanceY
        lsr DistanceY
        ; Now re-apply the sign bits
        ror SignBits
        bcc no_y_fix
        lda DistanceY
        eor #$FF
        sta DistanceY
no_y_fix:
        ror SignBits
        bcc no_x_fix
        lda DistanceX
        eor #$FF
        sta DistanceX
no_x_fix:
        ; Finally, apply this as our new entity speed
        lda DistanceX
        sta entity_table + EntityState::SpeedX, x
        lda DistanceY
        sta entity_table + EntityState::SpeedY, x
        rts
.endproc

.proc handle_damage
TargetEntity := R0
        dec PlayerHealth
        beq already_on_charons_boat
        ; was this a strong hit?
        ldx TargetEntity
        lda entity_table + EntityState::CollisionMask, x
        and #COLLISION_GROUP_STRONGHIT
        beq weak_hit
        dec PlayerHealth
        beq already_on_charons_boat
weak_hit:
        lda #0
        sta PlayerInvulnerability
        jsr knockback
        rts
already_on_charons_boat:
        ; we died! Oops!
        ; For now, do nothing. "God Mode, Activate!"
        lda #20
        sta PlayerHealth
        ; TODO: transition to the death state, setup reloading from the last checkpoint, etc
        rts
.endproc

.proc collide_with_entities
TargetEntity := R0
EntityIndexA := R4
EntityIndexB := R5
CollisionResult = R6
        ; Bounce targets take the highest priority.
        ; First off, are we airbourne and moving downwards?
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
bounce_loop:
        ldx TargetEntity
        lda entity_table + EntityState::CollisionMask, x
        and #COLLISION_GROUP_BOUNCE
        beq bounce_entity_finished
        ; check_collision
        lda TargetEntity
        sta EntityIndexB
        far_call FAR_aabb_standard_vs_standard
        lda CollisionResult
        bne bounce_found
bounce_entity_finished:
        lda TargetEntity
        clc
        adc #.sizeof(EntityState)
        bcs no_bounce_found        
        sta TargetEntity
        jmp bounce_loop
bounce_found:
        jsr handle_bounce
        ; since we collided with an entity on this frame, STOP HERE.
        ; Do not process any more entities.
        rts
grounded:
moving_upwards:
no_bounce_found:
        ; If we didn't find any bouncy entities, proceed to check for damaging ones, UNLESS
        ; we are currently invulnerable
        lda PlayerInvulnerability
        bne no_damaging_entities_found

        lda CurrentEntityIndex
        sta EntityIndexA
        lda #.sizeof(EntityState)
        sta TargetEntity
damage_loop:
        ldx TargetEntity
        lda entity_table + EntityState::CollisionMask, x
        and #COLLISION_GROUP_DAMAGING
        beq damage_entity_finished
        ; check_collision
        lda TargetEntity
        sta EntityIndexB
        far_call FAR_aabb_standard_vs_standard
        lda CollisionResult
        bne damaging_entity_found
damage_entity_finished:
        lda TargetEntity
        clc
        adc #.sizeof(EntityState)
        bcs no_damaging_entities_found        
        sta TargetEntity
        jmp damage_loop
damaging_entity_found:
        ; Ouch! Okay, deal damage to ourselves
        jsr handle_damage
        ; since we collided with an entity on this frame, STOP HERE.
        ; Do not process any more entities.
        rts
no_damaging_entities_found:
        ; For now, that is all of the supported Player vs. Entity collisions
        rts
.endproc

; === States ===

.proc boxgirl_standard
        jsr handle_jump
        jsr walking_acceleration
        ; apply physics normally
        far_call FAR_standard_entity_vertical_acceleration
        far_call FAR_apply_standard_entity_speed
        jsr set_3d_metasprite_pos
        jsr pick_walk_animation
        ; check for special ground tiles
        far_call FAR_sense_ground
        jsr handle_ground_tile
        debug_color TINT_R | TINT_B
        jsr collide_with_entities
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


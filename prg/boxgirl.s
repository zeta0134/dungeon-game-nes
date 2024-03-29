        .setcpu "6502"
        .include "actions.inc"
        .include "bhop/bhop.inc"
        .include "boxgirl.inc"
        .include "branch_util.inc"
        .include "camera.inc"
        .include "collision.inc"
        .include "debug.inc"
        .include "entity.inc"
        .include "event_queue.inc"
        .include "far_call.inc"
        .include "generators.inc"
        .include "kernel.inc"
        .include "map.inc"
        .include "mmc3.inc"
        .include "nes.inc"
        .include "input.inc"
        .include "saves.inc"
        .include "scrolling.inc"
        .include "sound.inc"
        .include "sprites.inc"
        .include "palette.inc"
        .include "particles.inc"
        .include "physics.inc"
        .include "prng.inc"
        .include "word_util.inc"
        .include "zeropage.inc"

        .segment "RAM"
PlayerInvulnerability: .res 1
PlayerStunTimer: .res 1
PlayerDashTimer: .res 1
PlayerPrimaryDirection: .res 1
PlayerLastFacing: .res 1
CoyoteTime: .res 1

PlayerSafeTileX: .res 1
PlayerSafeTileY: .res 1
PlayerSafeTileGroundLevel: .res 1
PlayerLastGroundTile: .res 1

ParticleCooldown: .res 1

PlayerDashInitialSpeed: .res 1
PlayerDashDuration: .res 1

        .segment "SPRITES_A000" ; will eventually move to an animation page

        .include "animations/boxgirl/idle.inc"
        .include "animations/boxgirl/move.inc"
        .include "animations/boxgirl/swim.inc"
        .include "animations/boxgirl/underwater.inc"
        .include "animations/boxgirl/teleport.inc"
        .include "animations/shadow/flicker.inc"

WALKING_SPEED = 16
WALKING_ACCEL = 3
SLIPPERINESS = 3

SWIMMING_SPEED = 12
SWIMMING_ACCEL = 1
SWIMMING_DRAG = 3

JUMP_SPEED = 48
DOUBLE_JUMP_SPEED = 48
BOUNCE_SPEED = 56

DASH_INITIAL_SPEED = 30 ; dashes perform 4 steps per frame
DASH_DECELERATION = 5 ; deceleration is applied once per frame
DASH_DURATION = 10
DASH_UPWARD_RISE = 4

COYOTE_TIME = 3

UNDERWATER_DASH_INITIAL_SPEED = 20
UNDERWATER_DASH_DURATION = 20


; Reminder: Data only goes up to 5
; Some of these probably need to be global
; ... the entity struct is gonna need to be bigger
; (other musings, etc)
DATA_FLAGS = 0

FLAG_JUMP =        %00000001
FLAG_DOUBLE_JUMP = %00000010
FLAG_DASH =        %00000100
FLAG_DOUBLE_DASH = %00001000

.segment "ENTITIES_A000"

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
        jeq failed_to_spawn

        ; Now perform boxgirl specific setup
        ; First the main animation metasprite
        ldy CurrentEntityIndex
        lda entity_table + EntityState::MetaSpriteIndex, y 
        sta MetaSpriteIndex
        set_metasprite_animation MetaSpriteIndex, boxgirl_anim_idle_right
        
        ; set all flag bits to 0
        lda #0
        sta entity_table + EntityState::Data + DATA_FLAGS, y

        ; player init stuff
        ; TODO: if we don't want health maxed when loading into a new
        ; room, we need to not do that here
        lda working_save + SaveFile::PlayerHealthMax
        sta working_save + SaveFile::PlayerHealthCurrent
        lda #0
        sta PlayerInvulnerability
        sta PlayerPrimaryDirection
        lda #COYOTE_TIME
        sta CoyoteTime
        lda #1
        sta ParticleCooldown

        ; default to east-facing for now
        ; (todo: pick a direction based on how we entered the map)
        lda #KEY_RIGHT
        sta PlayerLastFacing

        ; We spawned here, so it must be a safe tile
        lda entity_table + EntityState::PositionX+1, y
        sta PlayerSafeTileX
        lda entity_table + EntityState::PositionY+1, y
        sta PlayerSafeTileY
        lda entity_table + EntityState::GroundLevel, y
        sta PlayerSafeTileGroundLevel

        jsr init_world_physics

        ;finally, switch boxgirl to the idle routine
        jsr go_to_standard_locomotion
        
failed_to_spawn:
        rts
.endproc

.proc init_world_physics
        lda CurrentDistortion
        cmp #DISTORTION_UNDERWATER
        beq underwater_physics

standard_physics:
        ; TODO: check for underwater mode and adjust accordingly
        lda #STANDARD_GRAVITY_ACCEL
        sta GravityAccel
        lda #STANDARD_TERMINAL_VELOCITY
        sta TerminalVelocity
        lda #DASH_INITIAL_SPEED
        sta PlayerDashInitialSpeed
        lda #DASH_DURATION
        sta PlayerDashDuration
        rts

underwater_physics:
        lda #UNDERWATER_GRAVITY_ACCEL
        sta GravityAccel
        lda #UNDERWATER_TERMINAL_VELOCITY
        sta TerminalVelocity
        lda #UNDERWATER_DASH_INITIAL_SPEED
        sta PlayerDashInitialSpeed
        lda #UNDERWATER_DASH_DURATION
        sta PlayerDashDuration
        rts
.endproc

.proc go_to_standard_locomotion
        lda CurrentDistortion
        cmp #DISTORTION_UNDERWATER
        beq underwater_physics
standard_physics:
        ; TODO: pick the locomotion type based on the map mode
        set_update_func CurrentEntityIndex, boxgirl_standard
        rts
underwater_physics:
        set_update_func CurrentEntityIndex, boxgirl_underwater
        rts
.endproc

.proc update_invulnerability
        ldy CurrentEntityIndex
        ldx entity_table + EntityState::MetaSpriteIndex, y
        lda PlayerInvulnerability
        beq done
        dec PlayerInvulnerability
        metasprite_set_flag FLAG_FLICKERING, FLICKER_ACTIVE
        rts
done:
        metasprite_set_flag FLAG_FLICKERING, FLICKER_INACTIVE
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
        apply_friction entity_table + EntityState::SpeedX, ::SLIPPERINESS
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
        apply_friction entity_table + EntityState::SpeedY, ::SLIPPERINESS
done:
        rts
.endproc

.proc swimming_acceleration
        ldx CurrentEntityIndex
check_right:
        lda #KEY_RIGHT
        bit ButtonsHeld
        beq right_not_held
        ; right is held, so accelerate to the +X
        accelerate entity_table + EntityState::SpeedX, #SWIMMING_ACCEL
        max_speed entity_table + EntityState::SpeedX, #SWIMMING_SPEED
        ; note: we explicitly skip checking for left, to work around
        ; worn controllers and broken emulators; right wins
        jmp check_up
right_not_held:
check_left:
        lda #KEY_LEFT
        bit ButtonsHeld
        beq left_not_held
        ; left is held, so accelerate to the -X
        accelerate entity_table + EntityState::SpeedX, #(256-SWIMMING_ACCEL)
        min_speed entity_table + EntityState::SpeedX, #(256-SWIMMING_SPEED)
        jmp check_up
left_not_held:
        ; friction doesn't go high enough to feel right when swimming, we want
        ; EVEN LESS of it, so only apply friction every few frames or so
        lda GameloopCounter
        and #%00000011
        bne check_up
        apply_friction entity_table + EntityState::SpeedX, ::SWIMMING_DRAG
check_up:
        lda #KEY_UP
        bit ButtonsHeld
        beq up_not_held
        ; up is held, so accelerate to the -Y
        accelerate entity_table + EntityState::SpeedY, #(256-SWIMMING_ACCEL)
        min_speed entity_table + EntityState::SpeedY, #(256-SWIMMING_SPEED)
        ; note: we explicitly skip checking for down, to work around
        ; worn controllers and broken emulators; up wins
        jmp done
up_not_held:
check_down:
        lda #KEY_DOWN
        bit ButtonsHeld
        beq down_not_held
        ; down is held, so accelerate to the +Y
        accelerate entity_table + EntityState::SpeedY, #SWIMMING_ACCEL
        max_speed entity_table + EntityState::SpeedY, #SWIMMING_SPEED
        jmp done
down_not_held:
        ; friction doesn't go high enough to feel right when swimming, we want
        ; EVEN LESS of it, so only apply friction every few frames or so
        lda GameloopCounter
        and #%00000011
        bne done
        apply_friction entity_table + EntityState::SpeedY, ::SWIMMING_DRAG
done:
        rts
.endproc

; TODO: We have this pattern repeated at least 3 times, and will almost certainly
; be doing it more. Can we work this into a common function and pass in a pointer
; to a table, for selecting the animation from? That way any time we need a cardinal
; variant of some state, we've got it covered
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
        sta PlayerLastFacing
        rts
right_not_held:       
        lda #KEY_LEFT
        bit ButtonsHeld
        beq left_not_held
        ; switch to the walk right animation and state
        set_metasprite_animation MetaSpriteIndex, boxgirl_anim_move_left
        lda #KEY_LEFT
        sta PlayerPrimaryDirection
        sta PlayerLastFacing
        rts
left_not_held:
        lda #KEY_UP
        bit ButtonsHeld
        beq up_not_held
        ; switch to the walk right animation and state
        set_metasprite_animation MetaSpriteIndex, boxgirl_anim_move_up
        lda #KEY_UP
        sta PlayerPrimaryDirection
        sta PlayerLastFacing
        rts
up_not_held:
        lda #KEY_DOWN
        bit ButtonsHeld
        beq down_not_held
        ; switch to the walk right animation and state
        set_metasprite_animation MetaSpriteIndex, boxgirl_anim_move_down
        lda #KEY_DOWN
        sta PlayerPrimaryDirection
        sta PlayerLastFacing
        rts
down_not_held:
        lda #0 ; for idle, sure
        sta PlayerPrimaryDirection
        ;  note: do NOT clear PlayerLastFacing

        ; pick an idle animation based on our most recent walking direction
        lda PlayerLastFacing
check_north:
        cmp #KEY_UP
        bne check_east
        set_metasprite_animation MetaSpriteIndex, boxgirl_anim_idle_up
        rts

check_east:
        cmp #KEY_RIGHT
        bne check_south
        set_metasprite_animation MetaSpriteIndex, boxgirl_anim_idle_right
        rts

check_south:
        cmp #KEY_DOWN
        bne must_be_west
        set_metasprite_animation MetaSpriteIndex, boxgirl_anim_idle_down
        rts

must_be_west:
        set_metasprite_animation MetaSpriteIndex, boxgirl_anim_idle_left
        rts
.endproc

.proc pick_swim_animation
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
        set_metasprite_animation MetaSpriteIndex, boxgirl_anim_swim_right
        lda #KEY_RIGHT
        sta PlayerPrimaryDirection
        sta PlayerLastFacing
        rts
right_not_held:       
        lda #KEY_LEFT
        bit ButtonsHeld
        beq left_not_held
        ; switch to the walk right animation and state
        set_metasprite_animation MetaSpriteIndex, boxgirl_anim_swim_left
        lda #KEY_LEFT
        sta PlayerPrimaryDirection
        sta PlayerLastFacing
        rts
left_not_held:
        lda #KEY_UP
        bit ButtonsHeld
        beq up_not_held
        ; switch to the walk right animation and state
        set_metasprite_animation MetaSpriteIndex, boxgirl_anim_swim_up
        lda #KEY_UP
        sta PlayerPrimaryDirection
        sta PlayerLastFacing
        rts
up_not_held:
        lda #KEY_DOWN
        bit ButtonsHeld
        beq down_not_held
        ; switch to the walk right animation and state
        set_metasprite_animation MetaSpriteIndex, boxgirl_anim_swim_down
        lda #KEY_DOWN
        sta PlayerPrimaryDirection
        sta PlayerLastFacing
        rts
down_not_held:
        lda #0 ; for idle, sure
        sta PlayerPrimaryDirection
        ;  note: do NOT clear PlayerLastFacing

        ; pick an idle animation based on our most recent swimming direction
        lda PlayerLastFacing
check_north:
        cmp #KEY_UP
        bne check_east
        set_metasprite_animation MetaSpriteIndex, boxgirl_anim_swim_up
        rts

check_east:
        cmp #KEY_RIGHT
        bne check_south
        set_metasprite_animation MetaSpriteIndex, boxgirl_anim_swim_right
        rts

check_south:
        cmp #KEY_DOWN
        bne must_be_west
        set_metasprite_animation MetaSpriteIndex, boxgirl_anim_swim_down
        rts

must_be_west:
        set_metasprite_animation MetaSpriteIndex, boxgirl_anim_swim_left
        rts
.endproc

.proc pick_underwater_animation
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
        set_metasprite_animation MetaSpriteIndex, boxgirl_anim_underwater_right
        lda #KEY_RIGHT
        sta PlayerPrimaryDirection
        sta PlayerLastFacing
        rts
right_not_held:       
        lda #KEY_LEFT
        bit ButtonsHeld
        beq left_not_held
        ; switch to the walk right animation and state
        set_metasprite_animation MetaSpriteIndex, boxgirl_anim_underwater_left
        lda #KEY_LEFT
        sta PlayerPrimaryDirection
        sta PlayerLastFacing
        rts
left_not_held:
        lda #KEY_UP
        bit ButtonsHeld
        beq up_not_held
        ; switch to the walk right animation and state
        set_metasprite_animation MetaSpriteIndex, boxgirl_anim_underwater_up
        lda #KEY_UP
        sta PlayerPrimaryDirection
        sta PlayerLastFacing
        rts
up_not_held:
        lda #KEY_DOWN
        bit ButtonsHeld
        beq down_not_held
        ; switch to the walk right animation and state
        set_metasprite_animation MetaSpriteIndex, boxgirl_anim_underwater_down
        lda #KEY_DOWN
        sta PlayerPrimaryDirection
        sta PlayerLastFacing
        rts
down_not_held:
        lda #0 ; for idle, sure
        sta PlayerPrimaryDirection
        ;  note: do NOT clear PlayerLastFacing

        ; pick an idle animation based on our most recent swimming direction
        lda PlayerLastFacing
check_north:
        cmp #KEY_UP
        bne check_east
        set_metasprite_animation MetaSpriteIndex, boxgirl_anim_underwater_up
        rts

check_east:
        cmp #KEY_RIGHT
        bne check_south
        set_metasprite_animation MetaSpriteIndex, boxgirl_anim_underwater_right
        rts

check_south:
        cmp #KEY_DOWN
        bne must_be_west
        set_metasprite_animation MetaSpriteIndex, boxgirl_anim_underwater_down
        rts

must_be_west:
        set_metasprite_animation MetaSpriteIndex, boxgirl_anim_underwater_left
        rts
.endproc

; certain things need to happen whenever we make contact with the ground.
; these are those things
.proc handle_ground_contact
        ; are we currently grounded?
        ldx CurrentEntityIndex
        lda entity_table + EntityState::RampHeight, x
        bne ramp_contact_check
standard_contact_check:
        lda entity_table + EntityState::PositionZ, x
        ora entity_table + EntityState::PositionZ + 1, x
        bne not_grounded
        jmp grounded
ramp_contact_check:
        far_call FAR_compute_ramp_height
        ; Now compare against the Z coordinate
        lda RampGroundHeight+1
        cmp entity_table + EntityState::PositionZ+1, x
        bne check_if_below_ramp
        lda RampGroundHeight
        cmp entity_table + EntityState::PositionZ, x
check_if_below_ramp:
        bcc not_grounded

grounded:
        ; we are grounded; reset abilities which restore on landing
        entity_set_flag_x (FLAG_JUMP | FLAG_DOUBLE_JUMP | FLAG_DASH | FLAG_DOUBLE_DASH), (FLAG_JUMP | FLAG_DOUBLE_JUMP | FLAG_DASH | FLAG_DOUBLE_DASH)
        ; if CoyoteTime is any value other than its max, we were off the ground on the previous frame.
        lda CoyoteTime
        cmp #COYOTE_TIME
        beq no_landing
        ; Play a landing sound, to signal
        ; that landing-based abilities are now recharged
        st16 R0, sfx_landing
        jsr play_sfx_pulse1
        ldx CurrentEntityIndex ; clobbered by play_sfx
no_landing:
        ; reset coyote time as well
        lda #COYOTE_TIME
        sta CoyoteTime
        jmp done
not_grounded:
        lda CoyoteTime
        beq done
        dec CoyoteTime
        bne done
        ; coyote time has expired. Whether we have jumped or not, disable the first jump flag
        entity_set_flag_x FLAG_JUMP, 0
done:
        rts
.endproc

.proc handle_jump
        ldx CurrentEntityIndex
        ; have we pressed the jump button?
        if_action_down ::ACTION_JUMP
        beq jump_not_pressed
        ; may we single jump?
        entity_check_flag_x FLAG_JUMP
        beq check_double_jump
        ; nifty, apply a single jump:
        lda #JUMP_SPEED
        sta entity_table + EntityState::SpeedZ, x
        ; clear the JUMP flag
        entity_set_flag_x FLAG_JUMP, 0
        ; play a jump sfx
        st16 R0, sfx_jump
        jsr play_sfx_pulse1
        ; and done
        rts
check_double_jump:
        ; may we double jump?
        entity_check_flag_x FLAG_DOUBLE_JUMP
        beq jump_not_pressed
        ; nifty, apply a single jump:
        lda #DOUBLE_JUMP_SPEED
        sta entity_table + EntityState::SpeedZ, x
        ; clear the JUMP flag
        entity_set_flag_x FLAG_DOUBLE_JUMP, 0
        ; play a jump sfx
        st16 R0, sfx_double_jump
        jsr play_sfx_pulse1
        ; and done
jump_not_pressed:
        rts
.endproc

.proc initiate_dash
        ; note: relies on CurrentEntityIndex already being in X
        ; pick a dash direction based on our last cardinal facing
check_right:
        lda PlayerLastFacing
        cmp #KEY_RIGHT
        bne check_left

        ; Dash to the right!
        lda PlayerDashInitialSpeed
        sta entity_table + EntityState::SpeedX, x
        lda #0
        sta entity_table + EntityState::SpeedY, x
        ; TODO: switch to an appropriate dashing animation
        ; (we don't have one at the moment)
        jmp converge

check_left:
        lda PlayerLastFacing
        cmp #KEY_LEFT
        bne check_up

        ; Dash to the left!
        lda #$FF
        sec
        sbc PlayerDashInitialSpeed
        sta entity_table + EntityState::SpeedX, x
        lda #0
        sta entity_table + EntityState::SpeedY, x
        ; TODO: switch to an appropriate dashing animation
        ; (we don't have one at the moment)
        jmp converge

check_up:
        lda PlayerLastFacing
        cmp #KEY_UP
        bne check_down

        ; Dash upwards!
        lda #0
        sta entity_table + EntityState::SpeedX, x
        lda #$FF
        sec
        sbc PlayerDashInitialSpeed
        sta entity_table + EntityState::SpeedY, x
        ; TODO: switch to an appropriate dashing animation
        ; (we don't have one at the moment)
        jmp converge

check_down:
        lda PlayerLastFacing
        cmp #KEY_DOWN
        bne no_match

        ; Dash downwards!
        lda #0
        sta entity_table + EntityState::SpeedX, x
        lda PlayerDashInitialSpeed
        sta entity_table + EntityState::SpeedY, x
        ; TODO: switch to an appropriate dashing animation
        ; (we don't have one at the moment)
        jmp converge

no_match:
        ; huh? how did we get here? play an ERROR sound
        ; TODO: except that's a "jump" sound
        
        st16 R0, sfx_error_buzz
        jsr play_sfx_noise
        rts

converge:
        ; all dashes raise the player up in the air just slightly; this is mostly to help with chaining dashes
        ; at "ground level" onto platforms across chasms. The upward rise gives a tiny bit of wiggle room
        ; before bad timing will clonk into the opposing wall.
        ldx CurrentEntityIndex ; probably clobbered by picking an animation
        lda #DASH_UPWARD_RISE
        sta entity_table + EntityState::SpeedZ

        lda PlayerDashDuration
        sta PlayerDashTimer

        set_update_func CurrentEntityIndex, boxgirl_dashing

        ; play the dash SFX
        st16 R0, sfx_dash_pulse
        jsr play_sfx_pulse1
        st16 R0, sfx_dash_noise
        jsr play_sfx_noise

        ; Apply some screen shake
        ; (Warning: very powerful! Use responsibly)
        lda #$01
        sta CameraShakeSpeed
        lda #%00000111
        sta CameraShakeStrength
        lda #$2
        sta CameraShakeDecay
        
        rts
.endproc

.proc handle_dash
        ldx CurrentEntityIndex
        ; have we pressed the dash button?
        if_action_down ::ACTION_DASH
        beq dash_not_pressed
        ; may we dash?
        entity_check_flag_x FLAG_DASH
        beq check_double_dash
        ; first, consume the dash flag
        entity_set_flag_x FLAG_DASH, 0
        ; now, apply our dash (this will change our next state)
        jsr initiate_dash
        ; and done
        rts
check_double_dash:
        ; may we double dash?
        entity_check_flag_x FLAG_DOUBLE_DASH
        beq dash_not_pressed
        ; first consume the dash flag
        entity_set_flag_x FLAG_DOUBLE_DASH, 0
        ; now apply our dash (this will change our next state)
        jsr initiate_dash
        ; and done
        rts
dash_not_pressed:
        rts
.endproc

.proc handle_ground_tile
GroundType := R0
CollisionFlags := R1
CollisionHeights := R2
SensedTileX := R6
SensedTileY := R8
        lda GroundType
        sta PlayerLastGroundTile
        jeq safe_tile

        ; special tiles only trigger when we walk on top of them
        ; we need to ignore a match when are not at ground level
        ; (say, we are walking "behind" this tile)

        ; Note: this does mean that we are restricting the engine
        ; so that we can't have hazards, teleports, or buttons
        ; "behind" things, hidden from view. I say if we really
        ; need one of these, we can make it a special behavior
        ; separate from the standard one.
        
        ldx CurrentEntityIndex
        lda CollisionHeights
        and #$0F
        cmp entity_table + EntityState::GroundLevel, x
        jne safe_tile

        lda GroundType
check_exit:
        cmp #SURFACE_EXIT
        bne check_rising_hazard
        
        ; valid tile, valid height, WHOOSH
        jsr handle_teleport_tile
        rts
check_rising_hazard:
        cmp #RISING_HAZARD
        bne check_shallow_water
        ; TODO: do we want to allow hitting hazards from behind?
        set_update_func CurrentEntityIndex, boxgirl_rising_hazard_init

        rts
check_shallow_water:
        cmp #SHALLOW_WATER
        bne check_deep_water
        ; TODO: should we allow swimming behind things? (this tends to not look good)
        set_update_func CurrentEntityIndex, boxgirl_swimming
        ; force an animation state update
        lda #0
        sta PlayerPrimaryDirection
        st16 R0, sfx_splash
        jsr play_sfx_noise
        jsr spawn_splash_particles

        ; we've just splashed in water; kill all momentum
        ldx CurrentEntityIndex
        lda #0
        sta entity_table + EntityState::SpeedX, x
        sta entity_table + EntityState::SpeedY, x

        rts
check_deep_water:
        cmp #DEEP_WATER
        bne check_switch
        ; TODO: should we allow swimming behind things? (this tends to not look good)
        set_update_func CurrentEntityIndex, boxgirl_swimming
        ; force an animation state update
        lda #0
        sta PlayerPrimaryDirection
        st16 R0, sfx_splash
        jsr play_sfx_noise
        jsr spawn_splash_particles

        ; we've just splashed in water; kill all momentum
        ldx CurrentEntityIndex
        lda #0
        sta entity_table + EntityState::SpeedX, x
        sta entity_table + EntityState::SpeedY, x

        rts
check_switch:
        cmp #SWITCH_UNPRESSED
        bne safe_tile

        jsr handle_switch_tile
        rts
safe_tile:
        ; only record a safe tile if we are currently on the ground
        ldx CurrentEntityIndex
        lda entity_table + EntityState::PositionZ, x
        ora entity_table + EntityState::PositionZ+1, x
        bne not_safe

        ; record this position as our last safe tile
        lda SensedTileX
        sta PlayerSafeTileX
        lda SensedTileY
        sta PlayerSafeTileY
        ldx CurrentEntityIndex
        lda entity_table + EntityState::GroundLevel, x
        sta PlayerSafeTileGroundLevel

not_safe:
        rts
.endproc

.proc handle_water_tile
GroundType := R0
CollisionFlags := R1
CollisionHeights := R2
SensedTileX := R6
SensedTileY := R8
        lda GroundType
        sta PlayerLastGroundTile

check_still_submerged:
        cmp #SHALLOW_WATER
        beq still_in_water
        cmp #DEEP_WATER
        beq still_in_water

        ; we are no longer in water; emerge to dry ground
        jsr go_to_standard_locomotion
        ; force an animation state update
        lda #0
        sta PlayerPrimaryDirection
        st16 R0, sfx_splash
        jsr play_sfx_noise
        jsr spawn_splash_particles

        ; Give us just a tiny boost of speed, not quite a full jump, to sell the effect
        ; of leaping out of the water
        ldx CurrentEntityIndex
        lda #(JUMP_SPEED >> 1)
        sta entity_table + EntityState::SpeedZ, x


        rts
still_in_water:
        ; just keep swimming...
        rts
.endproc

.proc handle_interactables
GroundType := R0
TileAddr := R3
SensedTileX := R6
SensedTileY := R8
        ; Note: meant to be called after FAR_sense_ground, as it uses those results as a basis
        lda PlayerLastFacing
check_north:
        cmp #KEY_UP
        bne check_east
        dec SensedTileY
         ; safety: if we're < 0, we are out of bounds
        bmi no_interactable
        jmp done_with_direction
check_east:
        cmp #KEY_RIGHT
        bne check_south
        inc SensedTileX
        ; safety: if we are >= MapWidth, we are out of bounds
        lda SensedTileX
        cmp MapWidth
        bcs no_interactable
        jmp done_with_direction
check_south:
        cmp #KEY_DOWN
        bne must_be_west
        inc SensedTileY
         ; safety: if we're >= MapHeight, we are out of bounds
        lda SensedTileY
        cmp MapHeight
        bcs no_interactable
        jmp done_with_direction
must_be_west:
        dec SensedTileX
        ; safety: if we're < 0, we are out of bounds
        bmi no_interactable
done_with_direction:
        graphics_map_index SensedTileX, SensedTileY, TileAddr
        ldy #0
        lda (TileAddr), y
        tay
        lda TilesetAttributes, y ; a now contains combined attribute byte
        and #%11111100 ; strip off the palette
        beq no_interactable ; booooring
        sta GroundType

check_interactable:
        cmp #INTERACTABLE
        bne no_interactable ; currently we ignore anything else we are facing

        ; At this point we're definitely *facing* the interactable element, so
        ; set that flag. This will tell the action system that it should suppress
        ; all inputs for the A button
        lda #1
        sta action_a_button_suppressed
        
        ; Now, if we happen to have just pressed the A button, fire off the appropriate trigger
        lda #KEY_A
        and ButtonsDown
        beq done
        jsr handle_interactable_tile
done:
        rts


no_interactable:
        lda #0
        sta action_a_button_suppressed
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
        jsr play_sfx_pulse1
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

; TODO: simplify this and have it call the standard damage func?
.proc handle_entity_damage
TargetEntity := R0
        ; weak hits do 6 damage, 3 hearts (for testing)
        .repeat 6
        dec working_save + SaveFile::PlayerHealthCurrent
        jeq already_on_charons_boat
        .endrepeat
        ; was this a strong hit?
        ldx TargetEntity
        lda entity_table + EntityState::CollisionMask, x
        and #COLLISION_GROUP_STRONGHIT
        beq weak_hit
        ; strong hits to 6 MORE damage, for 6 hearts total
        .repeat 6
        dec working_save + SaveFile::PlayerHealthCurrent
        jeq already_on_charons_boat
        .endrepeat
weak_hit:
        jsr knockback
        set_update_func CurrentEntityIndex, boxgirl_stunned
        lda #10
        sta PlayerStunTimer

        ; this SFX is so meaty it has multiple components
        st16 R0, sfx_weak_hit_pulse
        jsr play_sfx_pulse1
        st16 R0, sfx_weak_hit_tri
        jsr play_sfx_triangle
        st16 R0, sfx_weak_hit_noise
        jsr play_sfx_noise

        ; hit stun the game engine, for impact
        lda #10
        sta HitstunTimer
        st16 GameMode, hitstun_gameplay_loop
        ; shake the camera while we're at it
        lda #$01
        sta CameraShakeSpeed
        lda #%00000111
        sta CameraShakeStrength
        lda #$1
        sta CameraShakeDecay
        ; Switch our palette over to the red one
        ldx CurrentEntityIndex
        ldy entity_table + EntityState::MetaSpriteIndex, x
        lda metasprite_table + MetaSpriteState::PaletteOffset, y
        and #%11111100
        ora #1
        sta metasprite_table + MetaSpriteState::PaletteOffset, y
        rts
already_on_charons_boat:
        ; we died! Oops!
        set_update_func CurrentEntityIndex, boxgirl_death_init
        ; this is a major event; big old hit stun
        lda #30
        sta HitstunTimer
        st16 GameMode, hitstun_gameplay_loop

        ; play the moral blow sfx
        st16 R0, sfx_mortal_blow_noise
        jsr play_sfx_noise
        st16 R0, sfx_weak_hit_tri
        jsr play_sfx_triangle

        ; TODO: we should mute the music track here, or maybe queue up a death specific one

        rts
.endproc

.proc handle_arbitrary_damage
IncomingDamage := R0
damage_loop:
        dec working_save + SaveFile::PlayerHealthCurrent
        beq already_on_charons_boat
        dec IncomingDamage
        bne damage_loop
        ; if we get here, we're still alive
        rts
already_on_charons_boat:
        ; oops! we died. Well let's get on with that
        set_update_func CurrentEntityIndex, boxgirl_death_init
        ; this is a major event; big old hit stun
        lda #30
        sta HitstunTimer
        st16 GameMode, hitstun_gameplay_loop
        ; play the moral blow sfx
        st16 R0, sfx_mortal_blow_noise
        jsr play_sfx_noise
        st16 R0, sfx_weak_hit_tri
        jsr play_sfx_triangle
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
        jsr handle_entity_damage
        ; since we collided with an entity on this frame, STOP HERE.
        ; Do not process any more entities.
        rts
no_damaging_entities_found:
        ; For now, that is all of the supported Player vs. Entity collisions
        rts
.endproc

.proc handle_dive_action
        ; have we pressed the dive button?
        lda #KEY_B
        bit ButtonsDown
        beq dive_not_pressed
        ; TODO: if diving is guarded by an upgrade, check for that upgrade here

        ; Make boxgirl's sprite vanish 
        ldy CurrentEntityIndex
        lda entity_table + EntityState::MetaSpriteIndex, y
        tax
        metasprite_set_flag FLAG_VISIBILITY, VISIBILITY_HIDDEN

        ; Splash us under the water's surface with appropriate juice
        st16 R0, sfx_splash
        jsr play_sfx_noise
        jsr spawn_splash_particles

        ; TODO: vary this timer if we are over deep water, we probably want a shorter duration
        ; Set the dive (stun) timer to around 2 seconds, and transition us to the diving state
        lda #90
        sta PlayerStunTimer
        set_update_func CurrentEntityIndex, boxgirl_diving

        ; Set our speed to 0 on all axis
        ldx CurrentEntityIndex
        lda #0
        sta entity_table + EntityState::SpeedX, x
        sta entity_table + EntityState::SpeedY, x

        ; TODO: check for a deep water tile here?
        
        ; and done
        rts
dive_not_pressed:
        rts
.endproc

; === States ===

.proc boxgirl_standard
        jsr handle_ground_contact
        jsr walking_acceleration
        ; apply physics normally
        far_call FAR_apply_standard_entity_speed
        far_call FAR_standard_entity_vertical_acceleration
        far_call FAR_apply_ramp_height
        jsr set_3d_metasprite_pos
        jsr pick_walk_animation
        ; check for special ground tiles
        far_call FAR_sense_ground
        jsr handle_ground_tile
        jsr handle_interactables
        debug_color TINT_R | TINT_B
        jsr collide_with_entities
        debug_color TINT_R | TINT_G
        ; check for actions, and trigger behavior accordingly
        jsr handle_jump
        jsr handle_dash
        jsr update_invulnerability

        ; SUBSCREEN STUFF
        ; We can only open the subscreen when no other action buttons are held
        lda #(KEY_A|KEY_B|KEY_SELECT)
        bit ButtonsHeld
        bne no_subscreen
        lda #KEY_START
        bit ButtonsDown
        beq no_subscreen

        ; open the subscreen
        st16 GameMode, subscreen_init
        ; Play a "subscreen opening" sound over the fade
        st16 R0, sfx_open_subscreen_pulse1
        jsr play_sfx_pulse1
        st16 R0, sfx_open_subscreen_pulse2
        jsr play_sfx_pulse2
no_subscreen:
        rts
.endproc

.proc boxgirl_underwater
        jsr handle_ground_contact
        jsr swimming_acceleration
        ; apply physics normally
        far_call FAR_standard_entity_vertical_acceleration
        far_call FAR_apply_ramp_height
        far_call FAR_apply_standard_entity_speed
        jsr set_3d_metasprite_pos
        jsr pick_underwater_animation
        ; check for special ground tiles
        far_call FAR_sense_ground
        jsr handle_ground_tile
        debug_color TINT_R | TINT_B
        jsr collide_with_entities
        debug_color TINT_R | TINT_G
        ; check for actions, and trigger behavior accordingly
        jsr handle_jump
        jsr handle_dash
        jsr update_invulnerability

        ; juice: spawn bubbles occasionally
        jsr spawn_underwater_bubble

        ; SUBSCREEN STUFF
        ; We can only open the subscreen when no other action buttons are held
        lda #(KEY_A|KEY_B|KEY_SELECT)
        bit ButtonsHeld
        bne no_subscreen
        lda #KEY_START
        bit ButtonsDown
        beq no_subscreen

        ; open the subscreen
        st16 GameMode, subscreen_init
        ; Play a "subscreen opening" sound over the fade
        st16 R0, sfx_open_subscreen_pulse1
        jsr play_sfx_pulse1
        st16 R0, sfx_open_subscreen_pulse2
        jsr play_sfx_pulse2
no_subscreen:
        rts
.endproc

.proc boxgirl_swimming
        ; swimming uses different acceleration curves for basic locomotion
        jsr swimming_acceleration
        ; apply physics normally
        far_call FAR_standard_entity_vertical_acceleration
        far_call FAR_apply_standard_entity_speed
        jsr set_3d_metasprite_pos
        jsr pick_swim_animation
        ; check for special water tiles
        far_call FAR_sense_ground
        jsr handle_water_tile
        ; enemies can still hurt us while we're swimming
        debug_color TINT_R | TINT_B
        jsr collide_with_entities
        debug_color TINT_R | TINT_G
        ; check for actions, and trigger behavior accordingly
        ;jsr handle_swim_action
        jsr handle_dive_action
        jsr update_invulnerability

        ; for now, that is all. Notably, swimming will not
        ; activate debug features. Later, swimming actions cannot
        ; be switched out; while swimming you are focused on this task.

        ; (we *could* technically have swimming variations for all actions, but to
        ; avoid scope creep I would like to keep this feature somewhat simple and static.)

        rts
.endproc

.proc boxgirl_diving
        ; since the player is invulnerable while diving, we'll re-use the stun timer to track duration
        lda PlayerStunTimer
        beq done_diving
still_diving:
        dec PlayerStunTimer

        ; since we are invisible, spawn bubbles periodically to signal our position
        ; We can use our stun timer to determine how often to spawn bubbles. Let's do one every
        ; 8 frames for testing
        lda PlayerStunTimer
        and #%00000111
        bne finshed_spawning_bubbles
        jsr spawn_surface_bubble
finshed_spawning_bubbles:
        rts
done_diving:
        ; If we found a valid destination, trigger the map fade now
        far_call FAR_sense_ground
        lda PlayerLastGroundTile
        cmp #DEEP_WATER
        bne surface
        jsr handle_deep_water_teleport
        rts

surface:
        ; Otherwise, we must surface and transition back to the swimming state
        ; Make boxgirl's sprite appear
        ldy CurrentEntityIndex
        lda entity_table + EntityState::MetaSpriteIndex, y
        tax
        metasprite_set_flag FLAG_VISIBILITY, VISIBILITY_DISPLAYED

        lda #0
        sta PlayerPrimaryDirection
        st16 R0, sfx_splash
        jsr play_sfx_noise
        jsr spawn_splash_particles
        set_update_func CurrentEntityIndex, boxgirl_swimming
        rts
.endproc

.proc boxgirl_stunned
        ; ~~Ouch!~~
        ; Are we still hurt?
        lda PlayerStunTimer
        beq done_being_stunned
still_stunned:
        dec PlayerStunTimer
        ; use a RED palette for our damaged state (for now)
        ldx CurrentEntityIndex
        ldy entity_table + EntityState::MetaSpriteIndex, x
        lda metasprite_table + MetaSpriteState::PaletteOffset, y
        and #%11111100
        ora #1
        sta metasprite_table + MetaSpriteState::PaletteOffset, y
        jmp update_ourselves
done_being_stunned:
        ; flip back to our standard palette
        ldx CurrentEntityIndex
        ldy entity_table + EntityState::MetaSpriteIndex, x
        lda metasprite_table + MetaSpriteState::PaletteOffset, y
        and #%11111100
        ora #0
        sta metasprite_table + MetaSpriteState::PaletteOffset, y
        ; Switch back to the standard locomotion state, so the player
        ; regains control on the next frame following this one
        jsr go_to_standard_locomotion
        lda #60
        sta PlayerInvulnerability
        ; now fall through to do standard update things
update_ourselves:
        ; We are stunned; do NOT process player inputs for jumping
        ; or walking acceleration, but DO process physics normally.
        ; we need to manually apply friction
        apply_friction entity_table + EntityState::SpeedX, ::SLIPPERINESS
        apply_friction entity_table + EntityState::SpeedY, ::SLIPPERINESS
        far_call FAR_standard_entity_vertical_acceleration
        far_call FAR_apply_ramp_height
        far_call FAR_apply_standard_entity_speed
        jsr set_3d_metasprite_pos
        ; while stunned, we can't collide with other entities, but we
        ; CAN still interact with standard ground tiles. Some of these
        ; are death planes and what not, so we need to process them.
        far_call FAR_sense_ground
        jsr handle_ground_tile
        ; otherwise, that's it!
        rts
.endproc

.proc boxgirl_teleport
        ; freeze position, and rise into the air
        ldx CurrentEntityIndex

        sadd16 {entity_table + EntityState::PositionZ, x}, {entity_table + EntityState::SpeedZ, x}

        lda entity_table + EntityState::SpeedZ, x
        adc #10
        bmi no_store
        sta entity_table + EntityState::SpeedZ, x
no_store:
        jsr set_3d_metasprite_pos        

        rts
.endproc

.proc boxgirl_rising_hazard_init
        ; TODO: switch to a "hurt" animation

        ; TODO: we could have a custom hurt sfx, since this is a cartoonish
        ; "bounce off the spikes" thing

        ; apply some camera shake (standard for any big hit)
        lda #$01
        sta CameraShakeSpeed
        lda #%00000111
        sta CameraShakeStrength
        lda #$2
        sta CameraShakeDecay

        ; We might fall on a hazard while still invulnerable; this doesn't
        ; negate the hazard. Clear this for now, so the animation doesn't
        ; gain unnecessary flicker.
        lda #0
        sta PlayerInvulnerability
        jsr update_invulnerability

        ; play a standard hurt sfx for now
        st16 R0, sfx_weak_hit_pulse
        jsr play_sfx_pulse1
        st16 R0, sfx_weak_hit_tri
        jsr play_sfx_triangle
        st16 R0, sfx_weak_hit_noise
        jsr play_sfx_noise

        ; set an appropriate stun timer, which determines how long the rising animation will play
        lda #30
        sta PlayerStunTimer

        set_update_func CurrentEntityIndex, boxgirl_rising_hazard_react
.endproc

.proc boxgirl_rising_hazard_react
        ; freeze horizontal position, and rise into the air at a constant speed
        ldx CurrentEntityIndex

        fadd16b {entity_table + EntityState::PositionZ, x}, #$7F

        ; set our palette color to red (for ouchies)
        ldy entity_table + EntityState::MetaSpriteIndex, x
        lda metasprite_table + MetaSpriteState::PaletteOffset, y
        and #%11111100
        ora #1
        sta metasprite_table + MetaSpriteState::PaletteOffset, y
        ; keep this up for a little while
        dec PlayerStunTimer
        bne no_switch
        set_update_func CurrentEntityIndex, boxgirl_hazard_recover_init
no_switch:
        jsr set_3d_metasprite_pos
        ; now for excessive fanciness: fade almost to black, using the stun timer
        ; to decide when to transition
        lda PlayerStunTimer
check_3_threshold:
        cmp #12
        bne check_2_threshold
        lda #3
        sta Brightness
        jmp done_with_fadeout
check_2_threshold:
        cmp #8
        bne check_1_threshold
        lda #2
        sta Brightness
        jmp done_with_fadeout
check_1_threshold:
        cmp #4
        bne done_with_fadeout
        lda #1
        sta Brightness
done_with_fadeout:

        rts
.endproc

.proc boxgirl_hazard_recover_init
        ; teleport to the last safe tile we were standing on
        ldx CurrentEntityIndex
        lda PlayerSafeTileX
        sta entity_table + EntityState::PositionX+1, x
        lda PlayerSafeTileY
        sta entity_table + EntityState::PositionY+1, x
        lda PlayerSafeTileGroundLevel
        sta entity_table + EntityState::GroundLevel, x
        ; center us within that tile
        lda #0
        sta entity_table + EntityState::PositionX, x
        lda #$C0 ; ish
        sta entity_table + EntityState::PositionY, x
        ; zero our height, which will hide our shadow also
        lda #0
        sta entity_table + EntityState::PositionZ, x
        sta entity_table + EntityState::PositionZ+1, x
        ; set our palette color back to normmal
        ldy entity_table + EntityState::MetaSpriteIndex, x
        lda metasprite_table + MetaSpriteState::PaletteOffset, y
        and #%11111100
        ora #0
        sta metasprite_table + MetaSpriteState::PaletteOffset, y
        ; draw ourselves normally
        jsr set_3d_metasprite_pos
        ; hide our sprite. We are setting up for a brief camera pan before we
        ; spawn back in
        ldy CurrentEntityIndex
        lda entity_table + EntityState::MetaSpriteIndex, y
        tax
        metasprite_set_flag FLAG_VISIBILITY, VISIBILITY_HIDDEN


        ; init done, now proceed to pan the camera to this position
        set_update_func CurrentEntityIndex, boxgirl_hazard_recover_camera_pan
        ; and we'll reuse the stun timer for the duration
        lda #30
        sta PlayerStunTimer
        rts
.endproc

.proc boxgirl_hazard_recover_camera_pan
        ; really all we need to do is wait this out
        dec PlayerStunTimer
        bne no_switch
        ; Give us some height, so we fall down onto the spawn tile
        ldx CurrentEntityIndex
        lda #0
        sta entity_table + EntityState::PositionZ+1, x
        ; zero out our speed
        lda #0
        sta entity_table + EntityState::SpeedX, x
        sta entity_table + EntityState::SpeedY, x
        sta entity_table + EntityState::SpeedZ, x
        ; make our sprite visible again
        lda entity_table + EntityState::MetaSpriteIndex
        tax
        metasprite_set_flag FLAG_VISIBILITY, VISIBILITY_DISPLAYED
        lda #60
        sta PlayerInvulnerability
        ; by default, hand control back to the player
        jsr go_to_standard_locomotion
        ; but hazards deal damage, so apply that here. If the player dies from this hazard, then
        ; they will immediately enter their death throes as a result of this call
        lda #4 ; hazards deal two full hearts of damage (for testing)
        sta R0
        jsr handle_arbitrary_damage
no_switch:
        jsr set_3d_metasprite_pos    
        ; now for continued fanciness: fade back in to full brightness, using the stun timer
        ; to decide when to transition
        lda PlayerStunTimer
check_2_threshold:
        cmp #6
        bne check_3_threshold
        lda #2
        sta Brightness
        jmp done_with_fadein
check_3_threshold:
        cmp #4
        bne check_4_threshold
        lda #3
        sta Brightness
        jmp done_with_fadein
check_4_threshold:
        cmp #2
        bne done_with_fadein
        lda #4
        sta Brightness
done_with_fadein:
        rts
.endproc

.proc boxgirl_death_init
MetaSpriteIndex := R0
        ; oh dear :'(
        ; whelp, let's load the death animation, which for debugging is the teleport anim with a red palette
        ldx CurrentEntityIndex
        lda #0
        sta entity_table + EntityState::SpeedZ, x
        lda entity_table + EntityState::MetaSpriteIndex, x
        sta MetaSpriteIndex
        set_metasprite_animation MetaSpriteIndex, boxgirl_anim_teleport

        ; set our palette color to red (for great loss of ketchup)
        ldx CurrentEntityIndex
        ldy entity_table + EntityState::MetaSpriteIndex, x
        lda metasprite_table + MetaSpriteState::PaletteOffset, y
        and #%11111100
        ora #1
        sta metasprite_table + MetaSpriteState::PaletteOffset, y

        jsr set_3d_metasprite_pos

        ; we'll use the stun timer to time the various throes of death
        lda #45
        sta PlayerStunTimer

        lda #3
        sta Brightness

        st16 R0, sfx_death_spin_pulse
        jsr play_sfx_pulse1
        st16 R0, sfx_death_spin_pulse
        jsr play_sfx_pulse1
        st16 R0, sfx_death_spin_tri
        jsr play_sfx_triangle

        set_update_func CurrentEntityIndex, boxgirl_death_play_anim
        rts
.endproc

.proc boxgirl_death_play_anim
        dec PlayerStunTimer
        bne not_quite_dead_yet
        ; hide the player sprite, and spawn 8 particles fanning out from this location
        ldy CurrentEntityIndex
        lda entity_table + EntityState::MetaSpriteIndex, y
        tax
        metasprite_set_flag FLAG_VISIBILITY, VISIBILITY_HIDDEN

        jsr spawn_death_particles

        st16 R0, sfx_death_splat_noise
        jsr play_sfx_noise

        set_update_func CurrentEntityIndex, boxgirl_death_wait_for_particles
        lda #60
        sta PlayerStunTimer
not_quite_dead_yet:
        ; we don't need to do anything other than decrement the timer and wait
        jsr set_3d_metasprite_pos
        rts
.endproc

.proc boxgirl_death_wait_for_particles
        dec PlayerStunTimer
        bne not_quite_dead_yet
        st16 GameMode, blackout_to_new_map
        set_update_func CurrentEntityIndex, boxgirl_death_rest_in_peace
not_quite_dead_yet:
        rts
.endproc

.proc boxgirl_death_rest_in_peace
        ; simply wait for the kernel to load the level
        rts
.endproc

.proc clamp_to_max_walking_speed
check_horiz:
        ldx CurrentEntityIndex
        lda entity_table + EntityState::SpeedX, x
        bmi horiz_negative
horiz_positive:
        max_speed entity_table + EntityState::SpeedX, #WALKING_SPEED
        jmp check_vert
 horiz_negative:
        min_speed entity_table + EntityState::SpeedX, #($FF - WALKING_SPEED)
check_vert:
        lda entity_table + EntityState::SpeedY, x
        bmi vert_negative
vert_positive:
        max_speed entity_table + EntityState::SpeedY, #WALKING_SPEED
        rts
vert_negative:
        min_speed entity_table + EntityState::SpeedY, #($FF - WALKING_SPEED)
        rts
.endproc

.proc boxgirl_dashing
        ; Are we still dashing?
        lda PlayerDashTimer
        beq done_dashing
still_dashing:
        dec PlayerDashTimer
        ; use a BLUE palette, to channel our inner hedgehog
        ldx CurrentEntityIndex
        ldy entity_table + EntityState::MetaSpriteIndex, x
        lda metasprite_table + MetaSpriteState::PaletteOffset, y
        and #%11111100
        ora #2
        sta metasprite_table + MetaSpriteState::PaletteOffset, y
        jmp update_ourselves
done_dashing:
        ; flip back to our standard palette
        ldx CurrentEntityIndex
        ldy entity_table + EntityState::MetaSpriteIndex, x
        lda metasprite_table + MetaSpriteState::PaletteOffset, y
        and #%11111100
        ora #0
        sta metasprite_table + MetaSpriteState::PaletteOffset, y
        ; Switch back to the standard locomotion state, so the player
        ; regains control on the next frame following this one
        jsr go_to_standard_locomotion
        ; Clamp our horizontal velocity to sane walking values, to forbid
        ; keeping weird momentum
        jsr clamp_to_max_walking_speed
        ; now fall through to do standard update things
update_ourselves:
        ; We are dashing! Ignore player input for a while, and simply move
        ; along the velocity we set when we initiated this state

        ; We dash very quickly, and this somewhat breaks ramps. So dash speed is
        ; set in quadrants, and each frame we perform four (4) physics steps before
        ; applying dash friction. This ensures that each individual step is <2px movement total
        far_call FAR_apply_standard_entity_speed
        far_call FAR_apply_standard_entity_speed
        far_call FAR_apply_standard_entity_speed
        far_call FAR_apply_standard_entity_speed


        ; Apply dash-specific friction on both axis
        apply_friction entity_table + EntityState::SpeedX, ::DASH_DECELERATION
        apply_friction entity_table + EntityState::SpeedY, ::DASH_DECELERATION
        ; We ignore gravity! Instead, process the static rising velocity we had set before
        far_call FAR_vertical_speed_only
        ; ... but *do* apply ramp height adjustments here
        far_call FAR_apply_ramp_height

        jsr set_3d_metasprite_pos
        ; while dashing, we can't collide with other entities, and we are
        ; rising in the air, so there is no need to check ground tiles; we are never grounded
        ; in this state. This is true (if brief) invulnerability

        ; eye candy
        lda CurrentDistortion
        cmp #DISTORTION_UNDERWATER
        beq spawn_bubbles
spawn_dust:
        jsr spawn_dash_particles
        ; That's it!
        rts
spawn_bubbles:
        jsr spawn_dash_bubbles
        ; That's it!
        rts
.endproc

.proc spawn_dash_particles
RandomX := R0
RandomY := R1
        dec ParticleCooldown
        jne done
        lda #2
        sta ParticleCooldown
        ; random in any direction on the X axis
        jsr next_rand
        and #%00000111
        sec
        sbc #%00000100
        sta RandomX
        ; random "up" (negative) on the Y axis
        jsr next_rand
        and #%00000111
        sec
        sbc #%00000100
        sta RandomY

        ldx CurrentEntityIndex
        ;                       xoff  yoff   xspeed   yspeed tile             behavior  attribute animspeed lifetime
        spawn_advanced_particle  $80,  $40, RandomX, RandomY, #69, #PARTICLE_TILE_ANIM,        #2,       #4,     #16
done:
        rts
.endproc

.proc spawn_dash_bubbles
RandomX := R0
RandomY := R1
Tile := R2
        dec ParticleCooldown
        jne done
        lda #2
        sta ParticleCooldown
        ; random in any direction on the X axis
        jsr next_rand
        and #%00000111
        sec
        sbc #%00000100
        sta RandomX
        ; random "up" (negative) on the Y axis
        jsr next_rand
        pha ; preserve
        and #%00000111
        sec
        sbc #%00000100
        sta RandomY

        ; un-preserve
        pla
        rol ; grab a bit we didn't use above
        rol 
        and #%00000010 ; mask out the useful part
        clc
        adc #77
        sta Tile


        ldx CurrentEntityIndex
        ;                       xoff  yoff   xspeed   yspeed tile             behavior  attribute animspeed lifetime
        spawn_advanced_particle  $80,  $40, RandomX, RandomY, Tile, #PARTICLE_STANDARD,        #0,       #0,     #16
done:
        rts
.endproc

.proc spawn_death_particles
        ldx CurrentEntityIndex
        ;                       xoff  yoff   xspeed   yspeed tile              behavior  attribute, animspeed, lifetime
        spawn_advanced_particle  $40, $180,    #$20,    #$00, #67,   #PARTICLE_STANDARD,        #1,        #0,      #30
        spawn_advanced_particle  $40, $180,    #$DF,    #$00, #67,   #PARTICLE_STANDARD,        #1,        #0,      #30
        spawn_advanced_particle  $40, $180,    #$00,    #$20, #67,   #PARTICLE_STANDARD,        #1,        #0,      #30
        spawn_advanced_particle  $40, $180,    #$00,    #$DF, #67,   #PARTICLE_STANDARD,        #1,        #0,      #30
        spawn_advanced_particle  $40, $180,    #$20,    #$DF, #67,   #PARTICLE_STANDARD,        #1,        #0,      #30
        spawn_advanced_particle  $40, $180,    #$20,    #$20, #67,   #PARTICLE_STANDARD,        #1,        #0,      #30
        spawn_advanced_particle  $40, $180,    #$DF,    #$20, #67,   #PARTICLE_STANDARD,        #1,        #0,      #30
        spawn_advanced_particle  $40, $180,    #$DF,    #$DF, #67,   #PARTICLE_STANDARD,        #1,        #0,      #30
        rts
.endproc

.proc spawn_splash_particles
        ldx CurrentEntityIndex
        ;                       xoff            yoff   xspeed          yspeed       tile              behavior  attribute, animspeed, lifetime
        spawn_advanced_particle $C0,            $80,    #$10,           #($100-$20), #81,    #PARTICLE_GRAVITY,      #$40,        #0,      #16
        spawn_advanced_particle $C0,            $80,    #$08,           #($100-$24), #81,    #PARTICLE_GRAVITY,      #$40,        #0,      #20
        spawn_advanced_particle ($FFFF - $40),  $80,    #($100-$10),    #($100-$20), #81,    #PARTICLE_GRAVITY,      #$00,        #0,      #16
        spawn_advanced_particle ($FFFF - $40),  $80,    #($100-$08),    #($100-$24), #81,    #PARTICLE_GRAVITY,      #$00,        #0,      #20
        rts
.endproc

.proc random_bubble_params
XOff := R0
Tile := R2
        ; Here we want to randomize both the bubble size and the X position somewhat
        lda #0
        sta XOff
        sta Tile

        jsr next_rand
        ; move 1 bit for the bubble size into carry
        lsr a
        ; the rest of these bits become the X offset
        sta XOff
        ; compute the actual tile number
        rol Tile ; pull in the carry bit
        asl Tile ; multiply that by two
        clc
        lda #77 ; 77 = small bubble, 79 = large bubble
        adc Tile
        sta Tile
        rts
.endproc

.proc spawn_surface_bubble
XOff := R0
Tile := R2
        jsr random_bubble_params

        ldx CurrentEntityIndex
        ;                       xoff   yoff   xspeed   yspeed tile               behavior  attribute, animspeed, lifetime
        spawn_advanced_particle  $40,   $80,    #$00,    #$EF, Tile,   #PARTICLE_STANDARD,        #0,        #0,      #30
        ; particle spawning expects static base values for the x offset, so we must manually add our computed offset to it here
        ; conveniently y still contains the index of the particle we just wrote to, so we can reuse it
        clc
        lda particle_table + ParticleState::PositionX, y
        adc XOff
        sta particle_table + ParticleState::PositionX, y
        lda particle_table + ParticleState::PositionX+1, y
        adc #0
        sta particle_table + ParticleState::PositionX+1, y

        ; all done. Fly, little bubble, fly!
        rts
.endproc

.proc spawn_underwater_bubble
XOff := R0
Tile := R2
        ; first, we kinda want to randomize if we spawn a bubble at all, otherwise it gets a little bit
        ; too predictable. Are we on a valid bubble spawn frame?
        lda GameloopCounter
        ; Okay so on every 4th frame...
        and #%00000011
        jne finished

        ; ... we'll have a 12.5% chance to spawn a bubble
        jsr next_rand
        and #%00000111
        jne finished

        ; we're spawning; randomize the parameters
        jsr random_bubble_params

        ; But unlike a surface bubble, start this one a bit higher up, with a much longer lifetime
        ldx CurrentEntityIndex
        ;                       xoff   yoff   xspeed   yspeed tile               behavior  attribute, animspeed, lifetime
        spawn_advanced_particle  $40,  $180,    #$00,    #$EF, Tile,   #PARTICLE_STANDARD,        #0,        #0,      #120
        ; we still want to randomize the offset, so do that here
        clc
        lda particle_table + ParticleState::PositionX, y
        adc XOff
        sta particle_table + ParticleState::PositionX, y
        lda particle_table + ParticleState::PositionX+1, y
        adc #0
        sta particle_table + ParticleState::PositionX+1, y
        ; all done. Float, little bubble, float!
finished:
        rts
.endproc

.proc error_buzz_if_not_already_safe
TestPosX := R5
TestTileX := R6
TestPosY := R7
TestTileY := R8
        ; play a buzzer SFX to tell the QA tester that this should have
        ; worked.

        ldx CurrentEntityIndex
        lda TestTileX
        cmp PlayerSafeTileX
        bne buzzer
        lda TestTileY
        cmp PlayerSafeTileY
        bne buzzer
        lda entity_table + EntityState::GroundLevel, x
        cmp PlayerSafeTileGroundLevel
        bne buzzer

        jmp no_buzzer
buzzer:
        st16 R0, sfx_error_buzz
        jsr play_sfx_noise

no_buzzer:
        ; this is not a valid teleport, so we will instead flag it as a valid safe tile.
        ; That won't break anything, and the above logic can use it to determine whether to
        ; play the error sound
        ldx CurrentEntityIndex
        lda TestTileX
        sta PlayerSafeTileX
        lda TestTileY
        sta PlayerSafeTileY
        lda entity_table + EntityState::GroundLevel, x
        sta PlayerSafeTileGroundLevel
        
        ; all done
        rts
.endproc

.proc _handle_trigger
GroundType := R0

; used by map functions and the error buzz; don't clobber
TestPosX := R5
TestTileX := R6
TestPosY := R7
TestTileY := R8

TriggerType  := R23
TriggerPosX  := R24
TriggerPosY  := R25
TriggerId    := R26

TriggerData1 := R27
TriggerData2 := R28
TriggerData3 := R29
TriggerData4 := R30
TriggerData5 := R31
        jsr find_trigger
        bne trigger_invalid

        ; Queue up the event this switch triggers
        ; Note: the event should also handle changing the tile
        ldx event_next
        lda TriggerType
        sta events_type, x
        lda TriggerPosX
        sta events_pos_x, x
        lda TriggerPosY
        sta events_pos_y, x
        lda TriggerId
        sta events_id, x
        lda TriggerData1
        sta events_data1, x
        lda TriggerData2
        sta events_data2, x
        lda TriggerData3
        sta events_data3, x
        lda TriggerData4
        sta events_data4, x
        lda TriggerData5
        sta events_data5, x
        jsr add_event
        rts
trigger_invalid:
        jsr error_buzz_if_not_already_safe
        rts
.endproc

.proc handle_switch_tile 
GroundType := R0
TriggerType  := R23
        ; This permits us to freely clobber R0 in the following routines
        lda GroundType
        sta TriggerType
        ; Play a "switch pressed" SFX
        st16 R0, sfx_press_switch_pulse
        jsr play_sfx_pulse1
        st16 R0, sfx_press_switch_noise
        jsr play_sfx_noise

        jsr _handle_trigger
        rts
.endproc

.proc handle_interactable_tile
GroundType := R0
TriggerType  := R23
        ; This permits us to freely clobber R0 in the following routines
        lda GroundType
        sta TriggerType

        jsr _handle_trigger
        rts
.endproc

.proc handle_teleport_tile
MapAddr := R0
TestPosX := R5
TestTileX := R6
TestPosY := R7
TestTileY := R8
ExitTableAddr := R9
MetaSpriteIndex := R11
        jsr find_teleport
        bne teleport_invalid

        ; We found a valid destination! Everything that follows is specific to
        ; stepping on a magic teleport tile, and handles the appropriate animations
        ; and map transitions

        ; Set the new game mode to "load a new map"
        st16 GameMode, blackout_to_new_map

        ; play a nifty "whoosh" sfx
        st16 R0, sfx_teleport
        jsr play_sfx_pulse1

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

teleport_invalid:
        jsr error_buzz_if_not_already_safe
        
        ; all done
        rts
.endproc

.proc handle_deep_water_teleport
        jsr find_teleport
        bne teleport_invalid

        ; Set the new game mode to "load a new map"
        st16 GameMode, blackout_to_new_map

        ; TODO: play a "bloop bloop" transition sound
        ; this should be fairly long, to hopefully mask
        ; a music cue that may need a full measure of wait time

        st16 R0, sfx_dive_underwater_pulse
        jsr play_sfx_pulse1
        st16 R0, sfx_dive_underwater_noise
        jsr play_sfx_noise

        ; Boxgirl's current animation state is just fine, so we'll reuse
        ; the nearly empty death state here to idle until the kernel is done
        ; loading the new map
        set_update_func CurrentEntityIndex, boxgirl_death_rest_in_peace
        ; all done
        rts

teleport_invalid:
        ; This is fairly unusual! Play an error buzz here
        st16 R0, sfx_error_buzz
        jsr play_sfx_noise

        ; Now transition the player back to their normal swimming state with a splash
        ; Make boxgirl's sprite re-appear
        ldy CurrentEntityIndex
        lda entity_table + EntityState::MetaSpriteIndex, y
        tax
        metasprite_set_flag FLAG_VISIBILITY, VISIBILITY_DISPLAYED

        lda #0
        sta PlayerPrimaryDirection
        st16 R0, sfx_splash
        jsr play_sfx_noise
        jsr spawn_splash_particles
        set_update_func CurrentEntityIndex, boxgirl_swimming
        rts
.endproc

; === Weird stuff that needs to be fixed below === 
; TODO: does all of this need to be in fixed? Surely there's a critical bit of it
; and the rest can go in a banked handler

        .segment "PRGFIXED_8000"

; common map scanning code, used for all exit logic. Returns #0 if a valid
; destination is found, and performs necessary setup. Returns nonzero otherwise.
; Note: this needs to bank in the map header, so it lives in fixed memory
.proc find_teleport
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
        access_data_bank working_save+SaveFile::CurrentMapBank
        lda working_save + SaveFile::CurrentMapPtr
        sta MapAddr
        lda working_save + SaveFile::CurrentMapPtr+1
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
        jeq no_valid_destination ; sanity check, can't leave a map with no exits defined
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
        sta working_save + SaveFile::CurrentMapPtr
        ldy #ExitTableEntry::target_map+1
        lda (ExitTableAddr), y
        sta working_save + SaveFile::CurrentMapPtr+1
        ldy #ExitTableEntry::target_bank
        lda (ExitTableAddr), y
        sta working_save + SaveFile::CurrentMapBank
        ldy #ExitTableEntry::target_entrance
        lda (ExitTableAddr), y
        sta TargetMapEntrance

        restore_previous_bank
        access_data_bank working_save+SaveFile::CurrentMapBank

        ; We are definitely about to teleport to this map, so read the entry and queue up the new music
        ; variation (if any) early

        lda working_save + SaveFile::CurrentMapPtr
        sta ExitTableAddr ; we're done with this ptr, so reuse it here
        lda working_save + SaveFile::CurrentMapPtr+1
        sta ExitTableAddr+1
        ldy #MapHeader::music_variant
        lda (ExitTableAddr), y
        ; TODO: instead of playing this here, let's toss it into a variable? It seems weird that
        ; "find teleport" also "switches music tracks" as a side effect
        jsr play_variant

        restore_previous_bank

        lda #0
        rts

no_match:
        add16b ExitTableAddr, #.sizeof(ExitTableEntry)
        dex
        jne loop

no_valid_destination:
        restore_previous_bank

        ; we did NOT find a valid teleport. Signal the error
        lda #$FF
        rts
.endproc

; Similar but for triggers instead
.proc find_trigger
MapAddr := R0
TestPosX := R5
TestTileX := R6
TestPosY := R7
TestTileY := R8
TriggerTableAddr := R9

TriggerPosX  := R24
TriggerPosY  := R25
TriggerId    := R26
TriggerData1 := R27
TriggerData2 := R28
TriggerData3 := R29
TriggerData4 := R30
TriggerData5 := R31
        ; helpfully our scratch registers are still set from the physics function,
        ; so we don't need to re-do the lookup here

        ; The target registers are our currently loaded map. Use these to locate the
        ; map header
        access_data_bank working_save+SaveFile::CurrentMapBank
        lda working_save + SaveFile::CurrentMapPtr
        sta MapAddr
        lda working_save + SaveFile::CurrentMapPtr+1
        sta MapAddr+1

        ldy #MapHeader::trigger_list
        lda (MapAddr), y
        sta TriggerTableAddr
        iny
        lda (MapAddr), y
        sta TriggerTableAddr+1

        ; loop through all the triggers, stopping if we find a match for our current tile position
        ldy #0
        lda (TriggerTableAddr), y ; length byte
        inc16 TriggerTableAddr
        beq no_valid_trigger ; sanity check: if this map doesn't have any triggers, bail right now
        tax ; x is otherwise unused, so it is our counter
loop:
        ldy #TriggerTableEntry::tile_x
        lda (TriggerTableAddr), y
        cmp TestTileX
        bne no_match
        ldy #TriggerTableEntry::tile_y
        lda (TriggerTableAddr), y
        cmp TestTileY
        bne no_match

        ; MATCH FOUND (!!!)

        ; For a trigger, all we need to do is read the metadata into scratch and then return
        ; The calling function will decide what to do with that data (usually it'll queue up an event)
        lda TestTileX
        sta TriggerPosX
        lda TestTileY
        sta TriggerPosY
        ldy #TriggerTableEntry::id
        lda (TriggerTableAddr), y
        sta TriggerId
        ldy #TriggerTableEntry::data1
        lda (TriggerTableAddr), y
        sta TriggerData1
        ldy #TriggerTableEntry::data2
        lda (TriggerTableAddr), y
        sta TriggerData2
        ldy #TriggerTableEntry::data3
        lda (TriggerTableAddr), y
        sta TriggerData3
        ldy #TriggerTableEntry::data4
        lda (TriggerTableAddr), y
        sta TriggerData4
        ldy #TriggerTableEntry::data5
        lda (TriggerTableAddr), y
        sta TriggerData5

        restore_previous_bank

        lda #0
        rts
no_match:
        add16b TriggerTableAddr, #.sizeof(TriggerTableEntry)
        dex
        bne loop

no_valid_trigger:
        restore_previous_bank

        ; we did NOT find a valid trigger. Signal the error
        lda #$FF
        rts
.endproc



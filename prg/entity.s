        .setcpu "6502"
        .include "branch_util.inc"
        .include "collision.inc"
        .include "far_call.inc"
        .include "entity.inc"
        .include "physics.inc"
        .include "sprites.inc"
        .include "scrolling.inc"
        .include "word_util.inc"
        .include "zeropage.inc"

        .include "animations/shadow.inc"

        .zeropage
CurrentEntityIndex: .byte $00

        .segment "RAM"
entity_table:
        .repeat MAX_ENTITIES
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
        ; Deactivate the update function, this stops any entity logic
        ; from running, and also acts as the marker, indicating that
        ; the slot is free for future use
        lda #0
        sta entity_table + EntityState::UpdateFunc+1, y
        ; Clear out collision data; for speed reasons, most collision checks
        ; don't verify that the entity is active, so we explicitly disable
        ; it here
        sta entity_table + EntityState::CollisionMask, y
        sta entity_table + EntityState::CollisionResponse, y
        clc
        tya
        adc #.sizeof(EntityState)
        cmp #(.sizeof(EntityState) * MAX_ENTITIES)
        beq done
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

        lda entity_table + EntityState::RampHeight, y
        beq standard_shadow_check
ramp_shadow_check:
        ; If a ramp is in play, then we must only draw the shadow if the entity
        ; height is currently above the ramp height
        far_call FAR_compute_ramp_height_y
        ; Now compare against the Z coordinate
        lda RampGroundHeight+1
        cmp entity_table + EntityState::PositionZ+1, y
        bne check_if_below_ramp
        lda RampGroundHeight
        cmp entity_table + EntityState::PositionZ, y
check_if_below_ramp:
        jcs no_shadow

standard_shadow_check:
        ; simple check: is our height nonzero?
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

        ; subtract the ramp height here, which is already in pixels
        sec
        lda metasprite_table + MetaSpriteState::PositionY, x
        sbc entity_table + EntityState::RampHeight, y
        sta metasprite_table + MetaSpriteState::PositionY, x
        lda metasprite_table + MetaSpriteState::PositionY+1, x
        sbc #0
        sta metasprite_table + MetaSpriteState::PositionY+1, x

        ; done drawing the shadow, get outta here
        rts

no_shadow:
        ; There is no shadow to draw; turn off the shadow animation
        ; x already contains MetaSpriteIndex
        metasprite_set_flag FLAG_VISIBILITY, VISIBILITY_HIDDEN
        ; and done
        rts
.endproc

blank_metasprite:
        .word blank_metasprite_frames
        .byte 1 ; length in frames

blank_metasprite_frames:
        .word blank_metasprite_frames ; doesn't matter, not used
        .byte $00, $00, $0; oam length, mapper, delay frames

; Most entities will perform some common setup w/ respect to their
; sprites. This routine is appropriate for anything with a main sprite
; and a shadow underneath, which is most in-game objects
.proc standard_entity_init
MetaSpriteIndex := R0
CollisionFlags := R1
CollisionHeights := R2
        ; allocate the main character sprite
        far_call FAR_find_unused_metasprite
        lda #$FF
        cmp MetaSpriteIndex
        jeq failed_to_spawn
        ldy CurrentEntityIndex
        lda MetaSpriteIndex
        sta entity_table + EntityState::MetaSpriteIndex, y
        ; basic initialization of the main sprite
        set_metasprite_animation MetaSpriteIndex, blank_metasprite
        set_metasprite_tile_offset MetaSpriteIndex, #0
        set_metasprite_palette_offset MetaSpriteIndex, #0
        ldx MetaSpriteIndex
        metasprite_set_flag FLAG_VISIBILITY, VISIBILITY_DISPLAYED
        ; allocate a shadow sprite
        far_call FAR_find_unused_metasprite
        lda #$FF
        cmp MetaSpriteIndex
        jeq failed_to_spawn
        ldy CurrentEntityIndex
        lda MetaSpriteIndex
        sta entity_table + EntityState::ShadowSpriteIndex, y
        ; basic init for the shadow sprite
        set_metasprite_animation MetaSpriteIndex, shadow_flicker
        set_metasprite_tile_offset MetaSpriteIndex, #$40 ; note: probably move this to its own bank later
        set_metasprite_palette_offset MetaSpriteIndex, #0
        ldx MetaSpriteIndex
        metasprite_set_flag FLAG_VISIBILITY, VISIBILITY_DISPLAYED

        ; set sane defaults for physics variables
        lda #0
        ldx CurrentEntityIndex
        sta entity_table + EntityState::SpeedX, x
        sta entity_table + EntityState::SpeedY, x
        sta entity_table + EntityState::SpeedZ, x
        ; default our height above the ground to 0
        sta entity_table + EntityState::PositionZ, x
        sta entity_table + EntityState::PositionZ+1, x
        ; default some other transient variables to 0
        sta entity_table + EntityState::RampHeight, x
        ; Our hitbox is at the bottom of our feet, but the spawning routine only gives us
        ; a tile coordinate, causing us to land at the top of our tile. That looks weird,
        ; so fix it here
        lda #$C0
        sta entity_table + EntityState::PositionY, x

        ; Set our initial ground height based on the block we spawned on
        far_call FAR_ground_nav_properties
        lda CollisionHeights
        and #$0F ; keep the surface height only
        sta entity_table + EntityState::GroundLevel, x

        ; register ourselves as a sorted entity, for proper back-to-front fake depth
        lda CurrentEntityIndex
        sta R0
        far_call FAR_register_sorted_entity

        ; Perform an initial draw with all of our updated properties
        jsr set_3d_metasprite_pos

        rts
failed_to_spawn:
        despawn_entity CurrentEntityIndex
        rts
.endproc
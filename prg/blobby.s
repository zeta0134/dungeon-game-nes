; Blobby v2, no longer a player character

        .setcpu "6502"
        .include "blobby.inc"
        .include "branch_util.inc"
        .include "entity.inc"
        .include "far_call.inc"
        .include "physics.inc"
        .include "prng.inc"
        .include "sprites.inc"
        .include "zeropage.inc"


        .segment "ENTITIES_A000" ; will eventually move to an AI page
        .include "animations/blobby/idle.inc"
        .include "animations/blobby/squish.inc"
        .include "animations/shadow.inc"

.proc blobby_init
MetaSpriteIndex := R0
        ; First perform standard entity init
        jsr standard_entity_init
        ; If spawning fails, it will leave #$FF in MetaSpriteIndex, which
        ; we can check for here
        lda #$FF
        cmp MetaSpriteIndex
        beq failed_to_spawn

        ; Now perform blobby specific setup
        ; First the main animation metasprite
        ldy CurrentEntityIndex
        lda entity_table + EntityState::MetaSpriteIndex, y 
        sta MetaSpriteIndex
        set_metasprite_animation MetaSpriteIndex, blobby_anim_idle
        set_metasprite_tile_offset MetaSpriteIndex, #64 ;  blobby's data is in the 2nd bank

        ; Blobby is a bounce target for jumping, and also a weak touch of death target for bumping
        ldx CurrentEntityIndex
        lda #(COLLISION_GROUP_BOUNCE | COLLISION_GROUP_WEAKHIT)
        sta entity_table + EntityState::CollisionMask, x

        ;finally, switch to blobby's idle routine
        set_update_func CurrentEntityIndex, blobby_idle
        
failed_to_spawn:
        rts
.endproc

.proc blobby_idle
MetaSpriteIndex := R0
        ; apply physics normally
        far_call FAR_standard_entity_vertical_acceleration
        far_call FAR_apply_standard_entity_speed
        jsr set_3d_metasprite_pos
        ; in our standard form, use our base palette (for now)
        ldx CurrentEntityIndex
        ldy entity_table + EntityState::MetaSpriteIndex, x
        lda metasprite_table + MetaSpriteState::PaletteOffset, y
        and #%11111100
        sta metasprite_table + MetaSpriteState::PaletteOffset, y
        ; were we squished recently?
        lda entity_table + EntityState::CollisionResponse, x
        beq no_response
        ; clear out the response, so we don't trigger again
        lda #0
        sta entity_table + EntityState::CollisionResponse, x
        ; while we are in our squished state, don't allow a second squish
        ; or a damage impact (which is inconsistently applied due to physics
        ; and therefore unfair)
        lda entity_table + EntityState::CollisionMask, x
        and #($FF - COLLISION_GROUP_BOUNCE - COLLISION_GROUP_WEAKHIT)
        sta entity_table + EntityState::CollisionMask, x
        ; set a squish timer using a data byte. One second seems reasonable
        lda #60
        sta entity_table + EntityState::Data, x
        ; set our metasprite animation accordingly
        lda entity_table + EntityState::MetaSpriteIndex, x
        sta MetaSpriteIndex
        set_metasprite_animation MetaSpriteIndex, blobby_anim_squish
        ; now switch
        set_update_func CurrentEntityIndex, blobby_squished
no_response:
        rts
.endproc

.proc blobby_squished
MetaSpriteIndex := R0
        ; apply physics normally
        far_call FAR_standard_entity_vertical_acceleration
        far_call FAR_apply_standard_entity_speed
        jsr set_3d_metasprite_pos
        ; in our squished form, use a green palette (for now)
        ldx CurrentEntityIndex
        ldy entity_table + EntityState::MetaSpriteIndex, x
        lda metasprite_table + MetaSpriteState::PaletteOffset, y
        and #%11111100
        ora #3
        sta metasprite_table + MetaSpriteState::PaletteOffset, y
        ; decrement our squish timer
        dec entity_table + EntityState::Data, x
        bne still_squished
        ; time to bounce back to our idle state
        ; first, become squishy again
        lda entity_table + EntityState::CollisionMask, x
        ora #(COLLISION_GROUP_BOUNCE | COLLISION_GROUP_WEAKHIT)
        sta entity_table + EntityState::CollisionMask, x
        ; if something happened while we were squished, ignore it
        ; (being squished was more important)
        lda #0
        sta entity_table + EntityState::CollisionResponse, x
        ; set our metasprite animation accordingly
        lda entity_table + EntityState::MetaSpriteIndex, x
        sta MetaSpriteIndex
        set_metasprite_animation MetaSpriteIndex, blobby_anim_idle
        ; all done
        set_update_func CurrentEntityIndex, blobby_idle
still_squished:
        rts
.endproc
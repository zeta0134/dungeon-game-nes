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

        ; Now perform boxgirl specific setup
        ; First the main animation metasprite
        ldy CurrentEntityIndex
        lda entity_table + EntityState::MetaSpriteIndex, y 
        sta MetaSpriteIndex
        set_metasprite_animation MetaSpriteIndex, blobby_anim_idle
        set_metasprite_tile_offset MetaSpriteIndex, #64 ;  blobby's data is in the 2nd bank

        lda CurrentEntityIndex
        lsr
        lsr
        lsr
        lsr
        and #%00000011
        ldx MetaSpriteIndex
        sta metasprite_table + MetaSpriteState::PaletteOffset, x

        ;finally, switch to blobby's idle routine
        set_update_func CurrentEntityIndex, blobby_idle
        
failed_to_spawn:
        rts
.endproc

.proc blobby_idle
        ; apply physics normally
        far_call FAR_standard_entity_vertical_acceleration
        far_call FAR_apply_standard_entity_speed
        jsr set_3d_metasprite_pos
        rts
.endproc
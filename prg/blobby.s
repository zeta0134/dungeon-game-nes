; Blobby v2, no longer a player character

        .setcpu "6502"
        .include "blobby.inc"
        .include "branch_util.inc"
        .include "entity.inc"
        .include "far_call.inc"
        .include "physics.inc"
        .include "sprites.inc"
        .include "zeropage.inc"


        .segment "PRGFIXED_E000" ; will eventually move to an AI page
        .include "animations/blobby/idle.inc"
        .include "animations/shadow.inc"

.proc blobby_init
        ; allocate our main character sprite
        jsr find_unused_metasprite
        lda #$FF
        cmp R0
        jeq failed_to_spawn
        ldy CurrentEntityIndex
        lda R0
        sta entity_table + EntityState::MetaSpriteIndex, y
        ; initialize that character sprite
        set_metasprite_animation R0, blobby_anim_idle
        set_metasprite_tile_offset R0, #64 ;  blobby's data is in the 2nd bank
        ldx R0
        metasprite_set_flag FLAG_VISIBILITY, VISIBILITY_DISPLAYED
        ; set the palette color based on the entity ID, slightly abusing the size
        ; of EntityState being 16
        lda CurrentEntityIndex
        lsr
        lsr
        lsr
        lsr
        and #%00000011
        sta R1
        sta metasprite_table + MetaSpriteState::PaletteOffset, x

        ; now do the same for blobby's shadow sprite
        jsr find_unused_metasprite
        lda #$FF
        cmp R0
        beq failed_to_spawn
        ldy CurrentEntityIndex
        lda R0
        sta entity_table + EntityState::ShadowSpriteIndex, y
        ; basic init for the shadow sprite
        set_metasprite_animation R0, shadow_flicker
        set_metasprite_tile_offset R0, #$18 ; note: probably move this to its own bank later
        set_metasprite_palette_offset R0, #0


        ldx R0
        metasprite_set_flag FLAG_VISIBILITY, VISIBILITY_DISPLAYED

        jsr set_3d_metasprite_pos

        ; use data bytes 0 and 1 to track speed
        lda #0
        ldy CurrentEntityIndex
        sta entity_table + EntityState::SpeedX, y
        sta entity_table + EntityState::SpeedY, y
        sta entity_table + EntityState::SpeedZ, y
        ; default our ground height to 0
        sta entity_table + EntityState::PositionZ, y
        sta entity_table + EntityState::PositionZ+1, y
        ; finally, switch to the idle routine
        set_update_func CurrentEntityIndex, blobby_idle
        rts
failed_to_spawn:
        despawn_entity CurrentEntityIndex
        rts
.endproc

.proc blobby_idle
        ; apply physics normally
        far_call FAR_standard_entity_vertical_acceleration
        far_call FAR_apply_standard_entity_speed
        jsr set_3d_metasprite_pos
        ; for now, do nothing else.
        rts
.endproc
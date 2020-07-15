        .setcpu "6502"
        .include "sprites.inc"
        .include "entity.inc"
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

;.macro initialize_metasprite index, pos_x, pos_y, palette, tilebase, animation
;        st16 R0, pos_x
;        set_metasprite_x #.sizeof(MetaSpriteState)*index, R0
;        st16 R0, pos_y
;        set_metasprite_y #.sizeof(MetaSpriteState)*index, R0
;        set_metasprite_tile_offset #.sizeof(MetaSpriteState)*index, #tilebase
;        set_metasprite_palette_offset #.sizeof(MetaSpriteState)*index, #palette
;        set_metasprite_animation #.sizeof(MetaSpriteState)*index, animation
;.endmacro

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
        ; finally, switch to the idle routine
        set_update_func R1, blobby_idle
        rts
failed_to_spawn:
        despawn_entity CurrentEntityIndex
        rts
.endproc

.proc blobby_idle
        rts
.endproc

.proc blobby_walk_right
        rts
.endproc

.endscope

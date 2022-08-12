.export shadow_solid, shadow_flicker

; solid - plain, boring sprite

shadow_solid:
        .word shadow_frames_solid
        .byte 1 ; length in frames

shadow_frames_solid:
        .word shadow_oam_solid
        .byte $01, $05, $FF; oam length, mapper, delay frames

; flicker - standard 30 Hz on/off pattern

shadow_flicker:
        .word shadow_frames_flicker
        .byte 2 ; length in frames

shadow_frames_flicker:
        .word shadow_oam_solid
        .byte $01, $05, $0; oam length, mapper, delay frames
        .word shadow_oam_solid
        .byte $00, $05, $0; oam length, mapper, delay frames


; sprite tiles for above

shadow_oam_solid:
        ;     Y-offset   Tile  Attr   X-offset
        .byte ($FF - 1), 1,    $00,   4
.export shadow_solid

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
; NOTE: OAM length of 0 here is untested!

; checkerboard - alternating dither pattern at 30 Hz

shadow_checkerboard:
        .word shadow_frames_checkerboard
        .byte 2 ; length in frames

shadow_frames_checkerboard:
        .word shadow_oam_checkerboard_left
        .byte $01, $05, $0; oam length, mapper, delay frames
        .word shadow_oam_checkerboard_right
        .byte $01, $05, $0; oam length, mapper, delay frames

; horizontal - alternating rows at 30 Hz

shadow_horizontal_stripes:
        .word shadow_frames_horizontal_stripes
        .byte 2 ; length in frames

shadow_frames_horizontal_stripes:
        .word shadow_oam_horiz_even
        .byte $01, $05, $0; oam length, mapper, delay frames
        .word shadow_oam_horiz_odd
        .byte $01, $05, $0; oam length, mapper, delay frames

shadow_vertical_stripes:
        .word shadow_frames_vertical_stripes
        .byte 2 ; length in frames

shadow_frames_vertical_stripes:
        .word shadow_oam_vert_even
        .byte $01, $05, $0; oam length, mapper, delay frames
        .word shadow_oam_vert_odd
        .byte $01, $05, $0; oam length, mapper, delay frames\

; sprite tiles for above

shadow_oam_solid:
        ;     Y-offset  Tile  Attr   X-offset
        .byte 0,        0,    $00,    0
shadow_oam_checkerboard_left:
        ;     Y-offset  Tile  Attr   X-offset
        .byte 0,        1,    $00,    0
shadow_oam_checkerboard_right:
        ;     Y-offset  Tile  Attr   X-offset
        .byte 0,        1,    $00,    1
shadow_oam_horiz_even:
        ;     Y-offset  Tile  Attr   X-offset
        .byte 0,        2,    $00,    0
shadow_oam_horiz_odd:
        ;     Y-offset  Tile  Attr   X-offset
        .byte 0,        3,    $00,    0
shadow_oam_vert_even:
        ;     Y-offset  Tile  Attr   X-offset
        .byte 0,        4,    $00,    0
shadow_oam_vert_odd:
        ;     Y-offset  Tile  Attr   X-offset
        .byte 0,        5,    $00,    0

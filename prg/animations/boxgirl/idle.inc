.export boxgirl_anim_idle

boxgirl_anim_idle_right:
        .word boxgirl_frames_idle_right
        .byte 1 ; length in frames

boxgirl_frames_idle_right:
        .word boxgirl_oam_idle_right_1
        .byte $04, $04, $FF; oam length, mapper, delay frames

boxgirl_oam_idle_right_1:
        ;     Y-offset  Tile  Attr   X-offset
        .byte 0,        0,    $00,    0
        .byte 0,        1,    $00,    8
        .byte 16,       2,    $00,    0
        .byte 16,       3,    $00,    8

boxgirl_anim_idle_left:
        .word boxgirl_frames_idle_left
        .byte 1 ; length in frames

boxgirl_frames_idle_left:
        .word boxgirl_oam_idle_left_1
        .byte $04, $04, $FF; oam length, mapper, delay frames

boxgirl_oam_idle_left_1:
        ;     Y-offset  Tile  Attr   X-offset
        .byte 0,        1,    $40,    0
        .byte 0,        0,    $40,    8
        .byte 16,       3,    $40,    0
        .byte 16,       2,    $40,    8
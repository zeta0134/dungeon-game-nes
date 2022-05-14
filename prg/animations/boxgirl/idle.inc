.export boxgirl_anim_idle_right, boxgirl_anim_idle_left

boxgirl_anim_idle_right:
        .word boxgirl_frames_idle_right
        .byte 1 ; length in frames

boxgirl_frames_idle_right:
        .word boxgirl_oam_idle_right_1
        .byte $04, $05, $FF; oam length, mapper, delay frames

boxgirl_oam_idle_right_1:
        ;     Y-offset  Tile  Attr   X-offset
        .byte 0,        1,    $00,    0
        .byte 0,        3,    $00,    8
        .byte 16,       5,    $00,    0
        .byte 16,       7,    $00,    8

boxgirl_anim_idle_left:
        .word boxgirl_frames_idle_left
        .byte 1 ; length in frames

boxgirl_frames_idle_left:
        .word boxgirl_oam_idle_left_1
        .byte $04, $05, $FF; oam length, mapper, delay frames

boxgirl_oam_idle_left_1:
        ;     Y-offset  Tile  Attr   X-offset
        .byte 0,        3,    $40,    0
        .byte 0,        1,    $40,    8
        .byte 16,       5,    $40,    0
        .byte 16,       7,    $40,    8
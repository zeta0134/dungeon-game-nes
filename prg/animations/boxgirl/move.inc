.export boxgirl_anim_move_right, boxgirl_anim_move_left, boxgirl_anim_move_down, boxgirl_anim_move_up

boxgirl_anim_move_right:
        .word boxgirl_frames_move_right
        .byte 1 ; length in frames

boxgirl_frames_move_right:
        .word boxgirl_oam_move_right_1
        .byte $04, $04, $FF; oam length, mapper, delay frames

boxgirl_oam_move_right_1:
        ;     Y-offset  Tile  Attr   X-offset
        .byte 0,        0,    $00,    1
        .byte 0,        1,    $00,    9
        .byte 16,       2,    $00,    0
        .byte 16,       3,    $00,    8

boxgirl_anim_move_left:
        .word boxgirl_frames_move_left
        .byte 1 ; length in frames

boxgirl_frames_move_left:
        .word boxgirl_oam_move_left_1
        .byte $04, $04, $FF; oam length, mapper, delay frames

boxgirl_oam_move_left_1:
        ;     Y-offset  Tile  Attr   X-offset
        .byte 0,        1,    $40,    255
        .byte 0,        0,    $40,    7
        .byte 16,       3,    $40,    0
        .byte 16,       2,    $40,    8

boxgirl_anim_move_down:
        .word boxgirl_frames_move_down
        .byte 1 ; length in frames

boxgirl_frames_move_down:
        .word boxgirl_oam_move_down_1
        .byte $04, $04, $FF; oam length, mapper, delay frames

boxgirl_oam_move_down_1:
        ;     Y-offset  Tile  Attr   X-offset
        .byte 0,        4,    $00,    0
        .byte 0,        5,    $00,    8
        .byte 16,       6,    $00,    0
        .byte 16,       7,    $00,    8

boxgirl_anim_move_up:
        .word boxgirl_frames_move_up
        .byte 1 ; length in frames

boxgirl_frames_move_up:
        .word boxgirl_oam_move_up_1
        .byte $04, $04, $FF; oam length, mapper, delay frames

boxgirl_oam_move_up_1:
        ;     Y-offset  Tile  Attr   X-offset
        .byte 0,        8,    $00,    0
        .byte 0,        9,    $00,    8
        .byte 16,       10,   $00,    0
        .byte 16,       11,   $00,    8
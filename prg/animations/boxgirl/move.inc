.export boxgirl_anim_move_right, boxgirl_anim_move_left, boxgirl_anim_move_down, boxgirl_anim_move_up

boxgirl_anim_move_right:
        .word boxgirl_frames_move_right
        .byte 1 ; length in frames

boxgirl_frames_move_right:
        .word boxgirl_oam_move_right_1
        .byte $04, $05, $FF; oam length, mapper, delay frames

boxgirl_oam_move_right_1:
        ;     Y-offset  Tile  Attr   X-offset
        .byte 0,        1,    $00,    1
        .byte 0,        3,    $00,    9
        .byte 16,       5,    $00,    0
        .byte 16,       7,    $00,    8

boxgirl_anim_move_left:
        .word boxgirl_frames_move_left
        .byte 1 ; length in frames

boxgirl_frames_move_left:
        .word boxgirl_oam_move_left_1
        .byte $04, $05, $FF; oam length, mapper, delay frames

boxgirl_oam_move_left_1:
        ;     Y-offset  Tile  Attr   X-offset
        .byte 0,        3,    $40,    255
        .byte 0,        1,    $40,    7
        .byte 16,       7,    $40,    0
        .byte 16,       5,    $40,    8

boxgirl_anim_move_down:
        .word boxgirl_frames_move_down
        .byte 1 ; length in frames

boxgirl_frames_move_down:
        .word boxgirl_oam_move_down_1
        .byte $04, $05, $FF; oam length, mapper, delay frames

boxgirl_oam_move_down_1:
        ;     Y-offset  Tile  Attr   X-offset
        .byte 0,        9,    $00,    0
        .byte 0,        11,   $00,    8
        .byte 16,       13,   $00,    0
        .byte 16,       15,   $00,    8

boxgirl_anim_move_up:
        .word boxgirl_frames_move_up
        .byte 1 ; length in frames

boxgirl_frames_move_up:
        .word boxgirl_oam_move_up_1
        .byte $04, $05, $FF; oam length, mapper, delay frames

boxgirl_oam_move_up_1:
        ;     Y-offset  Tile  Attr   X-offset
        .byte 0,        17,   $00,    0
        .byte 0,        19,   $00,    8
        .byte 16,       21,   $00,    0
        .byte 16,       23,   $00,    8
.export boxgirl_anim_underwater_right, boxgirl_anim_underwater_left, boxgirl_anim_underwater_down, boxgirl_anim_underwater_up

boxgirl_anim_underwater_right:
        .word boxgirl_frames_underwater_right
        .byte 1 ; length in frames

boxgirl_frames_underwater_right:
        .word boxgirl_oam_underwater_right_1
        .byte $04, $05, $FF; oam length, mapper, delay frames

boxgirl_oam_underwater_right_1:
        ;     Y-offset  Tile  Attr   X-offset
        .byte ($ff-31), 29,    $00,   0
        .byte ($ff-31), 31,    $00,   8
        .byte ($ff-15), 5,    $00,   0
        .byte ($ff-15), 7,    $00,   8

boxgirl_anim_underwater_left:
        .word boxgirl_frames_underwater_left
        .byte 1 ; length in frames

boxgirl_frames_underwater_left:
        .word boxgirl_oam_underwater_left_1
        .byte $04, $05, $FF; oam length, mapper, delay frames

boxgirl_oam_underwater_left_1:
        ;     Y-offset  Tile  Attr   X-offset
        .byte ($ff-31), 31,    $40,   0
        .byte ($ff-31), 29,    $40,   8
        .byte ($ff-15), 7,    $40,   0
        .byte ($ff-15), 5,    $40,   8

boxgirl_anim_underwater_down:
        .word boxgirl_frames_underwater_down
        .byte 1 ; length in frames

boxgirl_frames_underwater_down:
        .word boxgirl_oam_underwater_down_1
        .byte $04, $05, $FF; oam length, mapper, delay frames

boxgirl_oam_underwater_down_1:
        ;     Y-offset  Tile  Attr   X-offset
        .byte ($ff-31), 33,   $00,   0
        .byte ($ff-31), 35,   $00,   8
        .byte ($ff-15), 13,   $00,   0
        .byte ($ff-15), 15,   $00,   8

boxgirl_anim_underwater_up:
        .word boxgirl_frames_underwater_up
        .byte 1 ; length in frames

boxgirl_frames_underwater_up:
        .word boxgirl_oam_underwater_up_1
        .byte $04, $05, $FF; oam length, mapper, delay frames

boxgirl_oam_underwater_up_1:
        ;     Y-offset  Tile  Attr   X-offset
        .byte ($ff-31), 37,   $00,   0
        .byte ($ff-31), 39,   $00,   8
        .byte ($ff-15), 21,   $00,   0
        .byte ($ff-15), 23,   $00,   8

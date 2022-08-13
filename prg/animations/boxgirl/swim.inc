.export boxgirl_anim_swim_right, boxgirl_anim_swim_left, boxgirl_anim_swim_down, boxgirl_anim_swim_up

boxgirl_anim_swim_right:
        .word boxgirl_frames_swim_right
        .byte 1 ; length in frames

boxgirl_frames_swim_right:
        .word boxgirl_oam_swim_right_1
        .byte $04, $05, $FF; oam length, mapper, delay frames

boxgirl_oam_swim_right_1:
        ;     Y-offset  Tile  Attr   X-offset
        .byte ($ff-31), 29,    $00,   0
        .byte ($ff-31), 31,    $00,   8
        .byte ($ff-15), 25,    $00,   0
        .byte ($ff-15), 27,    $00,   8

boxgirl_anim_swim_left:
        .word boxgirl_frames_swim_left
        .byte 1 ; length in frames

boxgirl_frames_swim_left:
        .word boxgirl_oam_swim_left_1
        .byte $04, $05, $FF; oam length, mapper, delay frames

boxgirl_oam_swim_left_1:
        ;     Y-offset  Tile  Attr   X-offset
        .byte ($ff-31), 29,    $40,   0
        .byte ($ff-31), 31,    $40,   8
        .byte ($ff-15), 25,    $00,   0
        .byte ($ff-15), 27,    $00,   8

boxgirl_anim_swim_down:
        .word boxgirl_frames_swim_down
        .byte 1 ; length in frames

boxgirl_frames_swim_down:
        .word boxgirl_oam_swim_down_1
        .byte $04, $05, $FF; oam length, mapper, delay frames

boxgirl_oam_swim_down_1:
        ;     Y-offset  Tile  Attr   X-offset
        .byte ($ff-31), 33,    $00,   0
        .byte ($ff-31), 35,    $00,   8
        .byte ($ff-15), 25,    $00,   0
        .byte ($ff-15), 27,    $00,   8

boxgirl_anim_swim_up:
        .word boxgirl_frames_swim_up
        .byte 1 ; length in frames

boxgirl_frames_swim_up:
        .word boxgirl_oam_swim_up_1
        .byte $04, $05, $FF; oam length, mapper, delay frames

boxgirl_oam_swim_up_1:
        ;     Y-offset  Tile  Attr   X-offset
        .byte ($ff-31), 37,    $00,   0
        .byte ($ff-31), 39,    $00,   8
        .byte ($ff-15), 25,    $00,   0
        .byte ($ff-15), 27,    $00,   8

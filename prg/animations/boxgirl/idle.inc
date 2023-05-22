.export boxgirl_anim_idle_right, boxgirl_anim_idle_left

boxgirl_anim_idle_right:
        .word boxgirl_frames_idle_right
        .byte 1 ; length in frames

boxgirl_frames_idle_right:
        .word boxgirl_oam_idle_right_1
        .byte $04, $05, $FF; oam length, mapper, delay frames

boxgirl_oam_idle_right_1:
        ;     Y-offset  Tile  Attr   X-offset
        .byte ($ff-31), 1,    $00,   0
        .byte ($ff-31), 3,    $00,   8
        .byte ($ff-15), 5,    $00,   0
        .byte ($ff-15), 7,    $00,   8

boxgirl_anim_idle_left:
        .word boxgirl_frames_idle_left
        .byte 1 ; length in frames

boxgirl_frames_idle_left:
        .word boxgirl_oam_idle_left_1
        .byte $04, $05, $FF; oam length, mapper, delay frames

boxgirl_oam_idle_left_1:
        ;     Y-offset  Tile  Attr   X-offset
        .byte ($ff-31), 3,    $40,   0
        .byte ($ff-31), 1,    $40,   8
        .byte ($ff-15), 7,    $40,   0
        .byte ($ff-15), 5,    $40,   8

boxgirl_anim_idle_down:
        .word boxgirl_frames_idle_down
        .byte 1 ; length in frames

boxgirl_frames_idle_down:
        .word boxgirl_oam_idle_down_1
        .byte $04, $05, $FF; oam length, mapper, delay frames

boxgirl_oam_idle_down_1:
        ;     Y-offset  Tile  Attr   X-offset
        .byte ($ff-31),  9,   $00,   0
        .byte ($ff-31), 11,   $00,   8
        .byte ($ff-15), 13,   $00,   0
        .byte ($ff-15), 15,   $00,   8

boxgirl_anim_idle_up:
        .word boxgirl_frames_idle_up
        .byte 1 ; length in frames

boxgirl_frames_idle_up:
        .word boxgirl_oam_idle_up_1
        .byte $04, $05, $FF; oam length, mapper, delay frames

boxgirl_oam_idle_up_1:
        ;     Y-offset  Tile  Attr   X-offset
        .byte ($ff-31), 17,   $00,   0
        .byte ($ff-31), 19,   $00,   8
        .byte ($ff-15), 21,   $00,   0
        .byte ($ff-15), 23,   $00,   8
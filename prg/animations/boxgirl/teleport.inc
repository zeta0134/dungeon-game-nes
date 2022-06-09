boxgirl_anim_teleport:
        .word boxgirl_frames_teleport
        .byte 4 ; length in frames

boxgirl_frames_teleport:
        .word boxgirl_oam_teleport_1
        .byte $04, $05, $1; oam length, mapper, delay frames
        .word boxgirl_oam_teleport_2
        .byte $04, $05, $1; oam length, mapper, delay frames
        .word boxgirl_oam_teleport_3
        .byte $04, $05, $1; oam length, mapper, delay frames
        .word boxgirl_oam_teleport_4
        .byte $04, $05, $1; oam length, mapper, delay frames

boxgirl_oam_teleport_1:
        ;     Y-offset  Tile  Attr   X-offset
        .byte ($ff-31), 1,    $00,   0
        .byte ($ff-31), 3,    $00,   8
        .byte ($ff-15), 5,    $00,   0
        .byte ($ff-15), 7,    $00,   8

boxgirl_oam_teleport_2:
        ;     Y-offset  Tile  Attr   X-offset
        .byte ($ff-31),  9,   $00,   0
        .byte ($ff-31), 11,   $00,   8
        .byte ($ff-15), 13,   $00,   0
        .byte ($ff-15), 15,   $00,   8

boxgirl_oam_teleport_3:
        ;     Y-offset  Tile  Attr   X-offset
        .byte ($ff-31), 3,    $40,   0
        .byte ($ff-31), 1,    $40,   8
        .byte ($ff-15), 7,    $40,   0
        .byte ($ff-15), 5,    $40,   8

boxgirl_oam_teleport_4:
        ;     Y-offset  Tile  Attr   X-offset
        .byte ($ff-31), 17,   $00,   0
        .byte ($ff-31), 19,   $00,   8
        .byte ($ff-15), 21,   $00,   0
        .byte ($ff-15), 23,   $00,   8


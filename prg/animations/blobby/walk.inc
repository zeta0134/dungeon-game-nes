.export blobby_anim_walk_right, blobby_anim_walk_left

blobby_anim_walk_right:
        .word blobby_frames_walk_right
        .byte 4

blobby_frames_walk_right:
        .word blobby_oam_walk_right1
        .byte $04, $04, 8; oam length, mapper, delay frames
        .word blobby_oam_walk_right2
        .byte $04, $04, 8
        .word blobby_oam_walk_right3
        .byte $04, $04, 8
        .word blobby_oam_walk_right4
        .byte $04, $04, 8

blobby_oam_walk_right1:
        ;     Y-offset  Tile  Attr   X-offset
        .byte 0,        0,    $00,    0
        .byte 8,        1,    $00,    0
        .byte 0,        4,    $40,    7
        .byte 8,        5,    $40,    7

blobby_oam_walk_right2:
        ;     Y-offset  Tile  Attr   X-offset
        .byte 0,        10,    $00,    0
        .byte 8,        11,    $00,    0
        .byte 0,        6,    $40,    8
        .byte 8,        7,    $40,    8

blobby_oam_walk_right3:
        ;     Y-offset  Tile  Attr   X-offset
        .byte 0,        0,    $00,    1
        .byte 8,        1,    $00,    1
        .byte 0,        4,    $40,    8
        .byte 8,        5,    $40,    8

blobby_oam_walk_right4:
        ;     Y-offset  Tile  Attr   X-offset
        .byte 0,        8,    $00,    0
        .byte 8,        9,    $00,    0
        .byte 0,        4,    $40,    8
        .byte 8,        5,    $40,    8

blobby_anim_walk_left:
        .word blobby_frames_walk_left
        .byte 4

blobby_frames_walk_left:
        .word blobby_oam_walk_left1
        .byte $04, $04, 8; oam length, mapper, delay frames
        .word blobby_oam_walk_left2
        .byte $04, $04, 8
        .word blobby_oam_walk_left3
        .byte $04, $04, 8
        .word blobby_oam_walk_left4
        .byte $04, $04, 8

blobby_oam_walk_left1:
        ;     Y-offset  Tile  Attr   X-offset
        .byte 0,        4,    $00,    1
        .byte 8,        5,    $00,    1
        .byte 0,        0,    $40,    8
        .byte 8,        1,    $40,    8

blobby_oam_walk_left2:
        ;     Y-offset  Tile  Attr   X-offset
        .byte 0,        6,    $00,    0
        .byte 8,        7,    $00,    0
        .byte 0,        10,    $40,    8
        .byte 8,        11,    $40,    8

blobby_oam_walk_left3:
        ;     Y-offset  Tile  Attr   X-offset
        .byte 0,        4,    $00,    0
        .byte 8,        5,    $00,    0
        .byte 0,        0,    $40,    7
        .byte 8,        1,    $40,    7

blobby_oam_walk_left4:
        ;     Y-offset  Tile  Attr   X-offset
        .byte 0,        4,    $00,    0
        .byte 8,        5,    $00,    0
        .byte 0,        8,    $40,    8
        .byte 8,        9,    $40,    8
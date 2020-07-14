.export blobby_anim_walk_right
.export blobby_anim_walk_left
.export blobby_anim_walk_up
.export blobby_anim_walk_down

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

blobby_anim_walk_up:
        .word blobby_frames_walk_up
        .byte 4

blobby_frames_walk_up:
        .word blobby_oam_walk_up1
        .byte $04, $04, 8; oam length, mapper, delay frames
        .word blobby_oam_walk_up2
        .byte $04, $04, 8
        .word blobby_oam_walk_up3
        .byte $04, $04, 8
        .word blobby_oam_walk_up2
        .byte $04, $04, 8

blobby_oam_walk_up1:
        ;     Y-offset  Tile  Attr   X-offset
        .byte 255,      28,    $00,    0
        .byte   7,      29,    $00,    0
        .byte 255,      28,    $40,    8
        .byte   7,      29,    $40,    8

blobby_oam_walk_up2:
        ;     Y-offset  Tile  Attr   X-offset
        .byte 0,        20,    $00,    0
        .byte 8,        21,    $00,    0
        .byte 0,        20,    $40,    8
        .byte 8,        21,    $40,    8

blobby_oam_walk_up3:
        ;     Y-offset  Tile  Attr   X-offset
        .byte 0,        22,    $00,    0
        .byte 8,        23,    $00,    0
        .byte 0,        22,    $40,    8
        .byte 8,        23,    $40,    8

blobby_anim_walk_down:
        .word blobby_frames_walk_down
        .byte 4

blobby_frames_walk_down:
        .word blobby_oam_walk_down1
        .byte $04, $04, 8; oam length, mapper, delay frames
        .word blobby_oam_walk_down2
        .byte $04, $04, 8
        .word blobby_oam_walk_down3
        .byte $04, $04, 8
        .word blobby_oam_walk_down4
        .byte $04, $04, 8

blobby_oam_walk_down1:
        ;     Y-offset  Tile  Attr   X-offset
        .byte 0,      28,    $00,    0
        .byte 8,      29,    $00,    0
        .byte 0,      28,    $40,    8
        .byte 8,      29,    $40,    8

blobby_oam_walk_down2:
        ;     Y-offset  Tile  Attr   X-offset
        .byte 1,        16,    $00,    0
        .byte 9,        17,    $00,    0
        .byte 1,        16,    $40,    8
        .byte 9,        17,    $40,    8

blobby_oam_walk_down3:
        ;     Y-offset  Tile  Attr   X-offset
        .byte 0,        18,    $00,    0
        .byte 8,        19,    $00,    0
        .byte 0,        18,    $40,    8
        .byte 8,        19,    $40,    8

blobby_oam_walk_down4:
        ;     Y-offset  Tile  Attr   X-offset
        .byte 0,        16,    $00,    0
        .byte 8,        17,    $00,    0
        .byte 0,        16,    $40,    8
        .byte 8,        17,    $40,    8
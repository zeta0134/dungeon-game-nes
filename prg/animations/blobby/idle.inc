.export blobby_anim_idle, blobby_anim_idle_alt, blobby_anim_rest

blobby_anim_idle:
        .word blobby_frames_idle
        .byte 2

blobby_frames_idle:
        .word blobby_oam_idle1
        .byte $04, $04, 20; oam length, mapper, delay frames
        .word blobby_oam_idle2
        .byte $04, $04, 20

blobby_anim_idle_alt:
        .word blobby_frames_idle_alt
        .byte 4

blobby_frames_idle_alt:
        .word blobby_oam_idle1
        .byte $04, $04, 20; oam length, mapper, delay frames
        .word blobby_oam_idle3
        .byte $04, $04, 20
        .word blobby_oam_idle1
        .byte $04, $04, 20
        .word blobby_oam_idle4
        .byte $04, $04, 20

blobby_oam_idle1:
        ;     Y-offset  Tile  Attr   X-offset
        .byte 0,        0,    $00,    0
        .byte 8,        1,    $00,    0
        .byte 0,        0,    $40,    8
        .byte 8,        1,    $40,    8

blobby_oam_idle2:
        ;     Y-offset  Tile  Attr    X-offset
        .byte 0,        2,    $00,    0
        .byte 8,        3,    $00,    0
        .byte 0,        2,    $40,    8
        .byte 8,        3,    $40,    8

; lean left
blobby_oam_idle3:
        ;     Y-offset  Tile  Attr    X-offset
        .byte 0,        2,    $00,    255
        .byte 8,        7,    $00,    0
        .byte 0,        2,    $40,    7
        .byte 8,        1,    $40,    7

; lean right
blobby_oam_idle4:
        ;     Y-offset  Tile  Attr    X-offset
        .byte 0,        2,    $00,    1
        .byte 8,        1,    $00,    1
        .byte 0,        2,    $40,    9
        .byte 8,        7,    $40,    8

blobby_anim_rest:
        .word blobby_frames_rest
        .byte 2

blobby_frames_rest:
        .word blobby_oam_rest1
        .byte $04, $04, 30; oam length, mapper, delay frames
        .word blobby_oam_rest2
        .byte $04, $04, 30; oam length, mapper, delay frames

blobby_oam_rest1:
        ;     Y-offset  Tile  Attr   X-offset
        .byte 0,        30,    $00,    0
        .byte 8,        31,    $00,    0
        .byte 0,        30,    $40,    8
        .byte 8,        31,    $40,    8

blobby_oam_rest2:
        ;     Y-offset  Tile  Attr   X-offset
        .byte 0,        16,    $00,    0
        .byte 8,        31,    $00,    0
        .byte 0,        16,    $40,    8
        .byte 8,        31,    $40,    8
.export blobby_anim_roll

blobby_anim_roll:
        .word blobby_frames_roll
        .byte 12

blobby_frames_roll:
        .word blobby_oam_idle1
        .byte $04, $04, 5
        .word blobby_oam_roll1
        .byte $04, $04, 5
        .word blobby_oam_roll2
        .byte $04, $04, 7
        .word blobby_oam_roll3
        .byte $04, $04, 12
        .word blobby_oam_roll2
        .byte $04, $04, 7
        .word blobby_oam_roll1
        .byte $04, $04, 5
        .word blobby_oam_idle1
        .byte $04, $04, 5
        .word blobby_oam_roll4
        .byte $04, $04, 5
        .word blobby_oam_roll5
        .byte $04, $04, 7
        .word blobby_oam_roll6
        .byte $04, $04, 12
        .word blobby_oam_roll5
        .byte $04, $04, 7
        .word blobby_oam_roll4
        .byte $04, $04, 5

; to the left!
blobby_oam_roll1:
        ;     Y-offset  Tile  Attr   X-offset
        .byte 0,        0,    $00,    255
        .byte 8,        1,    $00,    255
        .byte 0,        0,    $40,    7
        .byte 8,        1,    $40,    7

; squish
blobby_oam_roll2:
        ;     Y-offset  Tile  Attr   X-offset
        .byte 0,        2,    $00,    254
        .byte 8,        3,    $00,    254
        .byte 0,        2,    $40,    6
        .byte 8,        3,    $40,    6

; squish MORE
blobby_oam_roll3:
        ;     Y-offset  Tile  Attr   X-offset
        .byte 0,        2,    $00,    254
        .byte 8,        3,    $00,    254
        .byte 0,        2,    $40,    5
        .byte 8,        3,    $40,    5

; to the right!
blobby_oam_roll4:
        ;     Y-offset  Tile  Attr   X-offset
        .byte 0,        0,    $00,    1
        .byte 8,        1,    $00,    1
        .byte 0,        0,    $40,    9
        .byte 8,        1,    $40,    9

; squish
blobby_oam_roll5:
        ;     Y-offset  Tile  Attr   X-offset
        .byte 0,        2,    $00,    2
        .byte 8,        3,    $00,    2
        .byte 0,        2,    $40,    10
        .byte 8,        3,    $40,    10

; squish MOAR
blobby_oam_roll6:
        ;     Y-offset  Tile  Attr   X-offset
        .byte 0,        2,    $00,    3
        .byte 8,        3,    $00,    3
        .byte 0,        2,    $40,    10
        .byte 8,        3,    $40,    10

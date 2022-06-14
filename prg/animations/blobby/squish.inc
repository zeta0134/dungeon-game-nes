.export blobby_anim_squish

blobby_anim_squish:
        .word blobby_frames_squish
        .byte 9

blobby_frames_squish:
        .word blobby_oam_squish1 ; 15
        .byte $02, $04, 3; oam length, mapper, delay frames
        .word blobby_oam_squish2 ; 13
        .byte $02, $04, 2
        .word blobby_oam_squish3 ; 31
        .byte $02, $04, 10
        .word blobby_oam_squish4 ; 30
        .byte $02, $04, 2
        .word blobby_oam_squish5 ; 1
        .byte $02, $04, 2
        .word blobby_oam_squish6 ; 3
        .byte $02, $04, 5
        .word blobby_oam_squish7 ; 1
        .byte $02, $04, 2
        .word blobby_oam_squish8 ; 30
        .byte $02, $04, 5
        .word blobby_oam_squish9 ; 1
        .byte $02, $04, 254 ; hold until idle

blobby_oam_squish1:
        ;     Y-offset  Tile  Attr   X-offset
        .byte ($ff-15),        15,    $00,    0
        .byte ($ff-15),        15,    $40,    8

blobby_oam_squish2:
        ;     Y-offset  Tile  Attr    X-offset
        .byte ($ff-15),        13,    $00,    0
        .byte ($ff-15),        13,    $40,    8

blobby_oam_squish3:
        ;     Y-offset  Tile  Attr    X-offset
        .byte ($ff-15),        31,    $00,    0
        .byte ($ff-15),        31,    $40,    8

blobby_oam_squish4:
        ;     Y-offset  Tile  Attr    X-offset
        .byte ($ff-15),        29,    $00,    0
        .byte ($ff-15),        29,    $40,    8

blobby_oam_squish5:
        ;     Y-offset  Tile  Attr    X-offset
        .byte ($ff-15),        1,    $00,    0
        .byte ($ff-15),        1,    $40,    8

blobby_oam_squish6:
        ;     Y-offset  Tile  Attr    X-offset
        .byte ($ff-15),        3,    $00,    0
        .byte ($ff-15),        3,    $40,    8

blobby_oam_squish7:
        ;     Y-offset  Tile  Attr    X-offset
        .byte ($ff-15),        1,    $00,    0
        .byte ($ff-15),        1,    $40,    8

blobby_oam_squish8:
        ;     Y-offset  Tile  Attr    X-offset
        .byte ($ff-15),        29,    $00,    0
        .byte ($ff-15),        29,    $40,    8

blobby_oam_squish9:
        ;     Y-offset  Tile  Attr    X-offset
        .byte ($ff-15),        1,    $00,    0
        .byte ($ff-15),        1,    $40,    8
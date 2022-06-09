.export blobby_anim_idle, blobby_anim_rest

blobby_anim_idle:
        .word blobby_frames_idle
        .byte 2

blobby_frames_idle:
        .word blobby_oam_idle1
        .byte $02, $04, 20; oam length, mapper, delay frames
        .word blobby_oam_idle2
        .byte $02, $04, 20

blobby_oam_idle1:
        ;     Y-offset  Tile  Attr   X-offset
        .byte ($ff-15),        1,    $00,    0
        .byte ($ff-15),        1,    $40,    8

blobby_oam_idle2:
        ;     Y-offset  Tile  Attr    X-offset
        .byte ($ff-15),        3,    $00,    0
        .byte ($ff-15),        3,    $40,    8

blobby_anim_rest:
        .word blobby_frames_rest
        .byte 2

blobby_frames_rest:
        .word blobby_oam_rest1
        .byte $02, $04, 30; oam length, mapper, delay frames
        .word blobby_oam_rest2
        .byte $02, $04, 30; oam length, mapper, delay frames

blobby_oam_rest1:
        ;     Y-offset  Tile  Attr   X-offset
        .byte ($ff-15),        31,    $00,    0
        .byte ($ff-15),        31,    $40,    8

blobby_oam_rest2:
        ;     Y-offset  Tile  Attr   X-offset
        .byte ($ff-15),        17,    $00,    0
        .byte ($ff-15),        17,    $40,    8

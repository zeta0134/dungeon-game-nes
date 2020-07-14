.export blobby_anim_chargeA
.export blobby_anim_chargeB
.export blobby_anim_chargeC


blobby_anim_chargeA:
        .word blobby_frames_chargeA
        .byte 2

blobby_frames_chargeA:
        .word blobby_oam_chargeA1
        .byte $04, $04, 6; oam length, mapper, delay frames
        .word blobby_oam_chargeA2
        .byte $04, $04, 6

blobby_oam_chargeA1:
        ;     Y-offset  Tile  Attr   X-offset
        .byte 0,        14,    $00,    0
        .byte 8,        15,    $00,    0
        .byte 0,        14,    $40,    8
        .byte 8,        15,    $40,    8

blobby_oam_chargeA2:
        ;     Y-offset  Tile  Attr   X-offset
        .byte 0,        24,    $00,    0
        .byte 8,        25,    $00,    0
        .byte 0,        24,    $40,    8
        .byte 8,        25,    $40,    8

blobby_anim_chargeB:
        .word blobby_frames_chargeB
        .byte 4

blobby_frames_chargeB:
        .word blobby_oam_chargeB1
        .byte $04, $04, 3; oam length, mapper, delay frames
        .word blobby_oam_chargeB2
        .byte $04, $04, 3
        .word blobby_oam_chargeB3
        .byte $04, $04, 3; oam length, mapper, delay frames
        .word blobby_oam_chargeB2
        .byte $04, $04, 3

blobby_oam_chargeB1:
        ;     Y-offset  Tile  Attr   X-offset
        .byte 0,        26,    $00,    255
        .byte 8,        27,    $00,    255
        .byte 0,        26,    $40,    7
        .byte 8,        27,    $40,    7

blobby_oam_chargeB2:
        ;     Y-offset  Tile  Attr   X-offset
        .byte 0,        12,    $00,    0
        .byte 8,        13,    $00,    0
        .byte 0,        12,    $40,    8
        .byte 8,        13,    $40,    8

blobby_oam_chargeB3:
        ;     Y-offset  Tile  Attr   X-offset
        .byte 0,        26,    $00,    1
        .byte 8,        27,    $00,    1
        .byte 0,        26,    $40,    9
        .byte 8,        27,    $40,    9

blobby_anim_chargeC:
        .word blobby_frames_chargeC
        .byte 4

blobby_frames_chargeC:
        .word blobby_oam_chargeC1
        .byte $04, $04, 1; oam length, mapper, delay frames
        .word blobby_oam_chargeC2
        .byte $04, $04, 1
        .word blobby_oam_chargeC3
        .byte $04, $04, 1; oam length, mapper, delay frames
        .word blobby_oam_chargeC4
        .byte $04, $04, 1

blobby_oam_chargeC1:
        ;     Y-offset  Tile  Attr   X-offset
        .byte  1,        26,    $00,    1
        .byte  9,        27,    $00,    1
        .byte  1,        26,    $40,    9
        .byte  9,        27,    $40,    9

blobby_oam_chargeC2:
        ;     Y-offset  Tile  Attr   X-offset
        .byte  1,        26,    $01,    255
        .byte  9,        27,    $01,    255
        .byte  1,        26,    $41,    7
        .byte  9,        27,    $41,    7

blobby_oam_chargeC3:
        ;     Y-offset  Tile  Attr   X-offset
        .byte 255,        26,    $02,    255
        .byte   7,        27,    $02,    255
        .byte 255,        26,    $42,    7
        .byte   7,        27,    $42,    7

blobby_oam_chargeC4:
        ;     Y-offset  Tile  Attr   X-offset
        .byte 255,        26,    $03,    1
        .byte   7,        27,    $03,    1
        .byte 255,        26,    $43,    9
        .byte   7,        27,    $43,    9
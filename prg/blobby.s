        .setcpu "6502"
        .include "sprites.inc"

.scope PRGLAST_E000
        .segment "PRGLAST_E000"
        ;.org $e000

.export blobby_oam_idle1, blobby_anim_idle, blobby_anim_jump, blobby_anim_idle_alt, blobby_anim_roll

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
        .byte 8,        3,    $00,    0
        .byte 0,        2,    $40,    7
        .byte 8,        1,    $40,    7

; lean right
blobby_oam_idle4:
        ;     Y-offset  Tile  Attr    X-offset
        .byte 0,        2,    $00,    1
        .byte 8,        1,    $00,    1
        .byte 0,        2,    $40,    9
        .byte 8,        3,    $40,    8


blobby_anim_jump:
        .word blobby_frames_jump
        .byte 22

blobby_frames_jump:
        .word blobby_oam_jump1
        .byte $04, $04, 15; oam length, mapper, delay frames
        .word blobby_oam_idle1
        .byte $04, $04, 4
        .word blobby_oam_idle2
        .byte $04, $04, 3
        .word blobby_oam_jump4
        .byte $04, $04, 2
        .word blobby_oam_jump5
        .byte $04, $04, 1
        .word blobby_oam_jump6
        .byte $04, $04, 1
        .word blobby_oam_jump7
        .byte $04, $04, 2
        .word blobby_oam_jump8
        .byte $04, $04, 4
        .word blobby_oam_jump9
        .byte $04, $04, 4
        .word blobby_oam_jump10
        .byte $04, $04, 12
        ; reverse all the way down
        .word blobby_oam_jump9
        .byte $04, $04, 4
        .word blobby_oam_jump8
        .byte $04, $04, 4
        .word blobby_oam_jump7
        .byte $04, $04, 2
        .word blobby_oam_jump6
        .byte $04, $04, 2
        .word blobby_oam_jump5
        .byte $04, $04, 1
        .word blobby_oam_jump4
        .byte $04, $04, 1
        .word blobby_oam_idle2
        .byte $04, $04, 2
        .word blobby_oam_idle1
        .byte $04, $04, 4
        ; blob a bit to sell a recovery
        .word blobby_oam_jump1
        .byte $04, $04, 4
        .word blobby_oam_idle1
        .byte $04, $04, 4
        .word blobby_oam_jump1
        .byte $04, $04, 4
        ; and rest
        .word blobby_oam_idle1
        .byte $04, $04, 60


; squish down horizontally
blobby_oam_jump1:
        ;     Y-offset  Tile  Attr    X-offset
        .byte 1,        0,    $00,    0
        .byte 8,        1,    $00,    0
        .byte 1,        0,    $40,    8
        .byte 8,        1,    $40,    8

; reuse 2 idle frames here

; squish vertically during takeoff
blobby_oam_jump4:
        .byte 255,        2,    $00,    0
        .byte   7,        3,    $00,    0
        .byte 255,        2,    $40,    8
        .byte   7,        3,    $40,    8

blobby_oam_jump5:
        .byte 254,        2,    $00,    1
        .byte   6,        3,    $00,    1
        .byte 254,        2,    $40,    7
        .byte   6,        3,    $40,    7

blobby_oam_jump6:
        .byte 253,        2,    $00,    1
        .byte   5,        3,    $00,    1
        .byte 253,        2,    $40,    7
        .byte   5,        3,    $40,    7

blobby_oam_jump7:
        .byte 252,        2,    $00,    0
        .byte   4,        3,    $00,    0
        .byte 252,        2,    $40,    8
        .byte   4,        3,    $40,    8
        
; decompress mid-air
blobby_oam_jump8:
        .byte 252,        2,    $00,    0
        .byte   4,        3,    $00,    0
        .byte 252,        2,    $40,    8
        .byte   4,        3,    $40,    8

blobby_oam_jump9:
        .byte 251,        2,    $00,    0
        .byte   3,        3,    $00,    0
        .byte 251,        2,    $40,    8
        .byte   3,        3,    $40,    8

blobby_oam_jump10:
        .byte 250,        0,    $00,    0
        .byte   2,        1,    $00,    0
        .byte 250,        0,    $40,    8
        .byte   2,        1,    $40,    8

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


.endscope

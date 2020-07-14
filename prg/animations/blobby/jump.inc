.export blobby_anim_jump

blobby_anim_jump:
        .word blobby_frames_jump
        .byte 23

blobby_frames_jump:
        .word blobby_oam_hsquish
        .byte $04, $04, 2; oam length, mapper, delay frames
        .word blobby_oam_hsquish_blink
        .byte $04, $04, 10
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
        .word blobby_oam_hsquish_blink
        .byte $04, $04, 4
        .word blobby_oam_idle1
        .byte $04, $04, 4
        .word blobby_oam_hsquish
        .byte $04, $04, 4
        ; and rest
        .word blobby_oam_idle1
        .byte $04, $04, 60


; squish down horizontally
blobby_oam_hsquish_blink:
        ;     Y-offset  Tile  Attr    X-offset
        .byte 1,        20,    $00,    0
        .byte 8,        21,    $00,    0
        .byte 1,        20,    $40,    8
        .byte 8,        21,    $40,    8

blobby_oam_hsquish:
        ;     Y-offset  Tile  Attr    X-offset
        .byte 1,        0,    $00,    0
        .byte 8,        1,    $00,    0
        .byte 1,        0,    $40,    8
        .byte 8,        1,    $40,    8

; reuse 2 idle frames here

; squish vertically during takeoff
blobby_oam_jump4:
        .byte 254,        2,    $00,    0;-1
        .byte   6,        3,    $00,    0
        .byte 254,        2,    $40,    8
        .byte   6,        3,    $40,    8

blobby_oam_jump5:
        .byte 252,        6,    $00,    1;-2
        .byte   4,        7,    $00,    1
        .byte 252,        6,    $40,    7
        .byte   4,        7,    $40,    7

blobby_oam_jump6:
        .byte 250,        6,    $00,    1;-3
        .byte   2,        7,    $00,    1
        .byte 250,        6,    $40,    7
        .byte   2,        7,    $40,    7

blobby_oam_jump7:
        .byte 248,        2,    $00,    0;-4
        .byte   0,        3,    $00,    0
        .byte 248,        2,    $40,    8
        .byte   0,        3,    $40,    8
        
; decompress mid-air
blobby_oam_jump8:
        .byte 248,        2,    $00,    0;-4
        .byte   0,        3,    $00,    0
        .byte 248,        2,    $40,    8
        .byte   0,        3,    $40,    8

blobby_oam_jump9:
        .byte 247,        2,    $00,    0;-5
        .byte 255,        3,    $00,    0
        .byte 247,        2,    $40,    8
        .byte 255,        3,    $40,    8

blobby_oam_jump10:
        .byte 246,        0,    $00,    0;-6
        .byte 254,        1,    $00,    0
        .byte 246,        0,    $40,    8
        .byte 254,        1,    $40,    8
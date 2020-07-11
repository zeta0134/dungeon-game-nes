        .setcpu "6502"
        .include "sprites.inc"

.scope PRGLAST_E000
        .segment "PRGLAST_E000"
        ;.org $e000

.export blobby_oam_idle1, blobby_anim_idle

blobby_anim_idle:
        .word blobby_frames_idle
        .byte $2

blobby_frames_idle:
        .word blobby_oam_idle1
        .byte $04, $04, 2; oam length, mapper, delay frames
        .word blobby_oam_idle2
        .byte $04, $04, 4

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


.endscope

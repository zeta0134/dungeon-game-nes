        .setcpu "6502"
        .include "sprites.inc"

.scope PRGLAST_E000
        .segment "PRGLAST_E000"
        ;.org $e000

.export blobby_oam_idle1

blobby_anim_idle:
        .word blobby_frames_idle
        .byte $2

blobby_frames_idle:
        .word blobby_oam_idle1
        .byte $04, $04, 20; oam length, mapper, delay frames
        .word blobby_oam_idle2
        .byte $04, $04, 40

blobby_oam_idle1:
        ;     Y-offset  Tile  Attr   X-offset
        .byte 0,        0,    $01,    0
        .byte 8,        1,    $01,    0
        .byte 0,        0,    $41,    8
        .byte 8,        1,    $41,    8

blobby_oam_idle2:
        ;     Y-offset  Tile  Attr    X-offset
        .byte 0,        2,    $01,    0
        .byte 8,        3,    $01,    0
        .byte 0,        2,    $41,    8
        .byte 8,        3,    $41,    8


.endscope

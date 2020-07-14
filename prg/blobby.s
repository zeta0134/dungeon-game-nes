        .setcpu "6502"
        .include "sprites.inc"

.scope PRGLAST_E000
        .segment "PRGLAST_E000"
        ;.org $e000
        .include "animations/blobby/idle.inc"
        .include "animations/blobby/jump.inc" ;note: currently depends on idle.inc!
        .include "animations/blobby/roll.inc" ;note: currently depends on idle.inc!
        .include "animations/blobby/walk.inc"
        .include "animations/blobby/charge.inc"

.endscope

        .setcpu "6502"

.scope CHR1
        .segment "CHR1"
        .align $400
        .incbin "build/sprites/blobby.chr"
.endscope
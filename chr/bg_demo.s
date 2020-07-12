        .setcpu "6502"

.scope CHR0
        .segment "CHR0"
        .align $800
        .incbin "build/tilesets/skull_tiles.chr"

        .align $800
        .incbin "build/tilesets/statusbar.chr"
.endscope

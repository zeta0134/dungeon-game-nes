        .setcpu "6502"

        .segment "BG0"
blank_index_0:
        .repeat $800
        .byte $00
        .endrepeat

        .segment "BG1"
hud_graphics:
        .incbin "build/tilesets/statusbar.chr"

        .segment "BG2"
        .incbin "build/tilesets/skull_tiles.chr"

        .segment "OBJ0"
blobby_graphics:
        .incbin "build/sprites/blobby.chr"
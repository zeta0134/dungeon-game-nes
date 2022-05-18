        .setcpu "6502"

        .segment "BG0"
blank_index_0:
        .repeat $800
        .byte $00
        .endrepeat

        .segment "BG1"
hud_graphics:
        .include "../build/tilesets/statusbar.chr"

        .segment "BG2"
        .include "../build/tilesets/tiles_3d.chr"

        .segment "OBJ0"
boxgirl_graphics:
        .incbin "build/sprites/greybox.chr"
        .incbin "build/sprites/shadow.chr"

        .segment "OBJ1"
blobby_graphics:
        .incbin "build/sprites/blobby.chr"

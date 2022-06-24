        .setcpu "6502"

        .segment "BG0"
blank_index_0:
        .repeat $800
        .byte $FF
        .endrepeat

        .segment "BG1"
hud_graphics:
        .incbin "../art/raw_chr/hud.chr"

        .segment "BG2"
        ;.include "../build/tilesets/tiles_3d.chr"

        .segment "BG3"
        ;.include "../build/tilesets/grassy_fields.chr"

        .segment "BG4"
        .include "../build/patternsets/grassy_fields_v3.chr"

        .segment "BG5"
        .include "../build/patternsets/test_tiles_3d.chr"

        .segment "OBJ0"
boxgirl_graphics:
        .incbin "build/sprites/greybox.chr"
        .incbin "build/sprites/shadow.chr"

        .segment "OBJ1"
blobby_graphics:
        .incbin "build/sprites/blobby.chr"

        .setcpu "6502"

        .segment "BG0"
blank_index_0:
        .repeat $800
        .byte $00
        .endrepeat

        .segment "BG1"
blank_index_3:
        .repeat $800
        .byte $FF
        .endrepeat

        .segment "BG2"
hud_graphics:
        .incbin "../art/raw_chr/hud.chr"

        .segment "BG3"
        .include "../build/patternsets/grassy_fields_v3.chr"

        .segment "BG4"
        .include "../build/patternsets/test_tiles_3d.chr"

        .segment "BG5"
        .include "../build/patternsets/greybox.chr"        

        .segment "BG6"
        .include "../build/fonts/finkheavy8x15.high.chr"

        .segment "BG7"
        .include "../build/fonts/finkheavy8x15.low.chr"

        .segment "BG8"
        .include "../build/dialog_portraits/zero.even.chr"
        .include "../build/dialog_portraits/ciel.even.chr"

        .segment "BG9"
        .include "../build/dialog_portraits/zero.odd.chr"
        .include "../build/dialog_portraits/ciel.odd.chr"

        .segment "OBJ0"
boxgirl_graphics:
        .incbin "build/sprites/greybox.chr"

        .segment "OBJ1"
shadow_graphics:
        .incbin "build/sprites/shadow.chr"
particle_graphics:
        .incbin "build/sprites/particles.chr"

        .segment "OBJ2"
blobby_graphics:
        .incbin "build/sprites/blobby.chr"

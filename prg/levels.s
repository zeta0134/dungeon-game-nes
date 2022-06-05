        .include "levels.inc"
        
        .segment "MAPS_0_A000"
; note: this is probably a bad idea
test_maps:
        .include "../build/maps/test_room_3d.incs"
        .include "../build/maps/bridges.incs"
test_tileset:
        .include "../build/tilesets/tiles_3d.mt"
        .include "../build/tilesets/grassy_fields.mt"
grassy_fields_pal:
        .incbin "../build/tilesets/grassy_fields.pal"
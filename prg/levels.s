        .include "levels.inc"
        
        .segment "MAPS_0_A000"
        ; Maps
        .include "../build/maps/test_room_3d.incs"
        .include "../build/maps/bridges.incs"
        ; Tilesets
        .include "../build/tilesets/tiles_3d.mt"
        .include "../build/tilesets/grassy_fields.mt"
        ; Palettes
        .include "../build/tilesets/grassy_fields.pal"
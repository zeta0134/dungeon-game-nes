        .include "levels.inc"

        ; levels may reference AI states, so include those references here
        .include "blobby.inc"
        .include "boxgirl.inc"
        
        .segment "MAPS_0_A000"
        ; Maps
        .include "../tools/v3_test_map.incs"
        .include "../build/maps/test_room_3d.incs"
        .include "../build/maps/bridges.incs"
        ; Tilesets
        .include "../build/tilesets/tiles_3d.mt"
        .include "../build/tilesets/grassy_fields.mt"

        .include "../tools/grassy_fields_v3.mt"
        .include "../tools/test_tiles_3d.mt"
        ; Palettes
        .include "../build/tilesets/tiles_3d.pal"
        .include "../build/tilesets/grassy_fields.pal"
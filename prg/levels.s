        .include "levels.inc"
        .include "level_logic.inc"
        .include "saves.inc"
        .include "text.inc"

        ; levels may reference AI states, so include those references here
        .include "blobby.inc"
        .include "boxgirl.inc"
        
        .segment "MAPS_0_A000"
        ; Maps
        .include "../build/maps/debug_hub.incs"
        .include "../build/maps/grassy_test_v3.incs"
        .include "../build/maps/horizontal_platforms.incs"
        .include "../build/maps/greybox_test.incs"
        .include "../build/maps/underwater_test.incs"
        .include "../build/maps/ramp_test.incs"
        .include "../build/maps/overlay_test.incs"

        ; Tilesets
        .include "../build/patternsets/grassy_fields_v3.mt"
        .include "../build/patternsets/test_tiles_3d.mt"
        .include "../build/patternsets/greybox.mt"
        

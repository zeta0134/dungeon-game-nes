.global load_map, load_tileset, load_entities

.struct MapHeader
        width .byte
        height .byte
        graphics_ptr .word
        collision_ptr .word
        entrance_table_ptr .word
        exit_table_ptr .word
        entity_table_ptr .word
        first_tileset .word
        second_tileset .word
        palette_ptr .word
        attributes_ptr .word
        music_track .byte
        music_variant .byte
        distortion_index .byte
        color_emphasis .byte
        logic_function .word
        overlay_list .word
        trigger_list .word
.endstruct

.struct ExitTableEntry
        tile_x .byte
        tile_y .byte
        target_map .word
        target_bank .byte
        target_entrance .byte
.endstruct

.struct TriggerTableEntry
        tile_x .byte
        tile_y .byte
        id .byte
        data0 .byte
        data1 .byte
        data2 .byte
        data3 .byte
        data4 .byte
.endstruct

; block types
SURFACE_EXIT     = (1 << 2)
RISING_HAZARD    = (2 << 2)
SHALLOW_WATER    = (3 << 2)
DEEP_WATER       = (4 << 2)
SWITCH_UNPRESSED = (5 << 2)
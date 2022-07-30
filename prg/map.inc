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
.endstruct

.struct ExitTableEntry
        tile_x .byte
        tile_y .byte
        target_map .word
        target_bank .byte
        target_entrance .byte
.endstruct
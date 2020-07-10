.import initialize_oam, draw_metasprite
.importzp OAMTableLength, OAMEntryIndex, OAMTableAddr, MetaspritePosX, MetaspritePosY

.struct AnimationHeader
        FrameTableAddr .word
        Length .byte
.endstruct

.struct AnimationFrame
        OAMTableAddr .word
        OAMLength .byte
        MapperBank .byte
        DelayFrames .byte
.endstruct

.struct OAMEntry
        YOffset .byte
        TileIndex .byte
        Attributes .byte
        XOffset .byte
.endstruct


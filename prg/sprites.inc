.import initialize_oam

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
        XOffset .byte
        YOffset .byte
        TileIndex .byte
        Attributes .byte
.endstruct


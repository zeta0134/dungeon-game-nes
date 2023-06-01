.global FAR_init_subscreen
.global FAR_update_subscreen


CURSOR_TL_OAM_INDEX = 16
CURSOR_TR_OAM_INDEX = 20
CURSOR_BL_OAM_INDEX = 24
CURSOR_BR_OAM_INDEX = 28

SHADOW_CURSOR_TL_OAM_INDEX = 32
SHADOW_CURSOR_TR_OAM_INDEX = 36
SHADOW_CURSOR_BL_OAM_INDEX = 40
SHADOW_CURSOR_BR_OAM_INDEX = 44

CURSOR_TL_TILE = 83
CURSOR_TR_TILE = 85
CURSOR_BL_TILE = 87
CURSOR_BR_TILE = 89

.struct Layout
        Length .byte ; in regions
        RegionsPtr .word
.endstruct

.struct Region
        PositionTop .byte
        PositionBottom .byte
        PositionLeft .byte
        PositionRight .byte
        ExitUp .byte
        ExitDown .byte
        ExitLeft .byte
        ExitRight .byte
.endstruct

; used internally by various menu screens
.global click_unimplemented_slot

.global initialize_cursor_pos
.global draw_cursor
.global draw_shadow_cursor
.global handle_click
.global handle_move_cursor
.global lerp_cursor_position
.global activate_shadow_cursor
.global hide_shadow_cursor

.global LayoutPtr
.global BehaviorPtr
.global CurrentRegionIndex
.global ShadowRegionIndex
.global ShadowCursorShown

.global FAR_initialize_actions
.global FAR_draw_ability_icon_immediate, FAR_draw_ability_icon_buffered
.global FAR_draw_ability_icon_buffered_top_row, FAR_draw_ability_icon_buffered_bottom_row
.global FAR_update_action_masks

.global action_memory
.global actionset_a
.global actionset_b
.global actionset_c
.global action_inventory

; Action Index IDs
ACTION_NONE = 0
; Implemented
ACTION_DASH = 1
ACTION_JUMP = 2
; Unimplemented
ACTION_FEATHER = 3
ACTION_FIRE = 4
ACTION_HAMMER = 5

; Action button masks
ACTION_BUTTON_DASH =    (1 << (ACTION_DASH - 1))
ACTION_BUTTON_JUMP =    (1 << (ACTION_JUMP - 1))
ACTION_BUTTON_FEATHER = (1 << (ACTION_FEATHER - 1))
ACTION_BUTTON_FIRE =    (1 << (ACTION_FIRE - 1))
ACTION_BUTTON_HAMMER =  (1 << (ACTION_HAMMER - 1))




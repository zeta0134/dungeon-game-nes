.global FAR_initialize_actions
.global FAR_draw_ability_icon_immediate, FAR_draw_ability_icon_buffered
.global FAR_draw_ability_icon_buffered_top_row, FAR_draw_ability_icon_buffered_bottom_row
.global FAR_update_action_masks, FAR_update_action_buttons

.global action_memory
.global actionset_a
.global actionset_b
.global actionset_c
.global action_inventory

.global actions_down_low
.global actions_down_high
.global actions_held_low
.global actions_held_high
.global actions_released_low
.global actions_released_high

.global action_a_slot
.global action_a_id
.global action_b_slot
.global action_b_id

; Action Index IDs
ACTION_NONE = 0
; Implemented
ACTION_JUMP = 1
ACTION_DASH = 2
; Unimplemented
ACTION_FEATHER = 3
ACTION_FIRE = 4
ACTION_HAMMER = 5

.macro if_action_held ACTION_ID
.scope
ACTION_MASK = (1 << (ACTION_ID - 1))
.if (ACTION_MASK > $FF)
        lda #>ACTION_MASK
        bit actions_held_high
.else
        lda #<ACTION_MASK
        bit actions_held_low
.endif
.endscope
.endmacro

.macro if_action_down ACTION_ID
.scope
ACTION_MASK = (1 << (ACTION_ID - 1))
.if (ACTION_MASK > $FF)
        lda #>ACTION_MASK
        bit actions_down_high
.else
        lda #<ACTION_MASK
        bit actions_down_low
.endif
.endscope
.endmacro

.macro if_action_up ACTION_ID
.scope
ACTION_MASK = (1 << (ACTION_ID - 1))
.if (ACTION_MASK > $FF)
        lda #>ACTION_MASK
        bit actions_up_high
.else
        lda #<ACTION_MASK
        bit actions_up_low
.endif
.endscope
.endmacro

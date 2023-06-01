; levels that other bits of the game engine
; might need to reference manually
; (most normal maps reference *each other*, so these exports are only
; needed if non-map logic needs to specify a destination)
.global debug_hub
.global grassy_test_v3
.global horizontal_platforms
.global greybox_test
.global underwater_test
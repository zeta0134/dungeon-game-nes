; These functions will be made available to your programs.
; All other symbols reside in the BHOP scope and, by default,
; will not pollute the global namespace.

.import bhop_init, bhop_play
.import bhop_mute_channel, bhop_unmute_channel

; dungeon-game specific variables
.importzp current_music_variant, target_music_variant
.import global_attenuation
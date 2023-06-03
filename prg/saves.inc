.struct SaveFile
	; State specific to the player
	PlayerHealthMax .byte ; * 
	PlayerHealthCurrent .byte ; *
	ActionSetMemory .byte 6   ; *
	ActionInventory .byte 12  ; *
	ActionSlotA .byte 1
	ActionSlotB .byte 1
	; Event flags, used to store all *sorts* of state in specific rooms
	; Global flags are always loaded; tweak this (decrease, probably) once
	; we have a better idea of what state truly needs to persist between areas
	GlobalEventFlags .byte 16
	; Area flags are a big pool. A small number of these bytes (up to 14) is
	; allocated to each major area (dungeons, towns, caves, etc) and each map
	; specifies which area's flags to load into memory. This can be as large as
	; we need, technically, but try not to go overboard here. Ideally prefer
	; temporary flags wherever possible.
	AreaEventFlags .byte 64
	; CRC32 checksum of all previous bytes. Checksum must match for a saved file to
	; be considered valid. (Ignore this for the working save, until just before writing
	; it to one of the real save slots)
	CurrentMapPtr .word
	CurrentMapBank .byte
	Checksum .byte 4
.endstruct

; Friendly names for the areas. Reference these directly in level data as necessary
; (also pick better names as necessary, but ignore that for now)
AREA_DEBUG_HUB = 0
AREA_OVERWORLD = 1
AREA_CAVES =     2
AREA_DUNGEON_0 = 3
AREA_DUNGEON_1 = 4
AREA_DUNGEON_2 = 5
AREA_DUNGEON_3 = 6
AREA_DUNGEON_4 = 7

.global working_save
.global current_save_slot
.global current_area

; for all of these, set current_save_slot first!
.global FAR_is_valid_save
.global FAR_save_game
.global FAR_load_game
.global FAR_erase_game
.global FAR_copy_game

; after loading a new game, call this before initializing the first map
.global FAR_initialize_area_flags
; every time we switch to a new map (including the first map after loading), set
; current_area, then call these
.global FAR_load_area_flags
.global FAR_save_area_flags

; Note: all of these clobber A, X and Y due to the whole bitmask thing
.global check_area_flag
.global set_area_flag
.global clear_area_flag
.global toggle_area_flag


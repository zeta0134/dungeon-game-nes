	.include "actions.inc"
	.include "crc.inc"
	.include "far_call.inc"
	.include "levels.inc"
	.include "saves.inc"
	.include "word_util.inc"
	.include "zeropage.inc"

	.segment "PRGRAM"

NUM_SAVE_SLOTS = 3

working_save: .tag SaveFile
save_slots: 	
	.repeat ::NUM_SAVE_SLOTS
	.tag SaveFile
	.endrepeat
backup_save_slots:	
	.repeat ::NUM_SAVE_SLOTS
	.tag SaveFile
	.endrepeat
current_save_slot: .res 1
working_events: .res 64
current_area: .res 1

	.segment "UTILITIES_A000"

area_save_position_table:
	.byte  0 ;AREA_DEBUG_HUB
	.byte  8 ;AREA_OVERWORLD
	.byte 16 ;AREA_CAVES
	.byte 24 ;AREA_DUNGEON_0
	.byte 32 ;AREA_DUNGEON_1
	.byte 40 ;AREA_DUNGEON_2
	.byte 48 ;AREA_DUNGEON_3
	.byte 56 ;AREA_DUNGEON_4

area_save_length_table:
	.byte 8 ;AREA_DEBUG_HUB
	.byte 8 ;AREA_OVERWORLD
	.byte 8 ;AREA_CAVES
	.byte 8 ;AREA_DUNGEON_0
	.byte 8 ;AREA_DUNGEON_1
	.byte 8 ;AREA_DUNGEON_2
	.byte 8 ;AREA_DUNGEON_3
	.byte 8 ;AREA_DUNGEON_4


; Create a brand new save file, suitable for starting a new game
.proc initialize_save
SavePtr := R0
WorkingPtr := R2
Length := R4
	; First: zero out all of this save's memory
	mov16 WorkingPtr, SavePtr
	lda #<.sizeof(SaveFile)
	sta Length
	lda #>.sizeof(SaveFile)
	sta Length+1
	ldy #0
loop:
	lda #0
	sta (WorkingPtr), y
	inc16 WorkingPtr
	dec16 Length
	cmp16 Length, #0
	bne loop
	; Now initialize any variables we want the player to start with
	; TODO: these are mostly debug values. The final game build needs to start the
	; player with the bare minimum state. We might want to separate the init paths for
	; easier debugging later.

	; 5 full hearts
	lda #10
	ldy #SaveFile::PlayerHealthMax
	sta (SavePtr), y
	ldy #SaveFile::PlayerHealthCurrent
	sta (SavePtr), y

	; For now, player starts with Jump and Dash abilities slotted,
	; and all the other abilities in their inventory already. (we will
	; certainly be fixing this as soon as ability pickup is implemented; we can
	; make a debug room with all the abilities for rapid testing)

	lda #ACTION_DASH
	ldy #SaveFile::ActionSetMemory+0
	sta (SavePtr), y
	lda #ACTION_JUMP
	ldy #SaveFile::ActionSetMemory+1
	sta (SavePtr), y

    lda #ACTION_FEATHER
    ldy #SaveFile::ActionInventory+0
	sta (SavePtr), y
	lda #ACTION_FIRE
    ldy #SaveFile::ActionInventory+1
	sta (SavePtr), y
	lda #ACTION_HAMMER
    ldy #SaveFile::ActionInventory+2
	sta (SavePtr), y

	; Also in the "just for now" category, let's start the player in the grassy test room, with
	; most of the interesting mechanics. This way we can test the debug key, which should port any
	; save file to the debug room instead

	ldy #SaveFile::CurrentMapPtr
	lda #<grassy_test_v3
	sta (SavePtr), y
	iny
	lda #>grassy_test_v3
	sta (SavePtr), y
	ldy #SaveFile::CurrentMapBank
	lda #<.bank(grassy_test_v3)
	sta (SavePtr), y

	; Just for completeness, compute a checksum of this file, this allows us to use this function
	; to initialize a real save slot if we want. (We're currently unsure of the final save game
	; flow)
	jsr _compute_checksum
	rts
.endproc

.proc _save_slot_ptr
SavePtr := R0
SaveSlot := R8
	lda current_save_slot
	sta SaveSlot
	st16 SavePtr, save_slots
	ldx SaveSlot
	beq done
loop:
	add16b SavePtr, #.sizeof(SaveFile)
	dec SaveSlot
	bne loop
done:
	rts
.endproc

.proc _backup_save_slot_ptr
BackupSavePtr := R2
SaveSlot := R8
	lda current_save_slot
	sta SaveSlot
	st16 BackupSavePtr, save_slots
	ldx SaveSlot
	beq done
loop:
	add16b BackupSavePtr, #.sizeof(SaveFile)
	dec SaveSlot
	bne loop
done:
	rts
.endproc

.proc _compute_checksum
SavePtr := R0
WorkingPtr := R2
Length := R4
	mov16 WorkingPtr, SavePtr
	jsr crc32init
	st16 Length, (.sizeof(SaveFile) - 4)

loop:
	ldy #0
	lda (WorkingPtr), y
	jsr crc32
	inc16 WorkingPtr
	dec16 Length
	cmp16 Length, #0
	bne loop
	jsr crc32end
	rts
.endproc

; Compares a previously computed checksum with the active save pointer.
; If the Z flag is **clear**, the checksum is a match.
.proc _verify_checksum
SavePtr := R0
	ldy #SaveFile::Checksum+0
	lda (SavePtr), y
	cmp testcrc+0
	bne done
	ldy #SaveFile::Checksum+1
	lda (SavePtr), y
	cmp testcrc+1
	bne done
	ldy #SaveFile::Checksum+2
	lda (SavePtr), y
	cmp testcrc+2
	bne done
	ldy #SaveFile::Checksum+3
	lda (SavePtr), y
	cmp testcrc+3
done:
	rts
.endproc

; writes a previously computed checksum to the active save ptr
.proc _write_checksum
SavePtr := R0
	ldy #SaveFile::Checksum+0
	lda testcrc+0
	sta (SavePtr), y
	ldy #SaveFile::Checksum+1
	lda testcrc+1
	sta (SavePtr), y
	ldy #SaveFile::Checksum+2
	lda testcrc+2
	sta (SavePtr), y
	ldy #SaveFile::Checksum+3
	lda testcrc+3
	sta (SavePtr), y
	rts
.endproc

; put the desired save slot in current_save_slot first!
; obviously this DELETES the save file, please be careful
.proc FAR_erase_game
SavePtr := R0
BackupSavePtr := R2
Length := R4
	; We'll write #0 to every byte in the save file, including the
	; checksum byte. This results in an invalid checksum, which is
	; treated as an empty save slot by the menuing routines.
	jsr _save_slot_ptr
	jsr _backup_save_slot_ptr
	lda #.sizeof(SaveFile)
	sta Length
	lda #0
	ldy #0
loop:
	sta (SavePtr), y
	sta (BackupSavePtr), y
	inc16 SavePtr
	dec Length
	bne loop

	rts
.endproc

; put the SOURCE save slot in current_save_slot
; put the DESTINATION save slot in R9
; obviously this OVERWRITES the destination file, please be careful
.proc FAR_copy_game
; What our helper functions write to
SavePtr := R0
BackupSavePtr := R2

; What we'll use during the copy to not be extra confused
DestinationPrimaryPtr := R0
DestinationBackupPtr := R2
SourcePrimaryPtr := R4
SourceBackupPtr := R6
Length := R8 ; clobbered by the utility functions, so effectively scratch
DestinationSlot := R9
	; grab the source pointers using current_save_slot
	jsr _save_slot_ptr
	mov16 SourcePrimaryPtr, SavePtr
	jsr _backup_save_slot_ptr
	mov16 SourceBackupPtr, BackupSavePtr

	; now grab the destination pointers using the argument provided in DestinationSlot
	lda DestinationSlot
	sta current_save_slot
	jsr _save_slot_ptr
	mov16 DestinationPrimaryPtr, SavePtr
	jsr _backup_save_slot_ptr
	mov16 DestinationBackupPtr, BackupSavePtr

	; now we can perform the copy without too much trouble
	lda #.sizeof(SaveFile)
	sta Length
	ldy #0
loop:
	lda (SourcePrimaryPtr), y
	sta (DestinationPrimaryPtr), y
	lda (SourceBackupPtr), y
	sta (DestinationBackupPtr), y
	inc16 SourcePrimaryPtr
	inc16 DestinationPrimaryPtr
	inc16 SourceBackupPtr
	inc16 DestinationBackupPtr
	dec Length
	bne loop
	
	rts
.endproc

; put the desired save slot in current_save_slot first!
.proc FAR_load_game
SavePtr := R0
BackupSavePtr := R2
WorkingPtr := R2 ; by the time we need this, we're done with backup save logic
Length := R4
	; First: is there a valid save in this slot at all?
	jsr _save_slot_ptr
	jsr _compute_checksum
	jsr _verify_checksum
	beq load_valid_save
invalid_primary_slot:
	; Is there a valid backup save? If so, we might use that instead
	jsr _backup_save_slot_ptr
	mov16 SavePtr, BackupSavePtr
	jsr _compute_checksum
	jsr _verify_checksum
	; TODO: should we tell the player that we've had to do this?
	beq load_valid_save
invalid_backup_slot:
	; Since there is no valid save, this is a new game. Initialize the working memory to a valid
	; save file, store that into both the active and backup slots, and then use that as the loaded
	; save moving forward
	jsr initialize_save
	jsr _compute_checksum
	jsr _write_checksum
	; fall through and use the remainder of the valid save loading logic
load_valid_save:
	st16 Length, .sizeof(SaveFile)
	st16 WorkingPtr, working_save
	ldy #0
loop:
	lda (SavePtr), y
	sta (WorkingPtr), y
	inc16 SavePtr
	inc16 WorkingPtr
	dec16 Length
	cmp16 Length, #0
	bne loop
setup_initial_state:
	near_call FAR_initialize_area_flags
	rts
.endproc

; put the desired save slot in current_save_slot first!
.proc FAR_save_game
SavePtr := R0
BackupSavePtr := R2
WorkingPtr := R2 ; by the time we need this, we're done with backup save logic
Length := R4
	; sanity: ensure our area flags are stored in the working save, otherwise we'll lose them
	near_call FAR_save_area_flags
	; first, compute the checksum for the working save, which may very well
	; be stale at this point
	st16 SavePtr, working_save
	jsr _compute_checksum
	jsr _write_checksum
	; now, copy the active save slot into its respective backup
	; if a POWER LOSS occurs here: the backup save slot is lost,
	; the working slot is untouched and should be loaded at next boot
	jsr _save_slot_ptr
	jsr _backup_save_slot_ptr
	st16 Length, .sizeof(SaveFile)
	ldy #0
copy_backup_loop:
	lda (SavePtr), y
	sta (BackupSavePtr), y
	inc16 SavePtr
	inc16 BackupSavePtr
	dec16 Length
	cmp16 Length, #0
	bne copy_backup_loop
	; now it is safe to copy the working save into the active slot
	; if a POWER LOSS occurs here, the active slot is lost, but the valid backup
	; we just finished copying can be loaded instead
	jsr _save_slot_ptr
	st16 WorkingPtr, working_save
	st16 Length, .sizeof(SaveFile)
	ldy #0
write_working_save_loop:
	lda (WorkingPtr), y
	sta (SavePtr), y
	inc16 WorkingPtr
	inc16 SavePtr
	dec16 Length
	cmp16 Length, #0
	bne write_working_save_loop
	; and done! At this point the active slot should be valid, and will be loaded
	; the next time the save routine is run.
	rts
.endproc

; Input: set current_save_slot before calling
; Result in R0, since flags/A are clobbered by far_call
.proc FAR_is_valid_save
SavePtr := R0
BackupSavePtr := R2
	jsr _save_slot_ptr
    jsr _compute_checksum
    jsr _verify_checksum
    beq valid
    jsr _backup_save_slot_ptr
    mov16 SavePtr, BackupSavePtr
    jsr _compute_checksum
    jsr _verify_checksum
    beq valid
invalid:
	lda #$FF
	sta R0
	rts
valid:
	lda #0
	sta R0
	rts 
.endproc

.proc FAR_initialize_area_flags
	; generally we should call this right after loading a new save file
	lda #0
	ldx #64
clear_loop:
	dex
	sta working_events, x
	bne clear_loop

	; load in the global event flags from the currently selected save
	ldx #32
global_event_loop:
	dex
	lda working_save + SaveFile::GlobalEventFlags, x
	sta working_events + 32, x
	cpx #0
	bne global_event_loop

	; reset the currently loaded area to 0, and load in those flags
	; (this way when we change areas later we have a consistent starting state)
	lda #0
	sta current_area
	near_call FAR_load_area_flags
	rts
.endproc

; put the area you want to load into current_area first
.proc FAR_load_area_flags
Length := R0
	; first, mostly for safety, clear out all 14 area flag bytes
	; in working memory. This is meant to make it harder to carry
	; event state from one room to another. In theory the extra bytes
	; aren't used by anything, but when Zeta is lacking in coffee, this
	; is not a guarantee :P
	ldx #14
	lda #0
clear_loop:
	dex
	sta working_events + 2, x
	bne clear_loop

	; Now, from the working save, load the bytes that correspond to the current
	; area, which we have in a table. (Not all areas uses all 14 bytes, many areas
	; might use far less)
	ldx current_area
	lda area_save_length_table, x
	sta Length
	lda area_save_position_table, x
	tax
	ldy #0
	; now X contains the starting position within the save file
	; and Y contains the offset into the working memory set
load_loop:
	lda working_save + SaveFile::AreaEventFlags, x
	sta working_events + 2, y
	inx
	iny
	; we could cpy here, but speed isn't important. I'm choosing to use the
	; same basic style of loop for this entire module, makes it easier to debug.
	dec Length 
	bne load_loop
done:
	rts
.endproc

; writes out the area specified by current_area, so ensure this is
; still valid before calling
.proc FAR_save_area_flags
Length := R0
	; Here we need to write the current area flags to the appropriate
	; place in the save file, so set up all of that state
	ldx current_area
	lda area_save_length_table, x
	sta Length
	lda area_save_position_table, x
	tax
	ldy #0
	; now X contains the starting position within the save file
	; and Y contains the offset into the working memory set
	; same thing as above, but the other way around
save_loop:
	lda working_events + 2, y
	sta working_save + SaveFile::AreaEventFlags, x
	inx
	iny
	; we could cpy here, but speed isn't important. I'm choosing to use the
	; same basic style of loop for this entire module, makes it easier to debug.
	dec Length 
	bne save_loop
	; while we're here, also write out the global event flags
	; (we have to do this at *some* point, and this is as good an opportunity as any)
	ldx #32
global_event_loop:
	dex
	lda working_events + 32, x
	sta working_save + SaveFile::GlobalEventFlags, x
	cpx #0
	bne global_event_loop
done:
	rts
.endproc

bitfield_masks:
	.byte %00000001
	.byte %00000010
	.byte %00000100
	.byte %00001000
	.byte %00010000
	.byte %00100000
	.byte %01000000
	.byte %10000000

; Event we want to inspect in A, result in Z, clobbers X and Y
; Usage note:
; - Events 0-15 are temporary, and will typically be reset to 0 when a new map is loaded
; - Events 16 - 127 are area specific
; - Events 128 - 255 are global (specific to the entire save file)
.proc check_area_flag
	tax ; preserve
	and #%00000111 ; isolate lower 3 bits
	tay ; which we'll use to index the bitmask LUT
	txa ; un-preserve
	.repeat 3
	lsr ; divide by 8
	.endrepeat
	tax ; and we'll use this to index the working area flags
	lda working_events, x
	and bitfield_masks, y
	rts
.endproc

; Same as above, sets the flag ignoring its original value
.proc set_area_flag
	tax ; preserve
	and #%00000111 ; isolate lower 3 bits
	tay ; which we'll use to index the bitmask LUT
	txa ; un-preserve
	.repeat 3
	lsr ; divide by 8
	.endrepeat
	tax ; and we'll use this to index the working area flags
	lda working_events, x
	ora bitfield_masks, y
	sta working_events, x
	rts
.endproc

; Same as above, sets the flag ignoring its original value
.proc clear_area_flag
	tax ; preserve
	and #%00000111 ; isolate lower 3 bits
	tay ; which we'll use to index the bitmask LUT
	txa ; un-preserve
	.repeat 3
	lsr ; divide by 8
	.endrepeat
	tax ; and we'll use this to index the working area flags
	lda working_events, x
	; here we need to clear the flag with a table that has only that flag's bit set. So...
	ora bitfield_masks, y ; force that flag  to 1, then
	eor bitfield_masks, y ; invert the flag, forcing it to 0
	sta working_events, x
	rts
.endproc

; convenience: whatever this flag was before, flip it
; flag to toggle in A, returns new state of the flag in Z
.proc toggle_area_flag
	; reuse the check area flag logic, as it handles some common setup for us
	; in a non-destructive way
	jsr check_area_flag
	; now: X is the byte we need to work with
	; Y is the index into the bitmask table
	; Z is the old state of the flag, but we're about to clobber that
	lda working_events, x
	eor bitfield_masks, y
	sta working_events, x
	; Perform the mask again to set Z to the new state of the flag
	and bitfield_masks, y
	rts
.endproc

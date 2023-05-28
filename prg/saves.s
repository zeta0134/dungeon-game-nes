	.include "actions.inc"
	.include "crc.inc"
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

	.segment "UTILITIES_A000"

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
	lda #0
	ldy #0
loop:
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
	ldy #SaveFile::ActionSetA+0
	sta (SavePtr), y
	lda #ACTION_JUMP
	ldy #SaveFile::ActionSetA+1
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
.proc load_game
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
	mov16 WorkingPtr, working_save
	ldy #0
loop:
	lda (SavePtr), y
	sta (WorkingPtr), y
	inc16 SavePtr
	inc16 WorkingPtr
	dec16 Length
	cmp16 Length, #0
	bne loop
done:
	rts
.endproc

; put the desired save slot in current_save_slot first!
.proc save_game
SavePtr := R0
BackupSavePtr := R2
WorkingPtr := R2 ; by the time we need this, we're done with backup save logic
Length := R4
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
	ldy #0
write_working_save_loop:
	lda (SavePtr), y
	sta (BackupSavePtr), y
	inc16 SavePtr
	inc16 BackupSavePtr
	dec16 Length
	cmp16 Length, #0
	bne write_working_save_loop
	; and done! At this point the active slot should be valid, and will be loaded
	; the next time the save routine is run.
	rts
.endproc
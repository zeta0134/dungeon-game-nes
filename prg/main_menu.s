        .setcpu "6502"
        .include "far_call.inc"
        .include "input.inc"
        .include "kernel.inc"
        .include "main_menu.inc"
        .include "mmc3.inc"
        .include "nes.inc"
        .include "palette.inc"
        .include "ppu.inc"
        .include "saves.inc"
        .include "subscreen.inc"
        .include "sound.inc"
        .include "sprites.inc"
        .include "word_util.inc"
        .include "vram_buffer.inc"
        .include "zeropage.inc"

        .zeropage
MainMenuState: .res 2
CancelBehavior: .res 2

        .segment "RAM"
FadeCounter: .res 1

        .segment "PRGFIXED_E000"

main_menu_bg_palette:
        .incbin "art/palettes/subscreen.pal"
main_menu_obj_palette:
        .incbin "art/palettes/subscreen_sprites.pal"

        .segment "SUBSCREEN_A000"

main_menu_base_nametable:
        .incbin "art/raw_nametables/file_select_base.nam"

file_select_str: .asciiz           "    SELECT FILE     "
erase_str: .asciiz            " ERASE WHICH FILE?  "
erase_confirm_string: .asciiz "  ARE YOU SURE!?    "
copy_str: .asciiz             "  COPY WHICH FILE?  "
copy_overwrite_str: .asciiz   " REALLY OVERWRITE!? "

new_file_str: .asciiz "New File"
filename_1_str: .asciiz "File #1"
filename_2_str: .asciiz "File #2"
filename_3_str: .asciiz "File #3"

area_names_table:
        .word area_debug_hub_str ; AREA_DEBUG_HUB = 0
        .word area_overworld_str ; AREA_OVERWORLD = 1
        .word area_caves_str     ; AREA_CAVES =     2
        .word area_dungeon_0_str ; AREA_DUNGEON_0 = 3
        .word area_dungeon_1_str ; AREA_DUNGEON_1 = 4
        .word area_dungeon_2_str ; AREA_DUNGEON_2 = 5
        .word area_dungeon_3_str ; AREA_DUNGEON_3 = 6
        .word area_dungeon_4_str ; AREA_DUNGEON_4 = 7

area_debug_hub_str: .asciiz "  Debug Hub"
area_overworld_str: .asciiz "  Overworld"
area_caves_str    : .asciiz "Underground"
area_dungeon_0_str: .asciiz "  Dungeon 0"
area_dungeon_1_str: .asciiz "  Dungeon 1"
area_dungeon_2_str: .asciiz "  Dungeon 2"
area_dungeon_3_str: .asciiz "  Dungeon 3"
area_dungeon_4_str: .asciiz "  Dungeon 4"


file_select_screen_regions:
        ; === File Slots ===

        ; [ID 0] - File Slot 1
        ; POS:   Top  Bottom  Left  Right
        .byte      7,      8,    3,    28
        ; EXITS:  Up    Down  Left  Right 
        .byte    $FF,      1,  $FF,   $FF

        ; [ID 1] - File Slot 2
        ; POS:   Top  Bottom  Left  Right
        .byte     13,     14,    3,    28
        ; EXITS:  Up    Down  Left  Right 
        .byte      0,      2,  $FF,   $FF

        ; [ID 2] - File Slot 3
        ; POS:   Top  Bottom  Left  Right
        .byte     19,     20,    3,    28
        ; EXITS:  Up    Down  Left  Right 
        .byte      1,      3,  $FF,   $FF

        ; [ID 3] - Options
        ; POS:   Top  Bottom  Left  Right
        .byte     25,     25,    3,    11
        ; EXITS:  Up    Down  Left  Right 
        .byte      2,    $FF,  $FF,     4

        ; [ID 4] - Copy File
        ; POS:   Top  Bottom  Left  Right
        .byte     25,     25,   14,    19
        ; EXITS:  Up    Down  Left  Right 
        .byte      2,    $FF,    3,     5

        ; [ID 5] - Erase File
        ; POS:   Top  Bottom  Left  Right
        .byte     25,     25,   22,    28
        ; EXITS:  Up    Down  Left  Right
        .byte      2,    $FF,    4,   $FF

; Functionally a subset of the file select screen, restricted
; to file slots only
copy_erase_screen_regions:
        ; === File Slots ===

        ; [ID 0] - File Slot 1
        ; POS:   Top  Bottom  Left  Right
        .byte      7,      8,    3,    28
        ; EXITS:  Up    Down  Left  Right 
        .byte    $FF,      1,  $FF,   $FF

        ; [ID 1] - File Slot 2
        ; POS:   Top  Bottom  Left  Right
        .byte     13,     14,    3,    28
        ; EXITS:  Up    Down  Left  Right 
        .byte      0,      2,  $FF,   $FF

        ; [ID 2] - File Slot 3
        ; POS:   Top  Bottom  Left  Right
        .byte     19,     20,    3,    28
        ; EXITS:  Up    Down  Left  Right 
        .byte      1,    $FF,  $FF,   $FF

file_select_screen_behaviors:
        ; Load File 1
        .word click_file_slot
        ; Load File 2
        .word click_file_slot
        ; Load File 3
        .word click_file_slot
        ; Options
        .word click_unimplemented_slot
        ; Copy File
        .word click_unimplemented_slot
        ; Erase File
        .word activate_erase_mode

copy_file_behaviors:
        ; Click File 1
        .word click_unimplemented_slot
        ; Click File 2
        .word click_unimplemented_slot
        ; Click File 3
        .word click_unimplemented_slot

erase_select_behaviors:
        ; Click File 1
        .word activate_erase_confirm_mode
        ; Click File 2
        .word activate_erase_confirm_mode
        ; Click File 3
        .word activate_erase_confirm_mode

erase_confirm_behaviors:
        ; Click File 1
        .word perform_erase
        ; Click File 2
        .word perform_erase
        ; Click File 3
        .word perform_erase

; === External Functions ===

.proc FAR_init_main_menu
        st16 MainMenuState, file_select_state_initial
        rts
.endproc

.proc FAR_update_main_menu
        jmp (MainMenuState)
        rts
.endproc

; === Main Menu States ===

.proc do_nothing
        ; Does what it says on the tin
        rts
.endproc

.proc file_select_state_initial
NametableAddr := R0
NametableLength := R2
        ; Note: upon entering this function, the BG palette set should have been faded out to black
        ; (presuming the previous kernel state was the title screen, logo, or attract mode, etc)

        ; we are about to fully initialize the nametable, so disable all interrupts and rendering,
        ; but not NMI, similar to a map load
        sei

         ; disable rendering
        lda #$00
        sta PPUMASK

        ; soft-disable NMI (sound engine updates only)
        lda #1
        sta NmiSoftDisable
        ; Reset PPUCTRL, but leave NMI enabled
        lda #(VBLANK_NMI)
        sta PPUCTRL

        ; Copy in the base nametable
        set_ppuaddr #$2000
        st16 NametableAddr, main_menu_base_nametable
        st16 NametableLength, $400
        ldx #0
        ldy #0
left_nametable_loop:
        lda (NametableAddr), y
        sta PPUDATA
        inc16 NametableAddr
        dec16 NametableLength
        lda NametableLength
        ora NametableLength+1
        bne left_nametable_loop
        
        ; Clear out the other nametable (set to tile 0, blank)
        set_ppuaddr #$2400
        st16 NametableLength, $400
right_nametable_loop:
        lda #0
        sta PPUDATA
        dec16 NametableLength
        lda NametableLength
        ora NametableLength+1
        bne right_nametable_loop

        ; Hide all game sprites
        far_call FAR_hide_all_sprites

        ; Set up the initial layout/behavior pointers for the file select screen
        st16 LayoutPtr, file_select_screen_regions
        st16 BehaviorPtr, file_select_screen_behaviors
        ; Set the initial cancel behavior to nothing at all. (We'll stay in the main
        ; menu for now once it's entered, since we don't yet have a title/logo sequence)
        st16 CancelBehavior, do_nothing

        lda #<file_select_screen_behaviors
        sta BehaviorPtr
        lda #>file_select_screen_behaviors
        sta BehaviorPtr+1

        ; Always start with the first file selected
        lda #0
        sta CurrentRegionIndex
        ; Using the above, initialize the cursor's position
        jsr initialize_cursor_pos
        ; Draw the cursor once here, so it is present during fade-in
        jsr draw_cursor
        lda #0
        sta ShadowCursorShown
        lda #$FF
        sta ShadowRegionIndex

        ; Draw all three file slots. Inbetween, empty the vram buffer safely, since
        ; we might otherwise overwhelm it with all the tile updates
        lda #0
        sta current_save_slot
        jsr draw_save_file
        jsr vram_slowboat

        inc current_save_slot
        jsr draw_save_file
        jsr vram_slowboat

        inc current_save_slot
        jsr draw_save_file
        jsr vram_slowboat

        ; Now, fully re-enable rendering

        ; reset PPUADDR to top-left
        set_ppuaddr #$2000

        lda #$00
        sta GameloopCounter
        sta LastNmi

        ; re-enable graphics
        lda #$1E
        sta PPUMASK
        lda #(VBLANK_NMI | BG_0000 | OBJ_1000 | OBJ_8X16)
        sta PPUCTRL

        ; un-soft-disable NMI
        lda #0
        sta NmiSoftDisable

        ; immediately wait for one vblank, for sync purposes
        jsr wait_for_next_vblank

        ; now we may safely enable interrupts
        cli

        ; Proceed to fade in the hud palete
        lda #0
        sta FadeCounter
        st16 MainMenuState, file_select_fade_in

        rts
.endproc

.proc _initial_save_ppuaddr
DestPpuAddr := R0
        st16 DestPpuAddr, $20E3
        lda current_save_slot
        cmp #1
        bcc done
        add16b DestPpuAddr, #192
        lda current_save_slot
        cmp #2
        bcc done
        add16b DestPpuAddr, #192
done:
        rts
.endproc

.proc blank_out_save_file
DestPpuAddr := R0
        jsr _initial_save_ppuaddr
        write_vram_header_ptr DestPpuAddr, #26, VRAM_INC_1
        
        lda #0
        ldx #26
        ldy VRAM_TABLE_INDEX
upper_loop:
        sta VRAM_TABLE_START, y
        iny
        dex
        bne upper_loop
        sty VRAM_TABLE_INDEX
        inc VRAM_TABLE_ENTRIES

        add16b DestPpuAddr, #32

        write_vram_header_ptr DestPpuAddr, #26, VRAM_INC_1
        
        lda #0
        ldx #26
        ldy VRAM_TABLE_INDEX
lower_loop:
        sta VRAM_TABLE_START, y
        iny
        dex
        bne lower_loop
        sty VRAM_TABLE_INDEX
        inc VRAM_TABLE_ENTRIES
        rts
.endproc

.proc draw_save_portrait
DestPpuAddr := R0
        jsr _initial_save_ppuaddr
        write_vram_header_ptr DestPpuAddr, #2, VRAM_INC_1
        ldy VRAM_TABLE_INDEX
        lda #$6E
        sta VRAM_TABLE_START, y
        iny
        lda #$6F
        sta VRAM_TABLE_START, y
        iny
        sty VRAM_TABLE_INDEX
        inc VRAM_TABLE_ENTRIES

        add16b DestPpuAddr, #32

        write_vram_header_ptr DestPpuAddr, #2, VRAM_INC_1
        ldy VRAM_TABLE_INDEX
        lda #$7E
        sta VRAM_TABLE_START, y
        iny
        lda #$7F
        sta VRAM_TABLE_START, y
        iny
        sty VRAM_TABLE_INDEX
        inc VRAM_TABLE_ENTRIES

        rts
.endproc

.proc _strlen
StringPtr := R2
        ; why would this ever crash? what could **possibly** go wrong?
        ldy #0
loop:
        lda (StringPtr), y
        beq done
        iny
        jmp loop
done:
        tya
        rts
.endproc

.proc draw_basic_string
DestPpuAddr := R0
StringPtr := R2
Length := R4
        jsr _strlen
        sta Length
        write_vram_header_ptr DestPpuAddr, Length, VRAM_INC_1
        ldy #0
        ldx VRAM_TABLE_INDEX
loop:
        lda (StringPtr), y
        beq done_with_string
        sec
        sbc #32 ; adjust for ascii offset
        sta VRAM_TABLE_START, x
        inx
        iny
        jmp loop
done_with_string:
        stx VRAM_TABLE_INDEX
        inc VRAM_TABLE_ENTRIES
        rts
.endproc

; Inputs: set current_save_slot to the file number we're working with
.proc draw_save_file
ValidSaveResult := R0
DestPpuAddr := R0
StringPtr := R2
        ; TODO: you were here!
        ; This needs to be vblank friendly (ie, use the vram buffer)
        ; For init we can queue it up using the slowboat. It's fine.
        far_call FAR_is_valid_save
        lda ValidSaveResult
        bne no_valid_save

        jsr blank_out_save_file
        jsr draw_save_portrait

        ; for now, use three fixed strings for the filenames
        ; (later it'd be neat to store a player name as part of the save struct)
        jsr _initial_save_ppuaddr
        add16b DestPpuAddr, #3 ; skip past the portrait

        lda current_save_slot
check_first:
        cmp #0
        bne check_second
        st16 StringPtr, filename_1_str
        jmp filename_converge
check_second:
        cmp #1
        bne must_be_third
        st16 StringPtr, filename_2_str
        jmp filename_converge
must_be_third:
        st16 StringPtr, filename_3_str
filename_converge:
        jsr draw_basic_string
        ; FOR NOW, do nothing more.
        ; TODO: draw hearts
        ; TODO: draw area name
        rts

no_valid_save:
        jsr blank_out_save_file
        jsr _initial_save_ppuaddr
        add16b DestPpuAddr, #3 ; skip past the portrait
        st16 StringPtr, new_file_str
        jsr draw_basic_string

        rts
.endproc

.proc file_select_fade_in
; parameters to the palette set functions
BasePaletteAddr := R0
Brightness := R2

        inc FadeCounter

        lda #10
        cmp FadeCounter
        beq done_with_fadein

        lda FadeCounter
        lsr
        sta Brightness
        st16 BasePaletteAddr, main_menu_obj_palette
        far_call FAR_queue_arbitrary_obj_palette
        st16 BasePaletteAddr, main_menu_bg_palette
        far_call FAR_queue_arbitrary_bg_palette

        rts

done_with_fadein:
        st16 MainMenuState, file_select_active

        ; (for now, do nothing!)
        rts
.endproc

.proc file_select_active
        ; update all active cursors
        jsr handle_move_cursor
        jsr lerp_cursor_position
        jsr handle_click
        jsr handle_cancel
        jsr draw_cursor
        jsr draw_shadow_cursor

        rts
.endproc

.proc confirm_choice_active
        ; this state locks the cursor in place, so don't
        ; attempt to move the cursor at all
        jsr lerp_cursor_position
        jsr handle_click
        jsr handle_cancel
        jsr draw_cursor
        jsr draw_shadow_cursor

        rts
.endproc

.proc activate_erase_mode
DestPpuAddr := R0
StringPtr := R2
        ; Draw the erase header
        st16 DestPpuAddr, $2086
        st16 StringPtr, erase_str
        jsr draw_basic_string
        ; Switch the layout pointers to use the file-restricted list, and erase confirm behaviors
        ; Set up the initial layout/behavior pointers for the file select screen
        st16 LayoutPtr, copy_erase_screen_regions
        st16 BehaviorPtr, erase_select_behaviors
        st16 CancelBehavior, return_to_file_select_mode
        ; Re-initialize the current index to point to the first file slot
        lda #0
        sta CurrentRegionIndex
        jsr initialize_cursor_pos
        ; return to file_select_active, whose logic is general enough to drive the rest
        st16 MainMenuState, file_select_active
        rts
.endproc

.proc activate_erase_confirm_mode
DestPpuAddr := R0
StringPtr := R2
        ; Draw the erase confirm header
        st16 DestPpuAddr, $2086
        st16 StringPtr, erase_confirm_string
        jsr draw_basic_string
        ; Switch the layout pointers to use the file-restricted list, and erase commit behaviors
        st16 LayoutPtr, copy_erase_screen_regions
        st16 BehaviorPtr, erase_confirm_behaviors
        st16 CancelBehavior, activate_erase_mode
        ; move to confirm_choice_active, which locks our cursor in place
        st16 MainMenuState, confirm_choice_active
        rts
.endproc

.proc perform_erase
        lda CurrentRegionIndex
        sta current_save_slot
        far_call FAR_erase_game
        ; TODO: SFX? fancy animation?
        jmp return_to_file_select_mode
        ; tail call
.endproc

.proc activate_copy_mode
        rts
.endproc

.proc activate_copy_confirm_mode
        rts
.endproc

.proc return_to_file_select_mode
DestPpuAddr := R0
StringPtr := R2
        ; Draw the file select header
        st16 DestPpuAddr, $2086
        st16 StringPtr, file_select_str
        jsr draw_basic_string
        ; Switch layout pointers to the initial file select mode
        ; Set up the initial layout/behavior pointers for the file select screen
        st16 LayoutPtr, file_select_screen_regions
        st16 BehaviorPtr, file_select_screen_behaviors
        st16 CancelBehavior, do_nothing
        ; Redraw (slowly) all three save files, just to be safe
        lda #0
        sta current_save_slot
        jsr draw_save_file
        jsr wait_for_next_vblank

        inc current_save_slot
        jsr draw_save_file
        jsr wait_for_next_vblank

        inc current_save_slot
        jsr draw_save_file
        jsr wait_for_next_vblank
        ; Re-initialize the current index to point to the first file slot
        lda #0
        sta CurrentRegionIndex
        jsr initialize_cursor_pos
        ; switch to file_select_active
        st16 MainMenuState, file_select_active
        rts
.endproc

.proc file_select_fade_out
; parameters to the palette set functions
BasePaletteAddr := R0
Brightness := R2
        dec FadeCounter
        beq done_with_fadeout

        lda FadeCounter
        lsr
        sta Brightness
        st16 BasePaletteAddr, main_menu_obj_palette
        far_call FAR_queue_arbitrary_obj_palette
        st16 BasePaletteAddr, main_menu_bg_palette
        far_call FAR_queue_arbitrary_bg_palette
        rts

done_with_fadeout:
        st16 MainMenuState, file_select_terminal
        rts
.endproc

.proc file_select_terminal
        ; Signal to the kernel that we should begin main gameplay
        st16 GameMode, init_engine
        rts
.endproc

; === File Select Behaviors ===

.proc handle_cancel
        lda #KEY_B
        and ButtonsDown
        bne has_clicked
        rts
has_clicked:
        jmp (CancelBehavior)
        ; tail call
.endproc

.proc click_file_slot
        lda CurrentRegionIndex
        sta current_save_slot
        far_call FAR_load_game

        st16 MainMenuState, file_select_fade_out
        rts
.endproc


        .setcpu "6502"
        .include "far_call.inc"
        .include "input.inc"
        .include "kernel.inc"
        .include "nes.inc"
        .include "palette.inc"
        .include "ppu.inc"
        .include "scrolling.inc"
        .include "sprites.inc"
        .include "subscreen.inc"
        .include "word_util.inc"
        .include "vram_buffer.inc"
        .include "zeropage.inc"

        .zeropage
SubScreenState: .res 2

        .segment "RAM"
FadeCounter: .res 1

LayoutPtr: .res 2
RegionIndex: .res 2

CursorTopCurrent: .res 2
CursorBottomCurrent: .res 2
CursorLeftCurrent: .res 2
CursorRightCurrent: .res 2
CursorTopTarget: .res 1
CursorBottomTarget: .res 1
CursorLeftTarget: .res 1
CursorRightTarget: .res 1
CursorPulseCounter: .res 1

        .segment "SUBSCREEN_A000"

CURSOR_TL_OAM_INDEX = 16
CURSOR_TR_OAM_INDEX = 20
CURSOR_BL_OAM_INDEX = 24
CURSOR_BR_OAM_INDEX = 28

CURSOR_TL_TILE = 83
CURSOR_TR_TILE = 85
CURSOR_BL_TILE = 87
CURSOR_BR_TILE = 89

subscreen_base_nametable:
        .incbin "art/raw_nametables/subscreen_base.nam"
subscreen_bg_palette:
        .incbin "art/palettes/subscreen.pal"
subscreen_obj_palette:
        .incbin "art/palettes/subscreen_sprites.pal"


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

inventory_screen_regions:
        ; [ID 0] - Equip Row 1, Slot 1 
        ; POS:   Top  Bottom  Left  Right
        .byte      4,      5,    6,     7
        ; EXITS:  Up    Down  Left  Right 
        .byte    $FF,      2,  $FF,     1

        ; [ID 1] - Equip Row 1, Slot 2 
        ; POS:   Top  Bottom  Left  Right
        .byte      4,      5,   10,    11
        ; EXITS:  Up    Down  Left  Right 
        .byte    $FF,      3,    0,   $FF

        ; [ID 2] - Equip Row 1, Slot 1 
        ; POS:   Top  Bottom  Left  Right
        .byte      8,      9,    6,     7
        ; EXITS:  Up    Down  Left  Right 
        .byte      0,      4,  $FF,     3

        ; [ID 3] - Equip Row 1, Slot 2 
        ; POS:   Top  Bottom  Left  Right
        .byte      8,      9,   10,    11
        ; EXITS:  Up    Down  Left  Right 
        .byte      1,      5,    2,   $FF

        ; [ID 4] - Equip Row 1, Slot 1 
        ; POS:   Top  Bottom  Left  Right
        .byte     12,     13,    6,     7
        ; EXITS:  Up    Down  Left  Right 
        .byte      2,      6,  $FF,     5

        ; [ID 5] - Equip Row 1, Slot 2 
        ; POS:   Top  Bottom  Left  Right
        .byte     12,     13,   10,    11
        ; EXITS:  Up    Down  Left  Right 
        .byte      3,      6,    4,   $FF

        ; [ID 6] - Quest Region (absolutely gigantic)
        ; POS:   Top  Bottom  Left  Right
        .byte     18,     27,    4,    29
        ; EXITS:  Up    Down  Left  Right 
        .byte      4,    $FF,  $FF,   $FF        


; === External Functions ===

.proc FAR_init_subscreen
        st16 SubScreenState, subscreen_state_initial
        rts
.endproc

.proc FAR_update_subscreen
        jmp (SubScreenState)
        rts
.endproc

; === Subscreen States ===

.proc subscreen_state_initial
NametableAddr := R0
NametableLength := R2
        ; Note: upon entering this function, the BG palette set has been faded out to black.

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
        st16 NametableAddr, subscreen_base_nametable
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

        ; FOR NOW, we'll start with the inventory screen, so initialize that 
        ; particular layout
        lda #<inventory_screen_regions
        sta LayoutPtr
        lda #>inventory_screen_regions
        sta LayoutPtr+1
        ; FOR NOW, we will always start in the 0th region
        ; (Later I really want to memorize the last region for player convenience)
        lda #0
        sta RegionIndex
        ; Using the above, initialize the cursor's position
        jsr initialize_cursor_pos
        ; Draw the cursor once here, so it is present during fade-in
        jsr draw_cursor

        ; TODO: other setup!

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
        st16 SubScreenState, subscreen_fade_in

        rts
.endproc

.proc subscreen_fade_in
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
        st16 BasePaletteAddr, subscreen_obj_palette
        jsr queue_arbitrary_obj_palette
        st16 BasePaletteAddr, subscreen_bg_palette
        jsr queue_arbitrary_bg_palette

        rts

done_with_fadein:
        st16 SubScreenState, subscreen_active

        ; (for now, do nothing!)
        rts
.endproc

.proc subscreen_active
        ; If the user has pressed START, exit the subscreen
        ; TODO: if we are partway through a multi-click action, like moving
        ; inventory items around, should we block exiting until that sequence
        ; is complete?
        lda #KEY_START
        bit ButtonsDown
        beq subscreen_still_active
        lda #10
        sta FadeCounter
        st16 SubScreenState, subscreen_fade_out
        rts

subscreen_still_active:
        ; update all active cursors
        jsr handle_move_cursor
        jsr lerp_cursor_position
        jsr draw_cursor
        inc CursorPulseCounter

        rts
.endproc

.proc subscreen_fade_out
; parameters to the palette set functions
BasePaletteAddr := R0
Brightness := R2
        dec FadeCounter
        beq done_with_fadeout

        lda FadeCounter
        lsr
        sta Brightness
        st16 BasePaletteAddr, subscreen_obj_palette
        jsr queue_arbitrary_obj_palette
        st16 BasePaletteAddr, subscreen_bg_palette
        jsr queue_arbitrary_bg_palette
        rts

done_with_fadeout:
        st16 SubScreenState, subscreen_terminal
        rts
.endproc

.proc subscreen_terminal
        ; we are about to restore a large chunk of the nametable, so disable all interrupts and rendering,
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

        ; TODO: restore the nametable here! (function not yet written)
        far_call FAR_render_initial_viewport


        ; reset PPUADDR to top-left
        set_ppuaddr #$2000

        lda #$00
        sta GameloopCounter
        sta LastNmi

        ; re-enable graphics
        lda #$1E
        sta PPUMASK
        ; The main game loop expects 8x16 sprites, so set that here
        lda #(VBLANK_NMI | BG_0000 | OBJ_1000 | OBJ_8X16)
        sta PPUCTRL

        ; un-soft-disable NMI
        lda #0
        sta NmiSoftDisable

        ; immediately wait for one vblank, for sync purposes
        jsr wait_for_next_vblank

        ; now we may safely enable interrupts
        cli

        ; Now signal to the kernel that it is safe to return to the main game mode
        st16 GameMode, return_from_subscreen
        rts
.endproc

; === Utility ===

.proc selected_region_ptr
RegionPtr := R14
        ; Initialize the pointer to the current region index, expanded to 16bit
        lda RegionIndex
        sta RegionPtr
        lda #0
        sta RegionPtr+1

        ; multiply the current region index by 8, which is the size
        ; of a Region struct
        .repeat 3
        asl RegionPtr
        rol RegionPtr+1
        .endrepeat

        ; add in the layout ptr, which is the start of the current region table
        clc
        lda LayoutPtr
        adc RegionPtr
        sta RegionPtr
        lda LayoutPtr+1
        adc RegionPtr+1
        sta RegionPtr+1

        rts
.endproc

; Meant to be called when first activating a particular subscreen.
; Reads the currently selected index and sets all relevant cursor
; variables to this position without any lerping of position.
.proc initialize_cursor_pos
RegionPtr := R14
        ; First perform a normal cursor update, which will provide sane values
        ; for the target position
        jsr update_cursor_pos

        ; Now, instead of lerping, immediately apply the target to the current position
        lda CursorTopTarget
        sta CursorTopCurrent + 1
        lda CursorBottomTarget
        sta CursorBottomCurrent + 1
        lda CursorLeftTarget
        sta CursorLeftCurrent + 1
        lda CursorRightTarget
        sta CursorRightCurrent + 1

        ; Clear out the sub-pixel coordinates
        lda #0
        sta CursorTopCurrent
        sta CursorBottomCurrent
        sta CursorLeftCurrent
        sta CursorRightCurrent

        ; Initialize other cursor-related tracking vars
        lda #0
        sta CursorPulseCounter

        rts
.endproc

.proc update_cursor_pos
RegionPtr := R14
        jsr selected_region_ptr

        ldy #Region::PositionTop
        lda (RegionPtr), y
        ; convert from tile index to pixel coordinate
        .repeat 3
        asl
        .endrepeat
        ; align the corner with the scrolled / offset tile boundary
        sec
        sbc #11
        sta CursorTopTarget

        ldy #Region::PositionBottom
        lda (RegionPtr), y
        .repeat 3
        asl
        .endrepeat
        sec
        sbc #1
        sta CursorBottomTarget

        ldy #Region::PositionLeft
        lda (RegionPtr), y
        .repeat 3
        asl
        .endrepeat
        sec
        sbc #13
        sta CursorLeftTarget

        ldy #Region::PositionRight
        lda (RegionPtr), y
        .repeat 3
        asl
        .endrepeat
        sec
        sbc #3
        sta CursorRightTarget

        rts
.endproc

; Side note: we will NOT be using the metasprite system, as doing so might clobber
; game state. Fortunately the various cursors are not that complicated, so it is
; fine to draw them manually. We *can* mess with OAM, the game loop will correct
; this when we return to it by performing a full redraw, as it does every frame.
.proc draw_cursor
CursorOffset := R0
        lda CursorPulseCounter
        .repeat 5
        lsr
        .endrepeat
        and #%00000001
        sta CursorOffset

        ; TOP LEFT
        ; Y position
        lda CursorTopCurrent + 1
        sec
        sbc CursorOffset
        sta SHADOW_OAM + CURSOR_TL_OAM_INDEX + 0
        ; X position
        lda CursorLeftCurrent + 1
        sec
        sbc CursorOffset
        sta SHADOW_OAM + CURSOR_TL_OAM_INDEX + 3
        ; Tile Index
        lda #CURSOR_TL_TILE
        sta SHADOW_OAM + CURSOR_TL_OAM_INDEX + 1

        ; TOP RIGHT
        ; Y position
        lda CursorTopCurrent + 1
        sec
        sbc CursorOffset
        sta SHADOW_OAM + CURSOR_TR_OAM_INDEX + 0
        ; X position
        lda CursorRightCurrent + 1
        clc
        adc CursorOffset
        sta SHADOW_OAM + CURSOR_TR_OAM_INDEX + 3
        ; Tile Index
        lda #CURSOR_TR_TILE
        sta SHADOW_OAM + CURSOR_TR_OAM_INDEX + 1    

        ; BOTTOM LEFT
        ; Y position
        lda CursorBottomCurrent + 1
        clc
        adc CursorOffset
        sta SHADOW_OAM + CURSOR_BL_OAM_INDEX + 0
        ; X position
        lda CursorLeftCurrent + 1
        sec
        sbc CursorOffset
        sta SHADOW_OAM + CURSOR_BL_OAM_INDEX + 3       
        ; Tile Index
        lda #CURSOR_BL_TILE
        sta SHADOW_OAM + CURSOR_BL_OAM_INDEX + 1

        ; BOTTOM RIGHT
        ; Y position
        lda CursorBottomCurrent + 1
        clc
        adc CursorOffset
        sta SHADOW_OAM + CURSOR_BR_OAM_INDEX + 0
        ; X position
        lda CursorRightCurrent + 1
        clc
        adc CursorOffset
        sta SHADOW_OAM + CURSOR_BR_OAM_INDEX + 3               
        ; Tile Index
        lda #CURSOR_BR_TILE
        sta SHADOW_OAM + CURSOR_BR_OAM_INDEX + 1


        ; Standard boring attributes, with palette 0
        lda #0
        sta SHADOW_OAM + CURSOR_TL_OAM_INDEX + 2
        sta SHADOW_OAM + CURSOR_TR_OAM_INDEX + 2
        sta SHADOW_OAM + CURSOR_BL_OAM_INDEX + 2
        sta SHADOW_OAM + CURSOR_BR_OAM_INDEX + 2

        rts
.endproc

.proc handle_move_cursor
RegionPtr := R14
        jsr selected_region_ptr

        lda #KEY_RIGHT
        bit ButtonsDown
        beq right_not_pressed

        ldy #Region::ExitRight
        lda (RegionPtr), y
        ; If this exit contains the special value $FF, then there
        ; is no exit from this direction. Skip this move entirely.
        cmp #$FF
        beq right_not_pressed
        ; A contains the new region, so store that
        sta RegionIndex
        ; Update the new target postiion
        ; (this also conveniently refreshes our RegionPtr)
        jsr update_cursor_pos

right_not_pressed:
        lda #KEY_LEFT
        bit ButtonsDown
        beq left_not_pressed

        ldy #Region::ExitLeft
        lda (RegionPtr), y
        ; If this exit contains the special value $FF, then there
        ; is no exit from this direction. Skip this move entirely.
        cmp #$FF
        beq left_not_pressed
        ; A contains the new region, so store that
        sta RegionIndex
        ; Update the new target postiion
        ; (this also conveniently refreshes our RegionPtr)
        jsr update_cursor_pos

left_not_pressed:
        lda #KEY_UP
        bit ButtonsDown
        beq up_not_pressed

        ldy #Region::ExitUp
        lda (RegionPtr), y
        ; If this exit contains the special value $FF, then there
        ; is no exit from this direction. Skip this move entirely.
        cmp #$FF
        beq up_not_pressed
        ; A contains the new region, so store that
        sta RegionIndex
        ; Update the new target postiion
        ; (this also conveniently refreshes our RegionPtr)
        jsr update_cursor_pos

up_not_pressed:
        lda #KEY_DOWN
        bit ButtonsDown
        beq down_not_pressed

        ldy #Region::ExitDown
        lda (RegionPtr), y
        ; If this exit contains the special value $FF, then there
        ; is no exit from this direction. Skip this move entirely.
        cmp #$FF
        beq down_not_pressed
        ; A contains the new region, so store that
        sta RegionIndex
        ; Update the new target postiion
        ; (this also conveniently refreshes our RegionPtr)
        jsr update_cursor_pos

down_not_pressed:
        ; All done

        rts
.endproc

.proc lerp_coordinate
CurrentPos := R0
TargetPos := R2
Distance := R4
        sec
        lda TargetPos
        sbc CurrentPos
        sta Distance
        lda TargetPos+1
        sbc CurrentPos+1
        sta Distance+1
        ; for sign checks, we need a third distance byte; we'll use
        ; #0 for both incoming values
        lda #0
        sbc #0
        sta Distance+2

        ; sanity check: are we already very close to the target?
        ; If our distance byte is either $00 or $FF, then there is
        ; less than 1px remaining
        lda Distance+1
        cmp #$00
        beq arrived_at_target
        cmp #$FF
        beq arrived_at_target

        ; this is a signed comparison, and it's much easier to simply split the code here
        lda Distance+2
        bmi negative_distance

positive_distance:
        ; divide the distance by 4
.repeat 2
        lsr Distance+1
        ror Distance
.endrepeat
        jmp store_result

negative_distance:
        ; divide the distance by 4
.repeat 2
        sec
        ror Distance+1
        ror Distance
.endrepeat

store_result:
        ; apply the computed distance/4 to the current position
        clc
        lda CurrentPos
        adc Distance
        sta CurrentPos
        lda CurrentPos+1
        adc Distance+1
        sta CurrentPos+1
        ; and we're done!
        rts

arrived_at_target:
        ; go ahead and apply the target position completely, to skip the tail end of the lerp
        lda TargetPos + 1
        sta CurrentPos + 1
        lda #0
        sta CurrentPos
        rts
.endproc

.proc lerp_cursor_position
CurrentPos := R0
TargetPos := R2
        ; LEFT
        ; For the target byte, use 0 for the subpixel value
        lda CursorLeftTarget
        sta TargetPos+1
        lda #0
        sta TargetPos

        ; Provide our current position to the lerp coordinate routine
        lda CursorLeftCurrent
        sta CurrentPos
        lda CursorLeftCurrent+1
        sta CurrentPos+1

        jsr lerp_coordinate

        ; Save the result for this coordinate
        lda CurrentPos
        sta CursorLeftCurrent
        lda CurrentPos+1
        sta CursorLeftCurrent+1

        ; Lather, rinse, repeat for the other 3 coordinates

        ; RIGHT
        ; For the target byte, use 0 for the subpixel value
        lda CursorRightTarget
        sta TargetPos+1
        lda #0
        sta TargetPos

        ; Provide our current position to the lerp coordinate routine
        lda CursorRightCurrent
        sta CurrentPos
        lda CursorRightCurrent+1
        sta CurrentPos+1

        jsr lerp_coordinate

        ; Save the result for this coordinate
        lda CurrentPos
        sta CursorRightCurrent
        lda CurrentPos+1
        sta CursorRightCurrent+1

        ; TOP
        ; For the target byte, use 0 for the subpixel value
        lda CursorTopTarget
        sta TargetPos+1
        lda #0
        sta TargetPos

        ; Provide our current position to the lerp coordinate routine
        lda CursorTopCurrent
        sta CurrentPos
        lda CursorTopCurrent+1
        sta CurrentPos+1

        jsr lerp_coordinate

        ; Save the result for this coordinate
        lda CurrentPos
        sta CursorTopCurrent
        lda CurrentPos+1
        sta CursorTopCurrent+1

        ; BOTTOM
        ; For the target byte, use 0 for the subpixel value
        lda CursorBottomTarget
        sta TargetPos+1
        lda #0
        sta TargetPos

        ; Provide our current position to the lerp coordinate routine
        lda CursorBottomCurrent
        sta CurrentPos
        lda CursorBottomCurrent+1
        sta CurrentPos+1

        jsr lerp_coordinate

        ; Save the result for this coordinate
        lda CurrentPos
        sta CursorBottomCurrent
        lda CurrentPos+1
        sta CursorBottomCurrent+1

        rts
.endproc
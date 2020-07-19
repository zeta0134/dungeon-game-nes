        .setcpu "6502"
        .include "nes.inc"
        .include "branch_util.inc"
        .include "mmc3.inc"
        .include "ppu.inc"
        .include "word_util.inc"
        .include "zeropage.inc"

        

.scope PRGLAST_E000
        .segment "PRGRAM"
MapData: .res 4096
TilesetData: .res 256
.export MapData
        .zeropage
; Map dimensions
MapWidth: .byte $00
MapHeight: .byte $00
; Current map position
MapUpperLeftRow: .word $0000
MapUpperLeftColumn: .word $0000
MapUpperRightColumn: .word $0000
MapLowerLeftRow: .word $0000
MapXOffset: .byte $00
MapYOffset: .byte $00
; Hardware scroll tiles within Nametable
HWScrollUpperLeftRow: .word $0000
HWScrollUpperLeftColumn: .word $0000
HWScrollUpperRightColumn: .word $0000
HWScrollLowerLeftRow: .word $0000
; Camera-tracking
CameraXTileCurrent: .byte $00
CameraXScrollCurrent: .byte $00
CameraYTileCurrent: .byte $00
CameraYScrollCurrent: .byte $00
.exportzp CameraXTileTarget, CameraXScrollTarget, CameraYTileTarget, CameraYScrollTarget, MapWidth, MapHeight
CameraXTileTarget: .byte $00
CameraXScrollTarget: .byte $00
CameraYTileTarget: .byte $00
CameraYScrollTarget: .byte $00
PpuYTileTarget: .byte $00
; IRQ variable to assist with screen split
SplitScanlinesToStatus: .byte $00

        .segment "PRGLAST_E000"
        ;.org $e000

.export load_map, load_tileset, init_map, scroll_camera, set_scroll_for_frame, install_irq_handler

.macro incColumn addr
.scope
        clc
        lda addr
        adc #1
        and #%00011111
        tax ; preserve low 5 bits for later
        bne no_overflow ; taken if A != 0 after mask
        lda addr+1
        eor #%00000100 ; flip nametable bit, from base 0x20 <-> 0x24
        sta addr+1
no_overflow:
        lda addr
        and #%11100000 ; mask off lower 5 bits
        sta addr
        txa
        clc 
        adc addr ; a now contains original top 3 bits, and incremented lower 5 bits, without carry
        sta addr
.endscope
.endmacro

.macro decColumn addr
.scope
        sec
        lda addr
        sbc #1
        and #%00011111
        tax ; preserve low 5 bits for later
        cmp #%00011111
        bne no_overflow ; taken if A != 31 after mask
        lda addr+1
        eor #%00000100 ; flip nametable bit, from base 0x20 <-> 0x24
        sta addr+1
no_overflow:
        lda addr
        and #%11100000 ; mask off lower 5 bits
        sta addr
        txa
        clc 
        adc addr ; a now contains original top 3 bits, and decremented lower 5 bits, without carry
        sta addr
.endscope
.endmacro


.macro incRow addr
.scope
        clc
        lda addr
        adc #%00100000
        sta addr
        bcs overflow
        ; check to see if we've reached the magic value 28
        ; lower 3 bits
        and #%11100000
        cmp #%10000000
        bne done
        ; upper 2 bits
        lda addr+1
        and #%00000011
        cmp #%00000011
        bne done
        ; we've overflowed into the status area
        ; first zero the lower 3 bits
        lda addr
        and #%00011111
        sta addr
        ; then the upper 2 bits
        lda addr+1
        and #%11111100
        sta addr+1
        jmp done
overflow:
        inc addr+1        
done:
.endscope
.endmacro

.macro decRow addr
.scope
        clc
        lda addr
        adc #%11100000 ;"subtract" 1 from the upper 3 bits
        sta addr
        ; if we *did* overflow the addition in hardware, then we *did not* overflow the 3-bit subtraction: 0x000 -> 0x111
        bcs done
        ; subtract 1 from the upper 2 bits
        lda addr+1
        sbc #0
        ; stash the result in x (it might be wrong)
        tax
        ; check for overflow in *just these two bits*
        and #%00000011
        cmp #%00000011
        bne no_overflow
        ; for the high byte we need to now *set* the lower 2 bits to 11, without affecting the rest of it
        lda addr+1
        ora #%00000011
        sta addr+1
        ; for the low byte, we need to *clear* the high bit; we previously set the upper 3 bits to 111
        lda addr
        eor #%10000000
        sta addr
        ; after these operations, the combined Y coordinate should be: 11011, or 27
        jmp done
no_overflow:
        ; actually write the value we stashed to x
        stx addr+1
done:
.endscope
.endmacro

; Loads a map into memory, in preparation for drawing, scrolling, and eventually
; maybe gameplay stuff
; Inputs:
;   R4: 16bit address of the map to load
; Clobbers: R0 - R4

.proc load_map
TempHeight := R0
TempWidth := R1
DestAddr := R2
SourceAddr := R4
        ldy #$00 ; we'll use indirect mode, but without an offset
        lda (SourceAddr),y
        sta MapWidth
        sta TempHeight
        inc16 SourceAddr
        lda (SourceAddr),y
        sta MapHeight
        sta TempWidth
        inc16 SourceAddr
        st16 DestAddr, (MapData)
loop:
        ; copy in one byte
        lda (SourceAddr),y
        sta (DestAddr),y
        inc16 SourceAddr
        inc16 DestAddr
        ; check MapWidth
        dec TempHeight
        bne loop
        ; reload MapWidth and check MapHeight
        lda MapWidth
        sta TempHeight
        dec TempWidth
        bne loop
        ; all done
        rts
.endproc

; Load a tilemap into memory; these always have a fixed size of 256 bytes
; Inputs:
;   R0: 16bit address of the map to load
.proc load_tileset
        ldy #$00
loop:
        lda (R0),y
        sta TilesetData,y
        iny
        bne loop
        rts
.endproc

; Initializes the scroll registers for the currently loaded map, then
;   copies the first entire screen worth of map data into the PPU
; Inputs:
;   R0: X position of the top-left corner of the screen, in map tiles
;   R1: Y position of the top-left corner of the screen, in map tiles
; Conditions:
;   This routine assumes rendering is already disabled.

.proc init_map
TileOffsetX := R0
TileOffsetY := R1
        ; first, use the Y position to calculate the row offset into MapData
        st16 MapUpperLeftRow, (MapData)
        lda TileOffsetY
        beq done_with_y_offset
y_offset_loop:
        clc
        add16 MapUpperLeftRow, MapWidth
        dec TileOffsetY
        bne y_offset_loop
done_with_y_offset:
        clc
        add16 MapUpperLeftRow, TileOffsetX
        ; At this point MapUpperLeft is correct, so use it as the base for
        ; lower left, which needs to advance an extra 24 tiles downwards.
        mov16 MapUpperLeftRow, MapLowerLeftRow
        ; While we're at it, we can use the same loop to initialize the nametable
        st16 HWScrollLowerLeftRow, $2000
        lda #$00
        lda PPUSTATUS ; reset read/write latch
        lda #(OBJ_0000 | BG_1000)
        sta PPUCTRL ; ensure VRAM increment mode is +1
        ldx #13
height_loop:
        ; draw the upper row
        mov16 MapLowerLeftRow, R0
        lda #16
        sta R2
        set_ppuaddr HWScrollLowerLeftRow
        jsr draw_upper_half_row ; a, y clobbered, x preserved
        add16 HWScrollLowerLeftRow, #32

        ; draw the lower row
        mov16 MapLowerLeftRow, R0
        lda #16
        sta R2
        set_ppuaddr HWScrollLowerLeftRow
        jsr draw_lower_half_row ; a, y clobbered, x preserved
        add16 HWScrollLowerLeftRow, #32
        ; increment the row counter and continue
        add16 MapLowerLeftRow, MapWidth
        dex
        bne height_loop
        ; Now initialize the remaining Map variables:
        mov16 MapUpperLeftRow, MapUpperLeftColumn
        mov16 MapUpperLeftRow, MapUpperRightColumn
        add16 MapUpperRightColumn, #16
        ; Initialize the remaining hardware scroll registers
        st16 HWScrollUpperLeftRow, $2000
        st16 HWScrollUpperLeftColumn, $2000
        st16 HWScrollUpperRightColumn, $2400
        ; done?
        rts
.endproc

; Optimization note: if we can decode tile index data into a
; consistent target address, we can do an absolute,y index, and save
; 2 cycles per 16x16 tile over storing the address in zero page

; Optimization: If we limit our tileset to 64 metatiles, and bake in
; the 4-byte offset, we can dodge both `asl` routines and load the CHR
; index directly into y, saving 6 cycles per tile

; Draws one half-row of 16x16 metatiles
; Inputs:
;   R0: 16bit starting address (map tiles)
;   R2: 16px tiles to copy
;   PPUADDR: nametable destination
; Note: PPUCTRL should be set to VRAM+1 mode before calling

.proc draw_upper_half_row
MapAddr := R0
TilesRemaining := R2
        clc
column_loop:
        ldy #$00
        lda (MapAddr),y ; a now holds the tile index
        tay
        lda TilesetData,y ; a now holds CHR index of the top-left tile
        sta PPUDATA
        iny
        lda TilesetData,y ; a now holds CHR index of the top-right tile
        sta PPUDATA
        inc16 MapAddr
        dec TilesRemaining
        bne column_loop
        rts
.endproc

.proc draw_lower_half_row
MapAddr := R0
TilesRemaining := R2
        clc
column_loop:
        ldy #$00
        lda (MapAddr),y ; a now holds the tile index
        tay
        lda TilesetData+2,y ; a now holds CHR index of the bottom-left tile
        sta PPUDATA
        iny
        lda TilesetData+2,y ; a now holds CHR index of the bottom-right tile
        sta PPUDATA
        inc16 MapAddr
        dec TilesRemaining
        bne column_loop
        rts
.endproc

; Draws one half-column of 16x16 metatiles
; Inputs:
;   R0: 16bit starting address (map tiles)
;   R2: 16px tiles to copy
;   PPUADDR: nametable destination
; Note: PPUCTRL should be set to VRAM+32 mode before calling

.proc draw_left_half_col
MapAddr := R0
TilesRemaining := R2
        clc
row_loop:
        ldy #$00
        lda (MapAddr),y ; a now holds the tile index
        tay 
        lda TilesetData, y
        sta PPUDATA
        iny
        iny
        lda TilesetData, y
        sta PPUDATA
        add16 MapAddr, MapWidth
        dec TilesRemaining
        bne row_loop
        rts
.endproc

.proc draw_right_half_col
MapAddr := R0
TilesRemaining := R2
        clc
row_loop:
        ldy #$00
        lda (MapAddr),y ; a now holds the tile index
        tay 
        lda TilesetData+1, y
        sta PPUDATA
        iny
        iny
        lda TilesetData+1, y
        sta PPUDATA
        add16 MapAddr, MapWidth
        dec TilesRemaining
        bne row_loop
        rts
.endproc

.proc shift_hwrows_right
        incColumn HWScrollUpperLeftRow
        incColumn HWScrollLowerLeftRow
        rts
.endproc

.proc shift_hwcolumns_right
        incColumn HWScrollUpperRightColumn
        incColumn HWScrollUpperLeftColumn
        rts
.endproc

.proc shift_hwrows_left
        decColumn HWScrollUpperLeftRow
        decColumn HWScrollLowerLeftRow
        rts
.endproc

.proc shift_hwcolumns_left
        decColumn HWScrollUpperRightColumn
        decColumn HWScrollUpperLeftColumn
        rts
.endproc

.proc shift_hwrows_down
        incRow HWScrollUpperLeftRow
        incRow HWScrollLowerLeftRow
        rts
.endproc

.proc shift_hwcolumns_down
        incRow HWScrollUpperRightColumn
        incRow HWScrollUpperLeftColumn
        rts
.endproc

.proc shift_hwrows_up
        decRow HWScrollUpperLeftRow
        decRow HWScrollLowerLeftRow
        rts
.endproc

.proc shift_hwcolumns_up
        decRow HWScrollUpperRightColumn
        decRow HWScrollUpperLeftColumn
        rts
.endproc

.macro split_row_across_nametables starting_hw_address, drawing_function
        lda #16
        sec
        sbc MapXOffset
        sta R2
        jsr drawing_function
        ; the right half needs to massage the target address; it should
        ; switch nametables, and start at the left-most tile, but keep
        ; the same Y coordinate
        lda starting_hw_address+1 ; ppuaddr high byte
        eor #%00000100 ; swap nametables
        sta PPUADDR
        lda starting_hw_address ; ppuaddr low byte
        and #%11100000 ; set X component to 0
        sta PPUADDR
        ; bytes remaining
        lda MapXOffset
        adc #1
        sta R2
        jsr drawing_function
.endmacro

.macro split_column_across_height_boundary starting_hw_address, drawing_function
.scope
        lda #14
        sec
        sbc MapYOffset
        sta R2
        jsr drawing_function
        lda starting_hw_address+1
        ; Set the Y component to zero
        and #%11111100
        sta PPUADDR
        lda starting_hw_address
        and #%00011111
        sta PPUADDR
        ; bytes remaining
        lda MapYOffset
        beq skip
        sta R2
        jsr drawing_function
skip:
.endscope
.endmacro

.proc scroll_camera
        ; did we move up or down?
        ; perform a 16-bit compare between target - current, and throw the result away
        lda CameraYTileCurrent
        cmp CameraYTileTarget
        ; if the result is zero, we did not scroll
        bne vertical_scroll
        jmp no_vertical_scroll
vertical_scroll:
        ; if the subtract here needed to borrow, the result is negative; we moved UP
        bcc scroll_down
        jmp scroll_up
scroll_down:
        inc CameraYTileCurrent
        inc PpuYTileTarget
        lda #28
        cmp PpuYTileTarget
        bne no_positive_y_wrap
        lda #0
        sta PpuYTileTarget
no_positive_y_wrap:
        ; switch to +1 mode
        lda #(VBLANK_NMI | OBJ_0000 | BG_1000)
        sta PPUCTRL
        set_ppuaddr HWScrollLowerLeftRow
        mov16 MapLowerLeftRow, R0
        ; the 5th bit of the scroll tells us if we're doing a left-column or a right-column
        lda #%00100000
        bit HWScrollLowerLeftRow
        bne lower_edge_lower_row
lower_edge_upper_row:
        split_row_across_nametables HWScrollLowerLeftRow, draw_upper_half_row
        ; The map index doesn't change, so we update *only* the row registers here
        ; We need to leave the columns alone until we cross a metatile boundary
        jsr shift_hwrows_down
        jmp no_horizontal_scroll
lower_edge_lower_row:
        split_row_across_nametables HWScrollLowerLeftRow, draw_lower_half_row
        clc
        add16 MapUpperRightColumn, MapWidth
        add16 MapUpperLeftColumn, MapWidth
        add16 MapUpperLeftRow, MapWidth
        add16 MapLowerLeftRow, MapWidth
        ; Increment MapYOffset with wrap around
        inc MapYOffset
        lda #14
        cmp MapYOffset
        bne shift_registers_down
        lda #0
        sta MapYOffset
shift_registers_down:
        ; Finish shifting hwrows down to the next metatile
        jsr shift_hwrows_down
        ; Shift columns down *twice* to advance a complete metatile
        jsr shift_hwcolumns_down
        jsr shift_hwcolumns_down
        ; note - NOT a bug! We intentionally prioritize vertical scroll and let horizontal lag by a frame or two; it's fine
        jmp no_horizontal_scroll
scroll_up:
        dec CameraYTileCurrent
        dec PpuYTileTarget
        bpl no_negative_y_wrap
        lda #27
        sta PpuYTileTarget
no_negative_y_wrap:
        ; switch to +1 mode
        lda #(VBLANK_NMI | OBJ_0000 | BG_1000)
        sta PPUCTRL
        set_ppuaddr HWScrollUpperLeftRow
        mov16 MapUpperLeftRow, R0
        ; the 5th bit of the scroll tells us if we're doing a left-column or a right-column
        lda #%00100000
        bit HWScrollUpperLeftRow
        beq upper_edge_upper_row
upper_edge_lower_row:
        split_row_across_nametables HWScrollUpperLeftRow, draw_lower_half_row
        ; The map index doesn't change, so we update *only* the row registers here
        ; We need to leave the columns alone until we cross a metatile boundary
        jsr shift_hwrows_up
        jmp no_horizontal_scroll
upper_edge_upper_row:
        split_row_across_nametables HWScrollUpperLeftRow, draw_upper_half_row
        sec
        sub16 MapUpperRightColumn, MapWidth
        sub16 MapUpperLeftColumn, MapWidth
        sub16 MapUpperLeftRow, MapWidth
        sub16 MapLowerLeftRow, MapWidth
        ; Decrement MapYOffset with wraparound
        dec MapYOffset
        bpl shift_registers_up
        lda #13
        sta MapYOffset
shift_registers_up:
        ; Finish shifting hwrows up to the next metatile
        jsr shift_hwrows_up
        ; Shift columns up *twice* to advance a complete metatile
        jsr shift_hwcolumns_up
        jsr shift_hwcolumns_up
         ; note - NOT a bug! We intentionally prioritize vertical scroll and let horizontal lag by a frame or two; it's fine
        jmp no_horizontal_scroll
no_vertical_scroll:
        ; did we move left or right?
        ; perform a 16-bit compare between target - current, and throw the result away
        lda CameraXTileCurrent
        cmp CameraXTileTarget
        ; if the result is zero, we did not scroll
        bne horizontal_scroll
        jmp no_horizontal_scroll
horizontal_scroll:
        ; if the subtract here needed to borrow, the result is negative; we moved LEFT
        bcc scroll_right
        jmp scroll_left
scroll_right:
        inc CameraXTileCurrent
        ; switch to +32 mode
        lda #(VBLANK_NMI | OBJ_0000 | BG_1000 | VRAM_DOWN)
        sta PPUCTRL
        set_ppuaddr HWScrollUpperRightColumn
        mov16 MapUpperRightColumn, R0
        ; the low bit of the scroll tells us if we're doing a left-column or a right-column
        lda #$01
        bit HWScrollUpperRightColumn
        beq right_side_left_column
right_side_right_column:
        split_column_across_height_boundary HWScrollUpperRightColumn, draw_right_half_col

        ; Move our map pointers to the right by one entire tile
        inc MapUpperRightColumn
        inc MapUpperLeftColumn
        inc MapUpperLeftRow
        inc MapLowerLeftRow
        ; Increment MapXOffset with wrap around
        inc MapXOffset
        lda #$0F
        and MapXOffset
        sta MapXOffset
        ; Finish shifting hwcolumns up to the next metatile
        jsr shift_hwcolumns_right
        ; Shift rows right *twice* to advance a complete metatile
        jsr shift_hwrows_right
        jsr shift_hwrows_right
        jmp no_horizontal_scroll
right_side_left_column:
        split_column_across_height_boundary HWScrollUpperRightColumn, draw_left_half_col

        ; The map index doesn't change, so we update *only* the column registers here
        ; Shift  hwcolumns right halfway to the next metatile
        jsr shift_hwcolumns_right
        jmp no_horizontal_scroll
scroll_left:
        dec CameraXTileCurrent
        ; switch to +32 mode
        lda #(VBLANK_NMI | OBJ_0000 | BG_1000 | VRAM_DOWN)
        sta PPUCTRL
        set_ppuaddr HWScrollUpperLeftColumn
        mov16 MapUpperLeftColumn, R0
        ; the low bit of the scroll tells us if we're doing a left-column or a right-column
        lda #$01
        bit HWScrollUpperLeftColumn
        beq left_side_left_column
left_side_right_column:
        split_column_across_height_boundary HWScrollUpperLeftColumn, draw_right_half_col
        ; The map index doesn't change, so we update *only* the column registers here
        ; Shift hwcolumns left halfway to the next metatile
        jsr shift_hwcolumns_left
        jmp no_horizontal_scroll
left_side_left_column:
        split_column_across_height_boundary HWScrollUpperLeftColumn, draw_left_half_col
        ; Move our map index to the left
        dec MapUpperRightColumn
        dec MapUpperLeftColumn
        dec MapUpperLeftRow
        dec MapLowerLeftRow
        ; Decrement MapXOffset with wraparound
        dec MapXOffset
        lda #$0F
        and MapXOffset
        sta MapXOffset
        ; Finish shifting hwcolumns left to the next metatile
        jsr shift_hwcolumns_left
        ; Shift rows left *twice* to advance a complete metatile
        jsr shift_hwrows_left
        jsr shift_hwrows_left
no_horizontal_scroll:
        ; Always copy in the new sub-tile scroll position
        ; (this visually hides the fact that we alternately may delay a row / column)
        lda CameraXScrollTarget
        sta CameraXScrollCurrent
        lda CameraYScrollTarget
        sta CameraYScrollCurrent
        rts
.endproc

.proc burn_some_cycles
.repeat 32
        nop
.endrep
        rts
.endproc

base_irq_handler:
        pha
        jsr burn_some_cycles
irq_first_byte:
        lda #0
irq_first_address:
        sta PPUADDR
irq_second_byte:
        lda #0
irq_second_address:
        sta PPUADDR
irq_cleanup_handler:
        jmp irq_do_nothing

MY_IRQ_HANDLER_THAT_SCARES_SMALL_CHILDREN := $00E0

.proc install_irq_handler
        ldx #17
        ldy #0
loop:
        lda base_irq_handler,y
        sta MY_IRQ_HANDLER_THAT_SCARES_SMALL_CHILDREN,y
        iny
        dex
        bne loop
        rts
.endproc

.macro set_first_irq_byte value
        lda value
        sta irq_first_byte - base_irq_handler + MY_IRQ_HANDLER_THAT_SCARES_SMALL_CHILDREN + 1
.endmacro

.macro set_second_irq_byte value
        lda value
        sta irq_second_byte - base_irq_handler + MY_IRQ_HANDLER_THAT_SCARES_SMALL_CHILDREN + 1
.endmacro

.macro set_irq_cleanup_handler address
        lda #<address
        sta irq_cleanup_handler - base_irq_handler + MY_IRQ_HANDLER_THAT_SCARES_SMALL_CHILDREN + 1
        lda #>address
        sta irq_cleanup_handler - base_irq_handler + MY_IRQ_HANDLER_THAT_SCARES_SMALL_CHILDREN + 2
.endmacro

; Based on the target hardware scroll position, write the appropriate PPU registers
; in advance of the next frame to draw. Typically meant to be called once at the tail
; end of NMI, but could potentially be useful for mid-frame shenanigans.
; Clobbers: R0

.proc set_scroll_for_frame
        ; First, set the nametable based on the 6th bit of the X tile position
        lda #%00100000
        bit CameraXTileTarget
        beq left_nametable
right_nametable:
        lda #(VBLANK_NMI | OBJ_0000 | BG_1000 | NT_2400)
        sta PPUCTRL
        jmp done_with_nametables
left_nametable:
        lda #(VBLANK_NMI | OBJ_0000 | BG_1000 | NT_2000)
        sta PPUCTRL
done_with_nametables:
        ; Reset PPU write latch
        lda PPUSTATUS
        lda CameraXScrollTarget
        sta R0
        lda CameraXTileTarget
        .repeat 3
        rol R0
        rol a
        .endrep
        ; a now contains low 5 bits of scroll tile, and upper 3 bits of sub-tile scroll
        ; (lower 5 bits of that are sub-pixels, and discarted)
        sta PPUSCROLL
        ; now do the same for Y scroll
        lda CameraYScrollTarget
        sta R0
        lda PpuYTileTarget
        .repeat 3
        rol R0
        rol a
        .endrep
        sta PPUSCROLL
setup_irq:
        ; conveniently, A has the number of *pixels* we have scrolled the background down the screen
        ; first off, stash it in R0 (we'll need this a few times)
        sta R0
        cmp #32
        bcc no_midscreen_split
_midscreen_split:
        cmp #(189 + 32)
        bcs _spinwait_midscreen_split
        jsr irq_midscreen_split
        rts
_spinwait_midscreen_split:
        jsr spinwait_midscreen_split
        rts
_no_midscreen_split:
        jsr no_midscreen_split
        rts
.endproc

.proc no_midscreen_split
        ; the first IRQ won't be until the top of the status area:
        set_first_irq_byte #$03
        set_second_irq_byte #$80
        set_irq_cleanup_handler (post_irq_status_upper_half)
        ; after 192 - 1 frames:
        lda #193
        sta MMC3_IRQ_LATCH
enable_rendering:
        lda #$1E
        sta PPUMASK
        lda #%01000000
wait_for_sprite_zero_to_clear:
        bit PPUSTATUS
        bne wait_for_sprite_zero_to_clear
reload_mmc3_irq:
        sta MMC3_IRQ_RELOAD
        sta MMC3_IRQ_DISABLE
        sta MMC3_IRQ_ENABLE
        rts
.endproc

; Used in the majority of Y-scroll positions, when there is enough time for an MMC3 IRQ
; to trigger on the proper scanline for a scroll split

.proc irq_midscreen_split
        ; The first IRQ will move us to the top of the playfield, but maintaining the same nametable
        ; and X coordinate
        ; the first byte is thus just based on our current nametable, with the Y component zeroed out:
        lda CameraXTileTarget
        and #%00100000
        lsr ; >> 3
        lsr
        lsr
        sta irq_first_byte - base_irq_handler + MY_IRQ_HANDLER_THAT_SCARES_SMALL_CHILDREN + 1
        ; The second byte is just coarse X, with the upper bits cleared
        lda CameraXTileTarget
        and #%00011111
        sta irq_second_byte - base_irq_handler + MY_IRQ_HANDLER_THAT_SCARES_SMALL_CHILDREN + 1
        set_irq_cleanup_handler (post_irq_midframe_status_split)
        ; The first IRQ will happen 192 - PpuYTileTarget - 32 scanlines into the display
        clc ; subtract one extra on purpose here
        lda #(192 + 32)
        sbc R0
        sta MMC3_IRQ_LATCH
        ; The IRQ following this is 192 - this number - 2
        clc
        sta R0
        lda #192
        sbc R0
        sta SplitScanlinesToStatus
enable_rendering:
        lda #$1E
        sta PPUMASK
        lda #%01000000
wait_for_sprite_zero_to_clear:
        bit PPUSTATUS
        bne wait_for_sprite_zero_to_clear
reload_mmc3_irq:
        sta MMC3_IRQ_RELOAD
        sta MMC3_IRQ_DISABLE
        sta MMC3_IRQ_ENABLE
        rts
.endproc

; Used in cases where the scroll split would be 3 or fewer scanlines from the start of display; in
; these cases the MMC3 IRQ is unreliable, so we manually spinwait instead. Configuration here is
; similar to "no_midscreen_split" but with the status area offset by a small amount

.proc spinwait_midscreen_split
        ; the first IRQ won't be until the top of the status area:
        set_first_irq_byte #$03
        set_second_irq_byte #$80
        set_irq_cleanup_handler (post_irq_status_upper_half)
        ; after 192 - 1 frames:
        lda #193
        sta MMC3_IRQ_LATCH
        ; We will spinwait for this many scanlines to perform a manual scroll split:
        sec
        lda #(192 + 32)
        sbc R0
        ; stash back in R0 for use in the spinwait loops below
        sta R0

        ; the first target byte is based on our current nametable, with the Y component zeroed out:
        lda CameraXTileTarget
        and #%00100000
        lsr ; >> 3
        lsr
        lsr
        tax ; stash in x

        ; The second byte is just coarse X, with the upper bits cleared
        lda CameraXTileTarget
        and #%00011111
        tay ; stash in Y

enable_rendering:
        lda #$1E
        sta PPUMASK
        lda #%01000000
wait_for_sprite_zero_to_clear:
        bit PPUSTATUS
        bne wait_for_sprite_zero_to_clear
reload_mmc3_irq:
        sta MMC3_IRQ_RELOAD
        sta MMC3_IRQ_DISABLE
        sta MMC3_IRQ_ENABLE
spinwait_for_R0_scanlines:
        sec
        lda #35
loop1:
        sbc #1
        bne loop1
        dec R0
        beq skip_status_area
        sec
        lda #21
loop2:
        sbc #1
        bne loop2
        dec R0
        beq skip_status_area
sec
        lda #22
loop3:
        sbc #1
        bne loop3
skip_status_area:
        ; write here our scroll bytes, which were previously stashed in X and Y:
        stx PPUADDR
        sty PPUADDR
done:
        rts
.endproc


.proc post_irq_midframe_status_split
        ; we will set PPUADDR to the start of the status area
        set_first_irq_byte #$03
        set_second_irq_byte #$80
        ; after this, we will prepare for the lower half
        set_irq_cleanup_handler (post_irq_status_upper_half)
        ; this will occur in a number of scanlines we calculated during NMI
        lda SplitScanlinesToStatus
        sta MMC3_IRQ_LATCH
        sta MMC3_IRQ_RELOAD
        ; now we need to pulse IRQ DISABLE / ENABLE to acknowledge the previous interrupt
        ; and enable the new one we just configured
        ; (the value we write is not important here)
        sta MMC3_IRQ_DISABLE
        sta MMC3_IRQ_ENABLE
        ; pop a in prep to return
        pla 
        rti        
.endproc

.proc post_irq_status_upper_half
        ; we must correct fine X for status area display,
        ; which was not fixed during the start of the IRQ handler
        ; Y is written here, but ignored; its only purpose is to reset the
        ; write latch for the next IRQ handler
        lda #$00
        sta PPUSCROLL 
        sta PPUSCROLL
        ; on the next IRQ we will set PPUADDR to the middle of the status area
        set_first_irq_byte #$07
        set_second_irq_byte #$80
        ; and run the mid-scanline cleanup function:
        set_irq_cleanup_handler (post_irq_status_lower_half)
        ; The upper status area lasts for 16 frames, so we write 16-1 to the latch:
        lda #14
        sta MMC3_IRQ_LATCH
        sta MMC3_IRQ_RELOAD
        ; and acknowledge the irq:
        sta MMC3_IRQ_DISABLE
        sta MMC3_IRQ_ENABLE
        ; pop a in prep to return
        pla 
        rti
.endproc

.proc post_irq_status_lower_half
        ; it doesn't matter what we set PPUADDR to, so we don't bother to update it here
        ; we will execute the following cleanup routine:
        set_irq_cleanup_handler (post_irq_blanking_area)
        ; in 16 scanlines, just like above:
        lda #14
        sta MMC3_IRQ_LATCH
        sta MMC3_IRQ_RELOAD
        ; we acknowledge the irq:
        sta MMC3_IRQ_DISABLE
        sta MMC3_IRQ_ENABLE
        ; pop a in prep to return
        pla 
        rti
.endproc

.proc post_irq_blanking_area
        ; Immediately disable background rendering
        ; (sprites are okay for now)
        lda #$16
        sta PPUMASK
        ; we're done with IRQs for this frame. Disable them entirely
        sta MMC3_IRQ_DISABLE
        ; pop a in prep to return
        pla 
        rti
.endproc

.proc irq_do_nothing
        ; do not pass go.
        ; do not collect $200
        ; (do pop a though)
        pla 
        rti
.endproc

.endscope
        .setcpu "6502"
        .include "nes.inc"
        .include "ppu.inc"
        .include "word_util.inc"
        .include "zeropage.inc"

        

.scope PRGLAST_E000
        .segment "PRGRAM"
MapData: .res 4096
TilesetData: .res 256
        .zeropage
; Map dimensions
MapWidth: .byte $00
MapHeight: .byte $00
; Current map position
MapUpperLeft: .word $0000
MapUpperRight: .word $0000
MapLowerLeft: .word $0000
MapXOffset: .byte $00
MapYOffset: .byte $00
; Hardware scroll tiles within Nametable
HWScrollUpperLeft: .word $0000
HWScrollUpperRight: .word $0000
HWScrollLowerLeft: .word $0000
; Camera-tracking
CameraXTileCurrent: .byte $00
CameraXScrollCurrent: .byte $00
CameraYTileCurrent: .byte $00
CameraYScrollCurrent: .byte $00
.exportzp CameraXTileTarget, CameraXScrollTarget, CameraYTileTarget, CameraYScrollTarget
CameraXTileTarget: .byte $00
CameraXScrollTarget: .byte $00
CameraYTileTarget: .byte $00
CameraYScrollTarget: .byte $00

        .segment "PRGLAST_E000"
        ;.org $e000

.export load_map, load_tileset, init_map, scroll_camera, set_scroll_for_frame

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
        bvs overflow
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
        bvs done
        ; subtract 1 from the upper 2 bits
        lda addr+1
        sbc #1
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
        st16 MapUpperLeft, (MapData)
        lda TileOffsetY
        beq done_with_y_offset
y_offset_loop:
        add16 MapUpperLeft, MapWidth
        dec TileOffsetY
        bne y_offset_loop
done_with_y_offset:
        add16 MapUpperLeft, TileOffsetX
        ; At this point MapUpperLeft is correct, so use it as the base for
        ; lower left, which needs to advance an extra 24 tiles downwards.
        mov16 MapUpperLeft, MapLowerLeft
        ; While we're at it, we can use the same loop to initialize the nametable
        st16 HWScrollLowerLeft, $2000
        lda #$00
        lda PPUSTATUS ; reset read/write latch
        lda #$A0
        sta PPUCTRL ; ensure VRAM increment mode is +1
        ldx #12
height_loop:
        ; draw the upper row
        mov16 MapLowerLeft, R0
        lda #16
        sta R2
        set_ppuaddr HWScrollLowerLeft
        jsr draw_lower_half_row ; a, y clobbered, x preserved
        add16 HWScrollLowerLeft, #32

        ; draw the lower row
        mov16 MapLowerLeft, R0
        lda #16
        sta R2
        set_ppuaddr HWScrollLowerLeft
        jsr draw_upper_half_row ; a, y clobbered, x preserved
        add16 HWScrollLowerLeft, #32
        ; increment the row counter and continue
        add16 MapLowerLeft, MapWidth
        dex
        bne height_loop
        ; Now we just need MapUpperRight:
        mov16 MapUpperLeft, MapUpperRight
        add16 MapUpperRight, #16
        ; Initialize the remaining hardware scroll registers
        st16 HWScrollUpperLeft, $2000
        st16 HWScrollUpperRight, $2400
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

.proc draw_lower_half_row
MapAddr := R0
TilesRemaining := R2
        clc
column_loop:
        ldy #$00
        lda (MapAddr),y ; a now holds the tile index
        asl a
        asl a ; a now holds an offset into the chrmap for this tile
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

.proc draw_upper_half_row
MapAddr := R0
TilesRemaining := R2
        clc
column_loop:
        ldy #$00
        lda (MapAddr),y ; a now holds the tile index
        asl a
        asl a ; a now holds an offset into the chrmap for this tile
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
        asl a
        asl a ; a now holds an offset into the chrmap for this tile
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
        asl a
        asl a ; a now holds an offset into the chrmap for this tile
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

.proc shift_hwscroll_right
        incColumn HWScrollUpperRight
        incColumn HWScrollUpperLeft
        incColumn HWScrollLowerLeft
        rts
.endproc

.proc shift_hwscroll_left
        decColumn HWScrollUpperRight
        decColumn HWScrollUpperLeft
        decColumn HWScrollLowerLeft
        rts
.endproc

.proc scroll_camera
        ; did we move left or right?
        ; perform a 16-bit compare between target - current, and throw the result away
        lda CameraXTileCurrent
        cmp CameraXTileTarget
        ; if the result is zero, we did not scroll
        beq no_horizontal_scroll
        ; if the subtract here needed to borrow, the result is negative; we moved LEFT
        bcs scroll_left
scroll_right:
        ; switch to +32 mode
        lda #$A4
        sta PPUCTRL
        set_ppuaddr HWScrollUpperRight
        mov16 MapUpperRight, R0
        lda #14
        clc
        sbc MapYOffset
        sta R2
        ; the low bit of the scroll tells us if we're doing a left-column or a right-column
        lda #$01
        bit HWScrollUpperRight
        beq right_side_left_column
right_side_right_column:
        jsr draw_right_half_col
        inc MapUpperRight
        inc MapUpperLeft
        inc MapLowerLeft
        jmp shift_registers_right
right_side_left_column:
        jsr draw_left_half_col
shift_registers_right:
        jsr shift_hwscroll_right
        jmp no_horizontal_scroll
scroll_left:
        ; switch to +32 mode
        lda #$A4
        sta PPUCTRL
        set_ppuaddr HWScrollUpperLeft
        mov16 MapUpperLeft, R0
        lda #14
        clc
        sbc MapYOffset
        sta R2
        ; the low bit of the scroll tells us if we're doing a left-column or a right-column
        lda #$01
        bit HWScrollUpperLeft
        beq left_side_left_column
left_side_right_column:
        jsr draw_right_half_col
        jmp shift_registers_left
left_side_left_column:
        jsr draw_left_half_col
        dec MapUpperRight
        dec MapUpperLeft
        dec MapLowerLeft
shift_registers_left:
        jsr shift_hwscroll_left
        jmp no_horizontal_scroll
no_horizontal_scroll:
        ; keep the new camera coordinates; we'll use these soon
        ; to set PPUSCROLL / PPUADDR, and later in the above comparisons
        lda CameraXScrollTarget
        sta CameraXScrollCurrent
        lda CameraXTileTarget
        sta CameraXTileCurrent
        lda CameraYScrollTarget
        sta CameraYScrollCurrent
        lda CameraYTileTarget
        sta CameraYTileCurrent
        rts
.endproc


; Based on the current hardware scroll position, write the appropriate PPU registers
; in advance of the next frame to draw. Typically meant to be called once at the tail
; end of NMI, but could potentially be useful for mid-frame shenanigans.
; Clobbers: R0

.proc set_scroll_for_frame
        ; First, set the nametable based on the 6th bit of the X tile position
        lda #%00100000
        bit CameraXTileCurrent
        beq left_nametable
right_nametable:
        lda #$A1
        sta PPUCTRL
        jmp done_with_nametables
left_nametable:
        lda #$A0
        sta PPUCTRL
done_with_nametables:
        ; Reset PPU write latch
        lda PPUSTATUS
        lda CameraXScrollCurrent
        sta R0
        lda CameraXTileCurrent
        .repeat 3
        rol R0
        rol a
        .endrep
        ; a now contains low 5 bits of scroll tile, and upper 3 bits of sub-tile scroll
        ; (lower 5 bits of that are sub-pixels, and discarted)
        sta PPUSCROLL
        ; now do the same for Y scroll
        lda CameraYScrollCurrent
        sta R0
        lda CameraYTileCurrent
        .repeat 3
        rol R0
        rol a
        .endrep
        sta PPUSCROLL
done:
        rts
.endproc

.endscope
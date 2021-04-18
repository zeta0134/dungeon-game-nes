        .setcpu "6502"
        .include "nes.inc"
        .include "branch_util.inc"
        .include "collision.inc"
        .include "mmc3.inc"
        .include "ppu.inc"
        .include "vram_buffer.inc"
        .include "word_util.inc"
        .include "zeropage.inc"

        

.scope PRGLAST_C000
        .segment "PRGRAM"
MapData: .res 4096
AttributeData: .res 1024
TilesetData: .res 256
.export MapData
        .zeropage
; Map dimensions
MapWidth: .byte $00
MapHeight: .byte $00
AttributeWidth: .byte $00
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
; Current attribute table position
AttributeUpperLeftRow: .word $0000
AttributeUpperLeftColumn: .word $0000
AttributeUpperRightColumn: .word $0000
AttributeLowerLeftRow: .word $0000
AttributeXOffset: .byte $00
AttributeYOffset: .byte $00
; Hardware scroll tiles within Attribute data
HWAttributeUpperLeftRow: .word $0000
HWAttributeUpperLeftColumn: .word $0000
HWAttributeUpperRightColumn: .word $0000
HWAttributeLowerLeftRow: .word $0000
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

        .segment "PRGLAST_C000"
        ;.org $e000

.export load_map, load_tileset, init_map, init_attributes, scroll_camera, set_scroll_for_frame, install_irq_handler

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

; Overview of attribute tables, the address layout is exploited by all of the
; below functions
; https://wiki.nesdev.com/w/index.php/PPU_attribute_tables

; The components of the attribute address are:
; 7       0
; ---- ----
; 11rr rccc
; the high byte of the address shouldn't change, so we can ignore it
; the highest nybble ranges from C - F
; 

; in this engine's case, we want to skip over the last value "F8" for
; the low byte, so we'll detect that byte and treat it as the reset
; point. (The F8 row is used for the status area instead of the map)

.macro incAttrRow addr
.scope
        clc
        lda addr
        adc #%00001000
        sta addr ; result might be wrong at this point
        ; check for overflow
        and #%11111000
        cmp #$F8
        bne no_overflow
        ; reload the address, and zero out the row component
        lda addr
        and #%11000111
        sta addr
no_overflow:
.endscope
.endmacro

.macro decAttrRow addr
.scope
        ; first check: will a subtract overflow:
        lda addr
        and #%00111000
        bne no_overflow
        ; set the row component to F0
        lda addr
        and #%00000111 ; preserve column
        ora #$F0 ; set row to bottom of the table
        sta addr
        jmp done
no_overflow:
        ; simply subtract and move on
        sec
        lda addr
        sbc #%00001000
        sta addr
done:
.endscope
.endmacro

.macro incAttrColumn addr
.scope
        ; are we about to overflow this nametable?
        lda addr
        and #%00000111
        cmp #$07
        bne no_overflow
        ; we'll need to zero out the column
        lda addr
        and #%11111000
        sta addr
        ; then swap nametables
        lda addr+1
        eor #%00000100
        sta addr+1
        jmp done
no_overflow:
        ; simply add 1 to the column and exit
        inc addr
done:
.endscope
.endmacro

.macro decAttrColumn addr
.scope
        ; are we about to overflow this nametable?
        lda addr
        and #%00000111
        cmp #$00
        bne no_overflow
        ; we'll need to set the column to $7
        lda addr
        ora #%00000111
        sta addr
        ; then swap nametables
        lda addr+1
        eor #%00000100
        sta addr+1
        jmp done
no_overflow:
        ; simply subtract 1 from the column and exit
        dec addr
done:
.endscope
.endmacro

; Loads a map into PRG RAM buffer, in preparation for drawing and gameplay
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
        clc
        ror
        sta AttributeWidth
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
        dec TempWidth
        bne loop
        ; reload MapWidth and check MapHeight
        lda MapWidth
        sta TempWidth
        dec TempHeight
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
; Conditions:
;   This routine assumes rendering is already disabled.

.proc init_map
        ; upper left should be off the top of the map by -1. The camera won't ever
        ; scroll that far, but it sets it up to be in the right spot once it scrolls
        ; down / right
        st16 MapUpperLeftRow, MapData
        sec
        sub16 MapUpperLeftRow, MapWidth
        dec16 MapUpperLeftRow

        ; lower left needs to advance an extra 22 tiles downwards.
        st16 MapLowerLeftRow, MapData
        dec16 MapLowerLeftRow

        ; Advance 13 tiles into the map data, based on the loaded width
        ldx #12
height_loop:
        clc
        add16 MapLowerLeftRow, MapWidth
        dex
        bne height_loop

        ; Now initialize the Map variables:
        ; off the map to the left by -1,-1
        st16 MapUpperLeftColumn, MapData
        dec16 MapUpperLeftColumn 

        ; off the map to the right by +1, -1  
        st16 MapUpperRightColumn, MapData
        clc
        add16 MapUpperRightColumn, #17

        ; Initialize the hardware scroll registers
        st16 HWScrollLowerLeftRow, $2340
        decColumn HWScrollLowerLeftRow
        decColumn HWScrollLowerLeftRow

        decRow HWScrollLowerLeftRow


        st16 HWScrollUpperLeftRow, $2000
        decRow HWScrollUpperLeftRow
        decColumn HWScrollUpperLeftRow
        decColumn HWScrollUpperLeftRow

        st16 HWScrollUpperLeftColumn, $241E
        st16 HWScrollUpperRightColumn, $2402

        ; done?
        lda #15
        sta MapXOffset
        lda #0
        sta MapYOffset


        ; of course not; initialize attribute stuffs
        st16 AttributeUpperLeftRow, AttributeData
        sec
        sub16 AttributeUpperLeftRow, #1
        sec
        sub16 AttributeUpperLeftRow, #32
        st16 AttributeUpperLeftColumn, AttributeData
        sec
        sub16 AttributeUpperLeftColumn, #1
        st16 AttributeLowerLeftRow, AttributeData
        sec
        sub16 AttributeLowerLeftRow, #1
        clc
        add16 AttributeLowerLeftRow, #(32*7)
        st16 AttributeUpperRightColumn, AttributeData
        clc
        add16 AttributeUpperRightColumn, #9

        st16 HWAttributeUpperLeftRow, $27F7
        st16 HWAttributeUpperLeftColumn, $27C7
        st16 HWAttributeLowerLeftRow, $27C7
        st16 HWAttributeUpperRightColumn, $27C1

        lda #7
        sta AttributeXOffset
        lda #0
        sta AttributeYOffset

        rts
.endproc

; With the currently loaded map data and tileset, generates the full
; attribute buffer in memory for use in the various scrolling routines
; Note: This is slow, but doesn't touch PPU registers, so it's safe to
; let it run through several frames if needed

.proc init_attributes
UpperRowPtr := R0
LowerRowPtr := R2
AttributeTablePtr := R4
AttributeScratchByte := R6
RowCounter := R7
ColumnCounter := R8
        st16 UpperRowPtr, MapData
        st16 LowerRowPtr, MapData
        add16 LowerRowPtr, MapWidth
        st16 AttributeTablePtr, AttributeData
        lda MapHeight
        sta RowCounter
row_loop:
        ; setup the start of the column loop
        ldy #0
column_loop:
        iny
        lda (LowerRowPtr),y ; bottom-right
        tax
        lda MetatileAttributes+1,x ; a now contains 2-bit palette index
        asl
        asl
        sta AttributeScratchByte
        
        dey
        lda (LowerRowPtr),y ; bottom-left
        tax
        lda MetatileAttributes+1,x
        ora AttributeScratchByte
        asl
        asl
        sta AttributeScratchByte

        iny
        lda (UpperRowPtr),y ; upper-right
        tax
        lda MetatileAttributes+1,x ; a now contains 2-bit palette index
        ora AttributeScratchByte
        asl
        asl
        sta AttributeScratchByte

        dey
        lda (UpperRowPtr),y ; upper-left
        tax
        lda MetatileAttributes+1,x
        ora AttributeScratchByte ; a now contains completed attribute byte

        sty ColumnCounter
        ldy #0
        sta (AttributeTablePtr),y

        ldy ColumnCounter

        inc16 AttributeTablePtr
        iny
        iny
        cpy MapWidth
        bne column_loop
done_with_column:
        clc
        add16 UpperRowPtr, MapWidth
        add16 LowerRowPtr, MapWidth
        add16 UpperRowPtr, MapWidth
        add16 LowerRowPtr, MapWidth
        dec RowCounter
        dec RowCounter
        bne row_loop
entirely_done:
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

; It feels really awkward to not be handling the header writing in the draw functions.
; This is something to consider refactoring maybe

.proc draw_upper_half_row
MapAddr := R0
TilesRemaining := R2
        ldx VRAM_TABLE_INDEX
column_loop:
        ldy #$00
        lda (MapAddr),y ; a now holds the tile index
        tay
        lda TilesetData,y ; a now holds CHR index of the top-left tile
        sta VRAM_TABLE_START,x
        inx
        lda TilesetData+1,y ; a now holds CHR index of the top-right tile
        sta VRAM_TABLE_START,x
        inx

        inc16 MapAddr
        dec TilesRemaining
        bne column_loop
        stx VRAM_TABLE_INDEX
        inc VRAM_TABLE_ENTRIES
        rts
.endproc

.proc draw_lower_half_row
MapAddr := R0
TilesRemaining := R2
        ldx VRAM_TABLE_INDEX
column_loop:
        ldy #$00
        lda (MapAddr),y ; a now holds the tile index
        tay
        lda TilesetData+2,y ; a now holds CHR index of the top-left tile
        sta VRAM_TABLE_START,x
        inx
        lda TilesetData+3,y ; a now holds CHR index of the top-right tile
        sta VRAM_TABLE_START,x
        inx

        inc16 MapAddr
        dec TilesRemaining
        bne column_loop
        stx VRAM_TABLE_INDEX
        inc VRAM_TABLE_ENTRIES
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
        ldx VRAM_TABLE_INDEX
row_loop:
        ldy #$00
        lda (MapAddr),y ; a now holds the tile index
        tay
        lda TilesetData+0,y ; a now holds CHR index of the top-left tile
        sta VRAM_TABLE_START,x
        inx
        lda TilesetData+2,y ; a now holds CHR index of the top-right tile
        sta VRAM_TABLE_START,x
        inx

        clc
        add16 MapAddr, MapWidth
        dec TilesRemaining
        bne row_loop
        stx VRAM_TABLE_INDEX
        inc VRAM_TABLE_ENTRIES
        rts
.endproc

.proc draw_right_half_col
MapAddr := R0
TilesRemaining := R2
        ldx VRAM_TABLE_INDEX
row_loop:
        ldy #$00
        lda (MapAddr),y ; a now holds the tile index
        tay
        lda TilesetData+1,y ; a now holds CHR index of the top-left tile
        sta VRAM_TABLE_START,x
        inx
        lda TilesetData+3,y ; a now holds CHR index of the top-right tile
        sta VRAM_TABLE_START,x
        inx

        clc
        add16 MapAddr, MapWidth
        dec TilesRemaining
        bne row_loop
        stx VRAM_TABLE_INDEX
        inc VRAM_TABLE_ENTRIES
        rts
.endproc

.proc draw_attribute_row
AttrAddr := R0
DestAddr := R2
BytesRemaining := R4
        ; sanity check
        lda #0
        cmp BytesRemaining
        beq skip

        write_vram_header_ptr DestAddr, BytesRemaining, VRAM_INC_1        
        ldx VRAM_TABLE_INDEX
column_loop:
        ; copy one byte into the vram buffer
        ldy #$00
        lda (AttrAddr),y ; a now holds the attribute byte
        sta VRAM_TABLE_START,x
        inx
        ; increment our address by one, and continue
        inc16 AttrAddr
        dec BytesRemaining
        bne column_loop
        ; update the 
        stx VRAM_TABLE_INDEX
        inc VRAM_TABLE_ENTRIES
skip:
        rts
.endproc

; Note: for simplicity, this is implemented as a series of 1-byte writes, which in practice
; should result in 7 transfers altogether. This is inefficient, but not terribly so. Later
; it would be good to optimize this using some sort of interleaving, using the +32 mode to
; write every other attribute byte.

.proc draw_attribute_column
AttrAddr := R0
DestAddr := R2
BytesRemaining := R4
        ; sanity check
        lda #0
        cmp BytesRemaining
        beq skip
row_loop:
        write_vram_header_ptr DestAddr, #1, VRAM_INC_1        
        ldx VRAM_TABLE_INDEX
        ; copy one byte into the vram buffer
        ldy #$00
        lda (AttrAddr),y ; a now holds the attribute byte
        sta VRAM_TABLE_START,x
        inx
        stx VRAM_TABLE_INDEX
        inc VRAM_TABLE_ENTRIES
        ; increment our address by the map width
        clc
        add16 AttrAddr, AttributeWidth
        ; ... and our target by one HW attribute row
        clc
        add16 DestAddr, #8
        dec BytesRemaining
        bne row_loop
skip:
        rts
.endproc

.macro split_row_across_nametables starting_hw_address, drawing_function
.scope
        lda #16
        sec
        sbc MapXOffset
        sta R2

        lda starting_hw_address
        sta VRAM_SCRATCH
        lda starting_hw_address+1
        sta VRAM_SCRATCH+1


        asl R2
        write_vram_header_ptr VRAM_SCRATCH, R2, VRAM_INC_1
        ror R2

        jsr drawing_function

        ; bytes remaining + 2
        lda MapXOffset
        clc
        adc #4
        ; edge case: do we have more than 16 tiles to go?
        cmp #17 ; >= 17
        bcc last_segment_prep
middle_segment:
        ; the middle segment must draw no more than 16 tiles
        lda #16
        sta R2

        ; here we need to massage the target address; it should
        ; switch nametables, and start at the left-most tile, but keep
        ; the same Y coordinate
        lda starting_hw_address+1 ; ppuaddr high byte
        eor #%00000100 ; swap nametables
        sta VRAM_SCRATCH+1

        lda starting_hw_address ; ppuaddr low byte
        and #%11100000 ; set X component to 0
        sta VRAM_SCRATCH

        asl R2
        write_vram_header_ptr VRAM_SCRATCH, R2, VRAM_INC_1
        ror R2

        jsr drawing_function

        ; now prepare R2 for the last segment
        lda MapXOffset
        sec
        sbc #12
        sta R2
        jmp last_segment

last_segment_prep:
        ; bytes remaining
        lda MapXOffset
        clc
        adc #4
        sta R2
last_segment:
        ; Same as above; if we drew a middle segment, we are now again on our
        ; *original* nametable, on the left side
        lda VRAM_SCRATCH+1 ; ppuaddr high byte
        eor #%00000100 ; swap nametables
        sta VRAM_SCRATCH+1

        lda VRAM_SCRATCH ; ppuaddr low byte
        and #%11100000 ; set X component to 0
        sta VRAM_SCRATCH

        asl R2
        write_vram_header_ptr VRAM_SCRATCH, R2, VRAM_INC_1
        ror R2

        jsr drawing_function
.endscope
.endmacro

.macro split_column_across_height_boundary starting_hw_address, drawing_function
.scope
        lda #14
        sec
        sbc MapYOffset
        sta R2

        lda MapYOffset
        bne no_fix
        dec R2 ; never draw more than 13 tiles in a single run
no_fix:

        asl R2
        write_vram_header_ptr starting_hw_address, R2, VRAM_INC_32
        ror R2

        jsr drawing_function

        lda starting_hw_address+1
        ; Set the Y component to zero
        and #%11111100
        sta VRAM_SCRATCH+1

        lda starting_hw_address
        and #%00011111
        sta VRAM_SCRATCH

        ; bytes remaining
        lda MapYOffset
        sec
        sbc #1
        beq skip
        bmi skip

        sta R2

        asl R2
        write_vram_header_ptr VRAM_SCRATCH, R2, VRAM_INC_32
        ror R2

        jsr drawing_function
skip:
.endscope
.endmacro

.macro split_attribute_row_across_nametables starting_hw_address, drawing_function
        lda starting_hw_address
        sta R2
        sta VRAM_SCRATCH
        lda starting_hw_address+1
        sta R2+1
        sta VRAM_SCRATCH+1

        ; first (leftmost) segment
        lda #8
        sec
        sbc AttributeXOffset
        sta R4

        jsr drawing_function

        ; bytes remaining + 2
        lda AttributeXOffset
        clc
        adc #2
        ; edge case: do we have more than 8 attribute bytes to go?
        cmp #9 ; >= 9
        bcc last_segment_prep
middle_segment:
        ; the middle segment must draw no more than 8 tiles
        lda #8
        sta R4

        ; here we need to massage the target address; it should
        ; switch nametables, and start at the left-most tile, but keep
        ; the same Y coordinate
        lda VRAM_SCRATCH+1 ; ppuaddr high byte
        eor #%00000100 ; swap nametables
        sta VRAM_SCRATCH+1
        sta R2+1

        lda VRAM_SCRATCH ; ppuaddr low byte
        and #%11111000 ; set X component to 0
        sta VRAM_SCRATCH
        sta R2

        jsr drawing_function

        ; now prepare R4 for the last segment
        lda AttributeXOffset
        sec
        sbc #6
        sta R4
        jmp last_segment

last_segment_prep:
        lda AttributeXOffset
        clc
        adc #2
        sta R4
last_segment:
        ; Same as above; if we drew a middle segment, we are now again on our
        ; *original* nametable, on the left side
        lda VRAM_SCRATCH+1 ; ppuaddr high byte
        eor #%00000100 ; swap nametables
        sta R2+1

        lda VRAM_SCRATCH ; ppuaddr low byte
        and #%11111000 ; set X component to 0
        sta R2

        jsr drawing_function
.endmacro

.macro split_attribute_column_across_height_boundary starting_hw_address, drawing_function
.scope
        lda starting_hw_address
        sta R2
        lda starting_hw_address+1
        sta R2+1

        ; top half
        lda #7
        sec
        sbc AttributeYOffset
        sta R4

        jsr drawing_function
        ; set the Y component of the attribute address to zero
        lda starting_hw_address+1
        sta R2+1
        lda starting_hw_address
        and #%11000111
        sta R2

        ; bytes remaining
        lda AttributeYOffset
        sta R4

        jsr drawing_function
.endscope
.endmacro


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

.proc shift_hwattrrows_left
        decAttrColumn HWAttributeUpperLeftRow
        decAttrColumn HWAttributeLowerLeftRow
        rts
.endproc

.proc shift_hwattrcolumns_left
        decAttrColumn HWAttributeUpperRightColumn
        decAttrColumn HWAttributeUpperLeftColumn
        rts
.endproc

.proc shift_hwattrrows_right
        incAttrColumn HWAttributeUpperLeftRow
        incAttrColumn HWAttributeLowerLeftRow
        rts
.endproc

.proc shift_hwattrcolumns_right
        incAttrColumn HWAttributeUpperRightColumn
        incAttrColumn HWAttributeUpperLeftColumn
        rts
.endproc

.proc shift_hwattrrows_down
        incAttrRow HWAttributeUpperLeftRow
        incAttrRow HWAttributeLowerLeftRow
        rts
.endproc

.proc shift_hwattrcolumns_down
        incAttrRow HWAttributeUpperRightColumn
        incAttrRow HWAttributeUpperLeftColumn
        rts
.endproc

.proc shift_hwattrrows_up
        decAttrRow HWAttributeUpperLeftRow
        decAttrRow HWAttributeLowerLeftRow
        rts
.endproc

.proc shift_hwattrcolumns_up
        decAttrRow HWAttributeUpperRightColumn
        decAttrRow HWAttributeUpperLeftColumn
        rts
.endproc



.proc scroll_tiles_down
        inc CameraYTileCurrent
        inc PpuYTileTarget
        lda #28
        cmp PpuYTileTarget
        bne no_positive_y_wrap
        lda #0
        sta PpuYTileTarget
no_positive_y_wrap:
        mov16 R0, MapLowerLeftRow
        ; the 5th bit of the scroll tells us if we're doing a left-column or a right-column
        lda #%00100000
        bit HWScrollLowerLeftRow
        ;bne lower_edge_lower_row
        jne lower_edge_lower_row
lower_edge_upper_row:
        split_row_across_nametables HWScrollLowerLeftRow, draw_upper_half_row
        
        jsr shift_hwrows_down
        ; Shift columns down *twice* to advance a complete metatile
        jsr shift_hwcolumns_down
        jsr shift_hwcolumns_down
        clc
        add16 MapUpperRightColumn, MapWidth
        add16 MapUpperLeftColumn, MapWidth
        ; Increment MapYOffset with wrap around
        inc MapYOffset
        lda #14
        cmp MapYOffset
        jne done
        lda #0
        sta MapYOffset

        jmp done
lower_edge_lower_row:
        split_row_across_nametables HWScrollLowerLeftRow, draw_lower_half_row
        clc
        add16 MapUpperLeftRow, MapWidth
        add16 MapLowerLeftRow, MapWidth
        ; Finish shifting hwrows down to the next metatile
        ; (We need to leave the columns alone until we cross a metatile boundary)
        jsr shift_hwrows_down
        
done:
        rts
.endproc

.proc scroll_attributes_down
        mov16 R0, AttributeLowerLeftRow
        split_attribute_row_across_nametables HWAttributeLowerLeftRow, draw_attribute_row
        ; move the attribute indices down
        clc
        add16 AttributeUpperRightColumn, AttributeWidth
        add16 AttributeUpperLeftColumn, AttributeWidth
        add16 AttributeUpperLeftRow, AttributeWidth
        add16 AttributeLowerLeftRow, AttributeWidth
        ; Increment AttributeYOffset with wraparound
        inc AttributeYOffset
        lda #7
        cmp AttributeYOffset
        bne shift_registers_down
        lda #0
        sta AttributeYOffset
shift_registers_down:
        jsr shift_hwattrrows_down
        jsr shift_hwattrcolumns_down
done:
        rts
.endproc

.proc scroll_tiles_up
        dec CameraYTileCurrent
        dec PpuYTileTarget
        bpl no_negative_y_wrap
        lda #27
        sta PpuYTileTarget
no_negative_y_wrap:
        mov16 R0, MapUpperLeftRow
        ; the 5th bit of the scroll tells us if we're doing a left-column or a right-column
        lda #%00100000
        bit HWScrollUpperLeftRow
        ;beq upper_edge_upper_row
        jeq upper_edge_upper_row
upper_edge_lower_row:
        split_row_across_nametables HWScrollUpperLeftRow, draw_lower_half_row
        jsr shift_hwrows_up
        ; Shift columns up *twice* to advance a complete metatile
        jsr shift_hwcolumns_up
        jsr shift_hwcolumns_up
        sec
        sub16 MapUpperRightColumn, MapWidth
        sub16 MapUpperLeftColumn, MapWidth
        ; Decrement MapYOffset with wraparound
        dec MapYOffset
        jpl done
        lda #13
        sta MapYOffset

        jmp done
upper_edge_upper_row:
        split_row_across_nametables HWScrollUpperLeftRow, draw_upper_half_row
        sec
        sub16 MapUpperLeftRow, MapWidth
        sub16 MapLowerLeftRow, MapWidth
        ; Finish shifting hwrows up to the next metatile
        ; (We need to leave the columns alone until we cross a metatile boundary)
        jsr shift_hwrows_up
done:
        rts
.endproc

.proc scroll_attributes_up
        mov16 R0, AttributeUpperLeftRow
        split_attribute_row_across_nametables HWAttributeUpperLeftRow, draw_attribute_row
        ; move the attribute indices up
        sec
        sub16 AttributeUpperRightColumn, AttributeWidth
        sub16 AttributeUpperLeftColumn, AttributeWidth
        sub16 AttributeUpperLeftRow, AttributeWidth
        sub16 AttributeLowerLeftRow, AttributeWidth
        ; Decrement AttributeYOffset with wraparound
        dec AttributeYOffset
        bpl shift_registers_up
        lda #6
        sta AttributeYOffset
shift_registers_up:
        jsr shift_hwattrrows_up
        jsr shift_hwattrcolumns_up
done:
        rts
.endproc

.proc scroll_tiles_right
        inc CameraXTileCurrent
        mov16 R0, MapUpperRightColumn
        ; the low bit of the scroll tells us if we're doing a left-column or a right-column
        lda #$01
        bit HWScrollUpperRightColumn
        bne right_side_right_column
        jmp right_side_left_column
right_side_right_column:
        split_column_across_height_boundary HWScrollUpperRightColumn, draw_right_half_col

        ; Move our map pointers to the right by one entire tile
        inc16 MapUpperRightColumn
        inc16 MapUpperLeftColumn
        inc16 MapUpperLeftRow
        inc16 MapLowerLeftRow
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
        jmp done
right_side_left_column:
        split_column_across_height_boundary HWScrollUpperRightColumn, draw_left_half_col

        ; The map index doesn't change, so we update *only* the column registers here
        ; Shift  hwcolumns right halfway to the next metatile
        jsr shift_hwcolumns_right
done:
        rts
.endproc

.proc scroll_attributes_right
        mov16 R0, AttributeUpperRightColumn
        split_attribute_column_across_height_boundary HWAttributeUpperRightColumn, draw_attribute_column

        ; Move our attribute pointers to the right by one
        ; ... note: I'm copying the tile code, but this FEELS WRONG. Shouldn't
        ; these all be inc16, to do a proper multi-byte operation?
        inc16 AttributeUpperRightColumn
        inc16 AttributeUpperLeftColumn
        inc16 AttributeUpperLeftRow
        inc16 AttributeLowerLeftRow
        ; Increment AttributeXOffset with wraparound
        inc AttributeXOffset
        lda #8
        cmp AttributeXOffset
        bne shift_registers_right
        lda #0
        sta AttributeXOffset
shift_registers_right:
        jsr shift_hwattrrows_right
        jsr shift_hwattrcolumns_right
done:
        rts
.endproc

.proc scroll_tiles_left
        dec CameraXTileCurrent
        mov16 R0, MapUpperLeftColumn
        ; the low bit of the scroll tells us if we're doing a left-column or a right-column
        lda #$01
        bit HWScrollUpperLeftColumn
        beq left_side_left_column
left_side_right_column:
        split_column_across_height_boundary HWScrollUpperLeftColumn, draw_right_half_col
        ; The map index doesn't change, so we update *only* the column registers here
        ; Shift hwcolumns left halfway to the next metatile
        jsr shift_hwcolumns_left
        jmp done
left_side_left_column:
        split_column_across_height_boundary HWScrollUpperLeftColumn, draw_left_half_col
        ; Move our map index to the left
        dec16 MapUpperRightColumn
        dec16 MapUpperLeftColumn
        dec16 MapUpperLeftRow
        dec16 MapLowerLeftRow
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
done:
        rts
.endproc

.proc scroll_attributes_left
        mov16 R0, AttributeUpperLeftColumn
        split_attribute_column_across_height_boundary HWAttributeUpperLeftColumn, draw_attribute_column

        ; Move our attribute pointers to the left by one
        ; ... note: I'm copying the tile code, but this FEELS WRONG. Shouldn't
        ; these all be inc16, to do a proper multi-byte operation?
        dec16 AttributeUpperRightColumn
        dec16 AttributeUpperLeftColumn
        dec16 AttributeUpperLeftRow
        dec16 AttributeLowerLeftRow
        ; Decrement AttributeXOffset with wraparound
        dec AttributeXOffset
        lda #$07
        and AttributeXOffset
        sta AttributeXOffset
shift_registers_right:
        jsr shift_hwattrrows_left
        jsr shift_hwattrcolumns_left
done:
        rts
.endproc

.proc scroll_camera
        ; did we move up or down?
        ; perform a 16-bit compare between target - current, and throw the result away
        lda CameraYTileCurrent
        cmp CameraYTileTarget
        ; if the result is zero, we did not scroll
        beq no_vertical_scroll
vertical_scroll:
        ; if the subtract here needed to borrow, the result is negative; we moved UP
        bcs scroll_up
scroll_down:
        ; Perform the vertical scroll, with attributes if needed, then exit
        ; note - We intentionally prioritize vertical scroll and let horizontal lag by
        ; a frame or two; it's fine
        jsr scroll_tiles_down
        lda CameraYTileCurrent
        and #$03
        bne done_scrolling
        jsr scroll_attributes_down
        jmp done_scrolling
scroll_up:
        ; (Here too, see above)
        jsr scroll_tiles_up
        lda CameraYTileCurrent
        and #$03
        cmp #$03
        bne done_scrolling
        jsr scroll_attributes_up
        jmp done_scrolling
no_vertical_scroll:
        ; did we move left or right?
        ; perform a 16-bit compare between target - current, and throw the result away
        lda CameraXTileCurrent
        cmp CameraXTileTarget
        ; if the result is zero, we did not scroll
        beq done_scrolling
horizontal_scroll:
        ; if the subtract here needed to borrow, the result is negative; we moved LEFT
        bcs scroll_left
scroll_right:
        jsr scroll_tiles_right
        lda CameraXTileCurrent
        and #$03
        bne done_scrolling
        jsr scroll_attributes_right
        jmp done_scrolling
scroll_left:
        jsr scroll_tiles_left
        lda CameraXTileCurrent
        and #$03
        cmp #$03
        bne done_scrolling
        jsr scroll_attributes_left
done_scrolling:
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
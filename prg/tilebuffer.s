; A system for queueing up changes to the tilemap, which then must be repainted.
; Anything outside the bounds of the camera is automatically repainted when it is
; scrolled into place, but anything already on-screen needs to be written again
; outside of scrolling updates. This file contains that logic.        

; The tile buffer is set up so that game logic can mostly ignore the camera.
; Tiles are queued up any time they are changed, and when the buffer is processed
; we can decide what tiles to keep/discard based on the camera's current location.

.macpack longbranch     

        .setcpu "6502"
        .include "collision.inc"
        .include "nes.inc"
        .include "ppu.inc"
        .include "scrolling.inc"
        .include "tilebuffer.inc"
        .include "vram_buffer.inc"
        .include "word_util.inc"
        .include "zeropage.inc"
        
.segment "PRGRAM"

MAX_BUFFERED_TILES = 128
BUFFER_INDEX_MASK = $7F

tilebuffer_x: .res MAX_BUFFERED_TILES
tilebuffer_y: .res MAX_BUFFERED_TILES
tilebuffer_starting_index: .res 1
tilebuffer_ending_index: .res 1

        .segment "SCROLLING_A000"

; result in A
.proc FAR_tilebuffer_remaining_capacity
        lda tilebuffer_starting_index
        sec
        sbc #1
        sec
        sbc tilebuffer_ending_index
        and #BUFFER_INDEX_MASK
        rts
.endproc

; Note: this is a good candidate for fixed mem
.proc FAR_tilebuffer_queue_tile
TilePosX := R0
TilePosY := R1
        ldx tilebuffer_ending_index
        lda TilePosX
        sta tilebuffer_x, x
        lda TilePosY
        sta tilebuffer_y, x
        rts
.endproc

.proc queue_single_tile
TilePosX := R0
TilePosY := R1
CameraMetatileX := R2
CameraMetatileY := R3

ScreenSpaceTileX := R2
ScreenSpaceTileY := R3

TargetPpuAddr := R4

GraphicsTileAddr := R6
GraphicsTileIndex := R8

        ; prep the 16x16 coordinates of the camera, discarding the half-tile offset
        lda CameraXTileCurrent
        lsr
        sta CameraMetatileX
        lda CameraYTileCurrent
        lsr
        sta CameraMetatileY

        ; sanity check: are the coordinates of this tile in-bounds of the camera?
        lda TilePosX
        sec
        sbc CameraMetatileX
        jmi reject_tile
        cmp #15 ; TODO: tweak this, it's probably too smol
        jcs reject_tile
        lda TilePosY
        sec
        sbc CameraMetatileY
        jmi reject_tile
        cmp #13 ; TODO: tweak this, it might be 1 tile too smol
        jcs reject_tile

        ; prep the tile coordinates for drawing into the PPU
        ; here we SUBTRACT the ppu's initial offset from the tile coordinates
        lda TilePosX
        sec
        sbc InitialMetatileOffsetX
        ; For X, we want the result to be from 0-31 to cover both nametables, so
        ; we can achieve that easily with a mask
        and #$1F
        sta ScreenSpaceTileX
        lda TilePosY
        sec
        sbc InitialMetatileOffsetY
        ; Y is a bit more complicated; we want it to range from 0-13, which is not a power
        ; of 2, so we effectively need to do a modulo in software. Later if we need to speed
        ; this up we can convert this to a lookup table, but for the initial run we'll just use
        ; two simple loops
y_minus_loop:
        bpl y_positive_loop
        clc
        adc #14
        jmp y_minus_loop

y_positive_loop:
        cmp #14
        bcc done_fixing_y
        sec
        sbc #14
        jmp y_positive_loop

done_fixing_y:
        sta ScreenSpaceTileY

        ; Now we need to construct the PPU address from the components
        ; First the Y position, which is (TileY << 1) << 5
        lda #0
        sta TargetPpuAddr+0
        lda ScreenSpaceTileY
        .repeat 6
        asl
        rol TargetPpuAddr+0
        .endrepeat
        sta TargetPpuAddr+1
        ; Add to this the X position, which is (TileX << 1) & $1F
        lda ScreenSpaceTileX
        asl
        and #$1F
        ora TargetPpuAddr+1
        sta TargetPpuAddr+1
        ; Now we add the nametable offset to the high byte, based on bit 5 of TileX
        lda ScreenSpaceTileX
        and #$10
        bne right_nametable
left_nametable:
        lda #$20
        jmp nametable_converge
right_nametable:
        lda #$24
nametable_converge:
        clc
        adc TargetPpuAddr+0
        sta TargetPpuAddr+0
        ; This completes the PPUADDR for the top row of this tile, and we can +32 later to get the bottom row.

        ; Now we need the graphics tile index from the map data, based on TilePosX and TilePosY
        graphics_map_index TilePosX, TilePosY, GraphicsTileAddr
        ldy #0
        lda (GraphicsTileAddr), y
        sta GraphicsTileIndex

        ; And we can finally queue up both halves to the vram buffer
        write_vram_header_ptr TargetPpuAddr, #2, VRAM_INC_1
        ldy VRAM_TABLE_INDEX
        ldx GraphicsTileIndex
        lda TilesetTopLeft, x
        sta VRAM_TABLE_START, y
        iny
        lda TilesetTopRight, x
        sta VRAM_TABLE_START, y
        iny
        sty VRAM_TABLE_INDEX
        inc VRAM_TABLE_ENTRIES

        add16b TargetPpuAddr, #32

        write_vram_header_ptr TargetPpuAddr, #2, VRAM_INC_1
        ldy VRAM_TABLE_INDEX
        ldx GraphicsTileIndex
        lda TilesetTopLeft, x
        sta VRAM_TABLE_START, y
        iny
        lda TilesetTopRight, x
        sta VRAM_TABLE_START, y
        iny
        sty VRAM_TABLE_INDEX
        inc VRAM_TABLE_ENTRIES

        ; TODO: queue up the attribute byte here, which requires a totally different PPUADDR but can reuse much of the
        ; other logic

reject_tile:
        rts
.endproc

; For now, one call to this function == one tile processed if the queue is not empty.
; Later, this function could handle multiple tiles at once with some heuristics to avoid
; overloading the vram buffer
.proc FAR_process_tilebuffer_queue
TilePosX := R0
TilePosY := R1
; note: R2 - R8 will be clobbered
        ldx tilebuffer_starting_index
        cpx tilebuffer_ending_index
        beq done

        lda tilebuffer_x, x
        sta TilePosX
        lda tilebuffer_y, x
        sta TilePosY
        inc tilebuffer_starting_index
        jsr queue_single_tile

done:
        rts
.endproc


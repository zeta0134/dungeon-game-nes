        .setcpu "6502"
        .include "nes.inc"
        .include "mmc3.inc"
        .include "scrolling.inc"
        .include "ppu.inc"
        .include "zeropage.inc"

.scope PRGLAST_E000
        .zeropage
; IRQ variable to assist with screen split
SplitScanlinesToStatus: .byte $00

        .segment "PRGLAST_E000"
        ;.org $e000

.export set_scroll_for_frame, install_irq_handler

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

.macro wait_for_sprite_zero_to_clear
.scope
        ;lda #%01000000
;keep_waiting:
        ;bit PPUSTATUS
        ;bne keep_waiting
.endscope
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
        ; clear PPUADDR to $2000 before we begin; this ensures the value for A12 is locked into place *before* we go
        ; mucking around with IRQ enablement later
        lda PPUSTATUS
        lda #$20
        sta PPUADDR
        lda #$00
        sta PPUADDR
        ; now set the scroll properly, using the camera's position
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
        cmp #33
        beq _single_scanline_spinwait_split
        cmp #34
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
_single_scanline_spinwait_split:
        jsr single_scanline_spinwait_split
        rts
.endproc

.proc no_midscreen_split
        ; the first IRQ won't be until the top of the status area:
        set_first_irq_byte #$03
        set_second_irq_byte #$80
        set_irq_cleanup_handler (post_irq_status_upper_half)
        ; after 192 - 1 frames:
        lda #191
        sta MMC3_IRQ_LATCH
enable_rendering:
        lda #$1E
        sta PPUMASK
        wait_for_sprite_zero_to_clear
reload_mmc3_irq:
        sta MMC3_IRQ_RELOAD
        sta MMC3_IRQ_DISABLE
        sta MMC3_IRQ_ENABLE
        rts
.endproc

; very much like no_midscreen_split, except we spinwait for one extra
; scanline right before the statusbar area; this works around an MMC3 IRQ
; resolution problem
.proc single_scanline_spinwait_split
        ; Set the scroll just like a midscreen split
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
        ; ... but set a spinwait cleanup routine; this will draw the status bar, rather than
        ; issuing a second IRQ to wait some more
        set_irq_cleanup_handler (spinwait_then_post_irq_status_upper_half)
        ; after 192 - 1 frames:
        lda #190
        sta MMC3_IRQ_LATCH
enable_rendering:
        lda #$1E
        sta PPUMASK
        wait_for_sprite_zero_to_clear
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
        lda #190
        sbc R0
        sta SplitScanlinesToStatus
enable_rendering:
        lda #$1E
        sta PPUMASK
        wait_for_sprite_zero_to_clear
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
        lda #191
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
        wait_for_sprite_zero_to_clear
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

.proc spinwait_then_post_irq_status_upper_half
        ; first, spinwait so the previous scanline can finish
        ; (we can't do this with an IRQ due to MMC3 timing problems)

        jsr burn_some_cycles
        ; MAGIC.gif
        .repeat 11
        nop
        .endrep

        ; Now, set the scroll position for the top of the status bar:
        ;set_first_irq_byte #$03
        lda #$03
        sta PPUADDR
        ;set_second_irq_byte #$80
        lda #$80
        sta PPUADDR

        ; Here we must correct fine X for status area display,
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
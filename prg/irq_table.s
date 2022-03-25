        .setcpu "6502"

        .include "branch_checks.inc"
        .include "nes.inc"
        .include "mmc3.inc"

        .zeropage

active_irq_index: .byte $00
inactive_irq_index: .byte $00
irq_table_index: .byte $00
two_thirds_temp: .byte $00
irq_stash: .byte $00

.exportzp active_irq_index, inactive_irq_index

        .segment "PRGRAM"


; note: for timing purpuses, ensure no table crosses a page boundary! align / relocate individual tables
; as required. It is NOT important for these tables to be adjacent in memory, but they MUST each reside
; on one page. (If they are sized as a power of 2, simply aligning the entire section to a page start
; should be sufficient.)
.align 256
; Sets the total size of the IRQ table. Note that when using double-buffering (recommended),
; the maximum available scanlines will be (IRQ_TABLE_SIZE / 2).
IRQ_TABLE_SIZE = 128
irq_table_scanlines: .res IRQ_TABLE_SIZE
irq_table_nametable_high: .res IRQ_TABLE_SIZE
irq_table_scroll_y: .res IRQ_TABLE_SIZE
irq_table_scroll_x: .res IRQ_TABLE_SIZE
irq_table_ppumask: .res IRQ_TABLE_SIZE
irq_table_chr0_bank: .res IRQ_TABLE_SIZE

.export irq_table_scanlines, irq_table_nametable_high, irq_table_scroll_y, irq_table_scroll_x, irq_table_ppumask, irq_table_chr0_bank

        .segment "PRGLAST_E000"

.align 32

; Credit: @PinoBatch, https://github.com/pinobatch
; Technically burns 12.664 cycles on average, which is
; good enough for our purposes here, we have a fairly generous
; timing window
.macro burn_12_and_two_thirds_cycles
.scope
        clc
        lda two_thirds_temp
        adc #170
        sta two_thirds_temp
        bcsnw continue
continue:
.endscope
.endmacro

; Note that the active index now defaults to 0. If for some reason we are comfortable
; ditching the double-buffering technique, then it is sufficient to remove all calls to
; swap_irq_buffers, and instead use the full size of the table as the only active index.
; Beware race conditions! Double-buffering is *much* safer.
.export initialize_irq_table
.proc initialize_irq_table
        jsr clear_irq_table
        lda #0
        sta active_irq_index
        lda #(IRQ_TABLE_SIZE / 2)
        sta inactive_irq_index
        rts
.endproc

; we don't really "clear" this so much as configure every entry
; to take more scanlines than there are in a single frame
; (note that irqs should be disabled during NMI if we go with this
; technique in a real project)
.export clear_irq_table
.proc clear_irq_table
        ldx #(IRQ_TABLE_SIZE & $FF)
loop:
        lda #$FF
        sta irq_table_scanlines, x
        ; this is unnecessarily inefficient, and should be redundant with
        ; memory already zeroed out by our reset routine. Still, we only
        ; ever need to do this once and it won't hurt to leave it in.
        lda #$00
        sta irq_table_scroll_x, x
        sta irq_table_scroll_y, x
        sta irq_table_nametable_high, x
        sta irq_table_chr0_bank, x
        lda #$1F
        sta irq_table_ppumask, x
        dex
        bne loop
        rts
.endproc

.export swap_irq_buffers
.proc swap_irq_buffers
        lda inactive_irq_index
        ldx active_irq_index
        stx inactive_irq_index
        sta active_irq_index
        rts
.endproc

; Sets up the render to use the IRQ table
.export setup_irq_table_for_frame
.proc setup_irq_table_for_frame
        ; reset PPU latch
        lda PPUSTATUS

        ; explicitly set bank locations and nametable (to 0)
        lda #(VBLANK_NMI | OBJ_1000 | BG_0000)
        sta PPUCTRL

        ; PPUMASK should hide sprites, but we need to display backgrounds otherwise MMC3's
        ; IRQ counter braks. To facilitate this, we'll display the HUD row again here, but
        ; with a completely empty CHR bank loaded instead of the usual HUD tiles
        lda #(BG_ON)
        sta PPUMASK

        ; Switch the blank bank in instead of the HUD graphics, guaranteeing that the
        ; top 8px will draw the background color and nothing else:
        mmc3_select_bank $0, #$00

        ; Now scroll to the HUD region for this first segment
        lda #$00
        sta PPUSCROLL ; x
        lda #224
        sta PPUSCROLL ; y

        ; reset the irq table
        lda active_irq_index
        sta irq_table_index

        ; just in case, acknowledge any pending interrupts
        sta MMC3_IRQ_DISABLE

        ; enable interrupts; the first one shall occur after 8 scanlines
        ; fancy TODO: once we have a settings screen, we could allow the user
        ; to adjust the timing of the first offset, allowing software-based
        ; calibration for varying amounts of vertical overscan
        lda #(8 - 1)
        sta MMC3_IRQ_LATCH
        sta MMC3_IRQ_RELOAD
        sta MMC3_IRQ_ENABLE

        rts
.endproc

.export irq
.proc irq
        ; earliest cycle: 285
        ; latest possible cycle: 305
        ; timing looks like: 
        ;     some opcode ; cpu (ppu)

        ; preserve registers

        pha ; 3 (9) 
        txa ; 2 (6)
        pha ; 3 (9)
        tya ; 2 (6)
        pha ; 3 (9)

        ; acknowledge IRQ (no effect on counter)
        sta MMC3_IRQ_DISABLE ; 4 (12)

        ; setup for CHR0 bank switching
        ; note: we intentionally ignore the shadow register here, instead
        ; we'll restore that when exiting the vector
        lda #(MMC3_BANKING_MODE + 0) ; 2 (6)
        sta MMC3_BANK_SELECT ; 4 (12)

        ; ppu dot range here: 13 - 33
        ; note: adjust this nop chain to alter alignment as a whole, both for IRQ-triggered
        ; writes and CPU-delay timed ones that follow 1px segments

        ; For a real MMC3
        .repeat 6
        nop
        .endrep ; 12 (36)

        ; ppu dot range here: 49 - 69

        ; CPU-delayed 1px scanlines will merge here:
split_xy_begin:
        ; prep initial bytes for writing
        ldy irq_table_index ; 3 (9)
        ldx irq_table_nametable_high, y ; 4 (12)
        lda irq_table_scroll_y, y  ; 4 (12)

        ; ppu dot range here: 82 - 102

        ; write first two bytes during *current* scanline (no visible change)
        stx $2006 ; 4 (12)
        sta $2005 ; 4 (12)

        ; calculate the nametable byte, a already contains scroll_y
        and #$F8 ; 2 (6)
        asl ; 2 (6) 
        asl ; 2 (6)
        sta irq_stash ; 3 (9)

        lda irq_table_scroll_x, y ; 4 (12)
        ; stash this on the stack for later reading
        pha ; 3 (9)
        lsr ; 2 (6)
        lsr ; 2 (6)
        lsr ; 2 (6)
        ora irq_stash ; 3 (9)
        ; stuff this in x for later writing
        tax ; 2 (6)

        ; ppu dot range here: 187 - 207

        ; burn 9 cycles here
        nop ; 2 (6)
        nop ; 2 (6)
        php ; 4 (12)
        plp ; 3 (9)

        ; ppu dot range here: 220 - 240

        ; perform the CHR0 bank swap here; this is timed as late as possible to minimize the
        ; chance of a visible glitch
        ; (todo: if we can remove the pla, we can guarantee a glitch-free write, as written we
        ; are a cycle or two early and might occasionally glitch depending on IRQ jitter)
        lda irq_table_chr0_bank, y ; 4 (12)
        sta MMC3_BANK_DATA ; 4 (12)

        ; ppu dot range here: 244 - 264

        ; restore scroll_x from the stack
        pla ; 4 (12)

        ; ppu dot range here: 256 - 276

        ; perform the last two scroll writes:
        sta $2005 ; 4 (12)
        stx $2006 ; 4 (12)

        ; ppu dot range here: 280 - 300

        lda irq_table_ppumask, y ; 4 (12)
        sta PPUMASK ; 4 (12)

        ; end timing sensitive code; prep for next scanline
        inc irq_table_index ; 5 (15)

        ; Wait the requisite number of scanlines before the next
check_1px:
        lda irq_table_scanlines, y ; 4 (12)
        cmp #$01 ; 2 (6)
        bnenw check_2px ; when not taken: 2 (6), when taken: 3 (9)
delay_1px_with_cpu:
        ; we've already missed the rising A12 edge, so here we need to use the CPU to delay
        ; at this stage we are within dots: 2 - 22

        ; accounting for the jmp, we need to burn exactly 15.6667 cycles. We can deal with 12.6667 of those here:
        burn_12_and_two_thirds_cycles ; 12.667 (~38)

        ; ... and the jmp consumes the last 3
        jmp split_xy_begin ; 3 (9)

check_2px:
        ; ppu dot range here: 5 - 25

        ; as it turns out, writing $00 to the scanline counter is inconsistent across MMC3 clones, flashcarts,
        ; and some older emulators. While it should work in theory on real hardware, it is safer to also use
        ; a CPU timed delay in this case
        cmp #$02 ; 2 (6)
        bne delay_with_mmc3_irq ; when not taken: 2 (6)

        ; ppu dot range here: 17 - 37

        ; now we need to burn 10.667 (for alignment) plus 113.667 (one entire scanline), for a total
        ; of 124.333
        ; First let's deal with that 1/3 cycle nonsense
        burn_12_and_two_thirds_cycles ; 12.667 (~38)
        burn_12_and_two_thirds_cycles ; 12.667 (~38)
        
        ; now there are 99 cycles left to burn
        ; let's do 96 of them with two timed bits of magic

        ; 48 cycles here (144)
        nop
        ldy #9
        dey
        bnenw *-1
        ; ... and again (144)
        nop
        ldy #9
        dey
        bnenw *-1

        ; and the jmp takes care of the last 3
        jmp split_xy_begin; 3 (9)

delay_with_mmc3_irq:
        sec
        sbc #2
        sta MMC3_IRQ_LATCH
        sta MMC3_IRQ_RELOAD
        sta MMC3_IRQ_ENABLE

        ; since we possibly clobbered the MMC3 bank select register, restore the shadow copy here
        ; (99% of the time this will have no effect, but if we interrupted a far call...)
        lda mmc3_bank_select_shadow
        sta MMC3_BANK_SELECT

        ; restore registers
        pla
        tay
        pla
        tax
        pla

        ; all done
        rti
.endproc
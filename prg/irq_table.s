        .setcpu "6502"

        .include "debug.inc"
        .include "branch_checks.inc"
        .include "irq_table.inc"
        .include "nes.inc"
        .include "mmc3.inc"
        .include "palette.inc"

        .zeropage

active_irq_index: .byte $00
inactive_irq_index: .byte $00
irq_table_index: .byte $00
two_thirds_temp: .byte $00
irq_stash: .byte $00

        .segment "PRGRAM"


; note: for timing purpuses, ensure no table crosses a page boundary! align / relocate individual tables
; as required. It is NOT important for these tables to be adjacent in memory, but they MUST each reside
; on one page. (If they are sized as a power of 2, simply aligning the entire section to a page start
; should be sufficient.)
.align 256
; Sets the total size of the IRQ table. Note that when using double-buffering (recommended),
; the maximum available scanlines will be (IRQ_TABLE_SIZE / 2).
irq_table_scanlines: .res IRQ_TABLE_SIZE
irq_table_nametable_high: .res IRQ_TABLE_SIZE
irq_table_scroll_y: .res IRQ_TABLE_SIZE
irq_table_scroll_x: .res IRQ_TABLE_SIZE
irq_table_ppumask: .res IRQ_TABLE_SIZE
irq_table_chr0_bank: .res IRQ_TABLE_SIZE

        .segment "RAM"

EvenChr1Bank: .res 1
OddChr1Bank: .res 1

        .segment "PRGFIXED_E000"

; tweak this until the branch asserts go away :P
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
.proc clear_irq_table
        ldx #0
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
        inx
        cpx #(IRQ_TABLE_SIZE & $FF)
        bne loop
        rts
.endproc

.proc swap_irq_buffers
        lda inactive_irq_index
        ldx active_irq_index
        stx inactive_irq_index
        sta active_irq_index
        rts
.endproc

; Sets up the render to use the IRQ table
.proc setup_irq_table_for_frame
        ; reset PPU latch
        lda PPUSTATUS

        ; explicitly set bank locations and nametable (to 0)
        lda #(VBLANK_NMI | OBJ_1000 | BG_0000 | OBJ_8X16)
        sta PPUCTRL

        .if ::DEBUG_MODE
        ; In debug mode we disable PPUMASK writes, so start the frame with everything
        ; turned on. This will break sprite clipping on vertical seams, and disable color
        ; emphasis effects in affected rooms, but allows us to use debug colors to measure
        ; performance.
        lda #(BG_ON | OBJ_ON)
        sta PPUMASK
        .else
        ; PPUMASK should hide sprites, but we need to display backgrounds otherwise MMC3's
        ; IRQ counter breaks. To facilitate this, we'll display the HUD row again here, but
        ; with a completely empty CHR bank loaded instead of the usual HUD tiles
        lda #(BG_ON)
        sta PPUMASK
        .endif

        ; Switch the blank bank in instead of the HUD graphics, guaranteeing that the
        ; top 8px will draw the background color and nothing else:
        mmc3_select_bank $0, #$02

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
        lda #(3 - 1)
        sta MMC3_IRQ_LATCH
        sta MMC3_IRQ_RELOAD
        sta MMC3_IRQ_ENABLE

        rts
.endproc

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

        ; burn 11 cycles here
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

        .if ::DEBUG_MODE
        .repeat 4 ; 8 (24)
        nop
        .endrepeat
        .else
        lda irq_table_ppumask, y ; 4 (12)
        sta PPUMASK ; 4 (12)
        .endif


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
        bne check_postirq_vector ; when not taken: 2 (6), when taken: 3 (9)

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

check_postirq_vector:
        ; ppu dot range here: 20 - 40
        cmp #$FC ; 2 (6)
        bccnw delay_with_mmc3_irq ; 2 (6) (when not taken)
        jmp post_irq_vector ; 3 (9)
        ; in theory we could check for other special cases here, in order of "who needs more cycles at the start"
delay_with_mmc3_irq:
        sec
        sbc #2
        sta MMC3_IRQ_LATCH
        sta MMC3_IRQ_RELOAD
        sta MMC3_IRQ_ENABLE

safely_return_from_irq:
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

        .repeat 4
        .byte $00
        .endrep

; === Pretty much everything that follows is specific to this project ===

post_irq_vector:
check_hud_palette:
        ; ppu dot range here: 41 - 61
        ; note: scanlines remaining is still in A
        cmp #$FE ; 2 (6)
        bnenw check_chr1_cheat ; 2 (6) not taken, 3 (9) (taken)
        jmp post_irq_hud_palette ; 3 (9)

check_chr1_cheat:
        ; TODO: when we are ready for CHR1 switching, check for
        ; #$FD here and perform the extra work.
        cmp #$FD ; 2 (6)
        bnenw no_match_found ; 2 (6) not taken
        jmp dialog_portrait_chr1_cheat ; 3 (9)

no_match_found:
        ; unknown special value. Treat this as an IRQ stop command
        sta MMC3_IRQ_DISABLE
        jmp safely_return_from_irq

post_irq_hud_palette:
        ; ppu dot range here: 62 - 82

        ; ====== Post-IRQ Scanline =============

        ;delay_cycles 48
        ; 48 cycles here (144)
        nop
        ldy #9
        dey
        bnenw *-1
        ; ppu dot range here: 206 - 226

        ; note: state of w flag is known since we just came out of IRQ routine,
        ; so we don't need to bit PPUSTATUS here
        lda #$3F                 ; 2 (6)
        sta PPUADDR              ; 4 (12)
        lda #$00                 ; 2 (6) (PPUMASK: disable rendering)
        ldx #$00                 ; 2 (6)
        ldy HudPaletteBuffer + 0      ; 4 (12)
        ; ppu dot range here: 248 - 268
        sta PPUMASK ; 4 (12) disable rendering
        stx PPUADDR ; 4 (12) second write, set to #$3F00 (bg palette hack immediately takes effect, still in hblank)
        sty PPUDATA ; 4 (12) set BG0 to #$0F (black)
        ; now it would take too long to set PPUADDR again, so very quickly get it *out* of
        ; the palette zone
        stx PPUADDR ; 4 (12)
        stx PPUADDR ; 4 (12) set PPUADDR to $0000 (not in palette mem)
        ; ppu dot range here: 308-328
        ; now we can set PPUADDR properly, and we'll go from standard background (#$0F)
        ; to background hack (still #$0F) for no visible change
        lda #$3F    ; 2 (6)
        sta PPUADDR ; 4 (12)
        lda #$00    ; 2 (6)
        sta PPUADDR ; 4 (12) set PPUADDR back to #$3F00 for BG palette hack
        ; ppu dot range here: 3 - 23

        ; === Copy BG0 ===

        ; Since we have some time to kill here, go ahead and switch CHR1 to its even bank.
        ; The HUD can place extra tiles here as needed, and the dialog portrait system will
        ; use this as the first scanline of portrait graphics
        lda #(MMC3_BANKING_MODE + 1) ; 2 (6)
        sta MMC3_BANK_SELECT ; 4 (12)
        lda EvenChr1Bank ; 4 (12)
        sta MMC3_BANK_DATA ; 4 (12)
        ; put it back when we're done
        lda #(MMC3_BANKING_MODE + 0) ; 2 (6)
        sta MMC3_BANK_SELECT ; 4 (12)

        ; delay_cycles 56
        ; 48 cycles here (144)
        nop
        ldy #9
        dey
        bnenw *-1
        ; another 2 here (6)
        nop ; 2 (6)

        ; ppu dot range here: 213 - 233
        lda HudPaletteBuffer + 0 ; 4 (12) BG0.0
        ldx HudPaletteBuffer + 1 ; 4 (12) BG0.1
        ldy HudPaletteBuffer + 2 ; 4 (12) BG0.2
        
        ; ppu dot range here: 249 - 269
        sta PPUDATA ; 4 (12) BG0.0
        stx PPUDATA ; 4 (12) BG0.1
        sty PPUDATA ; 4 (12) BG0.2
        lda HudPaletteBuffer + 3  ; 4 (12)
        sta PPUDATA ; 4 (12) BG0.3
        ; now pointing to BG1.0, which we will display for the next scanline
        ; ppu dot range here: 309 - 329

        ; === Copy BG1 ===

        ;delay_cycles 86
        ; 48 cycles here (144)
        nop
        ldy #9
        dey
        bnenw *-1
        ; another 34 cycles here (102)
        ldy #136 ;hides 'DEY'
        dey
        bminw *-2

        ; ppu dot range here: 214 - 234
        
        lda HudPaletteBuffer + 5 ; 4 (12) BG1.1
        ldx HudPaletteBuffer + 6 ; 4 (12) BG1.2
        ldy HudPaletteBuffer + 7 ; 4 (12) BG1.3

        ; ppu dot range here: 250 - 270
        sta PPUDATA ; 4 (12) skip past BG1.0 with a write (garbage data, not used)
        sta PPUDATA ; 4 (12) BG1.1
        stx PPUDATA ; 4 (12) BG1.2
        sty PPUDATA ; 4 (12) BG1.3
        ; now pointing to BG2.0, which we will display for the next scanline
        ; ppu dot range here: 298 - 318

        ; === Copy BG2 ===
        
        ;delay_cycles 85
        ; 48 cycles here (144)
        nop
        ldy #9
        dey
        bnenw *-1
        ; and another 37 here (111)
        ldy #4
        nop
        nop
        dey
        bnenw *-3
        ; ppu dot range here: 212 - 232

        lda HudPaletteBuffer + 9  ; 4 (12) BG2.1
        ldx HudPaletteBuffer + 10 ; 4 (12) BG2.2
        ldy HudPaletteBuffer + 11 ; 4 (12) BG2.3

        ; ppu dot range here: 248 - 268
        sta PPUDATA ; 4 (12) skip past BG2.0 with a write (garbage data, not used)
        sta PPUDATA ; 4 (12) BG2.1
        stx PPUDATA ; 4 (12) BG2.2
        sty PPUDATA ; 4 (12) BG2.3
        ; now pointing to BG3.0, which we will display for the next scanline
        ; ppu dot range here: 296 - 316

        ; === Copy BG3 ===
        ;delay_cycles 86
        ; 48 cycles here (144)
        nop
        ldy #9
        dey
        bnenw *-1
        ; another 38 cycles here (114)
        nop
        ldy #6
        dey
        bplnw *-1
        ; ppu dot range here: 213 - 233
        

        lda HudPaletteBuffer + 13 ; 4 (12) BG3.1
        ldx HudPaletteBuffer + 14 ; 4 (12) BG3.2
        ldy HudPaletteBuffer + 15 ; 4 (12) BG3.3
        ; ppu dot range here: 249 - 269
        
        sta PPUDATA ; 4 (12) skip past BG3.0 with a write (garbage data, not used)
        sta PPUDATA ; 4 (12) BG3.1
        stx PPUDATA ; 4 (12) BG3.2
        sty PPUDATA ; 4 (12) BG3.3
        ; now pointing to BG3.0, which we will display for the next scanline
        ; ppu dot range here: 297 - 317

        ; === Post-palette swap ===
        ; We don't have enough time remaining in this scanline to fix PPUADDR, since
        ; nametable prefetch begins at dot 320. Instead, spinwait again and do the setup
        ; properly.

        ; hrm... it might be cleaner to simply re-use the existing split/xy code, since
        ; we have enough time. We can time it a little bit early, since we don't care
        ; about glitches from setting PPUADDR too early (rendering is disabled) and this
        ; should compensate for DPCM jitter

        ; Specifically, setting PPUADDR early will transition us from OBJ0.0 (BG0.0) (#$0F) to
        ; BG0 (normal rendering disabled color) (also #$0F) for no visual change.

        ; not this:
        ;delay_cycles 28 ; Ideal. Maybe check if DPCM is playing, and use this if it isn't?
        ; but this:
        ;delay_cycles 20 ; accounting for worst-case DPCM jitter of 4 CPU cycles, twice
        nop ; 2 (6)
        nop ; 2 (6)
        nop ; 2 (6)
        php ; 3 (9)
        plp ; 4 (12)
        php ; 3 (9)
        plp ; 4 (12)        

        jmp split_xy_begin ; 3 (9)
        ; we want to end up on dot 49 - 69 here

        rti

dialog_portrait_chr1_cheat:
        ; ppu dot range here: 77 - 97
        ; setup for the CHR1 switch
        lda #(MMC3_BANKING_MODE + 1) ; 2 (6)
        sta MMC3_BANK_SELECT ; 4 (12)

        ; Swap the even/odd CHR banks
        lda EvenChr1Bank ; 4 (12)
        ldx OddChr1Bank  ; 4 (12)
        sta OddChr1Bank  ; 4 (12)
        stx EvenChr1Bank ; 4 (12)

        ; spinwait until we are safely in hblank
        ; delay 35 cycles (105)
        ldy #136 ; hides 'DEY'
        dey
        dey
        bminw *-3

        ; ppu dot range here: 248 - 268
        ; Perform the CHR1 swap
        lda EvenChr1Bank ; 4 (12)
        sta MMC3_BANK_DATA ; 4 (12)
        ; end timing sensitive code

        ; Now, as a special case, we need to set up an MMC3 IRQ for 6 scanlines from now,
        ; ignoring the value in the table. (#$FD, in addition to this CHR1 swap functionality,
        ; also unconditionally encodes an 8px sized split. We simply don't need to make this general
        ; for this project.)

        lda #5
        sta MMC3_IRQ_LATCH
        sta MMC3_IRQ_RELOAD
        sta MMC3_IRQ_ENABLE

        ; finally, we can safely exit the IRQ routine as normal
        jmp safely_return_from_irq
.endproc

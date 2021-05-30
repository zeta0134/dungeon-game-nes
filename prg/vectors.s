.include "nes.inc"

.include "input.inc"
.include "memory_util.inc"
.include "scrolling_irq.inc"
.include "vram_buffer.inc"

.scope PRGLAST_E000
        .segment "PRGRAM"

        .segment "PRGLAST_E000"

.macro spinwait_for_vblank
.scope
loop:
        bit PPUSTATUS
        bpl loop
.endscope
.endmacro

        .import start
reset:
        sei            ; Disable interrupts
        cld            ; make sure decimal mode is off (not that it does anything)
        ldx #$ff       ; initialize stack
        txs

        ; Wait for the PPU to finish warming up
        spinwait_for_vblank
        spinwait_for_vblank

        ; Initialize zero page and stack
        clear_page $0000
        clear_page $0100

        ; Jump to main
        jmp start

        .importzp GameloopCounter, LastNmi
nmi:
        ; preserve registers
        pha
        txa
        pha
        tya
        pha

        ; always update sprite OAM right away
        lda #$00
        sta OAMADDR
        lda #$02
        sta OAM_DMA

        lda GameloopCounter
        cmp LastNmi
        beq lag_frame


        ; ===========================================================
        ; Tasks which should be guarded by a successful gameloop
        ;   - Running these twice (or in the middle of the gameloop)
        ;     could break things
        ; ===========================================================

        ; Copy buffered PPU bytes into PPU address space, as quickly as possible
        jsr vram_zipper
        ; Read controller registers and update button status
        jsr poll_input
        ; This signals to the gameloop that it may continue
        lda GameloopCounter
        sta LastNmi

lag_frame:
        ; ===========================================================
        ; Tasks which MUST be performed every frame
        ;   - Mostly IRQ setup here, if we miss doing this the render
        ;     will glitch pretty badly
        ; ===========================================================

        ; Set PPUSCROLL and also configure IRQ for screen split
        jsr set_scroll_for_frame

        ; todo: we might wish to update the audio engine here? That way music
        ; continues to play at the proper speed even if the game lags, ie, we
        ; trade potentially worse lag for maintaining the tempo

        ; restore registers
        pla
        tay
        pla
        tax
        pla
        ; all done
        rti

        ;
        ; Labels nmi/reset/irq are part of prg3_e000.s
        ;
        .segment "VECTORS"
        .addr nmi
        .addr reset
        .addr $00E0
.endscope
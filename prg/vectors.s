.include "nes.inc"

.include "irq_table.inc"
.include "input.inc"
.include "main.inc"
.include "memory_util.inc"
.include "mmc3.inc"
.include "palette.inc"
.include "scrolling.inc"
.include "sound.inc"
.include "vram_buffer.inc"
.include "zeropage.inc"

        .segment "PRGFIXED_E000"

.macro spinwait_for_vblank
.scope
loop:
        bit PPUSTATUS
        bpl loop
.endscope
.endmacro

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

nmi:
        ; preserve registers
        pha
        txa
        pha
        tya
        pha

        ; is NMI disabled? if so get outta here fast
        lda NmiSoftDisable
        bne nmi_soft_disable

        lda GameloopCounter
        cmp LastNmi
        beq lag_frame

        ; always update sprite OAM right away
        lda #$00
        sta OAMADDR
        lda #$02
        sta OAM_DMA

        ; ===========================================================
        ; Tasks which should be guarded by a successful gameloop
        ;   - Running these twice (or in the middle of the gameloop)
        ;     could break things
        ; ===========================================================

        ; Copy buffered PPU bytes into PPU address space, as quickly as possible
        jsr vram_zipper
        ; Update palette memory if required
        ;jsr refresh_palettes
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

        ; set the static CHR bank for the playfield (in case the dialog system
        ; or something else clobbered it. Proooobalby unnecessary, but just to
        ; be safe)
        mmc3_select_bank $1, StaticChrBank ; CHR 2K HIGH

        ; Set PPUSCROLL and also configure IRQ for screen split
        jsr setup_irq_table_for_frame

        ; enable IRQs early here, so that they can interrupt the audio engine
        cli

nmi_soft_disable:
        ; Here we *only* update the audio engine, nothing else. This is mostly to
        ; smooth over transitions when loading a new level.
        jsr update_audio

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
        .addr irq

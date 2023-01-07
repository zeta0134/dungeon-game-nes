        .setcpu "6502"

        .include "far_call.inc"
        .include "kernel.inc"
        .include "irq_table.inc"
        .include "main.inc"
        .include "memory_util.inc"
        .include "mmc3.inc"
        .include "levels.inc"
        .include "nes.inc"
        .include "ppu.inc"
        .include "prng.inc"
        .include "sound.inc"
        .include "sprites.inc"
        .include "word_util.inc"
        .include "zeropage.inc"

.segment "PRGFIXED_E000"

start:
        lda #$00
        sta PPUMASK ; disable rendering
        sta PPUCTRL ; and NMI

        ; Clear out main memory regions
        st16 R0, ($0000)
        st16 R2, ($0100)
        jsr clear_memory
        st16 R0, ($0200)
        st16 R2, ($0600)
        jsr clear_memory

        jsr initialize_mmc3
        jsr initialize_palettes
        far_call FAR_initialize_oam
        jsr initialize_ppu
        jsr initialize_irq_table
        jsr init_audio

        ; disable unusual IRQ sources
        lda #%01000000
        sta $4017 ; APU frame counter
        lda #0
        sta $4010 ; DMC DMA

        ; initialize the prng seed to a nonzero value
        lda #1
        sta seed

        ; Setup our initial kernel state
        st16 GameMode, init_engine

        ; hand control over to the kernel, which will manage game mode management
        ; for the rest of runtime
main_loop:
        far_call FAR_run_kernel
        jmp main_loop

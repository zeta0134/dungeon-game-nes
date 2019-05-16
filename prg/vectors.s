.include "nes.inc"
.include "globals.inc"

.scope PRGLAST_E000
        .segment "PRGLAST_E000"

spinwait_for_vblank:
        bit PPUSTATUS
        bpl spinwait_for_vblank
        rts

reset:
        sei            ; Disable interrupts
        cld            ; make sure decimal mode is off (not that it does anything)
        ldx #$ff       ; initialize stack
        txs

        ; Wait for the PPU to finish warming up
        jsr spinwait_for_vblank
        jsr spinwait_for_vblank

        ; Jump to main
        jmp start

nmi:
        ; preserve registers
        pha
        ; perform sprite OAM
        lda #$00
        sta OAMADDR
        lda #$02
        sta OAM_DMA
        ; restore registers
        pla
        ; all done
        rti

irq:
        rti

        ;
        ; Labels nmi/reset/irq are part of prg3_e000.s
        ;
        .segment "VECTORS"
        .addr nmi
        .addr reset
        .addr irq
.endscope
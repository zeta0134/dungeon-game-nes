.include "nes.inc"

.scope PRGLAST_E000
        .segment "PRGLAST_E000"

spinwait_for_vblank:
        bit PPUSTATUS
        bpl spinwait_for_vblank
        rts

        .import start
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

        .import FrameCounter
nmi:
        ; preserve registers
        pha
        ; perform sprite OAM
        lda #$00
        sta OAMADDR
        lda #$02
        sta OAM_DMA
        
        inc FrameCounter
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
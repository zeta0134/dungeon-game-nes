.include "nes.inc"
.include "memory_util.inc"

.scope PRGLAST_E000
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

        .importzp FrameCounter
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
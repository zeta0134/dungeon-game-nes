.include "nes.inc"

.include "input.inc"
.include "memory_util.inc"
.include "scrolling.inc"
.include "ggsound.inc"

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
        txa
        pha
        tya
        pha
        ; perform sprite OAM
        lda #$00
        sta OAMADDR
        lda #$02
        sta OAM_DMA

        ; Tasks dependent on PPU not rendering
        jsr scroll_camera

        ; Cleanup PPU tasks, set registers for next frame
        jsr set_scroll_for_frame

        ; Other tasks that should run once per frame with consistent-ish timing
        jsr poll_input
        soundengine_update
        
        ; This signals to the gameloop that it may continue
        inc FrameCounter

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
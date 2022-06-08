        .setcpu "6502"
        .include "bhop/bhop.inc"
        .include "far_call.inc"
        .include "mmc3.inc"
        .include "sound.inc"
        .include "word_util.inc"
        .include "zeropage.inc"

        .segment "RAM"
Pulse1RowCounter: .res 1
Pulse2RowCounter: .res 1
TriangleRowCounter: .res 1
Pulse1DelayCounter: .res 1
Pulse2DelayCounter: .res 1
TriangleDelayCounter: .res 1

        .zeropage
Pulse1SfxPtr: .res 2
Pulse2SfxPtr: .res 2
TriangleSfxPtr: .res 2

        .segment "MUSIC_A000"

.export bhop_music_data
bhop_music_data:
        ;.include "../art/music/calm.asm"
        .include "../art/music/heat.asm"

        .segment "PRGFIXED_8000"

.proc update_audio
        access_data_bank #<.bank(bhop_music_data)
        jsr bhop_play
        jsr update_sfx
        restore_previous_bank
        rts
.endproc

.proc init_audio
        access_data_bank #<.bank(bhop_music_data)
        lda #0
        jsr bhop_init
        restore_previous_bank
        rts
.endproc

; inputs: track number in A
.proc play_track
        pha
        access_data_bank #<.bank(bhop_music_data)
        pla
        jsr bhop_init
        restore_previous_bank
        rts
.endproc

; === Utility functions needed by the music player ===
.proc bhop_apply_dpcm_bank
        pha ; preserve a for a moment
        lda #(MMC3_BANKING_MODE + $6)
        sta MMC3_BANK_SELECT
        pla ; restore the bank number, and write it
        sta MMC3_BANK_DATA        
        rts
.endproc
.export bhop_apply_dpcm_bank

.proc play_sfx_pulse1
SfxPtr := R0
        lda SfxPtr
        sta Pulse1SfxPtr
        lda SfxPtr+1
        sta Pulse1SfxPtr+1
        ldy #0
        lda (Pulse1SfxPtr), y
        sta Pulse1RowCounter
        inc16 Pulse1SfxPtr
        lda #0
        sta Pulse1DelayCounter
        lda #0
        jsr bhop_mute_channel
        rts
.endproc

.proc play_sfx_pulse2
SfxPtr := R0
        lda SfxPtr
        sta Pulse2SfxPtr
        lda SfxPtr+1
        sta Pulse2SfxPtr+1
        ldy #0
        lda (Pulse2SfxPtr), y
        sta Pulse2RowCounter
        inc16 Pulse2SfxPtr
        lda #0
        sta Pulse2DelayCounter
        lda #1
        jsr bhop_mute_channel
        rts
.endproc

.proc play_sfx_triangle
SfxPtr := R0
        lda SfxPtr
        sta TriangleSfxPtr
        lda SfxPtr+1
        sta TriangleSfxPtr+1
        ldy #0
        lda (TriangleSfxPtr), y
        sta TriangleRowCounter
        inc16 TriangleSfxPtr
        lda #0
        sta Pulse2DelayCounter
        lda #2
        jsr bhop_mute_channel
        rts
.endproc

.proc update_pulse1
        lda Pulse1DelayCounter
        beq advance
        dec Pulse1DelayCounter
        jmp done
advance:
        lda Pulse1RowCounter
        beq silence
        dec Pulse1RowCounter
        
        ldy #0
loop:
        lda (Pulse1SfxPtr), y
        bmi last_command
        ;clc
        ;adc #0
        tax
        inc16 Pulse1SfxPtr
        lda (Pulse1SfxPtr), y
        sta $4000, x
        inc16 Pulse1SfxPtr
        jmp loop
last_command:
        and #%01111111
        sta Pulse1DelayCounter
        inc16 Pulse1SfxPtr
        jmp done

silence:
        lda #0
        jsr bhop_unmute_channel
done:
        rts
.endproc

.proc update_pulse2
        lda Pulse2DelayCounter
        beq advance
        dec Pulse2DelayCounter
        jmp done
advance:
        lda Pulse2RowCounter
        beq silence
        dec Pulse2RowCounter
        
        ldy #0
loop:
        lda (Pulse2SfxPtr), y
        bmi last_command
        clc
        adc #4
        tax
        inc16 Pulse2SfxPtr
        lda (Pulse2SfxPtr), y
        sta $4000, x
        inc16 Pulse2SfxPtr
        jmp loop
last_command:
        and #%01111111
        sta Pulse2DelayCounter
        inc16 Pulse2SfxPtr
        jmp done

silence:
        lda #1
        jsr bhop_unmute_channel
done:
        rts
.endproc

.proc update_triangle
        lda TriangleDelayCounter
        beq advance
        dec TriangleDelayCounter
        jmp done
advance:
        lda TriangleRowCounter
        beq silence
        dec TriangleRowCounter
        
        ldy #0
loop:
        lda (TriangleSfxPtr), y
        bmi last_command
        clc
        adc #8
        tax
        inc16 TriangleSfxPtr
        lda (TriangleSfxPtr), y
        sta $4000, x
        inc16 TriangleSfxPtr
        jmp loop
last_command:
        and #%01111111
        sta TriangleDelayCounter
        inc16 TriangleSfxPtr
        jmp done

silence:
        lda #2
        jsr bhop_unmute_channel
done:
        rts
.endproc

.proc update_sfx
        jsr update_pulse1
        jsr update_pulse2
        jsr update_triangle
        rts
.endproc

; === SFX definitions follow ===

PULSE_DLV = $0
PULSE_SWEEP = $1
PULSE_FREQ_LOW = $2
PULSE_FREQ_HIGH = $3

DUTY_0 = %00000000
DUTY_1 = %01000000
DUTY_2 = %10000000
DUTY_3 = %11000000

NO_LENGTH = %00100000
VOL =       %00010000
DECAY =     %00000000

S_ENABLE = %10000000
S_PERIOD_0 = %00000000
S_PERIOD_1 = %00010000
S_PERIOD_2 = %00100000
S_PERIOD_3 = %00110000
S_PERIOD_4 = %01000000
S_PERIOD_5 = %01010000
S_PERIOD_6 = %01100000
S_PERIOD_7 = %01110000

S_SHIFT_0 = %00000000
S_SHIFT_1 = %00000001
S_SHIFT_2 = %00000010
S_SHIFT_3 = %00000011
S_SHIFT_4 = %00000100
S_SHIFT_5 = %00000101
S_SHIFT_6 = %00000110
S_SHIFT_7 = %00000111

S_NEG = %00001000

END_ROW = %10000000

MAX_LENGTH = %11111000

sfx_jump:
        .byte 3 ; length of this sfx in rows
        .byte PULSE_DLV, DUTY_0 | DECAY | $2
        .byte PULSE_FREQ_LOW, <(300)
        .byte PULSE_FREQ_HIGH, >(300) | MAX_LENGTH
        .byte PULSE_SWEEP, S_ENABLE | S_PERIOD_0 | S_SHIFT_5 | S_NEG
        .byte END_ROW | 6
        .byte PULSE_DLV, DUTY_1 | DECAY | $2
        .byte END_ROW | 2
        .byte PULSE_DLV, DUTY_2 | DECAY | $2
        .byte END_ROW | 5

sfx_teleport:
        .byte 4 ; length of this sfx in rows
        .byte PULSE_DLV, DUTY_2 | VOL | $C
        .byte PULSE_FREQ_LOW, <(210)
        .byte PULSE_FREQ_HIGH, >(210) | MAX_LENGTH
        .byte PULSE_SWEEP, S_ENABLE | S_PERIOD_0 | S_SHIFT_5 | S_NEG
        .byte END_ROW | 4
        .byte PULSE_DLV, DUTY_2 | VOL | $9
        .byte PULSE_FREQ_LOW, <(210)
        .byte PULSE_FREQ_HIGH, >(210) | MAX_LENGTH
        .byte PULSE_SWEEP, S_ENABLE | S_PERIOD_0 | S_SHIFT_5 | S_NEG
        .byte END_ROW | 4
        .byte PULSE_DLV, DUTY_2 | VOL | $6
        .byte PULSE_FREQ_LOW, <(210)
        .byte PULSE_FREQ_HIGH, >(210) | MAX_LENGTH
        .byte PULSE_SWEEP, S_ENABLE | S_PERIOD_0 | S_SHIFT_5 | S_NEG
        .byte END_ROW | 4
        .byte PULSE_DLV, DUTY_2 | VOL | $2
        .byte PULSE_FREQ_LOW, <(210)
        .byte PULSE_FREQ_HIGH, >(210) | MAX_LENGTH
        .byte PULSE_SWEEP, S_ENABLE | S_PERIOD_0 | S_SHIFT_5 | S_NEG
        .byte END_ROW | 4
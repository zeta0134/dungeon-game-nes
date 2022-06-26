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
NoiseRowCounter: .res 1
Pulse1DelayCounter: .res 1
Pulse2DelayCounter: .res 1
TriangleDelayCounter: .res 1
NoiseDelayCounter: .res 1
DpcmDelayCounter: .res 1

        .zeropage
Pulse1SfxPtr: .res 2
Pulse2SfxPtr: .res 2
TriangleSfxPtr: .res 2
NoiseSfxPtr: .res 2

        .segment "MUSIC_A000"

.export bhop_music_data
bhop_music_data:
        .include "../art/music/calm.asm"
        ;.include "../art/music/heat.asm"

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

.proc play_sfx_noise
SfxPtr := R0
        lda SfxPtr
        sta NoiseSfxPtr
        lda SfxPtr+1
        sta NoiseSfxPtr+1
        ldy #0
        lda (NoiseSfxPtr), y
        sta NoiseRowCounter
        inc16 NoiseSfxPtr
        lda #0
        sta Pulse2DelayCounter
        lda #3
        jsr bhop_mute_channel
        rts
.endproc

.proc play_sfx_dpcm
SampleAddr := R0
SampleLength := R1
SampleRate := R2
SampleBank := R3
SfxFrames := R4
        ; setup the sample properties
        lda SampleRate
        sta $4010
        lda SampleAddr
        sta $4012
        lda SampleLength
        sta $4013

        ; bank this sample right on in
        lda SampleBank
        jsr bhop_apply_dpcm_bank

        ; briefly disable the sample channel to set bytes_remaining in the memory
        ; reader to 0, then start it again to initiate playback
        lda #$0F
        sta $4015
        lda #$1F
        sta $4015

        ; tell bhop to ignore this channel...
        lda #4
        jsr bhop_mute_channel
        ; ... for this long
        lda SfxFrames
        sta DpcmDelayCounter
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

.proc update_noise
        lda NoiseDelayCounter
        beq advance
        dec NoiseDelayCounter
        jmp done
advance:
        lda NoiseRowCounter
        beq silence
        dec NoiseRowCounter
        
        ldy #0
loop:
        lda (NoiseSfxPtr), y
        bmi last_command
        clc
        adc #$C
        tax
        inc16 NoiseSfxPtr
        lda (NoiseSfxPtr), y
        sta $4000, x
        inc16 NoiseSfxPtr
        jmp loop
last_command:
        and #%01111111
        sta NoiseDelayCounter
        inc16 NoiseSfxPtr
        jmp done

silence:
        lda #3
        jsr bhop_unmute_channel
done:
        rts
.endproc

.proc update_dpcm
        lda DpcmDelayCounter
        beq done
        dec DpcmDelayCounter
        bne done
        ; we have just decremented the counter to zero from a playing state;
        ; un-mute DPCM and let bhop take over again
        lda #4
        jsr bhop_unmute_channel
done:
        rts
.endproc

.proc update_sfx
        jsr update_pulse1
        jsr update_pulse2
        jsr update_triangle
        jsr update_noise
        jsr update_dpcm
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

NOISE_VOL = $0
NOISE_PERIOD = $2
NOISE_LENGTH = $3

NOISE_MODE_1 = %10000000

END_ROW = %10000000
MAX_LENGTH = %11111000

sfx_jump:
        .byte 2 ; length of this sfx in rows
        .byte PULSE_DLV, DUTY_1 | DECAY | $2
        .byte PULSE_FREQ_LOW, <(300)
        .byte PULSE_FREQ_HIGH, >(300) | MAX_LENGTH
        .byte PULSE_SWEEP, S_ENABLE | S_PERIOD_0 | S_SHIFT_5 | S_NEG
        .byte END_ROW | 6
        .byte PULSE_DLV, DUTY_2 | DECAY | $2
        .byte END_ROW | 2

sfx_double_jump:
        .byte 2 ; length of this sfx in rows
        .byte PULSE_DLV, DUTY_1 | DECAY | $2
        .byte PULSE_FREQ_LOW, <(270)
        .byte PULSE_FREQ_HIGH, >(270) | MAX_LENGTH
        .byte PULSE_SWEEP, S_ENABLE | S_PERIOD_0 | S_SHIFT_5 | S_NEG
        .byte END_ROW | 5
        .byte PULSE_DLV, DUTY_2 | DECAY | $2
        .byte END_ROW | 3

sfx_bounce:
        .byte 2 ; length of this sfx in rows
        .byte PULSE_DLV, DUTY_2 | DECAY | $2
        .byte PULSE_FREQ_LOW, <(400)
        .byte PULSE_FREQ_HIGH, >(400) | MAX_LENGTH
        .byte PULSE_SWEEP, S_ENABLE | S_PERIOD_0 | S_SHIFT_5 | S_NEG
        .byte END_ROW | 6
        .byte PULSE_FREQ_LOW, <(310)
        .byte PULSE_FREQ_HIGH, >(310) | MAX_LENGTH
        .byte END_ROW | 6

sfx_weak_hit:
        .byte 1 ; length of this sfx in rows
        .byte PULSE_DLV, DUTY_0 | DECAY | $2
        .byte PULSE_FREQ_LOW, <(500)
        .byte PULSE_FREQ_HIGH, >(500) | MAX_LENGTH
        .byte PULSE_SWEEP, S_ENABLE | S_PERIOD_0 | S_SHIFT_4
        .byte END_ROW | 6

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

sfx_error_buzz:
        .byte 4
        .byte NOISE_VOL, NO_LENGTH | VOL | $C
        .byte NOISE_PERIOD, NOISE_MODE_1 | ($F - $5)
        .byte NOISE_LENGTH, MAX_LENGTH
        .byte END_ROW | 4
        .byte NOISE_VOL, NO_LENGTH | VOL | $0
        .byte END_ROW | 4
        .byte NOISE_VOL, NO_LENGTH | VOL | $C
        .byte END_ROW | 14
        .byte NOISE_VOL, NO_LENGTH | VOL | $0
        .byte END_ROW | 1



.macro noise_init row_mode, row_period, row_vol, row_length
        .byte NOISE_VOL, NO_LENGTH | VOL | row_vol
        .byte NOISE_PERIOD, (row_mode << 7) | ($F - row_period)
        .byte NOISE_LENGTH, MAX_LENGTH
        .byte END_ROW | row_length
.endmacro

.macro noise_cont row_mode, row_period, row_vol, row_length
        .byte NOISE_VOL, NO_LENGTH | VOL | row_vol
        .byte NOISE_PERIOD, (row_mode << 7) | ($F - row_period)
        .byte END_ROW | row_length
.endmacro

sfx_dash_pulse:
        ; Length in rows
        .byte 2
        .byte PULSE_DLV, DUTY_2 | DECAY | $0
        .byte PULSE_FREQ_LOW, <(1140)
        .byte PULSE_FREQ_HIGH, >(1140) | MAX_LENGTH
        .byte PULSE_SWEEP, S_ENABLE | S_PERIOD_0 | S_SHIFT_3
        .byte END_ROW | 2
        .byte PULSE_SWEEP, S_ENABLE | S_PERIOD_0 | S_SHIFT_4 | S_NEG
        .byte END_ROW | 6

sfx_dash_noise:
        ; Length in rows
        .byte 17 
        ;          Mode Period  Vol  Length
        noise_init    1,    $5,  $7,      0
        noise_cont    1,    $4,  $5,      0
        noise_cont    1,    $3,  $2,      0
        noise_cont    0,    $2,  $0,      0

        noise_cont    0,    $4,  $7,      0
        noise_cont    0,    $5,  $9,      0
        noise_cont    0,    $6,  $C,      0
        noise_cont    0,    $7,  $A,      0

        noise_cont    0,    $8,  $9,      0
        noise_cont    0,    $9,  $7,      0
        noise_cont    0,    $A,  $6,      0        
        noise_cont    0,    $B,  $6,      0

        noise_cont    0,    $B,  $5,      0
        noise_cont    0,    $C,  $5,      0
        noise_cont    0,    $C,  $5,      0
        noise_cont    0,    $D,  $4,      0

        noise_cont    0,    $D,  $3,      0
        noise_cont    0,    $E,  $2,      0
        noise_cont    0,    $E,  $1,      0
        noise_cont    0,    $F,  $1,      0

        noise_cont    0,    $F,  $0,      0

sfx_landing:
        ; Length in rows
        .byte 7
        .byte PULSE_DLV, DUTY_2 | VOL | $8
        .byte PULSE_FREQ_LOW, <(380)
        .byte PULSE_FREQ_HIGH, >(380) | MAX_LENGTH
        .byte PULSE_SWEEP, S_ENABLE | S_PERIOD_0 | S_SHIFT_4
        .byte END_ROW | 0
        .byte PULSE_DLV, DUTY_2 | VOL | $4
        .byte END_ROW | 0
        .byte PULSE_DLV, DUTY_2 | VOL | $2
        .byte END_ROW | 0
        .byte PULSE_DLV, DUTY_2 | VOL | $6
        .byte PULSE_FREQ_LOW, <(284)
        .byte PULSE_FREQ_HIGH, >(284) | MAX_LENGTH
        .byte PULSE_SWEEP, S_ENABLE | S_PERIOD_0 | S_SHIFT_5 | S_NEG
        .byte END_ROW | 0
        .byte PULSE_DLV, DUTY_2 | VOL | $3
        .byte END_ROW | 0
        .byte PULSE_DLV, DUTY_2 | VOL | $1
        .byte END_ROW | 0
        .byte PULSE_DLV, DUTY_2 | VOL | $1
        .byte END_ROW | 0

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
        ;.byte PULSE_DLV, DUTY_2 | DECAY | $2
        ;.byte END_ROW | 5

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

        .segment "DPCM_1"

orchestra_hit_sample: ; orchestra_hit
        .byte $55, $09, $98, $FE, $FD, $FF, $3F, $C0, $03, $00, $00, $C0, $F3, $C0, $FF, $FF, $7F, $00, $84, $1F
        .byte $38, $FC, $FF, $01, $00, $1E, $00, $00, $FC, $FF, $EC, $FF, $E3, $F1, $03, $FF, $01, $C0, $A1, $EF
        .byte $8B, $03, $7E, $00, $70, $C0, $C0, $01, $FF, $01, $D8, $9F, $03, $FE, $FF, $3F, $3C, $FF, $9F, $78
        .byte $FE, $3F, $0E, $FC, $5E, $80, $72, $68, $00, $00, $07, $08, $20, $E0, $00, $08, $EA, $9F, $83, $F8
        .byte $FF, $30, $E0, $3F, $4C, $38, $7C, $C0, $FF, $83, $F4, $1F, $FF, $FF, $C7, $FF, $F9, $81, $07, $FE
        .byte $38, $00, $1E, $18, $60, $F9, $13, $A0, $F6, $C0, $01, $D0, $1F, $1C, $84, $FF, $CF, $FD, $25, $1C
        .byte $87, $BE, $D8, $F7, $07, $9E, $E3, $29, $FC, $3C, $00, $3F, $00, $C0, $7F, $18, $F0, $03, $88, $1F
        .byte $07, $3C, $87, $01, $D8, $17, $78, $F0, $1F, $FE, $3F, $78, $1C, $7F, $10, $D0, $F7, $1D, $88, $FF
        .byte $8F, $83, $0E, $1C, $30, $E0, $87, $11, $38, $FC, $07, $A0, $87, $0F, $FD, $F1, $03, $8F, $F7, $20
        .byte $FE, $3F, $90, $C5, $FF, $00, $FE, $1E, $C0, $FF, $01, $60, $7F, $01, $C0, $7F, $98, $F0, $3F, $A0
        .byte $57, $FF, $15, $D8, $03, $C7, $F1, $87, $FE, $1D, $20, $3C, $78, $40, $CF, $03, $C4, $E1, $00, $FC
        .byte $3F, $70, $68, $7F, $18, $CE, $43, $FA, $01, $87, $5F, $3B, $78, $00, $F0, $1F, $F0, $FF, $80, $03
        .byte $7F, $9E, $C2, $A3, $FF, $01, $1A, $F0, $5C, $3F, $1C, $D0, $0E, $38, $1E, $C8, $03, $37, $F6, $07
        .byte $0E, $FC, $C0, $1F, $6F, $E1, $C7, $9F, $7F, $E0, $E7, $A1, $BC, $80, $1F, $78, $E0, $D7, $1E, $28
        .byte $E1, $3F, $30, $78, $F5, $E3, $F1, $1F, $80, $FF, $00, $00, $1C, $0E, $02, $80, $67, $0F, $46, $C4
        .byte $E7, $38, $F0, $3C, $1E, $FD, $21, $FC, $F1, $03, $87, $FF, $85, $0F, $DF, $7E, $00, $1E, $FC, $83
        .byte $07, $0E, $FD, $07, $1D, $FB, $61, $D0, $FF, $F8, $F1, $1F, $70, $EC, $85, $1D, $C0, $E3, $85, $71
        .byte $C0, $1E, $00, $4B, $FD, $0F, $18, $FE, $0B, $C0, $3F, $D0, $1F, $C3, $F1, $C0, $5F, $F8, $81, $03
        .byte $7F, $00, $C4, $4B, $30, $F0, $DD, $7F, $00, $F0, $17, $38, $A0, $C7, $5F, $70, $80, $3F, $FE, $C3
        .byte $8C, $E7, $3F, $00, $3E, $1C, $F0, $F0, $2F, $FC, $07, $82, $EF, $7B, $50, $BD, $1D, $38, $F0, $FF
        .byte $9E, $3A, $E1, $07, $76, $C0, $81, $17, $F8, $41, $0F, $1C, $3B, $F4, $07, $F6, $03, $80, $FF, $CE
        .byte $03, $7E, $07, $10, $88, $0F, $78, $60, $BA, $72, $DC, $03, $7F, $3C, $DA, $03, $3F, $F0, $DC, $01
        .byte $3D, $F4, $43, $FF, $B7, $F0, $01, $F8, $FE, $3F, $61, $1C, $0E, $00, $F8, $1F, $80, $E3, $0F, $0C
        .byte $FF, $81, $07, $F4, $03, $F0, $1F, $04, $E0, $FF, $03, $FA, $1F, $C0, $1F, $38, $80, $FF, $0F, $BC
        .byte $D0, $03, $FE, $DD, $C0, $1F, $FC, $E1, $E7, $0F, $B8, $F0, $03, $3E, $F0, $C0, $03, $3F, $80, $FF
        .byte $0F, $18, $F0, $03, $0E, $FC, $C0, $0B, $3F, $E0, $F8, $0F, $3C, $A0, $03, $0F, $FD, $80, $EA, $3F
        .byte $7C, $C0, $FF, $3F, $60, $54, $8F, $AF, $78, $C0, $FF, $01, $FB, $E1, $1F, $00, $FC, $81, $17, $F0
        .byte $C3, $3F, $14, $D0, $E1, $07, $F0, $FD, $01, $1D, $7B, $40, $FF, $03, $F0, $5E, $00, $F0, $7F, $E1
        .byte $1F, $00, $F8, $07, $18, $F8, $E3, $07, $FC, $7F, $80, $FF, $0F, $90, $FF, $03, $7E, $FE, $00, $E5
        .byte $1F, $E0, $37, $0E, $D8, $A0, $03, $80, $F7, $80, $6F, $27, $E8, $C0, $1F, $00, $F4, $07, $8E, $FD
        .byte $B0, $03, $7F, $E0, $D0, $0B, $1A, $F5, $1F, $A0, $FD, $F1, $17, $FE, $1F, $C0, $03, $1F, $FD, $27
        .byte $A0, $3F, $F0, $03, $FE, $13, $F0, $03, $07, $FC, $FC, $01, $3F, $F0, $FC, $81, $1F, $F0, $03, $80
        .byte $0F, $F8, $E1, $2F, $74, $3C, $A1, $3F, $F0, $02, $85, $1F, $FA, $03, $07, $F4, $F8, $81, $3F, $F0
        .byte $EB, $81, $3F, $FA, $03, $80, $FE, $7D, $01, $3F, $F4, $A2, $00, $1F, $7A, $00, $80, $BE, $3F, $E0
        .byte $07, $FC, $3D, $80, $1F, $FE, $E2, $80, $1F, $3F, $E0, $FF, $0F, $78, $01, $65, $7F, $E0, $80, $17
        .byte $7E, $FC, $80, $0F, $7D, $E0, $C2, $0F, $FD, $D1, $47, $2F, $FC, $C0, $0F, $3F, $E0, $C2, $4F, $1C
        .byte $E0, $03, $0E, $E8, $80, $00, $FF, $F1, $C0, $1F, $3C, $F0, $17, $0F, $FC, $81, $43, $FF, $3E, $80
        .byte $7E, $00, $F0, $DF, $0F, $F8, $01, $40, $FF, $DF, $C0, $FF, $21, $F0, $FF, $0B, $FC, $8F, $43, $87
        .byte $9F, $00, $FC, $04, $00, $FD, $0B, $C0, $0B, $C0, $85, $FF, $80, $FE, $07, $00, $FF, $03, $FC, $BF
        .byte $EC, $C1, $3F, $C0, $3F, $00, $E4, $DB, $81, $3F, $F0, $FF, $01, $F8, $7B, $7C, $07, $8C, $D0, $01
        .byte $3F, $E0, $EF, $0E, $F8, $71, $00, $7E, $C1, $24, $FA, $07, $00, $3F, $00, $82, $FF, $C2, $F0, $3F
        .byte $FA, $E0, $0F, $FC, $FF, $01, $03, $70, $C0, $C1, $17, $FA, $FD, $07, $FE, $2F, $E0, $07, $B8, $FF
        .byte $E1, $1F, $5E, $FC, $80, $03, $FA, $01, $00, $01, $FF, $81, $07, $F0, $E3, $A0, $BF, $20, $E0, $3F
        .byte $00, $FF, $0B, $FF, $7F, $00, $F0, $E7, $3F, $FC, $80, $03, $7F, $E0, $07, $0C, $38, $F0, $1F, $0E
        .byte $E8, $80, $1F, $7A, $F0, $FF, $7F, $38, $A0, $C7, $1F, $F8, $81, $43, $FF, $69, $80, $1E, $23, $A0
        .byte $C7, $0E, $B8, $F0, $03, $7F, $E0, $C7, $9F, $3F, $20, $E2, $5F, $C0, $80, $07, $F8, $9F, $80, $F6
        .byte $37, $E0, $FF, $0B, $F8, $03, $00, $FE, $3D, $F0, $3F, $3F, $00, $C5, $FF, $83, $A0, $00, $F4, $1F
        .byte $00, $FC, $3F, $00, $FF, $53, $06, $FC, $00, $A0, $3F, $F8, $FD, $FF, $03, $F0, $F3, $07, $FE, $00
        .byte $70, $1D, $00, $FC, $3F, $80, $7E, $F1, $58, $FD, $15, $88, $FF, $0F, $F8, $7F, $00, $F0, $1F, $00
        .byte $FC, $00, $E4, $7F, $00, $D8, $7F, $00, $F0, $07, $C0, $E3, $07, $FC, $FF, $0F, $FD, $7E, $00, $F0
        .byte $87, $F0, $EF, $01, $40, $7F, $01, $C0, $FF, $00, $F0, $FF, $81, $5F, $01, $50, $FF, $1F, $DB, $FF
        .byte $E0, $F0, $EF, $69, $16, $05, $00, $F0, $1F, $C0, $F9, $04, $40, $FD, $0F, $A8, $80, $03, $FF, $1F
        .byte $D0, $FF, $23, $A1, $FD, $2F, $FD, $4B, $00, $F0, $FF, $00, $FE, $07, $00, $F8, $0F, $50, $01, $D0
        .byte $FF, $3F, $00, $FC, $2F, $50, $FB, $1F, $50, $59, $C0, $8F, $FF, $01, $FC, $01, $E0, $C7, $0F, $C0
        .byte $0F, $F8, $7F, $E0, $0F, $FC, $81, $9F, $C0, $FF, $84, $00, $FF, $0F, $F8, $0F, $3C, $00, $10, $87
        .byte $FF, $D5, $00, $FE, $7E, $C0, $5F, $38, $FC, $17, $0F, $FC, $C0, $17, $00, $FE, $C0, $1F, $00, $36
        .byte $02, $BC, $BF, $00, $60, $7F, $C1, $FB, $8F, $07, $FE, $C2, $D7, $07, $F0, $E3, $07, $E0, $C0, $5F
        .byte $7F, $7E, $C0, $FF, $E1, $43, $E8, $05, $7D, $78, $01, $CF, $5F, $C0, $E1, $03, $50, $E0, $07, $BC
        .byte $FA, $FF, $04, $C0, $D3, $01, $00, $70, $EC, $A1, $3F, $FE, $FC, $DB, $01, $3F, $21, $57, $61, $C0
        .byte $FF, $1F, $00, $FD, $07, $E0, $2F, $E1, $3C, $00, $FF, $0D, $40, $89, $FF, $FF, $F7, $07, $FC, $C0
        .byte $00, $0F, $F1, $FD, $01, $FD, $21, $E0, $0F, $10, $F8, $01, $FF, $03, $78, $01, $3F, $F0, $9F, $84
        .byte $FF, $21, $C0, $7F, $E0, $3B, $00, $7F, $1E, $FD, $07, $03, $F0, $E3, $C5, $E3, $3F, $00, $FD, $7F
        .byte $10, $F3, $03, $07, $00, $80, $03, $3F, $80, $FF, $FF, $3F, $70, $E8, $81, $15, $C0, $C3, $3F, $60
        .byte $F8, $DF, $02, $FE, $07, $4F, $BD, $70, $C0, $3F, $80, $DF, $FF, $07, $FC, $00, $C2, $2D, $2A, $C0
        .byte $7F, $03, $D0, $FF, $80, $FE, $07, $40, $F8, $4F, $E0, $8F, $FF, $F0, $FF, $04, $C0, $30, $00, $F8
        .byte $0B, $E0, $FF, $03, $84, $FD, $80, $FF, $2F, $00, $C0, $9F, $2F, $F1, $07, $FA, $FC, $07, $E3, $7F
        .byte $00, $D7, $0F, $00, $FE, $07, $80, $FF, $81, $EB, $FF, $03, $F0, $81, $27, $FC, $00, $A0, $FF, $A1
        .byte $E7, $2F, $00, $78, $C0, $40, $FF, $07, $A0, $FF, $F0, $FF, $5F, $00, $30, $80, $DA, $0F, $00, $F0
        .byte $3F, $FC, $FF, $01, $00, $FE, $E0, $3B, $E0, $07, $F4, $C7, $F7, $1B, $7F, $00, $7F, $E0, $FF, $63
        .byte $07, $F0, $1F, $F1, $16, $00, $E8, $0F, $00, $FE, $02, $3F, $FF, $80, $FF, $07, $00, $F8, $01, $00
        .byte $7F, $E0, $0F, $FC, $FA, $FF, $05, $5C, $C0, $03, $3C, $7E, $E0, $0F, $EC, $F8, $F6, $07, $70, $3F
        .byte $F8, $C2, $7E, $C0, $A1, $03, $7A, $E0, $0F, $1C, $F8, $0B, $00, $7E, $E0, $0F, $BC, $F8, $FC, $3F
        .byte $00, $FF, $03, $80, $FF, $02, $C8, $FD, $07, $FC, $1F, $00, $7F, $EC, $00, $FE, $03, $F0, $07, $0F
        .byte $FC, $7F, $40, $FF, $E6, $C4, $F7, $00, $F4, $73, $01, $FD, $0F, $40, $07, $F0, $04, $FC, $05, $E0
        .byte $E4, $89, $FF, $7F, $C0, $01, $FC, $00, $23, $05, $FE, $07, $A0, $FF, $FE, $FC, $00, $FC, $7D, $62
        .byte $05, $1E, $D7, $61, $27, $F6, $3B, $F0, $FF, $81, $FF, $01, $BC, $10, $80, $3F, $20, $3D, $8C, $3D
        .byte $F0, $1F, $00, $FD, $C0, $9F, $1B, $B0, $D3, $49, $D1, $8B, $13, $80, $FF, $00, $FD, $27, $02, $FF
        .byte $0B, $D0, $FF, $1F, $00, $A8, $D0, $1F, $20, $41, $FF, $0F, $DD, $F7, $17, $F0, $FF, $A1, $7F, $01
        .byte $E0, $2F, $02, $C0, $FF, $02, $00, $10, $F4, $FF, $07, $00, $FF, $03, $F0, $FF, $84, $0D, $1F, $01
        .byte $FF, $07, $EC, $FC, $09, $F0, $7F, $2F, $44, $C4, $81, $FF, $01, $EE, $8F, $BF, $80, $1F, $AA, $1F
        .byte $D8, $91, $2F, $90, $07, $D4, $07, $E0, $2F, $3B, $12, $1E, $A9, $3F, $FE, $E3, $01, $FD, $00, $68
        .byte $D5, $14, $C0, $FF, $C4, $B2, $DA, $00, $F0, $0F, $F8, $DF, $1F, $00, $EC, $80, $FE, $D8, $01, $FF
        .byte $05, $E0, $FF, $95, $F8, $FF, $05, $EC, $1F, $01, $78, $00, $E0, $DF, $3F, $00, $FC, $05, $E0, $2F
        .byte $74, $CD, $09, $A8, $89, $FC, $FF, $FF, $17, $EC, $07, $00, $00, $80, $BF, $08, $FF, $FF, $BF, $00
        .byte $40, $27, $E8, $F8, $FF, $0F, $0A, $10, $00, $18, $FE, $FF, $5B, $ED, $87, $C3, $07, $FE, $07, $00
        .byte $E4, $9F, $07, $4C, $BD, $00, $C0, $C0, $83, $0F, $F4, $04, $5F, $3F, $8E, $FF, $CF, $A7, $FA, $FE
        .byte $0F, $60, $FC, $7F, $00, $F0, $FF, $01, $E0, $78, $02, $85, $4D, $38, $70, $C0, $01, $68, $81, $47
        .byte $47, $F1, $3F, $60, $D4, $F3, $50, $61, $F8, $B1, $FB, $07, $E9, $7F, $6D, $FF, $AB, $3F, $F1, $12
        .byte $0F, $F8, $25, $C0, $7B, $90, $B0, $E1, $37, $01, $FC, $81, $02, $A0, $1F, $78, $10, $DF, $1F, $FC
        .byte $16, $78, $1E, $3C, $97, $FF, $0F, $5C, $CF, $83, $F0, $97, $C0, $6E, $20, $A0, $E5, $81, $E2, $0E
        .byte $02, $5E, $1E, $F8, $1E, $22, $BC, $5F, $F1, $E0, $F1, $FC, $6F, $E8, $38, $FD, $20, $AC, $E3, $B3
        .byte $8A, $7E, $14, $0F, $1C, $58, $70, $20, $1D, $26, $E0, $F8, $0B, $E0, $0F, $2F, $79, $E3, $07, $FC
        .byte $E3, $43, $BA, $BE, $54, $85, $FF, $49, $F8, $2F, $E0, $F7, $01, $E0, $F7, $80, $8A, $3F, $C0, $D2
        .byte $6B, $50, $27, $FD, $28, $B4, $23, $4D, $E3, $0E, $FF, $38, $C2, $78, $E8, $81, $1F, $87, $86, $87
        .byte $01, $F8, $5F, $E0, $74, $EA, $30, $1C, $87, $E6, $07, $9C, $7B, $71, $EA, $31, $E2, $75, $E8, $DF
        .byte $02, $0F, $E7, $7D, $0A, $97, $FE, $03, $B8, $E0, $A1, $AE, $78, $40, $1B, $D2, $3C, $A0, $07, $4E
        .byte $F2, $0B, $0C, $7F, $60, $3F, $8E, $C2, $AF, $17, $FE, $C2, $8B, $A7, $7A, $40, $7F, $F0, $D0, $6B
        .byte $3B, $B8, $E0, $5F, $E0, $34, $6D, $C7, $43, $27, $0A, $DF, $01, $50, $35, $1C, $06, $83, $C7, $1D
        .byte $54, $96, $C7, $A1, $D8, $71, $78, $F5, $43, $F4, $E1, $83, $15, $FF, $89, $1D, $5E, $D6, $81, $3D
        .byte $F0, $13, $0F, $3C, $F8, $1F, $2A, $ED, $84, $53, $7F, $E1, $C7, $4F, $68, $B5, $0B, $2E, $B0, $C7
        .byte $89, $C7, $81, $3D, $20, $55, $F5, $13, $70, $FC, $25, $88, $3F, $61, $3F, $8C, $C7, $81, $3F, $F0
        .byte $43, $07, $FD, $10, $0A, $9F, $14, $DC, $8B, $3F, $80, $E9, $07, $EA, $C0, $8E, $3F, $E0, $C4, $5E
        .byte $3C, $87, $17, $CE, $AF, $00, $BD, $38, $E1, $D3, $4B, $7C, $0F, $52, $8F, $F3, $50, $65, $3B, $B4
        .byte $D0, $7F, $3C, $B2, $C2, $0F, $DC, $E0, $42, $2B, $E8, $85, $1F, $3A, $76, $D4, $07, $6E, $45, $01
        .byte $FF, $8E, $07, $FC, $2D, $60, $19, $5E, $58, $C9, $AA, $AA, $B1, $87, $BE, $70, $B2, $07, $76, $E0
        .byte $B3, $05, $76, $F8, $07, $ED, $C7, $E1, $05, $F1, $FA, $57, $C2, $72, $1C, $04, $EB, $2F, $50, $85
        .byte $1F, $1A, $FE, $03, $1E, $D8, $0B, $E0, $3F, $94, $C0, $FF, $07, $F8, $52, $81, $3F, $70, $60, $DF
        .byte $1D, $F0, $62, $07, $FC, $55, $A1, $3F, $F4, $C3, $8F, $1D, $F0, $C2, $07, $BE, $D0, $41, $07, $FE
        .byte $C0, $AE, $17, $74, $E0, $07, $1D, $F8, $43, $27, $7E, $C0, $B1, $3F, $70, $42, $0F, $1D, $F6, $41
        .byte $D5, $57, $78, $C1, $7F, $5E, $C0, $54, $1D, $C7, $F2, $80, $BF, $07, $F6, $C4, $4F, $80, $F5, $03
        .byte $1F, $E8, $85, $5F, $38, $E0, $C3, $1F, $D0, $F5, $02, $3E, $F5, $80, $FD, $05, $E0, $3F, $01, $F8
        .byte $3F, $C2, $5F, $40, $FA, $07, $30, $EC, $87, $0F, $F8, $7F, $00, $7E, $2B, $70, $FD, $05, $FE, $B1
        .byte $01, $A7, $76, $E0, $9B, $2C, $F0, $C3, $0E, $60, $D7, $40, $6F, $55, $D8, $03, $BB, $08, $FC, $07
        .byte $3C, $FA, $C0, $0F, $FC, $C0, $A3, $27, $74, $FA, $0F, $E0, $F6, $C2, $0F, $BC, $3B, $60, $07, $7E
        .byte $DC, $8B, $50, $7F, $E0, $07, $7C, $25, $E0, $87, $0E, $FA, $F2, $03, $7E, $C0, $BB, $11, $5F, $E0
        .byte $07, $50, $1F, $F4, $87, $1E, $F8, $F1, $42, $7F, $E0, $81, $12, $1F, $FC, $07, $0E, $F8, $F1, $82
        .byte $7E, $E8, $B1, $13, $7B, $F4, $05, $04, $FF, $E1, $80, $7E, $F8, $41, $03, $7E, $EC, $00, $D1, $79
        .byte $77, $C4, $1F, $E8, $3A, $42, $5F, $FC, $A0, $21, $3F, $BC, $C0, $9F, $2F, $F0, $02, $AE, $BD, $D0
        .byte $02, $1F, $FE, $D0, $03, $2F, $F6, $C0, $8D, $3F, $F0, $43, $0F, $BD, $F0, $03, $2F, $3E, $C0, $0F
        .byte $3F, $34, $C0, $0F, $3C, $F0, $03, $26, $FE, $C4, $81, $3F, $79, $F0, $0F, $1C, $F0, $03, $4F, $7D
        .byte $7A, $01, $3F, $11, $F4, $AB, $1D, $F0, $13, $62, $7D, $3B, $01, $FF, $49, $D4, $FE, $11, $F8, $1B
        .byte $85, $2D, $57, $01, $FB, $01, $D8, $F2, $07, $B0, $27, $A4, $93, $7F, $01, $FE, $0E, $C0, $FE, $03
        .byte $F4, $55, $D5, $43, $7F, $40, $3F, $10, $F8, $56, $07, $3E, $6A, $BB, $01, $FE, $E9, $F0, $0E, $78
        .byte $70, $23, $77, $C0, $9F, $1D, $F0, $E3, $20, $F6, $44, $55, $D9, $0E, $04, $FE, $20, $0E, $FD, $81
        .byte $E3, $5F, $F0, $C1, $1F, $78, $FF, $00, $4E, $E2, $81, $13, $4F, $EC, $D7, $4A, $D5, $B6, $D0, $0B
        .byte $D5, $BA, $E1, $4E, $9C, $D5, $42, $27, $7C, $A2, $54, $12, $F7, $04, $4F, $EC, $CC, $C2, $37, $52
        .byte $E8, $8F, $50, $FF, $20, $5E, $BD, $50, $E5, $C3, $9E, $D8, $41, $27, $7E, $D0, $0B, $3C, $74, $F0
        .byte $47, $1C, $F8, $41, $2F, $F5, $D0, $55, $3F, $70, $D0, $0F, $1F, $F8, $03, $47, $FD, $A8, $90, $3B
        .byte $16, $F0, $4B, $8D, $72, $71, $A3, $6D, $D4, $4A, $97, $56, $E4, $52, $8F, $58, $55, $55, $6C, $2B
        .byte $89, $6B, $55, $D4, $55, $13, $57, $53, $C4, $5D, $55, $71, $2B, $9D, $D0, $55, $AB, $46, $55, $45
        .byte $6D, $4B, $51, $79, $55, $29, $5E, $55, $95, $5A, $49, $55, $57, $6C, $D5, $1D, $29, $B5, $A3, $4D
        .byte $DC, $90, $55, $55, $96, $DA, $95, $A8, $55, $55, $55, $D5, $49, $55, $B5, $2A, $D5, $6A, $2A, $D5
        .byte $2A, $55, $55, $95, $55, $55, $95, $5A, $AD, $A8, $6A, $55, $AA, $A6, $99, $9A, $55, $55, $55, $AD
        .byte $54, $55, $55, $55, $55, $55, $5A, $55, $95, $A6, $AD, $A8, $6A, $55, $55, $55, $95, $5A, $56, $55
        .byte $55, $AD, $54, $D5, $CA, $AA, $AA, $4C, $55, $55, $2B, $55, $55, $55, $95, $5A, $95, $5A, $A9, $A5
        .byte $6A, $55, $55, $55, $55, $55, $55, $D3, $54, $AB, $54, $55, $4B, $55, $55, $4D, $55, $55, $55, $55
        .byte $55, $59, $55, $55, $55, $DA, $54, $55, $55, $53, $55, $55, $55, $55, $B5, $52, $55, $55, $55, $55
        .byte $55, $69, $55, $55, $55, $55, $55, $35, $55, $55, $55, $55, $55, $55, $55, $55, $55, $55, $55, $55
        .byte $55, $55, $55, $55, $55, $55, $55, $69, $4D, $55, $55, $55, $55, $55, $55, $55, $55, $55, $55, $55
        .byte $55, $55, $55, $55, $55, $55, $55, $55, $55, $55, $55, $55, $D5, $54, $55, $55, $55, $55, $55, $55
        .byte $4D, $55, $55, $55, $55, $5A, $55, $55, $55, $55, $55, $55, $55, $55, $53, $4B, $55

        .align 64
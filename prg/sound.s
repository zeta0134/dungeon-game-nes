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
        ;.include "../art/music/depths.asm"

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

.include "sfx.incs"
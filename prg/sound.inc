.global init_audio
.global update_audio
.global play_track
.global play_sfx_pulse1
.global play_sfx_pulse2
.global play_sfx_triangle
.global play_sfx_noise
.global play_sfx_dpcm

.global sfx_jump
.global sfx_double_jump
.global sfx_bounce
.global sfx_teleport
.global sfx_weak_hit
.global orchestra_hit_sample

.macro play_dpcm sample_addr, length
.scope
SampleAddr := R0
SampleLength := R1
SampleRate := R2
SampleBank := R3
SfxFrames := R4
        lda #<((sample_addr  - $C000) >> 6)
        sta SampleAddr
        lda #<(.bank(sample_addr))
        sta SampleBank

        lda #((length - 1) / 16)
        sta SampleLength
        lda #(length / 69)
        sta SfxFrames

        ; for now, all triggered dpcm SFX are at the max rate
        lda #$0F
        sta SampleRate
        jsr play_sfx_dpcm
.endscope
.endmacro
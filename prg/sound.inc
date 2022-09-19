.global init_audio
.global update_audio
.global play_track
.global play_variant
.global fade_to_track
.global play_sfx_pulse1
.global play_sfx_pulse2
.global play_sfx_triangle
.global play_sfx_noise
.global play_sfx_dpcm

.global sfx_jump
.global sfx_double_jump
.global sfx_bounce
.global sfx_teleport
.global sfx_weak_hit_pulse
.global sfx_weak_hit_tri
.global sfx_weak_hit_noise
.global sfx_error_buzz
.global sfx_dash_pulse, sfx_dash_noise
.global sfx_landing
.global sfx_dive_underwater_pulse, sfx_dive_underwater_noise

.global sfx_mortal_blow_noise
.global sfx_death_spin_pulse
.global sfx_death_spin_tri
.global sfx_death_splat_noise

.global sfx_dialog_ae_low_variant_1
.global sfx_dialog_ae_low_variant_2
.global sfx_dialog_ae_low_variant_3
.global sfx_dialog_ae_low_variant_4
.global sfx_dialog_iy_low_variant_1
.global sfx_dialog_iy_low_variant_2
.global sfx_dialog_iy_low_variant_3
.global sfx_dialog_iy_low_variant_4
.global sfx_dialog_ou_low_variant_1
.global sfx_dialog_ou_low_variant_2
.global sfx_dialog_ou_low_variant_3
.global sfx_dialog_ou_low_variant_4

.global sfx_dialog_ae_mid_variant_1
.global sfx_dialog_ae_mid_variant_2
.global sfx_dialog_ae_mid_variant_3
.global sfx_dialog_ae_mid_variant_4
.global sfx_dialog_iy_mid_variant_1
.global sfx_dialog_iy_mid_variant_2
.global sfx_dialog_iy_mid_variant_3
.global sfx_dialog_iy_mid_variant_4
.global sfx_dialog_ou_mid_variant_1
.global sfx_dialog_ou_mid_variant_2
.global sfx_dialog_ou_mid_variant_3
.global sfx_dialog_ou_mid_variant_4

.global sfx_splash

.global sfx_open_subscreen_pulse1
.global sfx_open_subscreen_pulse2
.global sfx_close_subscreen_pulse1
.global sfx_close_subscreen_pulse2
.global sfx_move_cursor
.global sfx_select_ability
.global sfx_equip_ability_pulse1
.global sfx_equip_ability_pulse2

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
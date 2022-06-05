        .setcpu "6502"
        .include "bhop/bhop.inc"
        .include "far_call.inc"
        .include "mmc3.inc"
        .include "sound.inc"

        .segment "MUSIC_A000"

.export bhop_music_data
bhop_music_data:
        .include "../art/music/calm.asm"

.segment "PRGFIXED_8000"

.proc update_audio
        access_data_bank #<.bank(bhop_music_data)
        jsr bhop_play
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
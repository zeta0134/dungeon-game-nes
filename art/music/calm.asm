; Dn-FamiTracker exported music data: calm.0cc
;

; Module header
	.word ft_song_list
	.word ft_instrument_list
	.word ft_sample_list
	.word ft_samples
	.word ft_groove_list
	.byte 0 ; flags
	.word 3600 ; NTSC speed
	.word 3000 ; PAL speed

; Instrument pointer list
ft_instrument_list:
	.word ft_inst_0
	.word ft_inst_1

; Instruments
ft_inst_0:
	.byte 0
	.byte $11
	.word ft_seq_2a03_0
	.word ft_seq_2a03_4

ft_inst_1:
	.byte 0
	.byte $11
	.word ft_seq_2a03_5
	.word ft_seq_2a03_4

; Sequences
ft_seq_2a03_0:
	.byte $11, $FF, $00, $00, $0D, $0C, $0B, $0A, $0A, $08, $08, $07, $06, $05, $04, $03, $03, $03, $02, $01
	.byte $01
ft_seq_2a03_4:
	.byte $01, $FF, $00, $00, $01
ft_seq_2a03_5:
	.byte $11, $FF, $00, $00, $01, $02, $02, $03, $03, $03, $03, $02, $02, $02, $02, $01, $01, $01, $01, $01
	.byte $00

; DPCM instrument list (pitch, sample index)
ft_sample_list:

; DPCM samples list (location, size, bank)
ft_samples:


; Groove list
ft_groove_list:
	.byte $00
; Grooves (size, terms)

; Song pointer list
ft_song_list:
	.word ft_song_0

; Song info
ft_song_0:
	.word ft_s0_frames
	.byte 1	; frame count
	.byte 128	; pattern length
	.byte 3	; speed
	.byte 110	; tempo
	.byte 0	; groove position
	.byte 0	; initial bank


;
; Pattern and frame data for all songs below
;

; Bank 0
ft_s0_frames:
	.word ft_s0f0
ft_s0f0:
	.word ft_s0p0c0, ft_s0p0c1, ft_s0p0c2, ft_s0p0c2, ft_s0p0c2
; Bank 0
ft_s0p0c0:
	.byte $82, $03, $E0, $FF, $1A, $FA, $21, $F8, $20, $FD, $1C, $FA, $21, $F8, $20, $F7, $1C, $FA, $21, $FF
	.byte $1A, $FA, $21, $F8, $20, $FD, $1C, $FA, $21, $F8, $20, $F7, $1C, $FA, $21, $FF, $19, $FA, $21, $F8
	.byte $20, $FD, $1C, $FA, $23, $F8, $21, $FD, $1C, $F9, $25, $FB, $19, $FA, $21, $F8, $20, $FD, $19, $FA
	.byte $23, $83, $F8, $21, $00, $F6, $23, $00, $F5, $21, $01, $F9, $20, $03, $FA, $1C, $03

; Bank 0
ft_s0p0c1:
	.byte $00, $05, $82, $03, $E1, $FF, $1A, $FA, $21, $F8, $20, $FD, $1C, $FA, $21, $F8, $20, $F7, $1C, $FA
	.byte $21, $FF, $1A, $FA, $21, $F8, $20, $FD, $1C, $FA, $21, $F8, $20, $F7, $1C, $FA, $21, $FF, $19, $FA
	.byte $21, $F8, $20, $FD, $1C, $FA, $23, $F8, $21, $FD, $1C, $F9, $25, $FB, $19, $FA, $21, $F8, $20, $FD
	.byte $19, $FA, $23, $83, $F8, $21, $00, $F6, $23, $00, $F5, $21, $01, $F9, $20, $01

; Bank 0
ft_s0p0c2:
	.byte $00, $7F


; DPCM samples (located at DPCM segment)

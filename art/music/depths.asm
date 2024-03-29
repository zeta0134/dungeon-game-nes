; Dn-FamiTracker exported music data: depths_repitched.dnm
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
	.word ft_inst_2
	.word ft_inst_3
	.word ft_inst_4
	.word ft_inst_5
	.word ft_inst_6
	.word ft_inst_7
	.word ft_inst_8
	.word ft_inst_9
	.word ft_inst_10

; Instruments
ft_inst_0:
	.byte 0
	.byte $00

ft_inst_1:
	.byte 0
	.byte $00

ft_inst_2:
	.byte 0
	.byte $11
	.word ft_seq_2a03_0
	.word ft_seq_2a03_4

ft_inst_3:
	.byte 0
	.byte $00

ft_inst_4:
	.byte 0
	.byte $13
	.word ft_seq_2a03_20
	.word ft_seq_2a03_16
	.word ft_seq_2a03_14

ft_inst_5:
	.byte 0
	.byte $11
	.word ft_seq_2a03_25
	.word ft_seq_2a03_19

ft_inst_6:
	.byte 0
	.byte $13
	.word ft_seq_2a03_15
	.word ft_seq_2a03_11
	.word ft_seq_2a03_9

ft_inst_7:
	.byte 0
	.byte $11
	.word ft_seq_2a03_30
	.word ft_seq_2a03_24

ft_inst_8:
	.byte 0
	.byte $11
	.word ft_seq_2a03_40
	.word ft_seq_2a03_29

ft_inst_9:
	.byte 0
	.byte $11
	.word ft_seq_2a03_40
	.word ft_seq_2a03_19

ft_inst_10:
	.byte 0
	.byte $15
	.word ft_seq_2a03_50
	.word ft_seq_2a03_2
	.word ft_seq_2a03_49

; Sequences
ft_seq_2a03_0:
	.byte $0D, $FF, $07, $00, $0A, $0B, $0C, $0E, $0C, $0B, $0A, $02, $01, $01, $01, $00, $00
ft_seq_2a03_2:
	.byte $04, $FF, $00, $01, $FC, $FE, $FF, $00
ft_seq_2a03_4:
	.byte $02, $FF, $00, $00, $01, $01
ft_seq_2a03_9:
	.byte $01, $FF, $00, $00, $00
ft_seq_2a03_11:
	.byte $04, $03, $00, $01, $0B, $0C, $0D, $0C
ft_seq_2a03_14:
	.byte $01, $FF, $00, $00, $00
ft_seq_2a03_15:
	.byte $18, $FF, $00, $00, $0A, $0A, $0A, $0A, $09, $08, $07, $06, $05, $05, $05, $04, $04, $04, $04, $03
	.byte $03, $02, $01, $01, $01, $01, $00, $00
ft_seq_2a03_16:
	.byte $04, $03, $00, $01, $0B, $0C, $0D, $0E
ft_seq_2a03_19:
	.byte $02, $01, $00, $00, $02, $02
ft_seq_2a03_20:
	.byte $0A, $FF, $00, $00, $0D, $0A, $07, $00, $00, $00, $00, $00, $00, $00
ft_seq_2a03_24:
	.byte $02, $FF, $00, $00, $01, $01
ft_seq_2a03_25:
	.byte $2C, $FF, $24, $00, $0A, $0D, $0E, $0E, $0F, $0F, $0F, $0F, $0E, $0E, $0E, $0E, $0D, $0D, $0D, $0C
	.byte $0C, $0C, $0B, $0B, $0B, $0B, $0A, $0A, $0A, $09, $09, $08, $08, $08, $07, $07, $07, $06, $06, $06
	.byte $02, $02, $02, $01, $01, $01, $01, $00
ft_seq_2a03_29:
	.byte $01, $FF, $00, $00, $01
ft_seq_2a03_30:
	.byte $26, $FF, $1D, $00, $0F, $0F, $0F, $0F, $0E, $0E, $0D, $0C, $0C, $0B, $0B, $0A, $09, $09, $08, $08
	.byte $08, $07, $07, $06, $06, $06, $05, $05, $04, $04, $04, $03, $03, $02, $02, $02, $02, $01, $01, $01
	.byte $01, $00
ft_seq_2a03_40:
	.byte $0B, $FF, $03, $00, $06, $06, $06, $02, $02, $02, $01, $01, $01, $01, $00
ft_seq_2a03_49:
	.byte $01, $FF, $00, $00, $02
ft_seq_2a03_50:
	.byte $0F, $FF, $00, $00, $06, $07, $0A, $0B, $0B, $0A, $08, $06, $04, $03, $02, $01, $01, $01, $00

; DPCM instrument list (pitch, sample index)
ft_sample_list:
	.byte 201, 255, 0
	.byte 202, 255, 3
	.byte 202, 255, 0
	.byte 203, 255, 0
	.byte 203, 255, 6
	.byte 204, 255, 0
	.byte 204, 255, 9
	.byte 205, 255, 3
	.byte 205, 255, 6
	.byte 206, 255, 3
	.byte 206, 255, 0
	.byte 193, 255, 12
	.byte 194, 255, 15
	.byte 195, 255, 15
	.byte 196, 255, 15
	.byte 196, 255, 12
	.byte 197, 255, 12
	.byte 199, 255, 15
	.byte 199, 255, 12
	.byte 200, 255, 12
	.byte 200, 255, 18
	.byte 201, 255, 15

; DPCM samples list (location, size, bank)
ft_samples:
  .byte <((ft_sample_0  - $C000) >> 6),   7, <.bank(ft_sample_0)
  .byte <((ft_sample_1  - $C000) >> 6),  28, <.bank(ft_sample_1)
  .byte <((ft_sample_2  - $C000) >> 6), 126, <.bank(ft_sample_2)
  .byte <((ft_sample_3  - $C000) >> 6),  12, <.bank(ft_sample_3)
  .byte <((ft_sample_4  - $C000) >> 6),  27, <.bank(ft_sample_4)
  .byte <((ft_sample_5  - $C000) >> 6),  87, <.bank(ft_sample_5)
  .byte <((ft_sample_6  - $C000) >> 6),  55, <.bank(ft_sample_6)

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
	.byte 66	; frame count
	.byte 32	; pattern length
	.byte 3	; speed
	.byte 150	; tempo
	.byte 0	; groove position
	.byte 0	; initial bank


;
; Pattern and frame data for all songs below
;

; Bank 0
ft_s0_frames:
	.word ft_s0f0
	.word ft_s0f1
	.word ft_s0f2
	.word ft_s0f3
	.word ft_s0f4
	.word ft_s0f5
	.word ft_s0f6
	.word ft_s0f7
	.word ft_s0f8
	.word ft_s0f9
	.word ft_s0f10
	.word ft_s0f11
	.word ft_s0f12
	.word ft_s0f13
	.word ft_s0f14
	.word ft_s0f15
	.word ft_s0f16
	.word ft_s0f17
	.word ft_s0f18
	.word ft_s0f19
	.word ft_s0f20
	.word ft_s0f21
	.word ft_s0f22
	.word ft_s0f23
	.word ft_s0f24
	.word ft_s0f25
	.word ft_s0f26
	.word ft_s0f27
	.word ft_s0f28
	.word ft_s0f29
	.word ft_s0f30
	.word ft_s0f31
	.word ft_s0f32
	.word ft_s0f33
	.word ft_s0f34
	.word ft_s0f35
	.word ft_s0f36
	.word ft_s0f37
	.word ft_s0f38
	.word ft_s0f39
	.word ft_s0f40
	.word ft_s0f41
	.word ft_s0f42
	.word ft_s0f43
	.word ft_s0f44
	.word ft_s0f45
	.word ft_s0f46
	.word ft_s0f47
	.word ft_s0f48
	.word ft_s0f49
	.word ft_s0f50
	.word ft_s0f51
	.word ft_s0f52
	.word ft_s0f53
	.word ft_s0f54
	.word ft_s0f55
	.word ft_s0f56
	.word ft_s0f57
	.word ft_s0f58
	.word ft_s0f59
	.word ft_s0f60
	.word ft_s0f61
	.word ft_s0f62
	.word ft_s0f63
	.word ft_s0f64
	.word ft_s0f65
ft_s0f0:
	.word ft_s0p0c0, ft_s0p0c0, ft_s0p0c0, ft_s0p0c3, ft_s0p0c4
ft_s0f1:
	.word ft_s0p0c0, ft_s0p1c1, ft_s0p0c0, ft_s0p1c3, ft_s0p1c4
ft_s0f2:
	.word ft_s0p2c0, ft_s0p2c1, ft_s0p2c2, ft_s0p2c3, ft_s0p2c4
ft_s0f3:
	.word ft_s0p3c0, ft_s0p3c1, ft_s0p3c2, ft_s0p2c3, ft_s0p3c4
ft_s0f4:
	.word ft_s0p4c0, ft_s0p4c1, ft_s0p4c2, ft_s0p2c3, ft_s0p2c4
ft_s0f5:
	.word ft_s0p5c0, ft_s0p5c1, ft_s0p5c2, ft_s0p2c3, ft_s0p3c4
ft_s0f6:
	.word ft_s0p6c0, ft_s0p6c1, ft_s0p6c2, ft_s0p2c3, ft_s0p6c4
ft_s0f7:
	.word ft_s0p7c0, ft_s0p7c1, ft_s0p7c2, ft_s0p2c3, ft_s0p7c4
ft_s0f8:
	.word ft_s0p8c0, ft_s0p8c1, ft_s0p8c2, ft_s0p2c3, ft_s0p2c4
ft_s0f9:
	.word ft_s0p9c0, ft_s0p9c1, ft_s0p9c2, ft_s0p2c3, ft_s0p3c4
ft_s0f10:
	.word ft_s0p10c0, ft_s0p10c1, ft_s0p2c2, ft_s0p2c3, ft_s0p2c4
ft_s0f11:
	.word ft_s0p11c0, ft_s0p11c1, ft_s0p3c2, ft_s0p2c3, ft_s0p3c4
ft_s0f12:
	.word ft_s0p12c0, ft_s0p12c1, ft_s0p4c2, ft_s0p2c3, ft_s0p2c4
ft_s0f13:
	.word ft_s0p13c0, ft_s0p13c1, ft_s0p5c2, ft_s0p2c3, ft_s0p3c4
ft_s0f14:
	.word ft_s0p14c0, ft_s0p14c1, ft_s0p6c2, ft_s0p2c3, ft_s0p6c4
ft_s0f15:
	.word ft_s0p15c0, ft_s0p15c1, ft_s0p7c2, ft_s0p2c3, ft_s0p7c4
ft_s0f16:
	.word ft_s0p16c0, ft_s0p16c1, ft_s0p8c2, ft_s0p2c3, ft_s0p2c4
ft_s0f17:
	.word ft_s0p17c0, ft_s0p17c1, ft_s0p9c2, ft_s0p2c3, ft_s0p3c4
ft_s0f18:
	.word ft_s0p18c0, ft_s0p18c1, ft_s0p2c2, ft_s0p2c3, ft_s0p2c4
ft_s0f19:
	.word ft_s0p19c0, ft_s0p19c1, ft_s0p3c2, ft_s0p2c3, ft_s0p3c4
ft_s0f20:
	.word ft_s0p20c0, ft_s0p20c1, ft_s0p4c2, ft_s0p2c3, ft_s0p2c4
ft_s0f21:
	.word ft_s0p21c0, ft_s0p21c1, ft_s0p5c2, ft_s0p2c3, ft_s0p3c4
ft_s0f22:
	.word ft_s0p22c0, ft_s0p22c1, ft_s0p6c2, ft_s0p2c3, ft_s0p6c4
ft_s0f23:
	.word ft_s0p23c0, ft_s0p23c1, ft_s0p7c2, ft_s0p2c3, ft_s0p7c4
ft_s0f24:
	.word ft_s0p24c0, ft_s0p24c1, ft_s0p8c2, ft_s0p2c3, ft_s0p2c4
ft_s0f25:
	.word ft_s0p17c0, ft_s0p25c1, ft_s0p9c2, ft_s0p2c3, ft_s0p3c4
ft_s0f26:
	.word ft_s0p18c0, ft_s0p26c1, ft_s0p2c2, ft_s0p2c3, ft_s0p2c4
ft_s0f27:
	.word ft_s0p27c0, ft_s0p27c1, ft_s0p3c2, ft_s0p2c3, ft_s0p3c4
ft_s0f28:
	.word ft_s0p20c0, ft_s0p28c1, ft_s0p4c2, ft_s0p2c3, ft_s0p2c4
ft_s0f29:
	.word ft_s0p29c0, ft_s0p29c1, ft_s0p5c2, ft_s0p2c3, ft_s0p3c4
ft_s0f30:
	.word ft_s0p30c0, ft_s0p30c1, ft_s0p6c2, ft_s0p2c3, ft_s0p6c4
ft_s0f31:
	.word ft_s0p31c0, ft_s0p31c1, ft_s0p7c2, ft_s0p2c3, ft_s0p7c4
ft_s0f32:
	.word ft_s0p32c0, ft_s0p32c1, ft_s0p8c2, ft_s0p2c3, ft_s0p2c4
ft_s0f33:
	.word ft_s0p33c0, ft_s0p9c1, ft_s0p9c2, ft_s0p2c3, ft_s0p3c4
ft_s0f34:
	.word ft_s0p34c0, ft_s0p58c1, ft_s0p34c2, ft_s0p34c2, ft_s0p34c4
ft_s0f35:
	.word ft_s0p34c0, ft_s0p59c1, ft_s0p0c0, ft_s0p0c0, ft_s0p34c4
ft_s0f36:
	.word ft_s0p36c0, ft_s0p60c1, ft_s0p0c0, ft_s0p0c0, ft_s0p36c4
ft_s0f37:
	.word ft_s0p36c0, ft_s0p61c1, ft_s0p0c0, ft_s0p0c0, ft_s0p36c4
ft_s0f38:
	.word ft_s0p38c0, ft_s0p62c1, ft_s0p0c0, ft_s0p0c0, ft_s0p38c4
ft_s0f39:
	.word ft_s0p38c0, ft_s0p63c1, ft_s0p0c0, ft_s0p0c0, ft_s0p38c4
ft_s0f40:
	.word ft_s0p40c0, ft_s0p64c1, ft_s0p0c0, ft_s0p0c0, ft_s0p40c4
ft_s0f41:
	.word ft_s0p40c0, ft_s0p57c1, ft_s0p0c0, ft_s0p0c0, ft_s0p40c4
ft_s0f42:
	.word ft_s0p34c0, ft_s0p34c1, ft_s0p34c2, ft_s0p34c2, ft_s0p34c4
ft_s0f43:
	.word ft_s0p34c0, ft_s0p35c1, ft_s0p0c0, ft_s0p0c0, ft_s0p34c4
ft_s0f44:
	.word ft_s0p36c0, ft_s0p36c1, ft_s0p34c2, ft_s0p34c2, ft_s0p36c4
ft_s0f45:
	.word ft_s0p36c0, ft_s0p37c1, ft_s0p0c0, ft_s0p0c0, ft_s0p36c4
ft_s0f46:
	.word ft_s0p38c0, ft_s0p38c1, ft_s0p34c2, ft_s0p34c2, ft_s0p38c4
ft_s0f47:
	.word ft_s0p38c0, ft_s0p39c1, ft_s0p0c0, ft_s0p0c0, ft_s0p38c4
ft_s0f48:
	.word ft_s0p40c0, ft_s0p40c1, ft_s0p34c2, ft_s0p34c2, ft_s0p40c4
ft_s0f49:
	.word ft_s0p40c0, ft_s0p41c1, ft_s0p0c0, ft_s0p0c0, ft_s0p40c4
ft_s0f50:
	.word ft_s0p34c0, ft_s0p42c1, ft_s0p34c2, ft_s0p34c2, ft_s0p34c4
ft_s0f51:
	.word ft_s0p34c0, ft_s0p43c1, ft_s0p0c0, ft_s0p0c0, ft_s0p34c4
ft_s0f52:
	.word ft_s0p36c0, ft_s0p44c1, ft_s0p34c2, ft_s0p34c2, ft_s0p36c4
ft_s0f53:
	.word ft_s0p36c0, ft_s0p45c1, ft_s0p0c0, ft_s0p0c0, ft_s0p36c4
ft_s0f54:
	.word ft_s0p38c0, ft_s0p46c1, ft_s0p34c2, ft_s0p34c2, ft_s0p38c4
ft_s0f55:
	.word ft_s0p38c0, ft_s0p47c1, ft_s0p0c0, ft_s0p0c0, ft_s0p38c4
ft_s0f56:
	.word ft_s0p40c0, ft_s0p48c1, ft_s0p34c2, ft_s0p34c2, ft_s0p40c4
ft_s0f57:
	.word ft_s0p40c0, ft_s0p49c1, ft_s0p0c0, ft_s0p0c0, ft_s0p40c4
ft_s0f58:
	.word ft_s0p34c0, ft_s0p50c1, ft_s0p34c2, ft_s0p34c2, ft_s0p34c4
ft_s0f59:
	.word ft_s0p34c0, ft_s0p51c1, ft_s0p0c0, ft_s0p0c0, ft_s0p34c4
ft_s0f60:
	.word ft_s0p36c0, ft_s0p52c1, ft_s0p34c2, ft_s0p34c2, ft_s0p36c4
ft_s0f61:
	.word ft_s0p53c0, ft_s0p53c1, ft_s0p0c0, ft_s0p0c0, ft_s0p36c4
ft_s0f62:
	.word ft_s0p38c0, ft_s0p54c1, ft_s0p34c2, ft_s0p34c2, ft_s0p38c4
ft_s0f63:
	.word ft_s0p38c0, ft_s0p55c1, ft_s0p0c0, ft_s0p0c0, ft_s0p38c4
ft_s0f64:
	.word ft_s0p40c0, ft_s0p56c1, ft_s0p34c2, ft_s0p34c2, ft_s0p40c4
ft_s0f65:
	.word ft_s0p40c0, ft_s0p57c1, ft_s0p0c0, ft_s0p0c0, ft_s0p40c4
; Bank 0
ft_s0p0c0:
	.byte $00, $1F

; Bank 0
ft_s0p0c3:
	.byte $00, $00, $82, $00, $E3, $F1, $1D, $1C, $F2, $00, $1B, $F3, $1A, $83, $F4, $00, $01, $F3, $00, $00
	.byte $1B, $01, $1C, $00, $F2, $00, $01, $1D, $01, $F1, $00, $04, $F1, $1D, $01, $82, $00, $1C, $F2, $00
	.byte $1B, $F3, $1A, $83, $F4, $00, $01, $F3, $00, $00, $1B, $01

; Bank 0
ft_s0p0c4:
	.byte $00, $00, $85, $35, $00, $1E

; Bank 0
ft_s0p1c1:
	.byte $00, $1E, $86, $03, $00, $00

; Bank 0
ft_s0p1c3:
	.byte $E3, $1C, $00, $F2, $00, $01, $1D, $01, $F1, $00, $02, $E4, $F1, $15, $03, $F2, $15, $03, $E6, $F5
	.byte $15, $07, $E4, $F5, $15, $03, $F6, $15, $03

; Bank 0
ft_s0p1c4:
	.byte $00, $07, $85, $96, $00, $17

; Bank 0
ft_s0p2c0:
	.byte $00, $03, $E2, $8F, $00, $F6, $20, $00, $7E, $02, $F8, $20, $02, $7E, $00, $F7, $20, $00, $7E, $02
	.byte $F6, $20, $00, $7E, $02, $F8, $20, $02, $7E, $08

; Bank 0
ft_s0p2c1:
	.byte $7F, $03, $E2, $8F, $00, $F3, $24, $00, $7E, $02, $F6, $24, $02, $7E, $00, $F4, $24, $00, $7E, $02
	.byte $F3, $24, $00, $7E, $02, $F5, $24, $02, $7E, $07, $86, $04, $00, $00

; Bank 0
ft_s0p2c2:
	.byte $00, $03, $E2, $29, $00, $7F, $02, $29, $02, $7F, $00, $29, $00, $7F, $02, $29, $00, $7F, $02, $29
	.byte $02, $7F, $08

; Bank 0
ft_s0p2c3:
	.byte $E6, $FC, $15, $07, $E4, $F8, $15, $03, $F8, $15, $03, $E6, $FC, $15, $07, $E4, $F8, $15, $03, $F8
	.byte $15, $03

; Bank 0
ft_s0p2c4:
	.byte $7E, $03, $0F, $01, $7E, $01, $04, $02, $7E, $00, $82, $01, $0F, $7E, $0F, $7E, $83, $04, $02, $7E
	.byte $08

; Bank 0
ft_s0p3c0:
	.byte $00, $07, $E2, $8F, $00, $F7, $20, $02, $7E, $00, $F6, $20, $00, $7E, $02, $F6, $20, $00, $7E, $02
	.byte $F7, $20, $02, $7E, $08

; Bank 0
ft_s0p3c1:
	.byte $00, $07, $E2, $8F, $00, $F5, $24, $02, $7E, $00, $F4, $24, $00, $7E, $02, $F3, $24, $00, $7E, $02
	.byte $F4, $24, $02, $7E, $07, $86, $05, $00, $00

; Bank 0
ft_s0p3c2:
	.byte $00, $07, $E2, $29, $02, $7F, $00, $29, $00, $7F, $02, $29, $00, $7F, $02, $29, $02, $7F, $08

; Bank 0
ft_s0p3c4:
	.byte $7E, $07, $04, $02, $7E, $00, $82, $01, $0F, $7E, $0F, $7E, $83, $04, $02, $7E, $08

; Bank 0
ft_s0p4c0:
	.byte $00, $03, $E2, $8F, $00, $F5, $24, $00, $7E, $02, $F8, $24, $02, $7E, $00, $F6, $24, $00, $7E, $02
	.byte $F5, $24, $00, $7E, $02, $F7, $24, $02, $7E, $08

; Bank 0
ft_s0p4c1:
	.byte $7F, $03, $E2, $8F, $00, $F3, $22, $00, $7E, $02, $F6, $22, $02, $7E, $00, $F4, $22, $00, $7E, $02
	.byte $F3, $22, $00, $7E, $02, $F5, $22, $02, $7E, $07, $86, $06, $00, $00

; Bank 0
ft_s0p4c2:
	.byte $00, $03, $E2, $27, $00, $7F, $02, $27, $02, $7F, $00, $27, $00, $7F, $02, $27, $00, $7F, $02, $27
	.byte $02, $7F, $08

; Bank 0
ft_s0p5c0:
	.byte $00, $07, $E2, $8F, $00, $F6, $24, $02, $7E, $00, $F4, $24, $00, $7E, $02, $F4, $24, $00, $7E, $02
	.byte $F6, $24, $02, $7E, $08

; Bank 0
ft_s0p5c1:
	.byte $00, $07, $E2, $8F, $00, $F5, $22, $02, $7E, $00, $F4, $22, $00, $7E, $02, $F3, $22, $00, $7E, $02
	.byte $F4, $22, $02, $7E, $07, $86, $07, $00, $00

; Bank 0
ft_s0p5c2:
	.byte $00, $07, $E2, $27, $02, $7F, $00, $27, $00, $7F, $02, $27, $00, $7F, $02, $27, $02, $7F, $08

; Bank 0
ft_s0p6c0:
	.byte $00, $03, $E2, $8F, $00, $F5, $24, $00, $7E, $02, $F6, $24, $02, $7E, $00, $F5, $24, $00, $7E, $02
	.byte $F5, $24, $00, $7E, $02, $F7, $24, $02, $7E, $08

; Bank 0
ft_s0p6c1:
	.byte $7F, $03, $E2, $8F, $00, $F3, $1D, $00, $7E, $02, $F6, $1D, $02, $7E, $00, $F4, $1D, $00, $7E, $02
	.byte $F3, $1D, $00, $7E, $02, $F5, $1D, $02, $7E, $07, $86, $08, $00, $00

; Bank 0
ft_s0p6c2:
	.byte $00, $03, $E3, $25, $00, $7F, $02, $25, $02, $7F, $00, $25, $00, $7F, $02, $25, $00, $7F, $02, $25
	.byte $02, $7F, $08

; Bank 0
ft_s0p6c4:
	.byte $7E, $03, $10, $01, $7E, $01, $05, $02, $7E, $00, $82, $01, $10, $7E, $10, $7E, $83, $05, $02, $7E
	.byte $08

; Bank 0
ft_s0p7c0:
	.byte $00, $07, $E2, $8F, $00, $F7, $24, $02, $7E, $00, $F6, $24, $00, $7E, $02, $F5, $24, $00, $7E, $02
	.byte $F6, $24, $02, $7E, $00, $7E, $07

; Bank 0
ft_s0p7c1:
	.byte $00, $07, $E2, $8F, $00, $F5, $1D, $02, $7E, $00, $F4, $1D, $00, $7E, $02, $F3, $1D, $00, $7E, $02
	.byte $F4, $1D, $02, $7E, $07, $86, $09, $00, $00

; Bank 0
ft_s0p7c2:
	.byte $00, $07, $E3, $25, $02, $7F, $00, $25, $00, $7F, $02, $25, $00, $7F, $02, $25, $02, $7F, $08

; Bank 0
ft_s0p7c4:
	.byte $7E, $07, $05, $02, $7E, $00, $82, $01, $10, $7E, $10, $7E, $83, $05, $02, $7E, $08

; Bank 0
ft_s0p8c0:
	.byte $00, $03, $E2, $8F, $00, $F5, $22, $00, $7E, $02, $F8, $22, $02, $7E, $00, $F6, $22, $00, $7E, $02
	.byte $F5, $22, $00, $7E, $02, $F7, $22, $02, $7E, $08

; Bank 0
ft_s0p8c1:
	.byte $00, $03, $E2, $8F, $00, $F3, $24, $00, $7E, $02, $F7, $24, $02, $7E, $00, $F4, $24, $00, $7E, $02
	.byte $F3, $24, $00, $7E, $02, $F5, $24, $02, $7E, $07, $86, $0A, $00, $00

; Bank 0
ft_s0p8c2:
	.byte $00, $03, $E2, $28, $00, $7F, $02, $28, $02, $7F, $00, $28, $00, $7F, $02, $28, $00, $7F, $02, $28
	.byte $02, $7F, $08

; Bank 0
ft_s0p9c0:
	.byte $00, $07, $E2, $8F, $00, $F7, $22, $02, $7E, $00, $F6, $22, $00, $7E, $02, $F5, $22, $00, $7E, $02
	.byte $F7, $22, $02, $7E, $04, $E7, $F7, $0C, $01, $7E, $01

; Bank 0
ft_s0p9c1:
	.byte $00, $07, $E2, $8F, $00, $F5, $24, $02, $7E, $00, $F4, $24, $00, $7E, $02, $F3, $24, $00, $7E, $02
	.byte $F5, $24, $02, $7E, $07, $86, $0B, $00, $00

; Bank 0
ft_s0p9c2:
	.byte $00, $07, $E2, $28, $02, $7F, $00, $28, $00, $7F, $02, $28, $00, $7F, $02, $28, $02, $7F, $08

; Bank 0
ft_s0p10c0:
	.byte $E7, $8F, $00, $F9, $11, $03, $E2, $F6, $20, $00, $7E, $02, $F9, $20, $02, $7E, $00, $F7, $20, $00
	.byte $7E, $02, $F6, $20, $00, $7E, $02, $F8, $20, $02, $7E, $04, $E7, $F8, $18, $01, $7E, $01

; Bank 0
ft_s0p10c1:
	.byte $7F, $03, $E2, $8F, $00, $F3, $24, $00, $7E, $02, $F6, $24, $02, $7E, $00, $F4, $24, $00, $7E, $02
	.byte $F3, $24, $00, $7E, $02, $F5, $24, $02, $7E, $07, $86, $0C, $00, $00

; Bank 0
ft_s0p11c0:
	.byte $E7, $8F, $00, $F9, $11, $07, $E2, $F8, $20, $02, $7E, $00, $F6, $20, $00, $7E, $02, $F6, $20, $00
	.byte $7E, $02, $E7, $F9, $11, $02, $7E, $04, $F9, $0F, $03

; Bank 0
ft_s0p11c1:
	.byte $E5, $8F, $00, $F7, $29, $03, $8F, $16, $00, $01, $8F, $26, $00, $08, $F5, $2A, $00, $8F, $00, $F6
	.byte $2B, $03, $8F, $16, $00, $01, $8F, $26, $00, $05, $8F, $00, $F7, $27, $02, $86, $0D, $00, $00

; Bank 0
ft_s0p12c0:
	.byte $00, $03, $E2, $8F, $00, $F5, $24, $00, $7E, $02, $F8, $24, $02, $7E, $00, $F6, $24, $00, $7E, $02
	.byte $F5, $24, $00, $7E, $02, $E7, $F8, $16, $02, $7E, $04, $F9, $0F, $03

; Bank 0
ft_s0p12c1:
	.byte $8F, $16, $00, $01, $8F, $26, $00, $0D, $8F, $00, $7E, $0D, $E5, $F4, $2C, $00, $86, $0E, $F5, $2D
	.byte $00

; Bank 0
ft_s0p13c0:
	.byte $00, $07, $E2, $8F, $00, $F6, $24, $02, $7E, $00, $F4, $24, $00, $7E, $02, $F4, $24, $00, $7E, $02
	.byte $F6, $24, $02, $7E, $04, $E7, $F9, $0D, $03

; Bank 0
ft_s0p13c1:
	.byte $E5, $8F, $00, $F7, $2E, $03, $8F, $16, $00, $01, $8F, $26, $00, $01, $E2, $8F, $00, $F6, $22, $02
	.byte $7E, $00, $E5, $F7, $2C, $01, $7E, $01, $E2, $F4, $22, $00, $7E, $02, $E5, $F6, $2B, $01, $7E, $05
	.byte $8F, $00, $F7, $25, $02, $86, $0F, $00, $00

; Bank 0
ft_s0p14c0:
	.byte $00, $03, $E2, $8F, $00, $F5, $24, $00, $7E, $02, $F6, $24, $02, $7E, $00, $F5, $24, $00, $7E, $02
	.byte $F5, $24, $00, $7E, $02, $E7, $F8, $11, $01, $F6, $11, $00, $F7, $13, $00, $F9, $14, $01, $7E, $01
	.byte $F9, $0D, $03

; Bank 0
ft_s0p14c1:
	.byte $8F, $16, $00, $01, $8F, $26, $00, $05, $E2, $8F, $00, $F7, $1D, $02, $7E, $00, $F5, $1D, $00, $7E
	.byte $02, $F4, $1D, $00, $7E, $02, $F6, $24, $02, $7E, $07, $86, $10, $00, $00

; Bank 0
ft_s0p15c0:
	.byte $00, $03, $7E, $03, $E2, $8F, $00, $F7, $1D, $02, $7E, $00, $F6, $1D, $00, $7E, $02, $F5, $1D, $00
	.byte $7E, $02, $E7, $F9, $0D, $03, $7E, $03, $F9, $0C, $03

; Bank 0
ft_s0p15c1:
	.byte $E5, $8F, $00, $F6, $25, $03, $8F, $16, $00, $01, $8F, $26, $00, $05, $8B, $02, $00, $03, $8F, $00
	.byte $8A, $F6, $27, $07, $7E, $03, $8F, $00, $F6, $24, $02, $86, $11, $00, $00

; Bank 0
ft_s0p16c0:
	.byte $00, $03, $E2, $8F, $00, $F5, $22, $00, $7E, $02, $F8, $22, $02, $7E, $00, $F6, $22, $00, $7E, $02
	.byte $F5, $22, $00, $7E, $02, $E7, $F9, $13, $02, $7E, $04, $F8, $18, $03

; Bank 0
ft_s0p16c1:
	.byte $8F, $16, $00, $01, $8F, $26, $00, $05, $E2, $8F, $00, $F7, $24, $02, $7E, $00, $F4, $24, $00, $7E
	.byte $02, $F3, $24, $00, $7E, $02, $F5, $24, $02, $7E, $07, $86, $12, $00, $00

; Bank 0
ft_s0p17c0:
	.byte $00, $07, $E2, $8F, $00, $F7, $22, $02, $7E, $00, $F6, $22, $00, $7E, $02, $F5, $22, $00, $7E, $02
	.byte $F7, $22, $02, $7E, $04, $E7, $F9, $0C, $01, $7E, $01

; Bank 0
ft_s0p17c1:
	.byte $00, $07, $E2, $8F, $00, $F5, $24, $02, $7E, $00, $F4, $24, $00, $7E, $02, $F3, $24, $00, $7E, $02
	.byte $F5, $24, $02, $7E, $07, $86, $13, $00, $00

; Bank 0
ft_s0p18c0:
	.byte $E7, $8F, $00, $F9, $11, $03, $E2, $F5, $20, $00, $7E, $02, $F7, $20, $02, $7E, $00, $F6, $20, $00
	.byte $7E, $02, $F5, $20, $00, $7E, $02, $F7, $20, $02, $7E, $04, $E7, $F8, $18, $01, $7E, $01

; Bank 0
ft_s0p18c1:
	.byte $7F, $03, $E2, $8F, $00, $F4, $24, $00, $7E, $02, $F7, $24, $02, $7E, $00, $F5, $24, $00, $7E, $02
	.byte $F4, $24, $00, $7E, $02, $F6, $24, $02, $7E, $07, $86, $14, $00, $00

; Bank 0
ft_s0p19c0:
	.byte $E7, $8F, $00, $F7, $11, $07, $E2, $F6, $20, $02, $7E, $00, $F5, $20, $00, $7E, $02, $F5, $20, $00
	.byte $7E, $02, $E7, $F9, $11, $01, $7E, $05, $13, $03

; Bank 0
ft_s0p19c1:
	.byte $E5, $8F, $06, $F7, $29, $01, $8F, $16, $00, $01, $8F, $26, $00, $01, $8F, $36, $00, $06, $94, $01
	.byte $8F, $00, $F4, $2E, $00, $94, $03, $82, $01, $F5, $2F, $81, $F6, $30, $8F, $16, $00, $8F, $26, $00
	.byte $83, $8F, $36, $00, $05, $8F, $06, $F6, $30, $01, $8F, $16, $00, $00, $86, $15, $00, $00

; Bank 0
ft_s0p20c0:
	.byte $00, $03, $E2, $8F, $00, $F5, $24, $00, $7E, $02, $F7, $24, $02, $7E, $00, $F6, $24, $00, $7E, $02
	.byte $F5, $24, $00, $7E, $02, $F7, $24, $02, $7E, $04, $E7, $F8, $18, $01, $7E, $01

; Bank 0
ft_s0p20c1:
	.byte $00, $07, $E2, $8F, $06, $F7, $22, $02, $E9, $8F, $16, $F6, $30, $00, $E2, $8F, $06, $F5, $22, $00
	.byte $E9, $8F, $16, $F6, $30, $02, $E2, $8F, $06, $F4, $22, $00, $E9, $8F, $16, $F6, $30, $01, $E5, $F3
	.byte $2D, $00, $8F, $06, $F6, $2E, $03, $F5, $2C, $01, $7E, $01, $8F, $06, $F7, $2B, $01, $8F, $16, $00
	.byte $00, $86, $16, $00, $00

; Bank 0
ft_s0p21c0:
	.byte $E7, $8F, $00, $F9, $0F, $07, $E2, $F6, $24, $02, $7E, $00, $F5, $24, $00, $7E, $02, $F5, $24, $00
	.byte $7E, $02, $E7, $F9, $0F, $01, $7E, $05, $F9, $0D, $03

; Bank 0
ft_s0p21c1:
	.byte $8F, $26, $00, $01, $8F, $36, $00, $05, $E2, $F5, $22, $01, $E9, $F7, $2B, $08, $E5, $F4, $2B, $00
	.byte $82, $01, $8F, $06, $F6, $2C, $8F, $16, $00, $8F, $26, $00, $8F, $36, $00, $83, $F5, $00, $02, $86
	.byte $17, $00, $00

; Bank 0
ft_s0p22c0:
	.byte $00, $03, $E2, $8F, $00, $F5, $24, $00, $7E, $02, $F7, $24, $02, $7E, $00, $F6, $24, $00, $7E, $02
	.byte $F5, $24, $00, $7E, $02, $E7, $F8, $11, $01, $F6, $11, $00, $F7, $13, $00, $F9, $14, $01, $7E, $01
	.byte $F9, $0D, $03

; Bank 0
ft_s0p22c1:
	.byte $00, $03, $82, $01, $F4, $00, $7E, $E5, $8F, $06, $F6, $29, $8F, $16, $00, $8F, $26, $00, $8F, $36
	.byte $00, $83, $F5, $00, $07, $F4, $00, $03, $F3, $00, $01, $7E, $00, $86, $18, $00, $00

; Bank 0
ft_s0p23c0:
	.byte $00, $03, $7E, $03, $E2, $8F, $00, $F6, $24, $02, $7E, $00, $F5, $24, $00, $7E, $02, $F5, $24, $00
	.byte $7E, $02, $E7, $F9, $0D, $01, $7E, $05, $F9, $0C, $03

; Bank 0
ft_s0p23c1:
	.byte $00, $07, $E2, $8F, $00, $F5, $1D, $02, $7E, $00, $F4, $1D, $00, $7E, $02, $F3, $1D, $00, $7E, $02
	.byte $F5, $1D, $02, $E5, $F4, $2A, $00, $8F, $00, $F7, $2B, $03, $8F, $06, $F6, $28, $01, $8F, $16, $00
	.byte $00, $86, $19, $00, $00

; Bank 0
ft_s0p24c0:
	.byte $00, $03, $E2, $8F, $00, $F5, $22, $00, $7E, $02, $F8, $22, $02, $7E, $00, $F6, $22, $00, $7E, $02
	.byte $F5, $22, $00, $7E, $02, $E7, $F8, $13, $01, $7E, $05, $F7, $18, $03

; Bank 0
ft_s0p24c1:
	.byte $8F, $26, $00, $01, $8F, $36, $00, $01, $F5, $00, $03, $E2, $8F, $06, $F7, $24, $02, $E9, $8F, $36
	.byte $F4, $28, $00, $E2, $8F, $06, $F4, $24, $00, $E9, $8F, $36, $F3, $28, $02, $E2, $8F, $00, $F3, $24
	.byte $00, $7E, $02, $F5, $24, $02, $7E, $07, $86, $1A, $00, $00

; Bank 0
ft_s0p25c1:
	.byte $00, $07, $E2, $8F, $00, $F5, $24, $02, $7E, $00, $F4, $24, $00, $7E, $02, $F3, $24, $00, $7E, $02
	.byte $F5, $24, $02, $7E, $07, $86, $1B, $00, $00

; Bank 0
ft_s0p26c1:
	.byte $00, $03, $E2, $8F, $00, $F3, $24, $00, $7E, $02, $F6, $24, $02, $7E, $00, $F4, $24, $00, $7E, $02
	.byte $F3, $24, $00, $7E, $02, $F5, $24, $02, $7E, $07, $86, $1C, $00, $00

; Bank 0
ft_s0p27c0:
	.byte $E7, $8F, $00, $F9, $11, $07, $E2, $F6, $20, $02, $7E, $00, $F5, $20, $00, $7E, $02, $F5, $20, $00
	.byte $7E, $02, $E7, $F9, $11, $01, $7E, $05, $F9, $13, $03

; Bank 0
ft_s0p27c1:
	.byte $00, $07, $E2, $8F, $00, $F5, $24, $02, $7E, $00, $F4, $24, $00, $7E, $02, $F3, $24, $00, $7E, $02
	.byte $E5, $8F, $06, $F6, $29, $03, $F5, $30, $01, $7E, $01, $8F, $06, $F6, $30, $01, $8F, $16, $00, $00
	.byte $86, $1D, $00, $00

; Bank 0
ft_s0p28c1:
	.byte $8F, $26, $00, $01, $8F, $36, $00, $05, $E2, $8F, $06, $F6, $22, $02, $E9, $8F, $36, $F6, $30, $00
	.byte $E2, $8F, $06, $F4, $22, $00, $E9, $8F, $36, $F5, $30, $02, $E2, $8F, $06, $F3, $22, $00, $E9, $8F
	.byte $36, $F4, $30, $02, $E2, $8F, $00, $F5, $22, $02, $7E, $07, $86, $1E, $00, $00

; Bank 0
ft_s0p29c0:
	.byte $E7, $8F, $00, $F9, $13, $07, $E2, $F6, $24, $02, $7E, $00, $F5, $24, $00, $7E, $02, $F5, $24, $00
	.byte $7E, $02, $E7, $F9, $13, $01, $7E, $05, $F9, $14, $03

; Bank 0
ft_s0p29c1:
	.byte $00, $07, $E2, $8F, $00, $F5, $22, $03, $94, $01, $E5, $8F, $00, $F4, $31, $01, $94, $02, $F5, $32
	.byte $01, $F7, $33, $05, $F5, $32, $02, $7E, $02, $F6, $31, $02, $86, $1F, $00, $00

; Bank 0
ft_s0p30c0:
	.byte $00, $03, $E2, $8F, $00, $F5, $24, $00, $7E, $02, $F7, $24, $02, $7E, $00, $F6, $24, $00, $7E, $02
	.byte $F5, $24, $00, $7E, $02, $F7, $24, $02, $7E, $04, $E7, $F9, $18, $01, $7E, $01

; Bank 0
ft_s0p30c1:
	.byte $7E, $03, $E2, $8F, $00, $F3, $1D, $00, $7E, $02, $82, $01, $E5, $8F, $06, $F6, $30, $8F, $16, $00
	.byte $8F, $26, $00, $8F, $36, $00, $83, $E2, $8F, $06, $F3, $1D, $00, $E9, $8F, $36, $F6, $30, $02, $E2
	.byte $8F, $06, $F5, $1D, $02, $E9, $8F, $36, $F5, $30, $02, $F4, $00, $01, $F3, $00, $01, $7E, $00, $86
	.byte $20, $00, $00

; Bank 0
ft_s0p31c0:
	.byte $E7, $8F, $00, $14, $07, $E2, $F6, $24, $02, $7E, $00, $F5, $24, $00, $7E, $02, $F5, $24, $00, $7E
	.byte $02, $E7, $F9, $14, $01, $7E, $05, $F9, $16, $03

; Bank 0
ft_s0p31c1:
	.byte $00, $07, $E2, $8F, $00, $F5, $1D, $02, $7E, $00, $F4, $1D, $00, $7E, $02, $F3, $1D, $00, $7E, $02
	.byte $F4, $1D, $02, $7E, $00, $E5, $8F, $06, $F4, $35, $03, $8F, $06, $F4, $30, $01, $8F, $16, $00, $00
	.byte $86, $21, $00, $00

; Bank 0
ft_s0p32c0:
	.byte $00, $03, $E2, $8F, $00, $F5, $22, $00, $7E, $02, $F8, $22, $02, $7E, $00, $F6, $22, $00, $7E, $02
	.byte $F5, $22, $00, $7E, $02, $F7, $22, $02, $7E, $04, $E7, $F7, $18, $01, $7E, $01

; Bank 0
ft_s0p32c1:
	.byte $8F, $26, $00, $01, $8F, $36, $00, $05, $E2, $8F, $06, $F7, $24, $02, $E9, $8F, $36, $F4, $30, $00
	.byte $E2, $8F, $06, $F4, $24, $00, $E9, $8F, $36, $F4, $30, $02, $E2, $8F, $06, $F3, $24, $00, $E9, $8F
	.byte $36, $F3, $30, $02, $E2, $8F, $06, $F5, $24, $02, $7E, $07, $86, $22, $00, $00

; Bank 0
ft_s0p33c0:
	.byte $E7, $8F, $00, $F8, $0C, $07, $E2, $F7, $22, $02, $7E, $00, $F6, $22, $00, $7E, $02, $F5, $22, $00
	.byte $7E, $02, $F7, $22, $02, $7E, $04, $E7, $0C, $01, $7E, $01

; Bank 0
ft_s0p34c0:
	.byte $E8, $8F, $46, $F6, $11, $1F

; Bank 0
ft_s0p34c1:
	.byte $E8, $8F, $00, $F1, $18, $1E, $86, $2C, $00, $00

; Bank 0
ft_s0p34c2:
	.byte $7F, $1F

; Bank 0
ft_s0p34c4:
	.byte $82, $01, $03, $0F, $04, $0E, $05, $0F, $07, $10, $0B, $12, $07, $16, $05, $12, $04, $83, $10, $01

; Bank 0
ft_s0p35c1:
	.byte $EA, $8F, $00, $F8, $29, $03, $E8, $F1, $18, $01, $EA, $F4, $29, $03, $E8, $F1, $18, $01, $EA, $F2
	.byte $29, $03, $F8, $2B, $03, $E8, $F1, $18, $01, $EA, $F4, $2B, $03, $E8, $F1, $18, $01, $EA, $F8, $27
	.byte $02, $86, $2D, $00, $00

; Bank 0
ft_s0p36c0:
	.byte $E8, $8F, $46, $F6, $0F, $1F

; Bank 0
ft_s0p36c1:
	.byte $E8, $8F, $00, $F1, $18, $01, $EA, $F4, $27, $03, $E8, $F1, $18, $01, $EA, $F2, $27, $03, $E8, $F1
	.byte $18, $12, $86, $2E, $00, $00

; Bank 0
ft_s0p36c4:
	.byte $82, $01, $01, $0F, $04, $0C, $06, $0F, $07, $11, $09, $12, $07, $14, $06, $12, $04, $83, $11, $01

; Bank 0
ft_s0p37c1:
	.byte $EA, $8F, $00, $F8, $2E, $03, $E8, $F1, $18, $01, $EA, $F4, $2E, $03, $E8, $F1, $18, $01, $EA, $F8
	.byte $2C, $03, $E8, $F1, $18, $01, $EA, $F4, $2C, $01, $F8, $2B, $03, $F2, $2C, $01, $F4, $2B, $01, $F8
	.byte $25, $02, $86, $2F, $00, $00

; Bank 0
ft_s0p38c0:
	.byte $E8, $8F, $46, $F6, $0D, $1F

; Bank 0
ft_s0p38c1:
	.byte $E8, $8F, $00, $F1, $14, $01, $EA, $F4, $25, $03, $E8, $F1, $14, $01, $EA, $F2, $25, $03, $E8, $F1
	.byte $14, $12, $86, $30, $00, $00

; Bank 0
ft_s0p38c4:
	.byte $82, $01, $03, $10, $05, $0E, $07, $10, $08, $12, $0B, $13, $08, $16, $07, $13, $05, $83, $12, $01

; Bank 0
ft_s0p39c1:
	.byte $EA, $8F, $00, $F8, $25, $03, $E8, $F1, $14, $01, $EA, $F4, $25, $03, $E8, $F1, $14, $01, $EA, $F2
	.byte $25, $03, $F8, $27, $03, $E8, $F1, $14, $01, $EA, $F4, $27, $03, $E8, $F1, $14, $01, $EA, $F8, $24
	.byte $02, $86, $31, $00, $00

; Bank 0
ft_s0p40c0:
	.byte $E8, $8F, $46, $F6, $0C, $1F

; Bank 0
ft_s0p40c1:
	.byte $E8, $8F, $00, $F1, $13, $01, $EA, $F4, $24, $03, $E8, $F1, $13, $01, $EA, $F2, $24, $03, $E8, $F1
	.byte $13, $12, $86, $32, $00, $00

; Bank 0
ft_s0p40c4:
	.byte $82, $01, $02, $0F, $04, $0D, $06, $0F, $07, $11, $0A, $12, $07, $15, $06, $12, $04, $83, $11, $01

; Bank 0
ft_s0p41c1:
	.byte $E8, $8F, $00, $F1, $13, $1E, $86, $33, $00, $00

; Bank 0
ft_s0p42c1:
	.byte $E8, $8F, $00, $F1, $18, $1E, $86, $34, $00, $00

; Bank 0
ft_s0p43c1:
	.byte $EA, $8F, $00, $F8, $29, $03, $E8, $F1, $18, $01, $EA, $F4, $29, $03, $E8, $F1, $18, $01, $EA, $F2
	.byte $29, $03, $F8, $30, $03, $E8, $F1, $18, $01, $EA, $F4, $30, $03, $E8, $F1, $18, $01, $EA, $F8, $30
	.byte $02, $86, $35, $00, $00

; Bank 0
ft_s0p44c1:
	.byte $E8, $8F, $00, $F1, $18, $01, $EA, $F4, $30, $03, $E8, $F1, $18, $01, $EA, $F2, $30, $03, $E8, $F1
	.byte $18, $07, $EA, $F8, $2E, $03, $F7, $2C, $01, $F4, $2E, $01, $F8, $2B, $01, $F4, $2C, $00, $86, $36
	.byte $00, $00

; Bank 0
ft_s0p45c1:
	.byte $00, $01, $EA, $8F, $00, $F4, $2B, $01, $F2, $2C, $03, $F2, $2B, $03, $E8, $F1, $18, $07, $EA, $F8
	.byte $2C, $03, $E8, $F1, $18, $01, $EA, $F4, $2C, $03, $E8, $F1, $18, $00, $86, $37, $00, $00

; Bank 0
ft_s0p46c1:
	.byte $EA, $8F, $00, $F2, $2C, $03, $E8, $F1, $14, $03, $EA, $F8, $29, $03, $E8, $F1, $14, $01, $EA, $F4
	.byte $29, $03, $E8, $F1, $14, $01, $EA, $F2, $29, $03, $E8, $F1, $14, $06, $86, $38, $00, $00

; Bank 0
ft_s0p47c1:
	.byte $E8, $8F, $00, $F1, $14, $17, $EA, $F8, $2B, $03, $F8, $28, $01, $F4, $2B, $00, $86, $39, $00, $00

; Bank 0
ft_s0p48c1:
	.byte $E8, $8F, $00, $F1, $13, $01, $EA, $F4, $28, $01, $F2, $2B, $03, $F2, $28, $03, $E8, $F1, $13, $12
	.byte $86, $3A, $00, $00

; Bank 0
ft_s0p49c1:
	.byte $E8, $8F, $00, $F1, $13, $1E, $86, $3B, $00, $00

; Bank 0
ft_s0p50c1:
	.byte $E8, $8F, $00, $F1, $18, $1E, $86, $3C, $00, $00

; Bank 0
ft_s0p51c1:
	.byte $E8, $8F, $00, $F1, $18, $13, $EA, $F8, $29, $03, $F8, $30, $01, $F4, $29, $01, $F8, $30, $02, $86
	.byte $3D, $00, $00

; Bank 0
ft_s0p52c1:
	.byte $EA, $8F, $00, $F2, $29, $01, $F4, $30, $03, $E8, $F1, $18, $01, $EA, $F2, $30, $03, $E8, $F1, $18
	.byte $12, $86, $3E, $00, $00

; Bank 0
ft_s0p53c0:
	.byte $E8, $8F, $46, $F6, $0F, $15, $EA, $F4, $33, $03, $E8, $F6, $0F, $01, $EA, $F4, $32, $03

; Bank 0
ft_s0p53c1:
	.byte $E8, $8F, $00, $F1, $18, $0F, $EA, $F6, $33, $03, $E8, $F1, $18, $01, $EA, $F7, $32, $03, $E8, $F1
	.byte $18, $01, $EA, $F8, $31, $02, $86, $3F, $00, $00

; Bank 0
ft_s0p54c1:
	.byte $E8, $8F, $00, $F1, $14, $01, $EA, $F4, $31, $03, $E8, $F1, $14, $01, $EA, $F8, $30, $03, $E8, $F1
	.byte $14, $01, $EA, $F4, $30, $03, $E8, $F1, $14, $01, $EA, $F2, $30, $03, $E8, $F1, $14, $06, $86, $40
	.byte $00, $00

; Bank 0
ft_s0p55c1:
	.byte $E8, $8F, $00, $F1, $14, $17, $EA, $F6, $35, $03, $F6, $30, $01, $F3, $35, $00, $86, $41, $00, $00

; Bank 0
ft_s0p56c1:
	.byte $00, $01, $EA, $8F, $00, $F3, $30, $03, $E8, $F1, $13, $01, $EA, $F1, $30, $03, $E8, $F1, $13, $12
	.byte $86, $42, $00, $00

; Bank 0
ft_s0p57c1:
	.byte $E8, $8F, $00, $F1, $13, $1E, $86, $2B, $00, $00

; Bank 0
ft_s0p58c1:
	.byte $E8, $8F, $00, $F1, $18, $1E, $86, $24, $00, $00

; Bank 0
ft_s0p59c1:
	.byte $E8, $8F, $00, $F1, $18, $1E, $86, $25, $00, $00

; Bank 0
ft_s0p60c1:
	.byte $E8, $8F, $00, $F1, $18, $1E, $86, $26, $00, $00

; Bank 0
ft_s0p61c1:
	.byte $E8, $8F, $00, $F1, $18, $1E, $86, $27, $00, $00

; Bank 0
ft_s0p62c1:
	.byte $E8, $8F, $00, $F1, $14, $1E, $86, $28, $00, $00

; Bank 0
ft_s0p63c1:
	.byte $E8, $8F, $00, $F1, $14, $1E, $86, $29, $00, $00

; Bank 0
ft_s0p64c1:
	.byte $E8, $8F, $00, $F1, $13, $1E, $86, $2A, $00, $00


; DPCM samples (located at DPCM segment)

	.segment "DPCM_0"
ft_sample_0: ; puretri-mid-loud-A4
	.byte $FF, $FF, $FF, $FF, $3F, $00, $00, $00, $00, $F0, $FF, $FF, $FF, $FF, $03, $00, $00, $00, $80, $FF
	.byte $FF, $FF, $FF, $1F, $00, $00, $00, $00, $FC, $FF, $FF, $FF, $FF, $00, $00, $00, $00, $C0, $FF, $FF
	.byte $FF, $FF, $0F, $00, $00, $00, $00, $FE, $FF, $FF, $FF, $7F, $00, $00, $00, $00, $F0, $FF, $FF, $FF
	.byte $FF, $03, $00, $00, $00, $00, $FF, $FF, $FF, $FF, $1F, $00, $00, $00, $00, $F8, $FF, $FF, $FF, $FF
	.byte $01, $00, $00, $00, $C0, $FF, $FF, $FF, $FF, $0F, $00, $00, $00, $00, $FC, $FF, $FF, $FF, $FF, $00
	.byte $00, $00, $00, $E0, $FF, $FF, $FF, $FF, $07, $00, $00, $00, $00

	.align 64

ft_sample_1: ; puretri-mid-loud-Gs4
	.byte $FF, $FF, $FF, $FF, $FF, $00, $00, $00, $00, $00, $FF, $FF, $FF, $FF, $FF, $00, $00, $00, $00, $00
	.byte $FF, $FF, $FF, $FF, $FF, $00, $00, $00, $00, $00, $FF, $FF, $FF, $FF, $FF, $00, $00, $00, $00, $00
	.byte $FF, $FF, $FF, $FF, $FF, $00, $00, $00, $00, $00, $FF, $FF, $FF, $FF, $FF, $00, $00, $00, $00, $80
	.byte $FF, $FF, $FF, $FF, $7F, $00, $00, $00, $00, $80, $FF, $FF, $FF, $FF, $7F, $00, $00, $00, $00, $80
	.byte $FF, $FF, $FF, $FF, $7F, $00, $00, $00, $00, $80, $FF, $FF, $FF, $FF, $7F, $00, $00, $00, $00, $80
	.byte $FF, $FF, $FF, $FF, $7F, $00, $00, $00, $00, $80, $FF, $FF, $FF, $FF, $3F, $00, $00, $00, $00, $C0
	.byte $FF, $FF, $FF, $FF, $3F, $00, $00, $00, $00, $C0, $FF, $FF, $FF, $FF, $3F, $00, $00, $00, $00, $C0
	.byte $FF, $FF, $FF, $FF, $3F, $00, $00, $00, $00, $C0, $FF, $FF, $FF, $FF, $3F, $00, $00, $00, $00, $C0
	.byte $FF, $FF, $FF, $FF, $3F, $00, $00, $00, $00, $E0, $FF, $FF, $FF, $FF, $1F, $00, $00, $00, $00, $E0
	.byte $FF, $FF, $FF, $FF, $1F, $00, $00, $00, $00, $E0, $FF, $FF, $FF, $FF, $1F, $00, $00, $00, $00, $E0
	.byte $FF, $FF, $FF, $FF, $1F, $00, $00, $00, $00, $E0, $FF, $FF, $FF, $FF, $1F, $00, $00, $00, $00, $E0
	.byte $FF, $FF, $FF, $FF, $0F, $00, $00, $00, $00, $F0, $FF, $FF, $FF, $FF, $0F, $00, $00, $00, $00, $F0
	.byte $FF, $FF, $FF, $FF, $0F, $00, $00, $00, $00, $F0, $FF, $FF, $FF, $FF, $0F, $00, $00, $00, $00, $F0
	.byte $FF, $FF, $FF, $FF, $0F, $00, $00, $00, $00, $F0, $FF, $FF, $FF, $FF, $0F, $00, $00, $00, $00, $F0
	.byte $FF, $FF, $FF, $FF, $07, $00, $00, $00, $00, $F8, $FF, $FF, $FF, $FF, $07, $00, $00, $00, $00, $F8
	.byte $FF, $FF, $FF, $FF, $07, $00, $00, $00, $00, $F8, $FF, $FF, $FF, $FF, $07, $00, $00, $00, $00, $F8
	.byte $FF, $FF, $FF, $FF, $07, $00, $00, $00, $00, $F8, $FF, $FF, $FF, $FF, $07, $00, $00, $00, $00, $FC
	.byte $FF, $FF, $FF, $FF, $03, $00, $00, $00, $00, $FC, $FF, $FF, $FF, $FF, $03, $00, $00, $00, $00, $FC
	.byte $FF, $FF, $FF, $FF, $03, $00, $00, $00, $00, $FC, $FF, $FF, $FF, $FF, $03, $00, $00, $00, $00, $FC
	.byte $FF, $FF, $FF, $FF, $03, $00, $00, $00, $00, $FC, $FF, $FF, $FF, $FF, $01, $00, $00, $00, $00, $FE
	.byte $FF, $FF, $FF, $FF, $01, $00, $00, $00, $00, $FE, $FF, $FF, $FF, $FF, $01, $00, $00, $00, $00, $FE
	.byte $FF, $FF, $FF, $FF, $01, $00, $00, $00, $00, $FE, $FF, $FF, $FF, $FF, $01, $00, $00, $00, $00, $FE
	.byte $FF, $FF, $FF, $FF, $01, $00, $00, $00, $00

	.align 64

ft_sample_2: ; puretri-mid-loud-As4
	.byte $FF, $FF, $FF, $FF, $0F, $00, $00, $00, $00, $FF, $FF, $FF, $FF, $07, $00, $00, $00, $80, $FF, $FF
	.byte $FF, $FF, $03, $00, $00, $00, $C0, $FF, $FF, $FF, $FF, $01, $00, $00, $00, $E0, $FF, $FF, $FF, $FF
	.byte $00, $00, $00, $00, $F0, $FF, $FF, $FF, $7F, $00, $00, $00, $00, $F8, $FF, $FF, $FF, $7F, $00, $00
	.byte $00, $00, $FC, $FF, $FF, $FF, $3F, $00, $00, $00, $00, $FE, $FF, $FF, $FF, $1F, $00, $00, $00, $00
	.byte $FF, $FF, $FF, $FF, $0F, $00, $00, $00, $80, $FF, $FF, $FF, $FF, $07, $00, $00, $00, $C0, $FF, $FF
	.byte $FF, $FF, $03, $00, $00, $00, $C0, $FF, $FF, $FF, $FF, $01, $00, $00, $00, $E0, $FF, $FF, $FF, $FF
	.byte $00, $00, $00, $00, $F0, $FF, $FF, $FF, $7F, $00, $00, $00, $00, $F8, $FF, $FF, $FF, $3F, $00, $00
	.byte $00, $00, $FC, $FF, $FF, $FF, $1F, $00, $00, $00, $00, $FE, $FF, $FF, $FF, $0F, $00, $00, $00, $00
	.byte $FF, $FF, $FF, $FF, $0F, $00, $00, $00, $80, $FF, $FF, $FF, $FF, $07, $00, $00, $00, $C0, $FF, $FF
	.byte $FF, $FF, $03, $00, $00, $00, $E0, $FF, $FF, $FF, $FF, $01, $00, $00, $00, $F0, $FF, $FF, $FF, $FF
	.byte $00, $00, $00, $00, $F8, $FF, $FF, $FF, $7F, $00, $00, $00, $00, $F8, $FF, $FF, $FF, $3F, $00, $00
	.byte $00, $00, $FC, $FF, $FF, $FF, $1F, $00, $00, $00, $00, $FE, $FF, $FF, $FF, $0F, $00, $00, $00, $00
	.byte $FF, $FF, $FF, $FF, $07, $00, $00, $00, $80, $FF, $FF, $FF, $FF, $03, $00, $00, $00, $C0, $FF, $FF
	.byte $FF, $FF, $01, $00, $00, $00, $E0, $FF, $FF, $FF, $FF, $01, $00, $00, $00, $F0, $FF, $FF, $FF, $FF
	.byte $00, $00, $00, $00, $F8, $FF, $FF, $FF, $7F, $00, $00, $00, $00, $FC, $FF, $FF, $FF, $3F, $00, $00
	.byte $00, $00, $FE, $FF, $FF, $FF, $1F, $00, $00, $00, $00, $FF, $FF, $FF, $FF, $0F, $00, $00, $00, $00
	.byte $FF, $FF, $FF, $FF, $07, $00, $00, $00, $80, $FF, $FF, $FF, $FF, $03, $00, $00, $00, $C0, $FF, $FF
	.byte $FF, $FF, $01, $00, $00, $00, $E0, $FF, $FF, $FF, $FF, $00, $00, $00, $00, $F0, $FF, $FF, $FF, $7F
	.byte $00, $00, $00, $00, $F8, $FF, $FF, $FF, $3F, $00, $00, $00, $00, $FC, $FF, $FF, $FF, $3F, $00, $00
	.byte $00, $00, $FE, $FF, $FF, $FF, $1F, $00, $00, $00, $00, $FF, $FF, $FF, $FF, $0F, $00, $00, $00, $80
	.byte $FF, $FF, $FF, $FF, $07, $00, $00, $00, $C0, $FF, $FF, $FF, $FF, $03, $00, $00, $00, $E0, $FF, $FF
	.byte $FF, $FF, $01, $00, $00, $00, $E0, $FF, $FF, $FF, $FF, $00, $00, $00, $00, $F0, $FF, $FF, $FF, $7F
	.byte $00, $00, $00, $00, $F8, $FF, $FF, $FF, $3F, $00, $00, $00, $00, $FC, $FF, $FF, $FF, $1F, $00, $00
	.byte $00, $00, $FE, $FF, $FF, $FF, $0F, $00, $00, $00, $00, $FF, $FF, $FF, $FF, $07, $00, $00, $00, $80
	.byte $FF, $FF, $FF, $FF, $07, $00, $00, $00, $C0, $FF, $FF, $FF, $FF, $03, $00, $00, $00, $E0, $FF, $FF
	.byte $FF, $FF, $01, $00, $00, $00, $F0, $FF, $FF, $FF, $FF, $00, $00, $00, $00, $F8, $FF, $FF, $FF, $7F
	.byte $00, $00, $00, $00, $FC, $FF, $FF, $FF, $3F, $00, $00, $00, $00, $FC, $FF, $FF, $FF, $1F, $00, $00
	.byte $00, $00, $FE, $FF, $FF, $FF, $0F, $00, $00, $00, $00, $FF, $FF, $FF, $FF, $07, $00, $00, $00, $80
	.byte $FF, $FF, $FF, $FF, $03, $00, $00, $00, $C0, $FF, $FF, $FF, $FF, $01, $00, $00, $00, $E0, $FF, $FF
	.byte $FF, $FF, $00, $00, $00, $00, $F0, $FF, $FF, $FF, $FF, $00, $00, $00, $00, $F8, $FF, $FF, $FF, $7F
	.byte $00, $00, $00, $00, $FC, $FF, $FF, $FF, $3F, $00, $00, $00, $00, $FE, $FF, $FF, $FF, $1F, $00, $00
	.byte $00, $00, $FF, $FF, $FF, $FF, $0F, $00, $00, $00, $80, $FF, $FF, $FF, $FF, $07, $00, $00, $00, $80
	.byte $FF, $FF, $FF, $FF, $03, $00, $00, $00, $C0, $FF, $FF, $FF, $FF, $01, $00, $00, $00, $E0, $FF, $FF
	.byte $FF, $FF, $00, $00, $00, $00, $F0, $FF, $FF, $FF, $7F, $00, $00, $00, $00, $F8, $FF, $FF, $FF, $3F
	.byte $00, $00, $00, $00, $FC, $FF, $FF, $FF, $1F, $00, $00, $00, $00, $FE, $FF, $FF, $FF, $1F, $00, $00
	.byte $00, $00, $FF, $FF, $FF, $FF, $0F, $00, $00, $00, $80, $FF, $FF, $FF, $FF, $07, $00, $00, $00, $C0
	.byte $FF, $FF, $FF, $FF, $03, $00, $00, $00, $E0, $FF, $FF, $FF, $FF, $01, $00, $00, $00, $F0, $FF, $FF
	.byte $FF, $FF, $00, $00, $00, $00, $F0, $FF, $FF, $FF, $7F, $00, $00, $00, $00, $F8, $FF, $FF, $FF, $3F
	.byte $00, $00, $00, $00, $FC, $FF, $FF, $FF, $1F, $00, $00, $00, $00, $FE, $FF, $FF, $FF, $0F, $00, $00
	.byte $00, $00, $FF, $FF, $FF, $FF, $07, $00, $00, $00, $80, $FF, $FF, $FF, $FF, $03, $00, $00, $00, $C0
	.byte $FF, $FF, $FF, $FF, $03, $00, $00, $00, $E0, $FF, $FF, $FF, $FF, $01, $00, $00, $00, $F0, $FF, $FF
	.byte $FF, $FF, $00, $00, $00, $00, $F8, $FF, $FF, $FF, $7F, $00, $00, $00, $00, $FC, $FF, $FF, $FF, $3F
	.byte $00, $00, $00, $00, $FE, $FF, $FF, $FF, $1F, $00, $00, $00, $00, $FE, $FF, $FF, $FF, $0F, $00, $00
	.byte $00, $00, $FF, $FF, $FF, $FF, $07, $00, $00, $00, $80, $FF, $FF, $FF, $FF, $03, $00, $00, $00, $C0
	.byte $FF, $FF, $FF, $FF, $01, $00, $00, $00, $E0, $FF, $FF, $FF, $FF, $00, $00, $00, $00, $F0, $FF, $FF
	.byte $FF, $7F, $00, $00, $00, $00, $F8, $FF, $FF, $FF, $7F, $00, $00, $00, $00, $FC, $FF, $FF, $FF, $3F
	.byte $00, $00, $00, $00, $FE, $FF, $FF, $FF, $1F, $00, $00, $00, $00, $FF, $FF, $FF, $FF, $0F, $00, $00
	.byte $00, $80, $FF, $FF, $FF, $FF, $07, $00, $00, $00, $C0, $FF, $FF, $FF, $FF, $03, $00, $00, $00, $C0
	.byte $FF, $FF, $FF, $FF, $01, $00, $00, $00, $E0, $FF, $FF, $FF, $FF, $00, $00, $00, $00, $F0, $FF, $FF
	.byte $FF, $7F, $00, $00, $00, $00, $F8, $FF, $FF, $FF, $3F, $00, $00, $00, $00, $FC, $FF, $FF, $FF, $1F
	.byte $00, $00, $00, $00, $FE, $FF, $FF, $FF, $1F, $00, $00, $00, $00, $FF, $FF, $FF, $FF, $0F, $00, $00
	.byte $00, $80, $FF, $FF, $FF, $FF, $07, $00, $00, $00, $C0, $FF, $FF, $FF, $FF, $03, $00, $00, $00, $E0
	.byte $FF, $FF, $FF, $FF, $01, $00, $00, $00, $F0, $FF, $FF, $FF, $FF, $00, $00, $00, $00, $F8, $FF, $FF
	.byte $FF, $7F, $00, $00, $00, $00, $F8, $FF, $FF, $FF, $3F, $00, $00, $00, $00, $FC, $FF, $FF, $FF, $1F
	.byte $00, $00, $00, $00, $FE, $FF, $FF, $FF, $0F, $00, $00, $00, $00, $FF, $FF, $FF, $FF, $07, $00, $00
	.byte $00, $80, $FF, $FF, $FF, $FF, $03, $00, $00, $00, $C0, $FF, $FF, $FF, $FF, $03, $00, $00, $00, $E0
	.byte $FF, $FF, $FF, $FF, $01, $00, $00, $00, $F0, $FF, $FF, $FF, $FF, $00, $00, $00, $00, $F8, $FF, $FF
	.byte $FF, $7F, $00, $00, $00, $00, $FC, $FF, $FF, $FF, $3F, $00, $00, $00, $00, $FE, $FF, $FF, $FF, $1F
	.byte $00, $00, $00, $00, $FF, $FF, $FF, $FF, $0F, $00, $00, $00, $00, $FF, $FF, $FF, $FF, $07, $00, $00
	.byte $00, $80, $FF, $FF, $FF, $FF, $03, $00, $00, $00, $C0, $FF, $FF, $FF, $FF, $01, $00, $00, $00, $E0
	.byte $FF, $FF, $FF, $FF, $00, $00, $00, $00, $F0, $FF, $FF, $FF, $7F, $00, $00, $00, $00, $F8, $FF, $FF
	.byte $FF, $7F, $00, $00, $00, $00, $FC, $FF, $FF, $FF, $3F, $00, $00, $00, $00, $FE, $FF, $FF, $FF, $1F
	.byte $00, $00, $00, $00, $FF, $FF, $FF, $FF, $0F, $00, $00, $00, $80, $FF, $FF, $FF, $FF, $07, $00, $00
	.byte $00, $C0, $FF, $FF, $FF, $FF, $03, $00, $00, $00, $E0, $FF, $FF, $FF, $FF, $01, $00, $00, $00, $E0
	.byte $FF, $FF, $FF, $FF, $00, $00, $00, $00, $F0, $FF, $FF, $FF, $7F, $00, $00, $00, $00, $F8, $FF, $FF
	.byte $FF, $3F, $00, $00, $00, $00, $FC, $FF, $FF, $FF, $1F, $00, $00, $00, $00, $FE, $FF, $FF, $FF, $0F
	.byte $00, $00, $00, $00, $FF, $FF, $FF, $FF, $0F, $00, $00, $00, $80, $FF, $FF, $FF, $FF, $07, $00, $00
	.byte $00, $C0, $FF, $FF, $FF, $FF, $03, $00, $00, $00, $E0, $FF, $FF, $FF, $FF, $01, $00, $00, $00, $F0
	.byte $FF, $FF, $FF, $FF, $00, $00, $00, $00, $F8, $FF, $FF, $FF, $7F, $00, $00, $00, $00, $FC, $FF, $FF
	.byte $FF, $3F, $00, $00, $00, $00, $FC, $FF, $FF, $FF, $1F, $00, $00, $00, $00, $FE, $FF, $FF, $FF, $0F
	.byte $00, $00, $00, $00, $FF, $FF, $FF, $FF, $07, $00, $00, $00, $80, $FF, $FF, $FF, $FF, $03, $00, $00
	.byte $00, $C0, $FF, $FF, $FF, $FF, $01, $00, $00, $00, $E0, $FF, $FF, $FF, $FF, $01, $00, $00, $00, $F0
	.byte $FF, $FF, $FF, $FF, $00, $00, $00, $00, $F8, $FF, $FF, $FF, $7F, $00, $00, $00, $00, $FC, $FF, $FF
	.byte $FF, $3F, $00, $00, $00, $00, $FE, $FF, $FF, $FF, $1F, $00, $00, $00, $00, $FF, $FF, $FF, $FF, $0F
	.byte $00, $00, $00, $80, $FF, $FF, $FF, $FF, $07, $00, $00, $00, $80, $FF, $FF, $FF, $FF, $03, $00, $00
	.byte $00, $C0, $FF, $FF, $FF, $FF, $01, $00, $00, $00, $E0, $FF, $FF, $FF, $FF, $00, $00, $00, $00, $F0
	.byte $FF, $FF, $FF, $7F, $00, $00, $00, $00, $F8, $FF, $FF, $FF, $3F, $00, $00, $00, $00, $FC, $FF, $FF
	.byte $FF, $3F, $00, $00, $00, $00, $FE, $FF, $FF, $FF, $1F, $00, $00, $00, $00, $FF, $FF, $FF, $FF, $0F
	.byte $00, $00, $00, $80, $FF, $FF, $FF, $FF, $07, $00, $00, $00, $C0, $FF, $FF, $FF, $FF, $03, $00, $00
	.byte $00, $E0, $FF, $FF, $FF, $FF, $01, $00, $00, $00, $F0, $FF, $FF, $FF, $FF, $00, $00, $00, $00, $F0
	.byte $FF, $FF, $FF, $7F, $00, $00, $00, $00, $F8, $FF, $FF, $FF, $3F, $00, $00, $00, $00, $FC, $FF, $FF
	.byte $FF, $1F, $00, $00, $00, $00, $FE, $FF, $FF, $FF, $0F, $00, $00, $00, $00, $FF, $FF, $FF, $FF, $07
	.byte $00, $00, $00, $80, $FF, $FF, $FF, $FF, $07, $00, $00, $00, $C0, $FF, $FF, $FF, $FF, $03, $00, $00
	.byte $00, $E0, $FF, $FF, $FF, $FF, $01, $00, $00, $00, $F0, $FF, $FF, $FF, $FF, $00, $00, $00, $00, $F8
	.byte $FF, $FF, $FF, $7F, $00, $00, $00, $00, $FC, $FF, $FF, $FF, $3F, $00, $00, $00, $00, $FE, $FF, $FF
	.byte $FF, $1F, $00, $00, $00, $00, $FE, $FF, $FF, $FF, $0F, $00, $00, $00, $00, $FF, $FF, $FF, $FF, $07
	.byte $00, $00, $00, $80, $FF, $FF, $FF, $FF, $03, $00, $00, $00, $C0, $FF, $FF, $FF, $FF, $01, $00, $00
	.byte $00, $E0, $FF, $FF, $FF, $FF, $00, $00, $00, $00, $F0, $FF, $FF, $FF, $FF, $00, $00, $00, $00, $F8
	.byte $FF, $FF, $FF, $7F, $00, $00, $00, $00, $FC, $FF, $FF, $FF, $3F, $00, $00, $00, $00, $FE, $FF, $FF
	.byte $FF, $1F, $00, $00, $00, $00, $FF, $FF, $FF, $FF, $0F, $00, $00, $00, $80, $FF, $FF, $FF, $FF, $07
	.byte $00, $00, $00, $C0, $FF, $FF, $FF, $FF, $03, $00, $00, $00, $C0, $FF, $FF, $FF, $FF, $01, $00, $00
	.byte $00, $E0, $FF, $FF, $FF, $FF, $00, $00, $00, $00, $F0, $FF, $FF, $FF, $7F, $00, $00, $00, $00, $F8
	.byte $FF, $FF, $FF, $3F, $00, $00, $00, $00, $FC, $FF, $FF, $FF, $1F, $00, $00, $00, $00, $FE, $FF, $FF
	.byte $FF, $1F, $00, $00, $00, $00, $FF, $FF, $FF, $FF, $0F, $00, $00, $00, $80, $FF, $FF, $FF, $FF, $07
	.byte $00, $00, $00, $C0, $FF, $FF, $FF, $FF, $03, $00, $00, $00, $E0, $FF, $FF, $FF, $FF, $01, $00, $00
	.byte $00, $F0, $FF, $FF, $FF, $FF, $00, $00, $00, $00, $F8, $FF, $FF, $FF, $7F, $00, $00, $00, $00, $F8
	.byte $FF, $FF, $FF, $3F, $00, $00, $00, $00, $FC, $FF, $FF, $FF, $1F, $00, $00, $00, $00, $FE, $FF, $FF
	.byte $FF, $0F, $00, $00, $00, $00, $FF, $FF, $FF, $FF, $07, $00, $00, $00, $80, $FF, $FF, $FF, $FF, $03
	.byte $00, $00, $00, $C0, $FF, $FF, $FF, $FF, $03, $00, $00, $00, $E0, $FF, $FF, $FF, $FF, $01, $00, $00
	.byte $00, $F0, $FF, $FF, $FF, $FF, $00, $00, $00, $00, $F8, $FF, $FF, $FF, $7F, $00, $00, $00, $00, $FC
	.byte $FF, $FF, $FF, $3F, $00, $00, $00, $00, $FE, $FF, $FF, $FF, $1F, $00, $00, $00, $00

	.align 64

ft_sample_3: ; puretri-mid-loud-B4
	.byte $FF, $FF, $FF, $FF, $03, $00, $00, $00, $F0, $FF, $FF, $FF, $1F, $00, $00, $00, $80, $FF, $FF, $FF
	.byte $FF, $00, $00, $00, $00, $FC, $FF, $FF, $FF, $07, $00, $00, $00, $E0, $FF, $FF, $FF, $7F, $00, $00
	.byte $00, $00, $FF, $FF, $FF, $FF, $03, $00, $00, $00, $F8, $FF, $FF, $FF, $1F, $00, $00, $00, $C0, $FF
	.byte $FF, $FF, $FF, $00, $00, $00, $00, $FC, $FF, $FF, $FF, $07, $00, $00, $00, $E0, $FF, $FF, $FF, $3F
	.byte $00, $00, $00, $00, $FF, $FF, $FF, $FF, $01, $00, $00, $00, $F8, $FF, $FF, $FF, $1F, $00, $00, $00
	.byte $C0, $FF, $FF, $FF, $FF, $00, $00, $00, $00, $FE, $FF, $FF, $FF, $07, $00, $00, $00, $F0, $FF, $FF
	.byte $FF, $3F, $00, $00, $00, $80, $FF, $FF, $FF, $FF, $01, $00, $00, $00, $F8, $FF, $FF, $FF, $0F, $00
	.byte $00, $00, $C0, $FF, $FF, $FF, $7F, $00, $00, $00, $00, $FE, $FF, $FF, $FF, $03, $00, $00, $00, $F0
	.byte $FF, $FF, $FF, $3F, $00, $00, $00, $80, $FF, $FF, $FF, $FF, $01, $00, $00, $00, $FC, $FF, $FF, $FF
	.byte $0F, $00, $00, $00, $E0, $FF, $FF, $FF, $7F, $00, $00, $00, $00

	.align 64

ft_sample_4: ; puretri-mid-soft-A4
	.byte $FF, $FF, $00, $00, $FF, $FF, $00, $00, $FF, $FF, $00, $00, $FF, $FF, $00, $00, $FF, $FF, $00, $80
	.byte $FF, $7F, $00, $80, $FF, $7F, $00, $80, $FF, $7F, $00, $80, $FF, $7F, $00, $80, $FF, $3F, $00, $C0
	.byte $FF, $3F, $00, $C0, $FF, $3F, $00, $C0, $FF, $3F, $00, $C0, $FF, $3F, $00, $E0, $FF, $1F, $00, $E0
	.byte $FF, $1F, $00, $E0, $FF, $1F, $00, $E0, $FF, $1F, $00, $E0, $FF, $0F, $00, $F0, $FF, $0F, $00, $F0
	.byte $FF, $0F, $00, $F0, $FF, $0F, $00, $F0, $FF, $0F, $00, $F8, $FF, $07, $00, $F8, $FF, $07, $00, $F8
	.byte $FF, $07, $00, $F8, $FF, $07, $00, $F8, $FF, $03, $00, $FC, $FF, $03, $00, $FC, $FF, $03, $00, $FC
	.byte $FF, $03, $00, $FC, $FF, $03, $00, $FE, $FF, $01, $00, $FE, $FF, $01, $00, $FE, $FF, $01, $00, $FE
	.byte $FF, $01, $00, $FE, $FF, $00, $00, $FF, $FF, $00, $00, $FF, $FF, $00, $00, $FF, $FF, $00, $00, $FF
	.byte $FF, $00, $80, $FF, $7F, $00, $80, $FF, $7F, $00, $80, $FF, $7F, $00, $80, $FF, $7F, $00, $80, $FF
	.byte $3F, $00, $C0, $FF, $3F, $00, $C0, $FF, $3F, $00, $C0, $FF, $3F, $00, $C0, $FF, $3F, $00, $E0, $FF
	.byte $1F, $00, $E0, $FF, $1F, $00, $E0, $FF, $1F, $00, $E0, $FF, $1F, $00, $E0, $FF, $0F, $00, $F0, $FF
	.byte $0F, $00, $F0, $FF, $0F, $00, $F0, $FF, $0F, $00, $F0, $FF, $0F, $00, $F0, $FF, $07, $00, $F8, $FF
	.byte $07, $00, $F8, $FF, $07, $00, $F8, $FF, $07, $00, $F8, $FF, $07, $00, $FC, $FF, $03, $00, $FC, $FF
	.byte $03, $00, $FC, $FF, $03, $00, $FC, $FF, $03, $00, $FC, $FF, $01, $00, $FE, $FF, $01, $00, $FE, $FF
	.byte $01, $00, $FE, $FF, $01, $00, $FE, $FF, $01, $00, $FF, $FF, $00, $00, $FF, $FF, $00, $00, $FF, $FF
	.byte $00, $00, $FF, $FF, $00, $00, $FF, $7F, $00, $80, $FF, $7F, $00, $80, $FF, $7F, $00, $80, $FF, $7F
	.byte $00, $80, $FF, $7F, $00, $C0, $FF, $3F, $00, $C0, $FF, $3F, $00, $C0, $FF, $3F, $00, $C0, $FF, $3F
	.byte $00, $C0, $FF, $1F, $00, $E0, $FF, $1F, $00, $E0, $FF, $1F, $00, $E0, $FF, $1F, $00, $E0, $FF, $1F
	.byte $00, $F0, $FF, $0F, $00, $F0, $FF, $0F, $00, $F0, $FF, $0F, $00, $F0, $FF, $0F, $00, $F0, $FF, $07
	.byte $00, $F8, $FF, $07, $00, $F8, $FF, $07, $00, $F8, $FF, $07, $00, $F8, $FF, $07, $00, $FC, $FF, $03
	.byte $00, $FC, $FF, $03, $00, $FC, $FF, $03, $00, $FC, $FF, $03, $00, $FC, $FF, $01, $00, $FE, $FF, $01
	.byte $00, $FE, $FF, $01, $00, $FE, $FF, $01, $00, $FE, $FF, $01, $00

	.align 64

ft_sample_5: ; puretri-mid-soft-Gs4
	.byte $FF, $FF, $01, $00, $FC, $FF, $07, $00, $F0, $FF, $1F, $00, $C0, $FF, $3F, $00, $80, $FF, $FF, $00
	.byte $00, $FE, $FF, $03, $00, $F8, $FF, $07, $00, $F0, $FF, $1F, $00, $C0, $FF, $7F, $00, $00, $FF, $FF
	.byte $00, $00, $FE, $FF, $03, $00, $F8, $FF, $0F, $00, $E0, $FF, $1F, $00, $C0, $FF, $7F, $00, $00, $FF
	.byte $FF, $01, $00, $FC, $FF, $03, $00, $F8, $FF, $0F, $00, $E0, $FF, $3F, $00, $80, $FF, $7F, $00, $00
	.byte $FF, $FF, $01, $00, $FC, $FF, $07, $00, $F0, $FF, $0F, $00, $E0, $FF, $3F, $00, $80, $FF, $FF, $00
	.byte $00, $FE, $FF, $01, $00, $FC, $FF, $07, $00, $F0, $FF, $1F, $00, $C0, $FF, $3F, $00, $80, $FF, $FF
	.byte $00, $00, $FE, $FF, $03, $00, $F8, $FF, $07, $00, $F0, $FF, $1F, $00, $C0, $FF, $7F, $00, $00, $FF
	.byte $FF, $00, $00, $FE, $FF, $03, $00, $F8, $FF, $0F, $00, $E0, $FF, $1F, $00, $C0, $FF, $7F, $00, $00
	.byte $FF, $FF, $01, $00, $FC, $FF, $03, $00, $F8, $FF, $0F, $00, $E0, $FF, $3F, $00, $80, $FF, $7F, $00
	.byte $00, $FF, $FF, $01, $00, $FC, $FF, $07, $00, $F0, $FF, $0F, $00, $E0, $FF, $3F, $00, $80, $FF, $FF
	.byte $00, $00, $FE, $FF, $01, $00, $FC, $FF, $07, $00, $F0, $FF, $1F, $00, $C0, $FF, $3F, $00, $80, $FF
	.byte $FF, $00, $00, $FE, $FF, $03, $00, $F8, $FF, $07, $00, $F0, $FF, $1F, $00, $C0, $FF, $7F, $00, $00
	.byte $FF, $FF, $00, $00, $FE, $FF, $03, $00, $F8, $FF, $0F, $00, $E0, $FF, $1F, $00, $C0, $FF, $7F, $00
	.byte $00, $FF, $FF, $01, $00, $FC, $FF, $03, $00, $F8, $FF, $0F, $00, $E0, $FF, $3F, $00, $80, $FF, $7F
	.byte $00, $00, $FF, $FF, $01, $00, $FC, $FF, $07, $00, $F0, $FF, $0F, $00, $E0, $FF, $3F, $00, $80, $FF
	.byte $FF, $00, $00, $FE, $FF, $01, $00, $FC, $FF, $07, $00, $F0, $FF, $1F, $00, $C0, $FF, $3F, $00, $80
	.byte $FF, $FF, $00, $00, $FE, $FF, $03, $00, $F8, $FF, $07, $00, $F0, $FF, $1F, $00, $C0, $FF, $7F, $00
	.byte $00, $FF, $FF, $00, $00, $FE, $FF, $03, $00, $F8, $FF, $0F, $00, $E0, $FF, $1F, $00, $C0, $FF, $7F
	.byte $00, $00, $FF, $FF, $01, $00, $FC, $FF, $03, $00, $F8, $FF, $0F, $00, $E0, $FF, $3F, $00, $80, $FF
	.byte $7F, $00, $00, $FF, $FF, $01, $00, $FC, $FF, $07, $00, $F0, $FF, $0F, $00, $E0, $FF, $3F, $00, $80
	.byte $FF, $FF, $00, $00, $FE, $FF, $01, $00, $FC, $FF, $07, $00, $F0, $FF, $1F, $00, $C0, $FF, $3F, $00
	.byte $80, $FF, $FF, $00, $00, $FE, $FF, $03, $00, $F8, $FF, $07, $00, $F0, $FF, $1F, $00, $C0, $FF, $7F
	.byte $00, $00, $FF, $FF, $00, $00, $FE, $FF, $03, $00, $F8, $FF, $0F, $00, $E0, $FF, $1F, $00, $C0, $FF
	.byte $7F, $00, $00, $FF, $FF, $01, $00, $FC, $FF, $03, $00, $F8, $FF, $0F, $00, $E0, $FF, $3F, $00, $80
	.byte $FF, $7F, $00, $00, $FF, $FF, $01, $00, $FC, $FF, $07, $00, $F0, $FF, $0F, $00, $E0, $FF, $3F, $00
	.byte $80, $FF, $FF, $00, $00, $FE, $FF, $01, $00, $FC, $FF, $07, $00, $F0, $FF, $1F, $00, $C0, $FF, $3F
	.byte $00, $80, $FF, $FF, $00, $00, $FE, $FF, $03, $00, $F8, $FF, $07, $00, $F0, $FF, $1F, $00, $C0, $FF
	.byte $7F, $00, $00, $FF, $FF, $00, $00, $FE, $FF, $03, $00, $F8, $FF, $0F, $00, $E0, $FF, $1F, $00, $C0
	.byte $FF, $7F, $00, $00, $FF, $FF, $01, $00, $FC, $FF, $03, $00, $F8, $FF, $0F, $00, $E0, $FF, $3F, $00
	.byte $80, $FF, $7F, $00, $00, $FF, $FF, $01, $00, $FC, $FF, $07, $00, $F0, $FF, $0F, $00, $E0, $FF, $3F
	.byte $00, $80, $FF, $FF, $00, $00, $FE, $FF, $01, $00, $FC, $FF, $07, $00, $F0, $FF, $1F, $00, $C0, $FF
	.byte $3F, $00, $80, $FF, $FF, $00, $00, $FE, $FF, $03, $00, $F8, $FF, $07, $00, $F0, $FF, $1F, $00, $C0
	.byte $FF, $7F, $00, $00, $FF, $FF, $00, $00, $FE, $FF, $03, $00, $F8, $FF, $0F, $00, $E0, $FF, $1F, $00
	.byte $C0, $FF, $7F, $00, $00, $FF, $FF, $01, $00, $FC, $FF, $03, $00, $F8, $FF, $0F, $00, $E0, $FF, $3F
	.byte $00, $80, $FF, $7F, $00, $00, $FF, $FF, $01, $00, $FC, $FF, $07, $00, $F0, $FF, $0F, $00, $E0, $FF
	.byte $3F, $00, $80, $FF, $FF, $00, $00, $FE, $FF, $03, $00, $FC, $FF, $07, $00, $F0, $FF, $1F, $00, $C0
	.byte $FF, $7F, $00, $80, $FF, $FF, $00, $00, $FE, $FF, $03, $00, $F8, $FF, $0F, $00, $F0, $FF, $1F, $00
	.byte $C0, $FF, $7F, $00, $00, $FF, $FF, $01, $00, $FE, $FF, $03, $00, $F8, $FF, $0F, $00, $E0, $FF, $3F
	.byte $00, $C0, $FF, $7F, $00, $00, $FF, $FF, $01, $00, $FC, $FF, $07, $00, $F8, $FF, $0F, $00, $E0, $FF
	.byte $3F, $00, $80, $FF, $FF, $00, $00, $FF, $FF, $01, $00, $FC, $FF, $07, $00, $F0, $FF, $1F, $00, $E0
	.byte $FF, $3F, $00, $80, $FF, $FF, $00, $00, $FE, $FF, $03, $00, $FC, $FF, $07, $00, $F0, $FF, $1F, $00
	.byte $C0, $FF, $7F, $00, $80, $FF, $FF, $00, $00, $FE, $FF, $03, $00, $F8, $FF, $0F, $00, $F0, $FF, $1F
	.byte $00, $C0, $FF, $7F, $00, $00, $FF, $FF, $01, $00, $FE, $FF, $03, $00, $F8, $FF, $0F, $00, $E0, $FF
	.byte $3F, $00, $C0, $FF, $7F, $00, $00, $FF, $FF, $01, $00, $FC, $FF, $07, $00, $F8, $FF, $0F, $00, $E0
	.byte $FF, $3F, $00, $80, $FF, $FF, $00, $00, $FF, $FF, $01, $00, $FC, $FF, $07, $00, $F0, $FF, $1F, $00
	.byte $E0, $FF, $3F, $00, $80, $FF, $FF, $00, $00, $FE, $FF, $03, $00, $FC, $FF, $07, $00, $F0, $FF, $1F
	.byte $00, $C0, $FF, $7F, $00, $80, $FF, $FF, $00, $00, $FE, $FF, $03, $00, $F8, $FF, $0F, $00, $F0, $FF
	.byte $1F, $00, $C0, $FF, $7F, $00, $00, $FF, $FF, $01, $00, $FE, $FF, $03, $00, $F8, $FF, $0F, $00, $E0
	.byte $FF, $3F, $00, $C0, $FF, $7F, $00, $00, $FF, $FF, $01, $00, $FC, $FF, $07, $00, $F8, $FF, $0F, $00
	.byte $E0, $FF, $3F, $00, $80, $FF, $FF, $00, $00, $FF, $FF, $01, $00, $FC, $FF, $07, $00, $F0, $FF, $1F
	.byte $00, $E0, $FF, $3F, $00, $80, $FF, $FF, $00, $00, $FE, $FF, $03, $00, $FC, $FF, $07, $00, $F0, $FF
	.byte $1F, $00, $C0, $FF, $7F, $00, $80, $FF, $FF, $00, $00, $FE, $FF, $03, $00, $F8, $FF, $0F, $00, $F0
	.byte $FF, $1F, $00, $C0, $FF, $7F, $00, $00, $FF, $FF, $01, $00, $FE, $FF, $03, $00, $F8, $FF, $0F, $00
	.byte $E0, $FF, $3F, $00, $C0, $FF, $7F, $00, $00, $FF, $FF, $01, $00, $FC, $FF, $07, $00, $F8, $FF, $0F
	.byte $00, $E0, $FF, $3F, $00, $80, $FF, $FF, $00, $00, $FF, $FF, $01, $00, $FC, $FF, $07, $00, $F0, $FF
	.byte $1F, $00, $E0, $FF, $3F, $00, $80, $FF, $FF, $00, $00, $FE, $FF, $03, $00, $FC, $FF, $07, $00, $F0
	.byte $FF, $1F, $00, $C0, $FF, $7F, $00, $80, $FF, $FF, $00, $00, $FE, $FF, $03, $00, $F8, $FF, $0F, $00
	.byte $F0, $FF, $1F, $00, $C0, $FF, $7F, $00, $00, $FF, $FF, $01, $00, $FE, $FF, $03, $00, $F8, $FF, $0F
	.byte $00, $E0, $FF, $3F, $00, $C0, $FF, $7F, $00, $00, $FF, $FF, $01, $00, $FC, $FF, $07, $00, $F8, $FF
	.byte $0F, $00, $E0, $FF, $3F, $00, $80, $FF, $FF, $00, $00, $FF, $FF, $01, $00, $FC, $FF, $07, $00, $F0
	.byte $FF, $1F, $00, $E0, $FF, $3F, $00, $80, $FF, $FF, $00, $00, $FE, $FF, $03, $00, $FC, $FF, $07, $00
	.byte $F0, $FF, $1F, $00, $C0, $FF, $7F, $00, $80, $FF, $FF, $00, $00, $FE, $FF, $03, $00, $F8, $FF, $0F
	.byte $00, $F0, $FF, $1F, $00, $C0, $FF, $7F, $00, $00, $FF, $FF, $01, $00, $FE, $FF, $03, $00, $F8, $FF
	.byte $0F, $00, $E0, $FF, $3F, $00, $C0, $FF, $7F, $00, $00, $FF, $FF, $01, $00, $FC, $FF, $07, $00, $F8
	.byte $FF, $0F, $00, $E0, $FF, $3F, $00, $80, $FF, $FF, $00, $00, $FF, $FF, $01, $00, $FC, $FF, $07, $00
	.byte $F0, $FF, $1F, $00, $E0, $FF, $3F, $00, $80, $FF, $FF, $00, $00, $FE, $FF, $03, $00, $FC, $FF, $07
	.byte $00, $F0, $FF, $1F, $00, $C0, $FF, $7F, $00, $80, $FF, $FF, $00, $00, $FE, $FF, $03, $00, $F8, $FF
	.byte $0F, $00, $F0, $FF, $1F, $00, $C0, $FF, $7F, $00, $00, $FF, $FF, $01, $00, $FE, $FF, $03, $00, $F8
	.byte $FF, $0F, $00, $E0, $FF, $3F, $00, $C0, $FF, $7F, $00, $00, $FF, $FF, $01, $00, $FC, $FF, $07, $00
	.byte $F8, $FF, $0F, $00, $E0, $FF, $3F, $00, $80, $FF, $FF, $00, $00

	.align 64

ft_sample_6: ; puretri-mid-soft-As4
	.byte $FF, $7F, $00, $C0, $FF, $1F, $00, $F0, $FF, $07, $00, $FC, $FF, $01, $00, $FF, $7F, $00, $C0, $FF
	.byte $1F, $00, $F0, $FF, $07, $00, $FC, $FF, $01, $00, $FF, $7F, $00, $C0, $FF, $1F, $00, $F0, $FF, $07
	.byte $00, $FC, $FF, $01, $00, $FF, $7F, $00, $C0, $FF, $1F, $00, $F0, $FF, $07, $00, $FC, $FF, $01, $00
	.byte $FF, $7F, $00, $C0, $FF, $1F, $00, $F0, $FF, $07, $00, $FC, $FF, $01, $00, $FF, $7F, $00, $C0, $FF
	.byte $1F, $00, $F0, $FF, $07, $00, $FC, $FF, $01, $00, $FF, $7F, $00, $C0, $FF, $1F, $00, $F0, $FF, $07
	.byte $00, $FC, $FF, $01, $00, $FF, $7F, $00, $C0, $FF, $1F, $00, $F0, $FF, $07, $00, $FC, $FF, $01, $00
	.byte $FF, $7F, $00, $C0, $FF, $1F, $00, $F0, $FF, $07, $00, $FC, $FF, $01, $00, $FF, $7F, $00, $C0, $FF
	.byte $1F, $00, $F0, $FF, $07, $00, $FC, $FF, $01, $00, $FF, $7F, $00, $C0, $FF, $1F, $00, $F0, $FF, $07
	.byte $00, $FC, $FF, $01, $00, $FF, $7F, $00, $C0, $FF, $1F, $00, $F0, $FF, $07, $00, $FC, $FF, $01, $00
	.byte $FF, $7F, $00, $C0, $FF, $1F, $00, $F0, $FF, $07, $00, $FC, $FF, $01, $00, $FF, $7F, $00, $C0, $FF
	.byte $1F, $00, $F0, $FF, $07, $00, $FC, $FF, $01, $00, $FF, $7F, $00, $C0, $FF, $1F, $00, $F0, $FF, $07
	.byte $00, $FC, $FF, $01, $00, $FF, $7F, $00, $C0, $FF, $1F, $00, $F0, $FF, $07, $00, $FC, $FF, $01, $00
	.byte $FF, $7F, $00, $C0, $FF, $1F, $00, $F0, $FF, $07, $00, $FC, $FF, $01, $00, $FF, $7F, $00, $C0, $FF
	.byte $1F, $00, $F0, $FF, $07, $00, $FC, $FF, $01, $00, $FF, $7F, $00, $C0, $FF, $1F, $00, $F0, $FF, $07
	.byte $00, $FC, $FF, $01, $00, $FF, $7F, $00, $C0, $FF, $1F, $00, $F0, $FF, $07, $00, $FC, $FF, $01, $00
	.byte $FF, $7F, $00, $C0, $FF, $1F, $00, $F0, $FF, $07, $00, $FC, $FF, $01, $00, $FF, $7F, $00, $C0, $FF
	.byte $1F, $00, $F0, $FF, $07, $00, $FC, $FF, $01, $00, $FF, $7F, $00, $C0, $FF, $1F, $00, $F0, $FF, $07
	.byte $00, $FC, $FF, $01, $00, $FF, $7F, $00, $C0, $FF, $1F, $00, $F0, $FF, $07, $00, $FC, $FF, $01, $00
	.byte $FF, $7F, $00, $C0, $FF, $1F, $00, $F0, $FF, $07, $00, $FC, $FF, $01, $00, $FF, $7F, $00, $C0, $FF
	.byte $1F, $00, $F0, $FF, $07, $00, $FC, $FF, $01, $00, $FF, $7F, $00, $C0, $FF, $1F, $00, $F0, $FF, $07
	.byte $00, $FC, $FF, $01, $00, $FF, $7F, $00, $C0, $FF, $1F, $00, $F0, $FF, $07, $00, $FC, $FF, $01, $00
	.byte $FF, $7F, $00, $C0, $FF, $1F, $00, $F0, $FF, $07, $00, $FC, $FF, $01, $00, $FF, $7F, $00, $C0, $FF
	.byte $1F, $00, $F8, $FF, $03, $00, $FE, $FF, $00, $80, $FF, $3F, $00, $E0, $FF, $0F, $00, $F8, $FF, $03
	.byte $00, $FE, $FF, $00, $80, $FF, $3F, $00, $E0, $FF, $0F, $00, $F8, $FF, $03, $00, $FE, $FF, $00, $80
	.byte $FF, $3F, $00, $E0, $FF, $0F, $00, $F8, $FF, $03, $00, $FE, $FF, $00, $80, $FF, $3F, $00, $E0, $FF
	.byte $0F, $00, $F8, $FF, $03, $00, $FE, $FF, $00, $80, $FF, $3F, $00, $E0, $FF, $0F, $00, $F8, $FF, $03
	.byte $00, $FE, $FF, $00, $80, $FF, $3F, $00, $E0, $FF, $0F, $00, $F8, $FF, $03, $00, $FE, $FF, $00, $80
	.byte $FF, $3F, $00, $E0, $FF, $0F, $00, $F8, $FF, $03, $00, $FE, $FF, $00, $80, $FF, $3F, $00, $E0, $FF
	.byte $0F, $00, $F8, $FF, $03, $00, $FE, $FF, $00, $80, $FF, $3F, $00, $E0, $FF, $0F, $00, $F8, $FF, $03
	.byte $00, $FE, $FF, $00, $80, $FF, $3F, $00, $E0, $FF, $0F, $00, $F8, $FF, $03, $00, $FE, $FF, $00, $80
	.byte $FF, $3F, $00, $E0, $FF, $0F, $00, $F8, $FF, $03, $00, $FE, $FF, $00, $80, $FF, $3F, $00, $E0, $FF
	.byte $0F, $00, $F8, $FF, $03, $00, $FE, $FF, $00, $80, $FF, $3F, $00, $E0, $FF, $0F, $00, $F8, $FF, $03
	.byte $00, $FE, $FF, $00, $80, $FF, $3F, $00, $E0, $FF, $0F, $00, $F8, $FF, $03, $00, $FE, $FF, $00, $80
	.byte $FF, $3F, $00, $E0, $FF, $0F, $00, $F8, $FF, $03, $00, $FE, $FF, $00, $80, $FF, $3F, $00, $E0, $FF
	.byte $0F, $00, $F8, $FF, $03, $00, $FE, $FF, $00, $80, $FF, $3F, $00, $E0, $FF, $0F, $00, $F8, $FF, $03
	.byte $00, $FE, $FF, $00, $80, $FF, $3F, $00, $E0, $FF, $0F, $00, $F8, $FF, $03, $00, $FE, $FF, $00, $80
	.byte $FF, $3F, $00, $E0, $FF, $0F, $00, $F8, $FF, $03, $00, $FE, $FF, $00, $80, $FF, $3F, $00, $E0, $FF
	.byte $0F, $00, $F8, $FF, $03, $00, $FE, $FF, $00, $80, $FF, $3F, $00, $E0, $FF, $0F, $00, $F8, $FF, $03
	.byte $00, $FE, $FF, $00, $80, $FF, $3F, $00, $E0, $FF, $0F, $00, $F8, $FF, $03, $00, $FE, $FF, $00, $80
	.byte $FF, $3F, $00, $E0, $FF, $0F, $00, $F8, $FF, $03, $00, $FE, $FF, $00, $80, $FF, $3F, $00, $E0, $FF
	.byte $0F, $00, $F8, $FF, $03, $00, $FE, $FF, $00, $80, $FF, $3F, $00, $E0, $FF, $0F, $00, $F8, $FF, $03
	.byte $00, $FE, $FF, $00, $80, $FF, $3F, $00, $E0, $FF, $0F, $00, $F8, $FF, $03, $00, $FE, $FF, $00, $80
	.byte $FF, $3F, $00, $E0, $FF, $0F, $00, $F8, $FF, $03, $00, $FE, $FF, $00, $80, $FF, $3F, $00, $E0, $FF
	.byte $0F, $00, $F8, $FF, $03, $00, $FE, $FF, $00, $80, $FF, $3F, $00, $E0, $FF, $0F, $00, $F8, $FF, $03
	.byte $00

	.align 64


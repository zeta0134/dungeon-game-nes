.import test_tiles_3d_chr

test_tiles_3d_tileset:
  .byte <.bank(test_tiles_3d_chr) ; CHR bank
  .byte 8 ; metatile count
  .byte $01 ; compression type
  .word $0028 ; decompressed length in bytes
              ; compressed length: $001B, ratio: 1.48:1 
  .byte $07, $00, $01, $01, $00, $03, $04, $05, $06, $01, $00, $02, $11, $42, $00, $07
  .byte $83, $08, $41, $00, $08, $83, $42, $00, $09, $69, $0d


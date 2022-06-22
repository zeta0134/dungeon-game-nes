.import test_tiles_3d_chr

test_tiles_3d_tileset:
  .byte <.bank(test_tiles_3d_chr) ; CHR bank
  .byte 8 ; metatile count
  .byte $00 ; compression type
  .word $0028 ; decompressed length in bytes
              ; compressed length: $0028, ratio: 1.00:1 
  .byte $00, $01, $01, $00, $03, $04, $05, $06, $00, $02, $00, $02, $03, $04, $05, $07
  .byte $00, $01, $01, $00, $00, $04, $05, $08, $00, $02, $00, $02, $00, $04, $05, $09
  .byte $00, $00, $00, $00, $00, $00, $00, $00


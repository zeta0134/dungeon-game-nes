; Collection of helpers and shortcuts for dealing with PPU registers

.macro set_ppuaddr addr
  lda #>(addr)
  sta PPUADDR
  lda #<(addr)
  sta PPUADDR
.endmacro


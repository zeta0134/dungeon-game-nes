#!/usr/bin/env python
#
# WIP. Should eventually convert a .tsx tileset from Tiled into
# the CHR data and engine metadata for display.

from PIL import Image

def bytes_to_palette(byte_array):
  return [(byte_array[i], byte_array[i+1], byte_array[i+2]) for i in range(0, len(byte_array), 3)]

def read_nes_palette(filename):
  with open(filename, "rb") as binary_file:
    data = binary_file.read()
    return bytes_to_palette(data)

def rgb_to_nes(color, palette):
  # Note: we work in reverse order mainly to avoid a hardware quirk:
  # the canonical code for black is 0x0F, but if we work forwards, we'll
  # end up with 0x0D instead, which is "blacker than black" and causes
  # NTSC signaling issues. Working backwards prefers the canonical color
  # in most cases.
  chosen_index = 63
  chosen_distance = 768
  for i in reversed(range(0, 64)):
    distance_r = abs(color[0] - palette[i][0])
    distance_g = abs(color[1] - palette[i][1])
    distance_b = abs(color[2] - palette[i][2])
    distance = distance_r + distance_g + distance_b
    if distance < chosen_distance:
      chosen_index = i
      chosen_distance = distance
  return chosen_index

def bits_to_byte(bit_array):
  byte = 0
  for i in range(0,8):
    byte = byte << 1;
    byte = byte + bit_array[i];
  return byte

def hardware_tile_to_bitplane(index_array):
  # Note: expects an 8x8 array of tile indices. Returns a 16-byte array of raw NES data
  # which encodes this tile's data as a bitplane for the PPU hardware
  low_bits = [x & 0x1 for x in index_array]
  high_bits = [x & 0x1 for x in index_array]
  low_bytes = [bits_to_byte(low_bits[i:i+8]) for i in range(0,64,8)]
  high_bytes = [bits_to_byte(high_bits[i:i+8]) for i in range(0,64,8)]
  return low_bytes + high_bytes

def read_tile(filename, nespalette):
  im = Image.open(filename)
  assert(im.getpalette() != None, "Non-paletted tile found! This is unsupported: " + filename)
  rgb_palette = bytes_to_palette(im.getpalette()[0:12])
  nes_palette = [rgb_to_nes(color, nespalette) for color in rgb_palette]
  assert(im.width == 16, "All tiles must be 16 pixels wide! Bailing. " + filename)
  assert(im.height == 16, "All tiles must be 16 pixels tall! Bailing. " + filename)
  chr_tl = hardware_tile_to_bitplane(im.crop((0, 0,  8,  8)).getdata())
  chr_tr = hardware_tile_to_bitplane(im.crop((8, 0, 16,  8)).getdata())
  chr_bl = hardware_tile_to_bitplane(im.crop((0, 8,  8, 16)).getdata())
  chr_br = hardware_tile_to_bitplane(im.crop((8, 8, 16, 16)).getdata())
  return {
    "palette": nes_palette,
    "chr": [chr_tl, chr_tr, chr_bl, chr_br]
  }

nespalette = read_nes_palette("ntscpalette.pal")
        
tile = read_tile("../art/tiles/hole.png", nespalette)
print("Tile palette: ", [hex(i) for i in tile["palette"]])

print("Top left corner: ")
for byte in tile["chr"][0]: print(format(byte, '#010b')) 


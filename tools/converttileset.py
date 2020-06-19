#!/usr/bin/env python3
#
# WIP. Should eventually convert a .tsx tileset from Tiled into
# the CHR data and engine metadata for display.

from PIL import Image
from pathlib import Path
import xml.etree.ElementTree as ElementTree
import sys, os

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
  high_bits = [((x & 0x2) >> 1) for x in index_array]
  low_bytes = [bits_to_byte(low_bits[i:i+8]) for i in range(0,64,8)]
  high_bytes = [bits_to_byte(high_bits[i:i+8]) for i in range(0,64,8)]
  return low_bytes + high_bytes

def read_tile(filename, nespalette):
  im = Image.open(filename)
  assert im.getpalette() != None, "Non-paletted tile found! This is unsupported: " + filename
  rgb_palette = bytes_to_palette(im.getpalette()[0:12])
  nes_palette = [rgb_to_nes(color, nespalette) for color in rgb_palette]
  assert im.width == 16, "All tiles must be 16 pixels wide! Bailing. " + filename
  assert im.height == 16, "All tiles must be 16 pixels tall! Bailing. " + filename
  chr_tl = hardware_tile_to_bitplane(im.crop((0, 0,  8,  8)).getdata())
  chr_tr = hardware_tile_to_bitplane(im.crop((8, 0, 16,  8)).getdata())
  chr_bl = hardware_tile_to_bitplane(im.crop((0, 8,  8, 16)).getdata())
  chr_br = hardware_tile_to_bitplane(im.crop((8, 8, 16, 16)).getdata())
  return {
    "palette": nes_palette,
    "chr": [chr_tl, chr_tr, chr_bl, chr_br]
  }

def read_tileset(filename, nespalette):
  tileset_element = ElementTree.parse(filename).getroot()
  tile_elements = tileset_element.findall("tile")
  image_elements = [tile.find("image") for tile in tile_elements]
  image_filenames = [image.get("source") for image in image_elements]
  
  # tileset filenames are relative to the tileset file's location, so
  # turn those into absolute paths:
  base_path = Path(filename).parent;
  image_filenames = [(base_path / file_path).resolve() for file_path in image_filenames]
  tiles = [read_tile(filename, nespalette) for filename in image_filenames]
  return tiles

def generate_base_palettes(tiles):
  palettes = []
  for tile in tiles:
    if not tile["palette"] in palettes:
      palettes.append(tile["palette"])
    tile["palette_index"] = palettes.index(tile["palette"])
  assert len(palettes) <= 4, "Base tileset cannot contain more than 4 palettes!"
  return palettes

def generate_chr_tiles(metatiles):
  chr_tiles = []
  for tile in metatiles:
    tile["chr_indices"] = [0,0,0,0]
    for c in range(0,4):
      if not tile["chr"][c] in chr_tiles:
        chr_tiles.append(tile["chr"][c])
      tile["chr_indices"][c] = chr_tiles.index(tile["chr"][c])
  return chr_tiles

def write_chr_tiles(chr_tiles, filename):
  with open(filename, "wb") as output_file:
    for tile in chr_tiles:
      output_file.write(bytes(tile))

def write_meta_tiles(metatiles, filename):
  with open(filename, "wb") as output_file:
    for tile in metatiles:
      output_file.write(bytes(tile["chr_indices"]))

def write_palettes(palettes, filename):
  with open(filename, "wb") as output_file:
    for palette in palettes:
      output_file.write(bytes(palette))

if len(sys.argv) != 5:
  print("Usage: convertileset.py input.tsx output.chr output.mt output.pal")
  sys.exit(-1)
input_tileset = sys.argv[1]
output_chr = sys.argv[2]
output_mt = sys.argv[3]
output_pal = sys.argv[4]

scriptdir = os.path.dirname(__file__)
nespalette = read_nes_palette(os.path.join(scriptdir,"ntscpalette.pal"))
tiles = read_tileset(input_tileset, nespalette)
        
print("Read:", len(tiles), "tiles!")
palettes = generate_base_palettes(tiles)
print("Found", len(palettes), "unique palettes!")
chr_tiles = generate_chr_tiles(tiles)
print("Found", len(chr_tiles), "unique 8x8 tiles!")

write_chr_tiles(chr_tiles, output_chr)
write_meta_tiles(tiles, output_mt)
write_palettes(palettes, output_pal)

#tile = read_tile("../art/tiles/hole.png", nespalette)
#print("Tile palette: ", [hex(i) for i in tile["palette"]])

#print("Top left corner: ")
#for byte in tile["chr"][0]: print(format(byte, '#010b')) 


#!/usr/bin/env python3
from PIL import Image
import pathlib
from pathlib import Path

from ca65 import pretty_print_table, ca65_label, ca65_byte_literal, ca65_word_literal
from compress import compress_smallest
import os, json, re, sys

supported_tile_types = {
  "NORMAL": 0,
  "EXIT": 1,
  "HAZARD": 2,
  "SHALLOW_WATER": 3,
  "DEEP_WATER": 4,
  "BUTTON": 5,
  "INTERACT": 6,
}

def bits_to_byte(bit_array):
  byte = 0
  for i in range(0,8):
    byte = byte << 1;
    byte = byte + bit_array[i];
  return byte

def hardware_tile_to_bitplane(index_array):
  # Note: expects an 8x8 array of palette indices. Returns a 16-byte array of raw NES data
  # which encodes this tile's data as a bitplane for the PPU hardware
  low_bits = [x & 0x1 for x in index_array]
  high_bits = [((x & 0x2) >> 1) for x in index_array]
  low_bytes = [bits_to_byte(low_bits[i:i+8]) for i in range(0,64,8)]
  high_bytes = [bits_to_byte(high_bits[i:i+8]) for i in range(0,64,8)]
  return low_bytes + high_bytes

def read_tile(filename):
  im = Image.open(filename)
  assert im.getpalette() != None, "Non-paletted tile found! This is unsupported: " + filename
  assert im.width == 16, "All tiles must be 16 pixels wide! Bailing. " + filename
  assert im.height == 16, "All tiles must be 16 pixels tall! Bailing. " + filename
  chr_tl = hardware_tile_to_bitplane(im.crop((0, 0,  8,  8)).getdata())
  chr_tr = hardware_tile_to_bitplane(im.crop((8, 0, 16,  8)).getdata())
  chr_bl = hardware_tile_to_bitplane(im.crop((0, 8,  8, 16)).getdata())
  chr_br = hardware_tile_to_bitplane(im.crop((8, 8, 16, 16)).getdata())
  return {
    "chr": [chr_tl, chr_tr, chr_bl, chr_br]
  }

def read_tileset(folderpath):
  filenames = os.listdir(folderpath)
  png_files = sorted([f for f in filenames if pathlib.Path(f).suffix == ".png"])
  metadata_path = (Path(folderpath) / "metadata.json").resolve()
  metadata = {}
  
  if os.path.isfile(metadata_path):
    with open(metadata_path, "r") as metadata_file:
      metadata = json.load(metadata_file)

  image_filenames = [(Path(folderpath) / filename).resolve() for filename in png_files]
  tiles = [read_tile(filename) for filename in image_filenames]
  for i in range(0, len(tiles)):
    tiles[i]["type"] = supported_tile_types["NORMAL"]
    for type_name, type_filenames in metadata.items():
      if png_files[i] in type_filenames:
        tiles[i]["type"] = supported_tile_types[type_name]
  return tiles

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
  chr_bytes = []
  for tile in chr_tiles:
    chr_bytes = chr_bytes + tile
  with open(filename, "w") as output_file:
    chr_label = nice_label(filename)+"_chr"

    output_file.write(".export %s\n\n" % chr_label)
    output_file.write(ca65_label(chr_label) + "\n")
    pretty_print_table(chr_bytes, output_file, 16)
    output_file.write("\n")

def nice_label(full_path_and_filename):
  (_, plain_filename) = os.path.split(full_path_and_filename)
  (base_filename, _) = os.path.splitext(plain_filename)
  safe_label = re.sub(r'[^A-Za-z0-9\-\_]', '_', base_filename)
  return safe_label

def attribute_byte(metatile):
  return ((metatile["type"]) << 2) & 0xFF

def write_meta_tiles(metatiles, filename):
  with open(filename, "w") as output_file:
    top_left_corners = []
    top_right_corners = []
    bottom_left_corners = []
    bottom_right_corners = []
    attribute_bytes = []
    for tile in metatiles:
      top_left_corners.append(tile["chr_indices"][0])
      top_right_corners.append(tile["chr_indices"][1])
      bottom_left_corners.append(tile["chr_indices"][2])
      bottom_right_corners.append(tile["chr_indices"][3])
      attribute_bytes.append(attribute_byte(tile))
    raw_metatile_bytes = top_left_corners + top_right_corners + bottom_left_corners + bottom_right_corners + attribute_bytes
    compression_type, compressed_bytes = compress_smallest(raw_metatile_bytes)

    metatile_label = nice_label(filename)+"_tileset"
    chr_label = nice_label(filename)+"_chr"

    output_file.write(".import %s\n\n" % chr_label)

    output_file.write(ca65_label(metatile_label) + "\n")
    output_file.write("  .byte <.bank(%s) ; CHR bank\n" % chr_label)
    output_file.write("  .byte %s ; metatile count\n" % len(metatiles))
    output_file.write("  .byte %s ; compression type\n" % ca65_byte_literal(compression_type))
    output_file.write("  .word %s ; decompressed length in bytes\n" % ca65_word_literal(len(raw_metatile_bytes)))
    output_file.write("              ; compressed length: $%04X, ratio: %.2f:1 \n" % (len(compressed_bytes), len(raw_metatile_bytes) / len(compressed_bytes)))
    pretty_print_table(compressed_bytes, output_file, 16)
    output_file.write("\n")

if __name__ == '__main__':
  if len(sys.argv) != 4:
    print("Usage: convertpatternset.py folder/with/tiles output.chr output.mt")
    sys.exit(-1)
  input_folder = sys.argv[1]
  output_chr = sys.argv[2]
  output_mt = sys.argv[3]

  tiles = read_tileset(input_folder)

  chr_tiles = generate_chr_tiles(tiles)
  write_chr_tiles(chr_tiles, output_chr)
  write_meta_tiles(tiles, output_mt)
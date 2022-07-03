#!/usr/bin/env python3
from PIL import Image
import os, sys

from convertpatternset import hardware_tile_to_bitplane, nice_label
from ca65 import pretty_print_table, ca65_label, ca65_byte_literal, ca65_word_literal

def read_font_image(filename):
  im = Image.open(filename)
  assert im.getpalette() != None, "Non-paletted tile found! This is unsupported: " + filename
  assert (im.width % 8) == 0, "Width should be a multiple of 8px! Bailing. " + filename
  assert (im.height % 16) == 0, "Height should be a multiple of 16px! Bailing. " + filename

  high_tiles = []
  low_tiles = []

  for y in range(0, im.height, 16):
    for x in range(0, im.width, 8):
      high_tiles.append(hardware_tile_to_bitplane(im.crop((x, y,  x+8,  y+8)).getdata()))
      low_tiles.append(hardware_tile_to_bitplane(im.crop((x, y+8,  x+8,  y+16)).getdata()))

  return high_tiles, low_tiles

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

if __name__ == '__main__':
    # DEBUG TEST THINGS
    if len(sys.argv) != 4:
      print("Usage: convertfont.py input.tmx output_high.chr output_low.chr")
      sys.exit(-1)
    input_filename = sys.argv[1]
    output_high_filename = sys.argv[2]
    output_low_filename = sys.argv[3]

    high_tiles, low_tiles = read_font_image(input_filename)
    write_chr_tiles(high_tiles, output_high_filename)
    write_chr_tiles(low_tiles, output_low_filename)
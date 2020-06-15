#!/usr/bin/env python
#
# Converts a map created by the Tiled editor, stored in .tmx format, to the internal
# representation used by the NES engine. Very much project specific, not general
# purpose at all.

import xml.etree.ElementTree as ElementTree
import sys

if len(sys.argv) != 3:
  print("Usage: convertmap.py input.tmx output.bin")
  sys.exit(-1)
input_file = sys.argv[1]
output_file = sys.argv[2]

map_element = ElementTree.parse(input_file).getroot()
width = int(map_element.get("width"))
height = int(map_element.get("height"))

layer = map_element.find("layer")
tileset = map_element.find("tileset")
tileset_base = int(tileset.get("firstgid"))
data = layer.find("data")

def tileset_index_to_metatile_index(tile_index, tileset_base):
  zero_based_tile_index = tile_index - tileset_base
  premultiplied_tile_index = zero_based_tile_index * 4
  return premultiplied_tile_index

if data.get("encoding") == "csv":
    cell_values = [tileset_index_to_metatile_index(int(x), tileset_base) for x in data.text.split(",")]
    # encode!
    with open(output_file, "wb") as output:
      output.write(bytes([width,height]))
      output.write(bytes(cell_values))
else:
  print("ERROR: non-csv encoding is not supported. Bailing.")
  sys.exit(-1)

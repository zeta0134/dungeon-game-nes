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
data = layer.find("data")

if data.get("encoding") == "csv":
    cell_values = [int(x) for x in data.text.split(",")]
    # encode!
    with open(output_file, "wb") as output:
      output.write(bytes([width,height]))
      output.write(bytes(cell_values))
else:
  print("ERROR: non-csv encoding is not supported. Bailing.")
  sys.exit(-1)

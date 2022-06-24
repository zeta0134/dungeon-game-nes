#!/usr/bin/env python3
import sys

from ca65 import pretty_print_table, ca65_label, ca65_byte_literal
from convertmap import generate_collision_tileset

# A short utility script to generate the lookup table for the collision system,
# using the same tiles and in the same order that the map exporter uses to generate
# the map. This ensures that the indexes are always in sync, even if I change the
# exact tile makeup down the road.

collision_tiles = generate_collision_tileset()

def height_byte(tile):
  low_nybble = tile.integer_properties.get("floor_height", 0)
  high_nybble = tile.integer_properties.get("hidden_floor_height", 0)
  return (high_nybble << 4) | low_nybble

def flags_byte(tile):
  is_floor_bit = int(tile.boolean_properties.get("is_floor", False))
  is_hidden_floor_bit = int(tile.boolean_properties.get("is_hidden_floor", False))
  return (is_floor_bit << 7) | (is_hidden_floor_bit << 6)

if __name__ == '__main__':
  # DEBUG TEST THINGS
  if len(sys.argv) != 2:
    print("Usage: collisiontileset.py output_file")
    sys.exit(-1)
  output_filename = sys.argv[1]

  height_bytes = [height_byte(t) for t in collision_tiles]
  flags_bytes = [flags_byte(t) for t in collision_tiles]

  with open(output_filename, "w") as output_file:
    output_file.write(ca65_label("collision_heights") + "\n")
    pretty_print_table(height_bytes, output_file)
    output_file.write("\n")
    output_file.write(ca65_label("collision_flags") + "\n")
    pretty_print_table(flags_bytes, output_file)
    output_file.write("\n")

#!/usr/bin/env python3
import xml.etree.ElementTree as ElementTree
import os, re, sys

from dataclasses import dataclass, field
from pathlib import Path
from typing import Dict

# === Data Types ===
# Note: concerned with data for map conversion only. We ignore everything else.
# Graphics conversion is a separate step entirely.

# Base tiles, read directly from a tileset
@dataclass
class TiledTile:
    tiled_index: int
    ordinal_index: int
    integer_properties: Dict[str, int]
    boolean_properties: Dict[str, bool]

@dataclass
class TiledTileSet:
    first_gid: int
    tiles: Dict[int, TiledTile]

BLANK_TILE = TiledTile(tiled_index=0, ordinal_index=0, integer_properties={}, boolean_properties={})

@dataclass
class CombinedMap:
    name: str
    width: int
    height: int
    tiles: [TiledTile]

def read_boolean_properties(tile_element):
    boolean_properties = {}
    properties_element = tile_element.find("properties")
    if properties_element:
        for prop in properties_element.findall("property"):
            if prop.get("type") == "bool":
                boolean_properties[prop.get("name")] = (prop.get("value") == "true")
    return boolean_properties

def read_integer_properties(tile_element):
    integer_properties = {}
    properties_element = tile_element.find("properties")
    if properties_element:
        for prop in properties_element.findall("property"):
            if prop.get("type") == "int":
                integer_properties[prop.get("name")] = int(prop.get("value"))
    return integer_properties

def read_tileset(tileset_filename, first_gid=0):
    tileset_element = ElementTree.parse(tileset_filename).getroot()
    tile_elements = tileset_element.findall("tile")
    tiles = {}
    for ordinal_index in range(0, len(tile_elements)):
        tile_element = tile_elements[ordinal_index]
        tiled_index = int(tile_element.get("id"))
        boolean_properties = read_boolean_properties(tile_element)
        integer_properties = read_integer_properties(tile_element)
        tiled_tile = TiledTile(ordinal_index=ordinal_index, tiled_index=tiled_index, boolean_properties=boolean_properties, integer_properties=integer_properties)
        tiles[tiled_index] = tiled_tile
    tileset = TiledTileSet(first_gid=first_gid, tiles=tiles)
    return tileset

def tile_from_gid(tile_index, tilesets):
    for tileset in reversed(tilesets):
        if tileset.first_gid <= tile_index:
            tileset_index = tile_index - tileset.first_gid
            return tileset.tiles.get(tileset_index, BLANK_TILE)
    return BLANK_TILE

def read_layer(layer_element, tilesets):
    data = layer_element.find("data")
    if data.get("encoding") == "csv":
        cell_values = [int(x) for x in data.text.split(",")]
        tiles = [tile_from_gid(x, tilesets) for x in cell_values]
        return tiles
    exiterror("Non-csv encoding is not supported.")

def combine_properties(graphics_tile, supplementary_tiles):
    combined_tile = graphics_tile
    for supplementary_tile in supplementary_tiles:
        combined_tile.integer_properties = graphics_tile.integer_properties | supplementary_tile.integer_properties
        combined_tile.boolean_properties = graphics_tile.boolean_properties | supplementary_tile.boolean_properties
    return combined_tile

def read_map(map_filename):
    map_element = ElementTree.parse(map_filename).getroot()
    map_width = int(map_element.get("width"))
    map_height = int(map_element.get("height"))

    # First read in all tilesets referenced by this map, making note of their
    # first gids
    tilesets = []
    tileset_elements = map_element.findall("tileset")
    for tileset_element in tileset_elements:
        first_gid = int(tileset_element.get("firstgid"))
        relative_path = tileset_element.get("source")
        base_path = Path(map_filename).parent
        tileset_path = (base_path / relative_path).resolve()
        tileset = read_tileset(tileset_path, first_gid)
        tilesets.append(tileset)
    
    # then read in all map layers. Using the raw index data and the first gids, we can
    # translate the lists to the actual tiles they reference
    layers = {}
    layer_elements = map_element.findall("layer")
    for layer_element in layer_elements:
        layers[layer_element.get("name")] = read_layer(layer_element, tilesets)

    # At this point we should have at least one layer named "Graphics", if we don't
    # we can't continue and must bail
    graphics_layer = layers.pop("Graphics")
    supplementary_layers = layers

    # Now we combine the layers
    combined_tiles = []
    for tile_index in range(0, len(graphics_layer)):
        graphics_tile = graphics_layer[tile_index]
        supplementary_tiles = [supplementary_layers[layer_name][tile_index] for layer_name in supplementary_layers]
        combined_tiles.append(combine_properties(graphics_tile, supplementary_tiles))

    # finally let's make the name something useful
    (_, plain_filename) = os.path.split(map_filename)
    (base_filename, _) = os.path.splitext(plain_filename)
    safe_label = re.sub(r'[^A-Za-z0-9\-\_]', '_', base_filename)

    return CombinedMap(name=safe_label, width=map_width, height=map_height, tiles=combined_tiles)

def ca65_byte_literal(value):
  return "$%02x" % (value & 0xFF)

def ca65_comment(text):
    return f"; {text}"

def ca65_label(label_name):
    return f"{label_name}:"

def pretty_print_table(raw_bytes, output_file, width=16):
  """ Formats a byte array as a big block of ca65 literals

  Just for style purposes, I'd like to collapse the table so that 
  only so many bytes are printed on each line. This is nicer than one 
  giant line or tons of individual .byte statements.
  """
  formatted_bytes = [ca65_byte_literal(byte) for byte in raw_bytes]
  for table_row in range(0, int(len(formatted_bytes) / width)):
    row_text = ", ".join(formatted_bytes[table_row * width : table_row * width + width])
    print("  .byte %s" % row_text, file=output_file)

  final_row = formatted_bytes[int(len(formatted_bytes) / width) * width : ]
  if len(final_row) > 0:
    final_row_text = ", ".join(final_row)
    print("  .byte %s" % final_row_text, file=output_file)

def write_map_header(tilemap, output_file):
    output_file.write(ca65_label(tilemap.name) + "\n")
    output_file.write("  .byte %s ; width\n" % ca65_byte_literal(tilemap.width))
    output_file.write("  .byte %s ; height\n" % ca65_byte_literal(tilemap.height))
    output_file.write("  .word %s_graphics\n" % tilemap.name)
    output_file.write("  .word %s_collision\n" % tilemap.name)
    output_file.write("\n")

def write_graphics_tiles(tilemap, output_file):
    output_file.write(ca65_label(tilemap.name + "_graphics") + "\n")
    # for now, compression type 0 == identity, raw bytes with no compression
    output_file.write("  .byte %s ; compression type\n" % ca65_byte_literal(0))
    raw_graphics_bytes = [tile.ordinal_index for tile in tilemap.tiles]
    pretty_print_table(raw_graphics_bytes, output_file, tilemap.width)




# DEBUG TEST THINGS
if len(sys.argv) != 3:
  print("Usage: 3dconvertmap.py input.tmx output.bin")
  sys.exit(-1)
input_filename = sys.argv[1]
output_filename = sys.argv[2]

tilemap = read_map(input_filename)

with open(output_filename, "w") as output_file:
    write_map_header(tilemap, output_file)
    write_graphics_tiles(tilemap, output_file)

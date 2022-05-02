#!/usr/bin/env python3
import xml.etree.ElementTree as ElementTree
import sys

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
        tiled_index = tile_element.get("id")
        boolean_properties = read_boolean_properties(tile_element)
        integer_properties = read_integer_properties(tile_element)
        tiled_tile = TiledTile(ordinal_index=ordinal_index, tiled_index=tiled_index, boolean_properties=boolean_properties, integer_properties=integer_properties)
        tiles[tiled_index] = tiled_tile
    tileset = TiledTileSet(first_gid=first_gid, tiles=tiles)
    return tileset

def read_layer(layer_element):
    # you were here
    pass

def read_map(map_filename):
    map_element = ElementTree.parse(map_filename).getroot()
    tilesets = []
    tileset_elements = map_element.findall("tileset")
    for tileset_element in tileset_elements:
        first_gid = tileset_element.get("firstgid")
        relative_path = tileset_element.get("source")
        base_path = Path(map_filename).parent
        tileset_path = (base_path / relative_path).resolve()
        tileset = read_tileset(tileset_path, first_gid)
        tilesets.append(tileset)
    # no! bad!
    print(tilesets)


# DEBUG TEST THINGS
if len(sys.argv) != 3:
  print("Usage: 3dconvertmap.py input.tmx output.bin")
  sys.exit(-1)
input_file = sys.argv[1]
output_file = sys.argv[2]

# this should be a MAP file, and we get the tileset from there
read_map(input_file)
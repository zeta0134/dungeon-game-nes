#!/usr/bin/env python3
import xml.etree.ElementTree as ElementTree
import os, re, sys

from dataclasses import dataclass, field
from pathlib import Path
from typing import Dict

from ca65 import pretty_print_table, ca65_label, ca65_byte_literal, ca65_word_literal

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
    name: str
    first_gid: int
    tiles: Dict[int, TiledTile]

BLANK_TILE = TiledTile(tiled_index=0, ordinal_index=0, integer_properties={}, boolean_properties={})

@dataclass
class CombinedMap:
    name: str
    width: int
    height: int
    graphics_tilesets: [TiledTileSet]
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

def read_tileset(tileset_filename, first_gid=0, name=""):
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
    tileset = TiledTileSet(first_gid=first_gid, tiles=tiles, name=name)
    return tileset

def tile_from_gid(tile_index, tilesets):
    for tileset in reversed(tilesets):
        if tileset.first_gid <= tile_index:
            tileset_index = tile_index - tileset.first_gid
            return tileset.tiles.get(tileset_index, BLANK_TILE)
    return BLANK_TILE

def tileset_from_gid(tile_index, tilesets):
    for tileset in reversed(tilesets):
        if tileset.first_gid <= tile_index:
            return tileset
    return None

def read_layer(layer_element, tilesets):
    data = layer_element.find("data")
    if data.get("encoding") == "csv":
        cell_values = [int(x) for x in data.text.split(",")]
        tiles = [tile_from_gid(x, tilesets) for x in cell_values]
        return tiles
    exiterror("Non-csv encoding is not supported.")

def combine_properties(graphics_tile, supplementary_tiles):
    combined_tile = TiledTile(
        ordinal_index=graphics_tile.ordinal_index,
        tiled_index=graphics_tile.tiled_index,
        boolean_properties=dict(graphics_tile.boolean_properties),
        integer_properties=dict(graphics_tile.integer_properties)
    )
    for supplementary_tile in supplementary_tiles:
        combined_tile.integer_properties = combined_tile.integer_properties | supplementary_tile.integer_properties
        combined_tile.boolean_properties = combined_tile.boolean_properties | supplementary_tile.boolean_properties
    return combined_tile

def nice_label(full_path_and_filename):
  (_, plain_filename) = os.path.split(full_path_and_filename)
  (base_filename, _) = os.path.splitext(plain_filename)
  safe_label = re.sub(r'[^A-Za-z0-9\-\_]', '_', base_filename)
  return safe_label

def identity_graphics_tilesets(layer_elements, tilesets):
    graphics_tilesets = []
    for layer_element in layer_elements:
        if layer_element.get("name") == "Graphics":
            data = layer_element.find("data")
            if data.get("encoding") == "csv":
                cell_values = [int(x) for x in data.text.split(",")]
                for tile_id in cell_values:
                    tileset = tileset_from_gid(tile_id, tilesets)
                    if tileset and tileset not in graphics_tilesets:
                        graphics_tilesets.append(tileset)
    return graphics_tilesets

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
        tileset = read_tileset(tileset_path, first_gid, nice_label(tileset_path))
        tilesets.append(tileset)
    
    # then read in all map layers. Using the raw index data and the first gids, we can
    # translate the lists to the actual tiles they reference
    layers = {}
    layer_elements = map_element.findall("layer")
    for layer_element in layer_elements:
        layers[layer_element.get("name")] = read_layer(layer_element, tilesets)

    graphics_tilesets = identity_graphics_tilesets(layer_elements, tilesets)

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

    return CombinedMap(name=safe_label, width=map_width, height=map_height, tiles=combined_tiles, graphics_tilesets=graphics_tilesets)

def write_map_header(tilemap, output_file):
    output_file.write(ca65_label(tilemap.name) + "\n")
    output_file.write("  .byte %s ; width\n" % ca65_byte_literal(tilemap.width))
    output_file.write("  .byte %s ; height\n" % ca65_byte_literal(tilemap.height))
    output_file.write("  .word %s_graphics\n" % tilemap.name)
    output_file.write("  .word %s_collision\n" % tilemap.name)
    output_file.write("  .word %s_tileset ; first tileset \n" % tilemap.graphics_tilesets[0].name)
    output_file.write("\n")

def write_graphics_tiles(tilemap, output_file):
    output_file.write(ca65_label(tilemap.name + "_graphics") + "\n")
    # for now, compression type 0 == identity, raw bytes with no compression
    output_file.write("  .byte %s ; compression type\n" % ca65_byte_literal(0))
    raw_graphics_bytes = [tile.ordinal_index for tile in tilemap.tiles]
    output_file.write("  .word %s ; length in bytes\n" % ca65_word_literal(len(raw_graphics_bytes)))
    pretty_print_table(raw_graphics_bytes, output_file, tilemap.width)
    output_file.write("\n")

def generate_collision_tileset():
    tiles = []
    # First off, there is a permanent wall tile, with no walkable surfaces:
    tiles.append(BLANK_TILE)

    # There are 16 visible surface heights, 0-15
    for visible_surface_height in range(0, 16):
        vislble_surface_tile = TiledTile(
            tiled_index=len(tiles), 
            ordinal_index=len(tiles), 
            integer_properties={
                "floor_height": visible_surface_height
            }, 
            boolean_properties={
                "is_floor": True
            }
        )
        tiles.append(vislble_surface_tile)
    # There are 15 occluded surface heights, 0-14
    for hidden_surface_height in range(0, 15):
        hidden_surface_tile = TiledTile(
            tiled_index=len(tiles), 
            ordinal_index=len(tiles), 
            integer_properties={
                "hidden_floor_height": hidden_surface_height
            }, 
            boolean_properties={
                "is_hidden_floor": True
            }
        )
        tiles.append(hidden_surface_tile)

    # There are a multitude of combinations, but not all combinations are needed.
    # occluded surfaces must always appear "behind" a visible surface, that is:
    # occluded surface < visible surface
    for visible_surface_height in range(1, 16):
        for hidden_surface_height in range(0, visible_surface_height):
            combined_surface_tile = TiledTile(
                tiled_index=len(tiles), 
                ordinal_index=len(tiles), 
                integer_properties={
                    "hidden_floor_height": hidden_surface_height,
                    "floor_height": visible_surface_height
                }, 
                boolean_properties={
                    "is_hidden_floor": True,
                    "is_floor": True
                }
            )
            tiles.append(combined_surface_tile)

    return tiles

def find_collision_index(combined_tile, collision_tiles):
    for candidate_tile in collision_tiles:
        if (
            candidate_tile.integer_properties.get("floor_height") == combined_tile.integer_properties.get("floor_height") and
            candidate_tile.integer_properties.get("hidden_floor_height") == combined_tile.integer_properties.get("hidden_floor_height") and
            candidate_tile.boolean_properties.get("is_floor") == combined_tile.boolean_properties.get("is_floor") and
            candidate_tile.boolean_properties.get("is_hidden_floor") == combined_tile.boolean_properties.get("is_hidden_floor")
        ):
            return candidate_tile.ordinal_index
    # no valid collision tile was found! BAIL, we cannot generate this map.
    print("Invalid collision tile encountered:")
    print(combined_tile)
    print("This tile is not in preset in the global collision set.")
    sys.exit(-1)

def write_collision_tiles(tilemap, output_file):
    collision_tiles = generate_collision_tileset()
    output_file.write(ca65_label(tilemap.name + "_collision") + "\n")
    # for now, compression type 0 == identity, raw bytes with no compression
    output_file.write("  .byte %s ; compression type\n" % ca65_byte_literal(0))
    raw_collision_bytes = [find_collision_index(tile, collision_tiles) for tile in tilemap.tiles]
    output_file.write("  .word %s ; length in bytes\n" % ca65_word_literal(len(raw_collision_bytes)))
    pretty_print_table(raw_collision_bytes, output_file, tilemap.width)
    output_file.write("\n")

if __name__ == '__main__':
    # DEBUG TEST THINGS
    if len(sys.argv) != 3:
      print("Usage: convert3dmap.py input.tmx output.bin")
      sys.exit(-1)
    input_filename = sys.argv[1]
    output_filename = sys.argv[2]

    tilemap = read_map(input_filename)

    with open(output_filename, "w") as output_file:
        write_map_header(tilemap, output_file)
        write_graphics_tiles(tilemap, output_file)
        write_collision_tiles(tilemap, output_file)

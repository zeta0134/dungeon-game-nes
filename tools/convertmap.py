#!/usr/bin/env python3
import xml.etree.ElementTree as ElementTree
import math, os, re, sys

from dataclasses import dataclass, field
from pathlib import Path
from typing import Dict

from ca65 import pretty_print_table, ca65_label, ca65_byte_literal, ca65_word_literal
from compress import compress_smallest

# === Data Types ===
# Note: concerned with data for map conversion only. We ignore everything else.
# Graphics conversion is a separate step entirely.

# Base tiles, read directly from a tileset
@dataclass
class TiledTile:
    tiled_index: int
    ordinal_index: int
    type: str
    integer_properties: Dict[str, int]
    boolean_properties: Dict[str, bool]
    string_properties: Dict[str, str]

@dataclass
class TiledTileSet:
    name: str
    first_gid: int
    tiles: Dict[int, TiledTile]
    string_properties: Dict[str, str]

@dataclass
class Exit:
    x: int
    y: int
    map_name: str
    entrance_id: int

@dataclass
class Entrance:
    x: int
    y: int

@dataclass
class Entity:
    x: int
    y: int
    initial_state: str

BLANK_TILE = TiledTile(tiled_index=0, ordinal_index=0, integer_properties={}, boolean_properties={}, string_properties={}, type="")

@dataclass
class Overlay:
    name: str
    width: int
    height: int
    event_id: int
    metadata: int
    index: int
    tiles: [TiledTile]

@dataclass
class Trigger:
    x: int
    y: int
    integer_properties: Dict[str, int]
    boolean_properties: Dict[str, bool]
    string_properties: Dict[str, str]

@dataclass
class CombinedMap:
    name: str
    width: int
    height: int
    tiles: [TiledTile]
    overlays: [Overlay]
    entrances: [Entrance]
    exits: [Exit]
    entities: [Entity]
    triggers: [Trigger]
    chr0_label: str
    chr1_label: str
    global_palette: [int]
    music_track: int
    music_variant: int
    distortion_index: int
    color_emphasis: int
    logic_function: str
    area_id: int

def read_boolean_properties(tile_element):
    boolean_properties = {}
    properties_element = tile_element.find("properties")
    if properties_element:
        for prop in properties_element.findall("property"):
            if prop.get("type") == "bool":
                boolean_properties[prop.get("name")] = (prop.get("value") == "true")
    return boolean_properties

def read_integer_properties(parent_element):
    integer_properties = {}
    properties_element = parent_element.find("properties")
    if properties_element:
        for prop in properties_element.findall("property"):
            if prop.get("type") == "int":
                integer_properties[prop.get("name")] = int(prop.get("value"))
    return integer_properties

def read_string_properties(parent_element):
    string_properties = {}
    properties_element = parent_element.find("properties")
    if properties_element:
        for prop in properties_element.findall("property"):
            if prop.get("type") == None or prop.get("type") == "string":
                string_properties[prop.get("name")] = prop.get("value")
    return string_properties

def read_tileset(tileset_filename, first_gid=0, name=""):
    tileset_element = ElementTree.parse(tileset_filename).getroot()
    tile_elements = tileset_element.findall("tile")
    tiles = {}
    for ordinal_index in range(0, len(tile_elements)):
        tile_element = tile_elements[ordinal_index]
        tiled_index = int(tile_element.get("id"))
        tiled_type = tile_element.get("type")
        boolean_properties = read_boolean_properties(tile_element)
        integer_properties = read_integer_properties(tile_element)
        string_properties = read_string_properties(tile_element)
        tiled_tile = TiledTile(ordinal_index=ordinal_index, tiled_index=tiled_index, boolean_properties=boolean_properties, integer_properties=integer_properties, string_properties=string_properties, type=tiled_type)
        tiles[tiled_index] = tiled_tile
    string_properties = read_string_properties(tileset_element)
    # dirty, *dirty* hack
    if "global_palette" in string_properties:
        base_path = Path(tileset_filename).parent
        palette_path = (base_path / string_properties["global_palette"]).resolve()
        string_properties["global_palette"] = palette_path
    tileset = TiledTileSet(first_gid=first_gid, tiles=tiles, name=name, string_properties=string_properties)
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

def combine_tile_properties(graphics_tile, supplementary_tiles):
    combined_tile = TiledTile(
        ordinal_index=graphics_tile.ordinal_index,
        tiled_index=graphics_tile.tiled_index,
        boolean_properties=dict(graphics_tile.boolean_properties),
        integer_properties=dict(graphics_tile.integer_properties),
        string_properties=dict(graphics_tile.string_properties),
        type=graphics_tile.type
    )
    for supplementary_tile in supplementary_tiles:
        combined_tile.integer_properties = combined_tile.integer_properties | supplementary_tile.integer_properties
        combined_tile.boolean_properties = combined_tile.boolean_properties | supplementary_tile.boolean_properties
        combined_tile.string_properties = combined_tile.string_properties | supplementary_tile.string_properties
    return combined_tile

def combine_tileset_properties(tilesets):
    combined_properties = {}
    for tileset in tilesets:
        combined_properties = combined_properties | tileset.string_properties
    return combined_properties

def nice_label(full_path_and_filename):
  (_, plain_filename) = os.path.split(full_path_and_filename)
  (base_filename, _) = os.path.splitext(plain_filename)
  safe_label = re.sub(r'[^A-Za-z0-9\-\_]', '_', base_filename)
  return safe_label

def identify_object(object_element):
    if object_element.get("gid"):
        return "tile"
    if object_element.get("x") and object_element.get("y"):
        if object_element.get("width") and object_element.get("height"):
            if object_element.find("ellipse"):
                return "ellipse"
            if object_element.find("text"):
                return "text"
            return "rectangle"
        if object_element.find("point"):
            return "point"
        if object_element.find("polygon"):
            return "polygon"
    return None

def read_entrances(object_elements, tilesets, map_width, map_height):
    # Put the default spawn in the center of the map. (All maps *should* override this)
    default_spawn = Entrance(x=math.floor(map_width/2),y=math.floor(map_height/2))
    # If we have an undefined entrance, use the default spawn location
    entrances = [default_spawn,default_spawn,default_spawn,default_spawn,default_spawn]
    for object_element in object_elements:
        if identify_object(object_element) == "tile":
            tile = tile_from_gid(int(object_element.get("gid")), tilesets)
            if tile.type == "entrance":
                entrance_index = tile.integer_properties["index"]
                entrance_x = math.floor(int(object_element.get("x")) / 16)
                # for some reason, Tiled considers the origin of these things to be on their bottom, not
                # their top, so we get different logic depending on the axis. Thanks tiled.
                entrance_y = math.floor((int(object_element.get("y")) - 16) / 16)
                entrances[entrance_index] = Entrance(x=entrance_x, y=entrance_y)
    return entrances

def read_exits(object_elements, tilesets):
    exits = []
    for object_element in object_elements:
        if identify_object(object_element) == "tile":
            tile = tile_from_gid(int(object_element.get("gid")), tilesets)
            if tile.type == "exit":
                exit_x = math.floor(int(object_element.get("x")) / 16)
                exit_y = math.floor((int(object_element.get("y")) - 16) / 16)
                exit_map_name = "undefined_name_missing"
                exit_index = 0
                properties_element = object_element.find("properties")
                if properties_element:
                    for property_element in properties_element.findall("property"):
                        if property_element.get("name") == "destination_map":
                            exit_map_name = property_element.get("value")
                        if property_element.get("name") == "destination_doorway":
                            exit_index = int(property_element.get("value"))
                exits.append(Exit(x=exit_x,y=exit_y,map_name=exit_map_name,entrance_id=exit_index))
    return exits

def read_entities(object_elements, tilesets):
    entities = []
    for object_element in object_elements:
        if identify_object(object_element) == "tile":
            tile = tile_from_gid(int(object_element.get("gid")), tilesets)
            if tile.type == "entity":
                entity_initial_state = tile.string_properties["initial_state"]
                entity_tile_x = math.floor(int(object_element.get("x")) / 16)
                # for some reason, Tiled considers the origin of these things to be on their bottom, not
                # their top, so we get different logic depending on the axis. Thanks tiled.
                entity_tile_y = math.floor((int(object_element.get("y")) - 16) / 16)
                entities.append(Entity(x=entity_tile_x, y=entity_tile_y, initial_state=entity_initial_state))
    return entities

def read_triggers(object_elements, tilesets):
    triggers = []
    for object_element in object_elements:
        if identify_object(object_element) == "tile":
            tile = tile_from_gid(int(object_element.get("gid")), tilesets)
            if tile.type == "trigger":
                trigger_x = math.floor(int(object_element.get("x")) / 16)
                trigger_y = math.floor((int(object_element.get("y")) - 16) / 16)

                boolean_properties = read_boolean_properties(object_element)
                integer_properties = read_integer_properties(object_element)
                string_properties = read_string_properties(object_element)

                triggers.append(Trigger(x=trigger_x,y=trigger_y,boolean_properties=boolean_properties, integer_properties=integer_properties, string_properties=string_properties))
    return triggers

def read_global_palette(filename):
    with open(filename, "rb") as palette_file:
        palette_raw = palette_file.read()
        return palette_raw

# Given a list of layer elements, parses the layer contents, then
# combines common attributes, using the "Graphics" layer as a base.
def read_and_combine_layers(layer_elements, tilesets):
    layers = {}
    for layer_element in layer_elements:
        layers[layer_element.get("name")] = read_layer(layer_element, tilesets)

    # At this point we should have at least one layer named "Graphics", if we don't
    # we can't continue and must bail
    graphics_layer = layers.pop("Graphics")
    supplementary_layers = layers

    combined_tiles = []
    for tile_index in range(0, len(graphics_layer)):
        graphics_tile = graphics_layer[tile_index]
        supplementary_tiles = [supplementary_layers[layer_name][tile_index] for layer_name in supplementary_layers]
        combined_tiles.append(combine_tile_properties(graphics_tile, supplementary_tiles))
    return combined_tiles

def compose_overlay_metadata(boolean_properties, integer_properties, string_properties):
    # note: very simple for now, we'll be expanding this later for sure
    if string_properties.get("when_event_is") == "SET":
        return 0x80
    return 0x00

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
    
    # first read in all the base map layers
    layer_elements = map_element.findall("layer")
    combined_tiles = read_and_combine_layers(layer_elements, tilesets)

    # now do it again, this time with any overlay groups in the order that they appear
    overlays = []
    overlay_index = 0
    group_elements = map_element.findall("group")
    for group_element in group_elements:
        group_boolean_properties = read_boolean_properties(group_element)
        group_integer_properties = read_integer_properties(group_element)
        group_string_properties = read_string_properties(group_element)
        if group_element.get("class") == "overlay":
            layer_elements = group_element.findall("layer")
            overlay_tiles = read_and_combine_layers(layer_elements, tilesets)
            event_id = group_integer_properties["event_id"]
            metadata = compose_overlay_metadata(group_boolean_properties, group_integer_properties, group_string_properties)
            overlays.append(Overlay(tiles=overlay_tiles, name=group_element.get("name"), width=map_width, height=map_height, event_id=event_id, metadata=metadata, index=overlay_index))
            overlay_index = overlay_index + 1

    # Read in supplementary structures: entrances, exits, etc
    objects = []
    for objectgroup in map_element.findall("objectgroup"):
        objects.extend(objectgroup.findall("object"))

    entrances = read_entrances(objects, tilesets, map_width, map_height)
    exits = read_exits(objects, tilesets)
    entities = read_entities(objects, tilesets)
    triggers = read_triggers(objects, tilesets)

    common_tileset_properties = combine_tileset_properties(tilesets)
    chr0_label = common_tileset_properties["chr0_tileset"]
    chr1_label = common_tileset_properties.get("chr1_tileset", chr0_label)
    global_palette = read_global_palette(common_tileset_properties["global_palette"])

    map_integer_properties = read_integer_properties(map_element)
    music_track = map_integer_properties.get("music_track", 0xFF)
    music_variant = map_integer_properties.get("music_variant", 0xFF)
    distortion_index = map_integer_properties.get("distortion_index", 0)
    color_emphasis = map_integer_properties.get("color_emphasis", 0)
    map_string_properties = read_string_properties(map_element)
    logic_function = map_string_properties.get("logic_function", "maplogic_default")
    area_id = map_string_properties.get("area_id", "AREA_DEBUG_HUB")

    # finally let's make the name something useful
    (_, plain_filename) = os.path.split(map_filename)
    (base_filename, _) = os.path.splitext(plain_filename)
    safe_label = re.sub(r'[^A-Za-z0-9\-\_]', '_', base_filename)

    return CombinedMap(name=safe_label, width=map_width, height=map_height, tiles=combined_tiles, overlays=overlays,
        entrances=entrances, exits=exits, entities=entities, triggers=triggers, chr0_label=chr0_label, chr1_label=chr1_label, 
        global_palette=global_palette, music_track=music_track, music_variant=music_variant,
        distortion_index=distortion_index, color_emphasis=color_emphasis, logic_function=logic_function, area_id=area_id)

def write_map_header(tilemap, output_file):
    output_file.write(ca65_label(tilemap.name) + "\n")
    output_file.write("  .byte %s ; width\n" % ca65_byte_literal(tilemap.width))
    output_file.write("  .byte %s ; height\n" % ca65_byte_literal(tilemap.height))
    output_file.write("  .word %s_graphics\n" % tilemap.name)
    output_file.write("  .word %s_collision\n" % tilemap.name)
    output_file.write("  .word %s_entrances\n" % tilemap.name)
    output_file.write("  .word %s_exits\n" % tilemap.name)
    output_file.write("  .word %s_entities\n" % tilemap.name)
    output_file.write("  .word %s ; first tileset \n" % tilemap.chr0_label)
    output_file.write("  .word %s ; second tileset \n" % tilemap.chr1_label)
    output_file.write("  .word %s_palette\n" % tilemap.name)
    output_file.write("  .word %s_attributes\n" % tilemap.name)
    output_file.write("  .byte %s ; music track\n" % ca65_byte_literal(tilemap.music_track))
    output_file.write("  .byte %s ; music variant\n" % ca65_byte_literal(tilemap.music_variant))
    output_file.write("  .byte %s ; distortion index\n" % ca65_byte_literal(tilemap.distortion_index))
    output_file.write("  .byte %s ; color emphasis\n" % ca65_byte_literal(tilemap.color_emphasis))
    output_file.write("  .word %s\n" % tilemap.logic_function)
    output_file.write("  .word %s_overlays\n" % tilemap.name)
    output_file.write("  .word %s_triggers\n" % tilemap.name)
    output_file.write("  .byte %s ; area_id\n" % tilemap.area_id)
    output_file.write("\n")

def write_palette_data(tilemap, output_file):
    output_file.write(ca65_label(tilemap.name + "_palette") + "\n")
    pretty_print_table(tilemap.global_palette, output_file, 16)
    output_file.write("\n")

def write_entrance_table(tilemap, output_file):
    output_file.write(ca65_label(tilemap.name + "_entrances") + "\n")
    for index in range(0, len(tilemap.entrances)):
        friendly_name = "spawn" if index == 0 else "door #" + str(index)
        x_byte = ca65_byte_literal(tilemap.entrances[index].x)
        y_byte = ca65_byte_literal(tilemap.entrances[index].y)
        output_file.write("  .byte %s, %s ; %s\n" % (x_byte, y_byte, friendly_name))
    output_file.write("\n")

def write_exit_table(tilemap, output_file):
    output_file.write(ca65_label(tilemap.name + "_exits") + "\n")
    output_file.write("  .byte %s ; length \n" % ca65_byte_literal(len(tilemap.exits)))
    for exit in tilemap.exits:
        output_file.write("  .byte %s, %s ; coordinates \n" % (ca65_byte_literal(exit.x), ca65_byte_literal(exit.y)))
        output_file.write("  .word %s ; target map\n" % exit.map_name)
        output_file.write("  .byte <.bank(%s) ; target bank\n" % exit.map_name)
        output_file.write("  .byte %s ; entrance id\n" % exit.entrance_id)
    output_file.write("\n")

def write_entity_table(tilemap, output_file):
    output_file.write(ca65_label(tilemap.name + "_entities") + "\n")
    output_file.write("  .byte %s ; length \n" % ca65_byte_literal(len(tilemap.entities)))
    for entity in tilemap.entities:
        output_file.write("  .word %s ; initial state\n" % entity.initial_state)
        output_file.write("  .byte %s, %s    ; coordinates \n" % (ca65_byte_literal(entity.x), ca65_byte_literal(entity.y)))
    output_file.write("\n")

def write_graphics_tiles(tilemap, output_file):
    raw_graphics_bytes = [tile.integer_properties["metatile_index"] for tile in tilemap.tiles]
    compression_type, compressed_bytes = compress_smallest(raw_graphics_bytes)

    output_file.write(ca65_label(tilemap.name + "_graphics") + "\n")
    output_file.write("  .byte %s ; compression type\n" % ca65_byte_literal(compression_type))
    output_file.write("  .word %s ; decompressed length in bytes\n" % ca65_word_literal(len(raw_graphics_bytes)))
    output_file.write("              ; compressed length: $%04X, ratio: %.2f:1 \n" % (len(compressed_bytes), len(raw_graphics_bytes) / len(compressed_bytes)))
    pretty_print_table(compressed_bytes, output_file, tilemap.width)
    output_file.write("\n")

def attribute_bits(tilemap, x, y):
    if x >= tilemap.width or y >= tilemap.height:
        return 0
    return tilemap.tiles[y*tilemap.width+x].integer_properties.get("attribute_index", 0) & 0x3

def attribute_bytes(tilemap):
    raw_attributes = []
    for y in range(0, math.floor(tilemap.height / 2)):
        for x in range(0, math.floor(tilemap.width / 2)):
            top_left = attribute_bits(tilemap, x*2, y*2)
            top_right = attribute_bits(tilemap, x*2+1, y*2)
            bottom_left = attribute_bits(tilemap, x*2, y*2+1)
            bottom_right = attribute_bits(tilemap, x*2+1, y*2+1)
            attribute_byte = (bottom_right << 6) | (bottom_left << 4) | (top_right << 2) | (top_left)
            raw_attributes.append(attribute_byte)
    return raw_attributes

def write_attributes(tilemap, output_file):
    raw_attribute_bytes = attribute_bytes(tilemap)
    compression_type, compressed_bytes = compress_smallest(raw_attribute_bytes)

    output_file.write(ca65_label(tilemap.name + "_attributes") + "\n")
    output_file.write("  .byte %s ; compression type\n" % ca65_byte_literal(compression_type))
    output_file.write("  .word %s ; decompressed length in bytes\n" % ca65_word_literal(len(raw_attribute_bytes)))
    output_file.write("              ; compressed length: $%04X, ratio: %.2f:1 \n" % (len(compressed_bytes), len(raw_attribute_bytes) / len(compressed_bytes)))
    pretty_print_table(compressed_bytes, output_file, tilemap.width)
    output_file.write("\n")

def generate_collision_tileset():
    tiles = []
    # First off, there is a permanent wall tile, with no walkable surfaces:
    tiles.append(BLANK_TILE)

    # There are 16 visible surface heights, 0 - 15
    for visible_surface_height in range(0, 16):
        vislble_surface_tile = TiledTile(
            tiled_index=len(tiles), 
            ordinal_index=len(tiles), 
            integer_properties={
                "floor_height": visible_surface_height
            }, 
            boolean_properties={
                "is_floor": True
            },
            string_properties={},
            type="collision"
        )
        tiles.append(vislble_surface_tile)
    # There are 15 occluded surface heights, 0-14, but we only permit the even numbered ones
    # for two reasons:
    #   - art-wise, we can only occlude if the background is BG0, but we signal height variance by
    #       changing a given platform's background color. This means odd-numbered platforms are never
    #       the right color, visually, to be a hidden surface
    #   - doing this greatly decreases the number of hidden+visible combinations we'll need later
    for hidden_surface_height in range(0, 15, 2):
        hidden_surface_tile = TiledTile(
            tiled_index=len(tiles), 
            ordinal_index=len(tiles), 
            integer_properties={
                "hidden_floor_height": hidden_surface_height
            }, 
            boolean_properties={
                "is_hidden_floor": True
            },
            string_properties={},
            type="collision"
        )
        tiles.append(hidden_surface_tile)

    # There are a multitude of combinations, but not all combinations are needed.
    # occluded surfaces must always appear "behind" a visible surface, that is:
    # occluded surface < visible surface
    for visible_surface_height in range(1, 16):
        for hidden_surface_height in range(0, visible_surface_height, 2):
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
                },
                string_properties={},
                type="collision"
            )
            tiles.append(combined_surface_tile)

    # Finally we need to generate collision variants. Right now we only support 3 of these, one for each type of ramp.
    # Collision variants are all visible surfaces, we'll never have these "behind" things in a way that would require
    # player occlusion.
    for visible_surface_height in range(0, 15):
        for collision_variant in range(1, 10):
            collision_variant_tile = TiledTile(
                tiled_index=len(tiles), 
                ordinal_index=len(tiles), 
                integer_properties={
                    "floor_height": visible_surface_height,
                    "collision_variant": collision_variant
                }, 
                boolean_properties={
                    "is_floor": True
                },
                string_properties={},
                type="collision"
            )
            tiles.append(collision_variant_tile)

    return tiles

def find_collision_index(combined_tile, collision_tiles):
    for candidate_tile in collision_tiles:
        if (
            candidate_tile.integer_properties.get("floor_height") == combined_tile.integer_properties.get("floor_height") and
            candidate_tile.integer_properties.get("hidden_floor_height") == combined_tile.integer_properties.get("hidden_floor_height") and
            candidate_tile.boolean_properties.get("is_floor") == combined_tile.boolean_properties.get("is_floor") and
            candidate_tile.boolean_properties.get("is_hidden_floor") == combined_tile.boolean_properties.get("is_hidden_floor") and
            candidate_tile.integer_properties.get("collision_variant") == combined_tile.integer_properties.get("collision_variant")
        ):
            return candidate_tile.ordinal_index
    # no valid collision tile was found! BAIL, we cannot generate this map.
    print("Invalid collision tile encountered:")
    print(combined_tile)
    print("This tile is not in preset in the global collision set.")
    sys.exit(-1)

def write_collision_tiles(tilemap, output_file):
    collision_tiles = generate_collision_tileset()
    raw_collision_bytes = [find_collision_index(tile, collision_tiles) for tile in tilemap.tiles]
    compression_type, compressed_bytes = compress_smallest(raw_collision_bytes)

    output_file.write(ca65_label(tilemap.name + "_collision") + "\n")
    output_file.write("  .byte %s ; compression type\n" % ca65_byte_literal(compression_type))
    output_file.write("  .word %s ; decompressed length in bytes\n" % ca65_word_literal(len(raw_collision_bytes)))
    output_file.write("              ; compressed length: $%04X, ratio: %.2f:1 \n" % (len(compressed_bytes), len(raw_collision_bytes) / len(compressed_bytes)))
    pretty_print_table(compressed_bytes, output_file, tilemap.width)
    output_file.write("\n")

@dataclass
class OverlayEntry:
    x: int
    y: int
    metatile_index: int
    navtile_index: int
    attribute: int

def overlay_label(tilemap, overlay):
    return tilemap.name + "_overlay_" + str(overlay.index)

def overlay_entries(overlay_map):
    collision_tiles = generate_collision_tileset()
    entries = []

    for y in range(0, overlay_map.height):
        for x in range(0, overlay_map.width):
            tile = overlay_map.tiles[y*overlay_map.width + x]
            if "metatile_index" in tile.integer_properties:
                metatile_index = tile.integer_properties.get("metatile_index")
                attribute = tile.integer_properties.get("attribute_index", 0) & 0x3
                navtile_index = find_collision_index(tile, collision_tiles)
                entries.append(OverlayEntry(x=x, y=y, metatile_index=metatile_index, navtile_index=navtile_index, attribute=attribute))
    # TODO: if we're going to sort these by order, this is the place to do it
    return entries

def write_overlay(tilemap, overlay, output_file):
    tiles_to_write = overlay_entries(overlay)
    output_file.write(ca65_label(overlay_label(tilemap, overlay)) + "\n")
    output_file.write("  .byte %s ; length in tiles\n" % ca65_byte_literal(len(tiles_to_write)))
    output_file.write("  ;       X,   Y,Tile, Nav,Attr\n")
    for tile in tiles_to_write:
        tile_raw_bytes = [tile.x, tile.y, tile.metatile_index, tile.navtile_index, tile.attribute]
        pretty_print_table(tile_raw_bytes, output_file)
    output_file.write("\n")

def write_overlay_list(tilemap, output_file):
    output_file.write(ca65_label(tilemap.name + "_overlays") + "\n")
    output_file.write("  .byte %s ; num overlays\n" % ca65_byte_literal(len(tilemap.overlays)))
    for overlay in tilemap.overlays:
        output_file.write("  .word %s\n" % overlay_label(tilemap, overlay))
        output_file.write("  .byte %s, %s ; event_id, metadata \n" % (overlay.event_id, overlay.metadata))
    output_file.write("\n")
    for overlay in tilemap.overlays:
        write_overlay(tilemap, overlay, output_file)

def write_trigger_metadata(t, output_file):
    output_file.write("  ;-----------------------\n")
    output_file.write("  .byte %s, %s ; (X, Y)\n" % (t.x, t.y))

    lines = [".byte $0 ; unused"] * 6

    if "event_id" in t.integer_properties:
        lines[0] = ".byte %s ; event_id" % t.integer_properties["event_id"]

    if "with_event" in t.string_properties:
        if t.string_properties["with_event"] == "SET":
            lines[1] = ".byte 1 ; SET"
        if t.string_properties["with_event"] == "UNSET":
            lines[1] = ".byte 0 ; UNSET"

    if "dialog" in t.string_properties:
        lines[3] = ".byte <.bank(%s) ; dialog bank" % t.string_properties["dialog"]
        lines[4] = ".word %s ; dialog label" % t.string_properties["dialog"]
        lines[5] = ""

    if "data0" in t.integer_properties:
        lines[1] = ".byte %s ; data1" % t.integer_properties["data1"]
    if "data1" in t.integer_properties:
        lines[2] = ".byte %s ; data2" % t.integer_properties["data2"]
    if "data2" in t.integer_properties:
        lines[3] = ".byte %s ; data3" % t.integer_properties["data3"]
    if "data3" in t.integer_properties:
        lines[4] = ".byte %s ; data4" % t.integer_properties["data4"]
    if "data4" in t.integer_properties:
        lines[5] = ".byte %s ; data5" % t.integer_properties["data5"]

    for line in lines:
        output_file.write("  %s\n" % line)

def write_triggers(tilemap, output_file):
    output_file.write(ca65_label(tilemap.name + "_triggers") + "\n")
    output_file.write("  .byte %s ; num triggers\n" % ca65_byte_literal(len(tilemap.triggers)))
    for trigger in tilemap.triggers:
        write_trigger_metadata(trigger, output_file)
    output_file.write("\n")

if __name__ == '__main__':
    # DEBUG TEST THINGS
    if len(sys.argv) != 3:
      print("Usage: convertmap.py input.tmx output.bin")
      sys.exit(-1)
    input_filename = sys.argv[1]
    output_filename = sys.argv[2]

    tilemap = read_map(input_filename)

    with open(output_filename, "w") as output_file:
        write_map_header(tilemap, output_file)
        write_palette_data(tilemap, output_file)
        write_entrance_table(tilemap, output_file)
        write_exit_table(tilemap, output_file)
        write_entity_table(tilemap, output_file)
        write_graphics_tiles(tilemap, output_file)
        write_collision_tiles(tilemap, output_file)
        write_attributes(tilemap, output_file)
        write_overlay_list(tilemap, output_file)
        write_triggers(tilemap, output_file)
#!/usr/bin/env python3

from xml import etree
from xml.etree.ElementTree import ElementTree, Element

from PIL import Image
import pathlib
from pathlib import Path
import json, os, re, sys

def bytes_to_palette(byte_array):
  return [(byte_array[i], byte_array[i+1], byte_array[i+2]) for i in range(0, len(byte_array), 3)]

def read_nes_palette(filename):
  with open(filename, "rb") as binary_file:
    data = binary_file.read()
    return bytes_to_palette(data)

def png_filenames(folderpath):
  filenames = os.listdir(folderpath)
  return sorted([f for f in filenames if pathlib.Path(f).suffix == ".png"])

def nes_to_rgb(palette_filename, nes_global_palette):
  with open(palette_filename, "rb") as binary_file:
    raw_data = binary_file.read()
    return [nes_global_palette[i] for i in raw_data]

def bg_palette(global_palette, i):
  return [
    global_palette[0][0], global_palette[0][1], global_palette[0][2], 
    global_palette[i*4+1][0], global_palette[i*4+1][1], global_palette[i*4+1][2], 
    global_palette[i*4+2][0], global_palette[i*4+2][1], global_palette[i*4+2][2], 
    global_palette[i*4+3][0], global_palette[i*4+3][1], global_palette[i*4+3][2]
  ]

def generate_palette_variants(input_folder, output_folder, global_palette, prefix=""):
  input_filenames = png_filenames(input_folder)
  for input_filename in input_filenames:
    # read the source palette
    input_tile_path = (Path(input_folder) / input_filename).resolve()
    im = Image.open(input_tile_path)
    assert im.getpalette() != None, "Non-paletted tile found! This is unsupported: " + input_filename

    # write one variant palette for all 4 BG colors
    for i in range(0,4):
      bg_filename = (Path(output_folder) / (prefix + f"bg{i}_" + input_filename)).resolve()
      im.putpalette(bg_palette(global_palette, i))
      im.save(bg_filename)

def generate_tileset(input_folder, output_folder, metatile_index=0, attribute_index=0, chr=0, bg=0):
  prefix = f"chr{chr}_bg{bg}_"

  # start by grabbing the full list of tilenames; we need the length
  # for the header
  input_filenames = png_filenames(input_folder)

  # construct a nice name for the tileset; Tiled uses this for its dropdown selector
  (_, plain_input_folder_name) = os.path.split(input_folder)
  (_, plain_output_folder_name) = os.path.split(output_folder)

  # generate the XML document root and give it appropriate attributes for Tiled
  tileset_element = Element("tileset", attrib={
    "version": "1.8",
    "tiledversion": "1.8.2",
    "name": f"{plain_input_folder_name}_bg{bg}",
    "tilewidth": "16",
    "tileheight": "16",
    "tilecount": f"{len(input_filenames)}",
    "columns": "0"
  })
  # We don't do anything weird with the grid element, but we should still generate
  # and include a standard one
  grid_element = Element("grid", attrib={
    "orientation": "orthagonal",
    "width": "1",
    "height": "1"
  })
  tileset_element.append(grid_element)
  
  # the tileset properties will carry the bank and palette data, which the map converter
  # consumes when generating its final header
  (_, folder_name) = os.path.split(input_folder)
  tileset_properties_element = Element("properties")
  tileset_properties_element.append(Element("property", attrib={
    "name": f"chr{chr}_tileset",
    "type": "string",
    "value": folder_name+"_tileset"
  }))
  tileset_properties_element.append(Element("property", attrib={
    "name": f"global_palette",
    "type": "string",
    "value": "globalpalette.pal"
  }))
  tileset_element.append(tileset_properties_element)


  # Okay, now, for each input filename, generate an appropriate element
  tile_id = 0
  for input_filename in input_filenames:
    id_string = f"{tile_id}"
    tile_element = Element("tile", attrib={"id": id_string})
    properties_element = Element("properties")
    properties_element.append(Element("property", attrib={
      "name": "metatile_index",
      "type": "int",
      "value": str(metatile_index)
    }))
    properties_element.append(Element("property", attrib={
      "name": "attribute_index",
      "type": "int",
      "value": str(attribute_index)
    }))
    image_element = Element("image", attrib={
      "width": "16",
      "height": "16",
      "source": prefix+input_filename
    })
    tile_element.append(properties_element)
    tile_element.append(image_element)
    tileset_element.append(tile_element)

    tile_id += 1
    metatile_index += 1

  # pretty print and output
  etree.ElementTree.indent(tileset_element)
  document = ElementTree(element=tileset_element)
  output_path = (Path(output_folder) / (f"chr{chr}_{plain_input_folder_name}_bg{bg}.tsx")).resolve()
  document.write(output_path,encoding="UTF-8",xml_declaration=True)
  return metatile_index

def copy_palette(output_folder, palette_filename):
  # I'm certain this is probably a one-liner, but I am far too lazy to look it up today
  with open(palette_filename, "rb") as source_file:
    data = source_file.read()
    target_path = (Path(output_folder) / "globalpalette.pal")
    with open(target_path, "wb") as destination_file:
      destination_file.write(data)

if len(sys.argv) != 3:
  print("Usage: generatetilesets.py configuration.json <output/folder>")
  sys.exit(-1)
configuration_path = sys.argv[1]
output_folder = sys.argv[2]

with open(configuration_path, "r") as metadata_file:
  metadata = json.load(metadata_file)

  base_path = Path(configuration_path).parent.parent
  first_chr_folder = (base_path / "patternsets" / metadata["chr0"]).resolve()
  second_chr_folder = (base_path / "patternsets" /  metadata["chr1"]).resolve()
  palette_filename = (base_path / "palettes" /  metadata["palette"]).resolve()

  pathlib.Path(output_folder).mkdir(parents=True, exist_ok=True)

  scriptdir = os.path.dirname(__file__)
  nes_global_palette = read_nes_palette(os.path.join(scriptdir,"ntscpalette.pal"))
  bg_palette_as_rgb = nes_to_rgb(palette_filename, nes_global_palette)

  generate_palette_variants(first_chr_folder, output_folder, bg_palette_as_rgb, prefix="chr0_")
  generate_palette_variants(second_chr_folder, output_folder, bg_palette_as_rgb, prefix="chr1_")

  generate_tileset(first_chr_folder, output_folder, metatile_index=0, attribute_index=0, chr=0, bg=0)
  generate_tileset(first_chr_folder, output_folder, metatile_index=0, attribute_index=1, chr=0, bg=1)
  generate_tileset(first_chr_folder, output_folder, metatile_index=0, attribute_index=2, chr=0, bg=2)
  next_metatile_index = generate_tileset(first_chr_folder, output_folder, metatile_index=0, attribute_index=3, chr=0, bg=3)

  generate_tileset(second_chr_folder, output_folder, metatile_index=next_metatile_index, attribute_index=0, chr=1, bg=0)
  generate_tileset(second_chr_folder, output_folder, metatile_index=next_metatile_index, attribute_index=1, chr=1, bg=1)
  generate_tileset(second_chr_folder, output_folder, metatile_index=next_metatile_index, attribute_index=2, chr=1, bg=2)
  generate_tileset(second_chr_folder, output_folder, metatile_index=next_metatile_index, attribute_index=3, chr=1, bg=3)

  copy_palette(output_folder, palette_filename)
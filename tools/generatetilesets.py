#!/usr/bin/env python3

from xml import etree
from xml.etree.ElementTree import ElementTree, Element

from PIL import Image
import pathlib
from pathlib import Path
import os, re, sys

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

def generate_tileset(input_folder, output_folder, metatile_index=0, attribute_index=0, prefix=""):
  # start by grabbing the full list of tilenames; we need the length
  # for the header
  input_filenames = png_filenames(input_folder)

  # generate the XML document root and give it appropriate attributes for Tiled
  tileset_element = Element("tileset", attrib={
    "version": "1.8",
    "tiledversion": "1.8.2",
    "name": "test_tileset",
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
  output_path = (Path(output_folder) / (prefix+"test_tileset.tsx")).resolve()
  document.write(output_path,encoding="UTF-8",xml_declaration=True)

if len(sys.argv) != 5:
  print("Usage: generatetilesets.py <first/chr/folder> <second/chr/folder> <palette.pal> <output/folder>")
  sys.exit(-1)
first_chr_folder = sys.argv[1]
second_chr_folder = sys.argv[2]
palette_filename = sys.argv[3]
output_folder = sys.argv[4]

pathlib.Path(output_folder).mkdir(parents=True, exist_ok=True)

scriptdir = os.path.dirname(__file__)
nes_global_palette = read_nes_palette(os.path.join(scriptdir,"ntscpalette.pal"))
bg_palette_as_rgb = nes_to_rgb(palette_filename, nes_global_palette)

generate_palette_variants(first_chr_folder, output_folder, bg_palette_as_rgb, prefix="chr0_")
# generate_palette_variants(second_chr_folder, output_folder, bg_palette_as_rgb, prefix="chr1_")

generate_tileset(first_chr_folder, output_folder, metatile_index=0, attribute_index=0, prefix="chr0_bg0_")
generate_tileset(first_chr_folder, output_folder, metatile_index=0, attribute_index=1, prefix="chr0_bg1_")
generate_tileset(first_chr_folder, output_folder, metatile_index=0, attribute_index=2, prefix="chr0_bg2_")
generate_tileset(first_chr_folder, output_folder, metatile_index=0, attribute_index=3, prefix="chr0_bg3_")
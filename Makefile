.PHONY: all clean dir run

ARTDIR := art
SOURCEDIR := prg
CHRDIR := chr
BUILDDIR := build
ROM_NAME := $(notdir $(CURDIR)).nes
DBG_NAME := $(notdir $(CURDIR)).dbg

# Assembler files, for building out the banks
PRG_ASM_FILES := $(wildcard $(SOURCEDIR)/*.s)
CHR_ASM_FILES := $(wildcard $(CHRDIR)/*.s)
O_FILES := \
  $(patsubst $(SOURCEDIR)/%.s,$(BUILDDIR)/%.o,$(PRG_ASM_FILES)) \
  $(patsubst $(CHRDIR)/%.s,$(BUILDDIR)/%.o,$(CHR_ASM_FILES))

# Artwork files, for performing conversions to NES format bitplanes
SPRITE_FILES := $(wildcard $(ARTDIR)/sprites/*.png)
RAW_CHR_FILES := \
	$(patsubst $(ARTDIR)/sprites/%.png,$(BUILDDIR)/sprites/%.chr,$(SPRITE_FILES)) \
	
# Data files (maps, game data, etc) for more complex conversions
MAP_FILES := $(wildcard $(ARTDIR)/maps/*.tmx)
BIN_FILES := \
	$(patsubst $(ARTDIR)/maps/%.tmx,$(BUILDDIR)/maps/%.incs,$(MAP_FILES))

PATTERNSET_FOLDERS := $(wildcard $(ARTDIR)/patternsets/*)
PATTERNSET_CHR_FILES := $(patsubst $(ARTDIR)/patternsets/%,$(BUILDDIR)/patternsets/%.chr,$(PATTERNSET_FOLDERS))

TILESETS := $(wildcard $(ARTDIR)/tilesets/*.json)
TILESET_FOLDERS := $(patsubst $(ARTDIR)/tilesets/%.json,$(ARTDIR)/tilesets/%,$(TILESETS))

FONTS := $(wildcard $(ARTDIR)/fonts/*.png)
FONT_CHR_FILES := $(patsubst $(ARTDIR)/fonts/%.png,$(BUILDDIR)/fonts/%.high.chr,$(FONTS))

DIALOG_PORTRAITS := $(wildcard $(ARTDIR)/dialog_portraits/*.png)
DIALOG_PORTRAIT_CHR_FILES := $(patsubst $(ARTDIR)/dialog_portraits/%.png,$(BUILDDIR)/dialog_portraits/%.even.chr,$(DIALOG_PORTRAITS))

.PRECIOUS: $(BIN_FILES) $(RAW_CHR_FILES) $(TILESET_CHR_FILES) $(FONT_CHR_FILES) $(DIALOG_PORTRAIT_CHR_FILES) $(PATTERNSET_CHR_FILES)

all: dir $(ROM_NAME)

dir:
	@mkdir -p build/sprites
	@mkdir -p build/patternsets
	@mkdir -p build/maps
	@mkdir -p build/fonts
	@mkdir -p build/dialog_portraits

clean:
	-@rm -rf build
	-@rm -f $(ROM_NAME)
	-@rm -f $(DBG_NAME)

run: dir $(ROM_NAME)
	rusticnes-sdl $(ROM_NAME)

mesen: dir $(ROM_NAME)
	mono vendor/Mesen-X-v1.0.0.exe $(ROM_NAME)

beta: dir $(ROM_NAME)
	/home/zeta0134/Downloads/MesenBeta/Mesen $(ROM_NAME)

debug: dir $(ROM_NAME)
	mono vendor/Mesen-X-v1.0.0.exe $(ROM_NAME) debug_entity_0.lua

profile: dir $(ROM_NAME)
	mono vendor/Mesen-X-v1.0.0.exe $(ROM_NAME) debug_color_performance.lua

everdrive: dir $(ROM_NAME)
	mono vendor/edlink-n8.exe $(ROM_NAME)

$(ROM_NAME): $(SOURCEDIR)/mmc3.cfg $(O_FILES)
	ld65 -m $(BUILDDIR)/map.txt --dbgfile $(DBG_NAME) -o $@ -C $^

$(BUILDDIR)/%.o: $(SOURCEDIR)/%.s $(PATTERNSET_CHR_FILES) $(BIN_FILES) $(BUILDDIR)/collision_tileset.incs
	ca65 -g -o $@ $<

$(BUILDDIR)/%.o: $(CHRDIR)/%.s $(RAW_CHR_FILES) $(PATTERNSET_CHR_FILES) $(FONT_CHR_FILES) $(DIALOG_PORTRAIT_CHR_FILES)
	ca65 -g -o $@ $<

$(BUILDDIR)/sprites/%.chr: $(ARTDIR)/sprites/%.png
	vendor/pilbmp2nes.py $< -o $@ --planes="0;1" --tile-height=16

$(BUILDDIR)/maps/%.incs: $(ARTDIR)/maps/%.tmx $(TILESET_FOLDERS)
	tools/convertmap.py $< $@

$(BUILDDIR)/patternsets/%.chr: $(ARTDIR)/patternsets/%
	tools/convertpatternset.py $< $@ $(basename $@).mt

$(BUILDDIR)/collision_tileset.incs: tools/generatecollisionset.py tools/convertmap.py
	tools/generatecollisionset.py $@

$(ARTDIR)/tilesets/%: $(ARTDIR)/tilesets/%.json
	tools/generatetilesets.py $< $@

$(BUILDDIR)/fonts/%.high.chr: $(ARTDIR)/fonts/%.png
	tools/convertfont.py $< $@ $(basename $(basename $@)).low.chr

$(BUILDDIR)/dialog_portraits/%.even.chr: $(ARTDIR)/dialog_portraits/%.png
	tools/mangledialogportrait.py $< $@ $(basename $(basename $@)).odd.chr


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
	$(patsubst $(ARTDIR)/maps/%.tmx,$(BUILDDIR)/maps/%.bin,$(MAP_FILES))
TILESET_FILES := $(wildcard $(ARTDIR)/tilesets/*.tsx)
TILESET_CHR_FILES := $(patsubst $(ARTDIR)/tilesets/%.tsx,$(BUILDDIR)/tilesets/%.chr,$(TILESET_FILES))

.PRECIOUS: $(BIN_FILES)

all: dir $(ROM_NAME)

dir:
	@mkdir -p build/sprites
	@mkdir -p build/tilesets
	@mkdir -p build/maps

clean:
	-@rm -rf build
	-@rm -f $(ROM_NAME)
	-@rm -f $(DBG_NAME)

run: dir $(ROM_NAME)
	rusticnes-sdl $(ROM_NAME)

mesen: dir $(ROM_NAME)
	mono vendor/Mesen-X-v1.0.0.exe $(ROM_NAME)

$(ROM_NAME): $(SOURCEDIR)/mmc3.cfg $(O_FILES)
	ld65 -m $(BUILDDIR)/map.txt --dbgfile $(DBG_NAME) -o $@ -C $^

$(BUILDDIR)/%.o: $(SOURCEDIR)/%.s $(BIN_FILES) $(TILESET_CHR_FILES)
	ca65 -g -o $@ $<

$(BUILDDIR)/%.o: $(CHRDIR)/%.s $(RAW_CHR_FILES) $(TILESET_CHR_FILES)
	ca65 -g -o $@ $<

$(BUILDDIR)/sprites/%.chr: $(ARTDIR)/sprites/%.png
	vendor/pilbmp2nes.py $< -o $@ --planes="0;1" --tile-height=16

$(BUILDDIR)/maps/%.bin: $(ARTDIR)/maps/%.tmx
	tools/convertmap.py $< $@

$(BUILDDIR)/tilesets/%.chr: $(ARTDIR)/tilesets/%.tsx
	tools/converttileset.py $< $@ $(basename $@).mt $(basename $@).pal






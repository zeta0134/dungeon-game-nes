.PHONY: all clean dir run

ARTDIR := art
SOURCEDIR := prg
CHRDIR := chr
BUILDDIR := build
ROM_NAME := $(notdir $(CURDIR)).nes

# Assembler files, for building out the banks
PRG_ASM_FILES := $(wildcard $(SOURCEDIR)/*.s)
CHR_ASM_FILES := $(wildcard $(CHRDIR)/*.s)
O_FILES := \
  $(patsubst $(SOURCEDIR)/%.s,$(BUILDDIR)/%.o,$(PRG_ASM_FILES)) \
  $(patsubst $(CHRDIR)/%.s,$(BUILDDIR)/%.o,$(CHR_ASM_FILES))

# Artwork files, for performing conversions to NES format bitplanes
SPRITE_FILES := $(wildcard $(ARTDIR)/sprites/*.png)
TILE_FILES := $(wildcard $(ARTDIR)/tiles/*.png)
CHR_FILES := \
	$(patsubst $(ARTDIR)/sprites/%.png,$(BUILDDIR)/sprites/%.chr,$(SPRITE_FILES)) \
	$(patsubst $(ARTDIR)/tiles/%.png,$(BUILDDIR)/tiles/%.chr,$(TILE_FILES))


all: dir $(ROM_NAME)

dir:
	@mkdir -p build/sprites
	@mkdir -p build/tiles

clean:
	-@rm -rf build
	-@rm -f $(ROM_NAME)

run: dir $(ROM_NAME)
	rusticnes-sdl $(ROM_NAME)

$(ROM_NAME): $(SOURCEDIR)/mmc3.cfg $(O_FILES)
	ld65 -m $(BUILDDIR)/map.txt -o $@ -C $^

$(BUILDDIR)/%.o: $(SOURCEDIR)/%.s
	ca65 -o $@ $<

$(BUILDDIR)/%.o: $(CHRDIR)/%.s $(CHR_FILES)
	ca65 -o $@ $<

$(BUILDDIR)/sprites/%.chr: $(ARTDIR)/sprites/%.png
	vendor/pilbmp2nes.py $< -o $@ --planes="0;1" --tile-height=16

$(BUILDDIR)/tiles/%.chr: $(ARTDIR)/tiles/%.png
	vendor/pilbmp2nes.py $< -o $@ --planes="0;1"






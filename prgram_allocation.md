# PRG RAM Allocation

We target MMC3, with the following capabilities for general purpose memory:
PRG RAM: 8192 bytes (8k)
NES Interlal WRAM: 2048 bytes (2k)

For practical purposes, we are not considering the zero page, stack page, or OAM shadow page to be
available for general program use. As such:
NES General Purpose WRAM: 1280 bytes (1.25)

Total Available RAM: 9472 bytes (9.25k)

PRG RAM is available from 0x6000 - 0x7FFF. MMC3 does not permit bank switching this memory region, so the amount
and address are fixed. We'll put our Shadow OAM at 0x0200, leaving the region from 0x0300 - 0x07FF available as 
internal WRAM.

Within the MMC3, the PRG RAM area _can_ be battery backed, so we should generally prefer WRAM for temporary game
structures. We will certainly need to be efficient with SRAM use, as we need the lion's share of PRG RAM available
for game engine purposes.

## Map Data
Current Room: 64 metatiles x 32 metatiles* = **2048 bytes**
Tilemap: 256 tiles x (4 CHR tiles + 4 Collision data + 1 flags) = **2304 bytes**
Attribute Shadow = 32 4x4 metatiles x 16 4x4 metatiles = **512 bytes**

Note: Rooms can be any arbitrary rectangle shape that fits in this space, the width/height is not constrained
by the engine.
Theoretical widest room: 170x12 (10.6 screens wide)
Theoretical tallest room: 16x128 (10.6 playfields tall, or around 9.14 "screens" tall)

## Sound Engine
"bhop" is likely our engine of choice here. It consumes around 1 page but is still under development.
Call this: **512 bytes** (for safety)
If bhop doesn't gain SFX support, we'll need some state for that as well, included in the above.

## Metasprites
Metasprites contain position and animation state for drawing a graphical entity onscreen. The engine currently 
permits 21 active metasprites, which in hindsight is a large number.

One metasprite requires:
Position: 4 bytes
AnimationAddr: 2 bytes
AnimationFrameAddr: 2 bytes
FrameCounter: 1 byte
DelayCounter: 1 byte
TileOffset: 1 byte
PaletteOffset: 1 byte
Total: 12 bytes
All Metasprites: **252 bytes**

There can be more or less metasprites than entities, they're tracked entirely separately. Magic sprites in particular
are likely to use the metasprite system, though bullets and simpler particles may be their own thing.

## Entities
The plan is to constrain entities in a given room by the number of horizontal tiles contained in their sprite art.
Since the player is on average 2 tiles wide, this means there can be at most 6 NPCs active in a single room, with
1-3 NPCs being *far* more common. We'll want enough slots in the entity list to support invisible puzzle objects
and stuff like projectiles and magic attacks. Let's conservatively plan for up to 16 active entities.

A single entity requires:
Update Function: 2 byte
Position: 4 bytes
MetaSprite Index: 1 byte
Arbitrary Data: 9 bytes
Total: 16 bytes
All Entities: **256 bytes**

## Total (so far)

Total Available RAM: 9472 bytes (9.25k)
Map Data (too big for WRAM): 4864 bytes
Other Structures: 1020 bytes
Remaining in PRG RAM / potential SRAM: 3328 bytes
Remaining in WRAM: 260 bytes
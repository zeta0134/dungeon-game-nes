# Dungeon Game (Code Name)

Work in progress! This is a project to teach myself NES homebrew development, targeting the MMC3 mapper. I have *no idea what I'm doing.* Expect lots of bugs. :)

# Build instructions

Depends on [cc65](https://github.com/cc65/cc65) tooling, so have that installed and available on your operating system's PATH equivalent. Also depends on python, so make sure that's available on Windows. Then to compile the ROM from scratch:

```
make
```

If you have [RusticNES-sdl](https://github.com/zeta0134/rusticnes-sdl) available on your path, you can quickly run the game, useful for testing. Adjust the makefile to taste if you prefer a different emulator:
```
make run
```

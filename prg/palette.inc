.global BgPaletteDirty
.global ObjPaletteDirty
.global BgPaletteBuffer
.global ObjPaletteBuffer
.global HudPaletteBuffer
.global Brightness
.global HudPaletteActive
.global HudGradientBuffer

; These accept parameters in A, and so are in fixed memory. (And also smol)
.global set_brightness

.global FAR_refresh_palettes
.global FAR_refresh_palettes_gameloop ; *

.global FAR_init_hud_palette ; *
.global FAR_refresh_palettes_lag_frame ; *
.global FAR_queue_arbitrary_bg_palette  ; *
.global FAR_queue_arbitrary_obj_palette ; *
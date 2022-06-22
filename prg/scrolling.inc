.global FAR_init_map
.global FAR_init_attributes
.global FAR_scroll_camera
.global FAR_render_initial_viewport
.global FAR_init_scroll_position

.global set_scroll_for_entire_frame

.global MapData, AttributeData, TilesetTopLeft, TilesetTopRight, TilesetBottomLeft, TilesetBottomRight, TilesetAttributes
.global DynamicChrBank, StaticChrBank
.globalzp CameraXTileTarget, CameraXScrollTarget, CameraYTileTarget, CameraYScrollTarget, MapWidth, MapHeight, AttributeWidth, PpuXTileTarget, PpuYTileTarget
.globalzp CameraYScrollCurrent, CameraYTileCurrent, CameraXScrollCurrent, CameraXTileCurrent

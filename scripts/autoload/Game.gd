extends Node
## Global map state, tools, undo, save/load, export helpers.

const APP_VERSION := "0.7.1+15"
const AUTOSAVE_PATH := "user://autosave.json"
const MAX_UNDO := 48

## Grid sizes offered in the New-map menu.
const MAP_SIZES := [32, 48, 64]

signal map_changed
signal tool_changed
signal selection_changed
signal brush_changed
signal custom_changed

enum Tool { PEN, ERASE, FILL }

## Brush sizes — radius in cells (0=1×1, 1=3×3, 2=5×5)
const BRUSH_RADII := [0, 1, 2]
const BRUSH_LABELS := ["1×", "3×", "5×"]

var settings: Dictionary = {
	"locale": "en",
}

var map: MapData
var active_layer: String = Palette.LAYER_GROUND
var selected_tile: int = Palette.GRASS
var current_tool: Tool = Tool.PEN
var brush_index: int = 0
var grid_size: int = 32

var _undo: Array[MapData] = []
var _redo: Array[MapData] = []
var _painting: bool = false


func _ready() -> void:
	Palette.ensure()
	load_settings()
	if not _try_load_autosave():
		map = MapTemplates.make(MapTemplates.ID_SETTLEMENT)
	map_changed.emit()


func new_map(seeded: bool = true) -> void:
	new_from_template(MapTemplates.ID_SETTLEMENT if seeded else MapTemplates.ID_BLANK)


func set_map_size(size: int) -> void:
	if size in MAP_SIZES and size != grid_size:
		grid_size = size
		_push_undo()
		map = map.resized(size, size)
		_redo.clear()
		_persist_autosave()
		map_changed.emit()


func new_from_template(template_id: String) -> void:
	_push_undo()
	Palette.clear_custom()
	TileAtlas.clear_custom()
	map = MapTemplates.make(template_id)
	if map.w != grid_size or map.h != grid_size:
		map = map.resized(grid_size, grid_size)
	_redo.clear()
	_persist_autosave()
	map_changed.emit()
	custom_changed.emit()


func set_tool(t: Tool) -> void:
	if current_tool == t:
		return
	current_tool = t
	tool_changed.emit()


func set_layer(layer: String) -> void:
	if layer != Palette.LAYER_GROUND and layer != Palette.LAYER_PROPS:
		return
	if active_layer == layer:
		return
	active_layer = layer
	# auto-pick first tile of that layer if current doesn't match
	if Palette.layer_of(selected_tile) != layer and selected_tile != Palette.EMPTY:
		var ids: Array[int] = Palette.ground_ids() if layer == Palette.LAYER_GROUND else Palette.prop_ids()
		if not ids.is_empty():
			selected_tile = ids[0]
	selection_changed.emit()


func select_tile(id: int) -> void:
	selected_tile = id
	if id != Palette.EMPTY:
		var layer := Palette.layer_of(id)
		if layer != active_layer:
			active_layer = layer
	current_tool = Tool.PEN
	selection_changed.emit()
	tool_changed.emit()


func cycle_brush() -> void:
	brush_index = (brush_index + 1) % BRUSH_RADII.size()
	brush_changed.emit()


func get_brush_radius() -> int:
	return BRUSH_RADII[brush_index]


func begin_stroke() -> void:
	if _painting:
		return
	_painting = true
	_push_undo()


func end_stroke() -> void:
	if not _painting:
		return
	_painting = false
	_redo.clear()
	_persist_autosave()
	map_changed.emit()


func paint_at(c: int, r: int) -> void:
	if not map.in_bounds(c, r):
		return
	match current_tool:
		Tool.PEN:
			var layer := active_layer
			var tid := selected_tile
			if tid != Palette.EMPTY and Palette.layer_of(tid) != layer:
				layer = Palette.layer_of(tid)
			var radius := get_brush_radius()
			var changed := false
			for dr in range(-radius, radius + 1):
				for dc in range(-radius, radius + 1):
					if map.set_cell(layer, c + dc, r + dr, tid):
						changed = true
			if changed:
				map_changed.emit()
		Tool.ERASE:
			var radius := get_brush_radius()
			var erased := false
			for dr in range(-radius, radius + 1):
				for dc in range(-radius, radius + 1):
					var cc := c + dc
					var rr := r + dr
					if not map.in_bounds(cc, rr):
						continue
					if map.get_cell(Palette.LAYER_PROPS, cc, rr) != Palette.EMPTY:
						if map.set_cell(Palette.LAYER_PROPS, cc, rr, Palette.EMPTY):
							erased = true
					else:
						if map.set_cell(Palette.LAYER_GROUND, cc, rr, Palette.GRASS):
							erased = true
			if erased:
				map_changed.emit()
		Tool.FILL:
			_flood_fill(c, r)


func _flood_fill(c: int, r: int) -> void:
	var layer := active_layer
	var tid := selected_tile
	if tid != Palette.EMPTY and Palette.layer_of(tid) != layer:
		layer = Palette.layer_of(tid)
	# props fill only single cell (props sparse)
	if layer == Palette.LAYER_PROPS:
		if map.set_cell(layer, c, r, tid):
			map_changed.emit()
		return
	if not map.in_bounds(c, r):
		return
	var target := map.get_cell(layer, c, r)
	if target == tid:
		return
	# Seen-on-push so each cell enters the stack at most once;
	# the loop is bounded by the full map cell count (no truncation).
	var seen := {}
	var stack: Array[Vector2i] = [Vector2i(c, r)]
	seen[r * map.w + c] = true
	var filled := 0
	var max_cells := map.w * map.h
	while not stack.is_empty() and filled < max_cells:
		var p: Vector2i = stack.pop_back()
		if map.get_cell(layer, p.x, p.y) != target:
			continue
		if map.set_cell(layer, p.x, p.y, tid):
			filled += 1
		for n in [Vector2i(p.x + 1, p.y), Vector2i(p.x - 1, p.y), Vector2i(p.x, p.y + 1), Vector2i(p.x, p.y - 1)]:
			if not map.in_bounds(n.x, n.y):
				continue
			var key: int = n.y * map.w + n.x
			if not seen.has(key):
				seen[key] = true
				stack.append(n)
	if filled > 0:
		map_changed.emit()


func _push_undo() -> void:
	if map == null:
		return
	_undo.append(map.clone())
	if _undo.size() > MAX_UNDO:
		_undo.pop_front()


func undo() -> void:
	if _undo.is_empty():
		return
	_redo.append(map.clone())
	map = _undo.pop_back()
	grid_size = map.w
	_persist_autosave()
	map_changed.emit()


func redo() -> void:
	if _redo.is_empty():
		return
	_undo.append(map.clone())
	map = _redo.pop_back()
	grid_size = map.w
	_persist_autosave()
	map_changed.emit()


func export_json_text() -> String:
	return map.to_json()


func import_json_text(text: String) -> bool:
	var m := MapData.from_json(text)
	if m == null:
		return false
	_push_undo()
	_sync_custom_tiles(m)
	map = m
	grid_size = m.w
	_redo.clear()
	_persist_autosave()
	map_changed.emit()
	custom_changed.emit()
	return true


## Register any custom tiles carried by the map (load/import path).
func _sync_custom_tiles(m: MapData) -> void:
	if m == null or m.custom_tiles.is_empty():
		Palette.clear_custom()
		TileAtlas.clear_custom()
		return
	Palette.clear_custom()
	TileAtlas.clear_custom()
	for id in m.custom_tiles:
		var e: Dictionary = m.custom_tiles[id]
		if not (e is Dictionary):
			continue
		var layer := str(e.get("layer", Palette.LAYER_GROUND))
		if layer != Palette.LAYER_GROUND and layer != Palette.LAYER_PROPS:
			layer = Palette.LAYER_GROUND
		var color: Color = Color(0.7, 0.7, 0.7)
		if e.has("color"):
			color = Color(e["color"])
		Palette.register_custom(int(id), str(e.get("name", "Custom")), layer, color)
		TileAtlas.register_custom_texture(int(id), str(e.get("png", "")))


## Upload a PNG as a new paintable tile; returns the new tile id or -1 on failure.
func add_custom_tile(png_b64: String, name: String, layer: String) -> int:
	if png_b64.is_empty():
		return -1
	if layer != Palette.LAYER_GROUND and layer != Palette.LAYER_PROPS:
		layer = Palette.LAYER_GROUND
	var id := Palette.next_custom_id()
	if not TileAtlas.register_custom_texture(id, png_b64):
		return -1
	Palette.register_custom(id, name if name.strip_edges() != "" else "Custom", layer, Color(0.7, 0.7, 0.7))
	if map == null:
		return -1
	map.custom_tiles[str(id)] = {
		"name": name if name.strip_edges() != "" else "Custom",
		"layer": layer,
		"png": png_b64,
	}
	_persist_autosave()
	custom_changed.emit()
	map_changed.emit()
	return id


func save_json_to_path(path: String) -> Error:
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		return FileAccess.get_open_error()
	f.store_string(map.to_json())
	f.close()
	return OK


func load_json_from_path(path: String) -> Error:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return FileAccess.get_open_error()
	var text := f.get_as_text()
	f.close()
	if not import_json_text(text):
		return ERR_PARSE_ERROR
	return OK


func _persist_autosave() -> void:
	if map == null:
		return
	var f := FileAccess.open(AUTOSAVE_PATH, FileAccess.WRITE)
	if f:
		f.store_string(map.to_json())
		f.close()


func _try_load_autosave() -> bool:
	if not FileAccess.file_exists(AUTOSAVE_PATH):
		return false
	var f := FileAccess.open(AUTOSAVE_PATH, FileAccess.READ)
	if f == null:
		return false
	var text := f.get_as_text()
	f.close()
	var m := MapData.from_json(text)
	if m == null:
		# corrupt autosave → fall back to template instead of a blank map
		return false
	_sync_custom_tiles(m)
	map = m
	grid_size = m.w
	return true


func load_settings() -> void:
	var f := FileAccess.open("user://settings.cfg", FileAccess.READ)
	if f:
		var data: Variant = f.get_var()
		if data is Dictionary:
			settings.merge(data, true)
		f.close()


func save_settings() -> void:
	var f := FileAccess.open("user://settings.cfg", FileAccess.WRITE)
	if f:
		f.store_var(settings)
		f.close()


func set_title(new_title: String) -> void:
	if map == null:
		return
	map.title = new_title if new_title.strip_edges() != "" else "Untitled"
	_persist_autosave()
	map_changed.emit()


func filename_base() -> String:
	var base := map.title.to_lower()
	var out := ""
	for i in range(base.length()):
		var ch := base[i]
		if (ch >= "a" and ch <= "z") or (ch >= "0" and ch <= "9"):
			out += ch
		elif ch == " " or ch == "_" or ch == "-":
			out += "-"
	while "--" in out:
		out = out.replace("--", "-")
	out = out.strip_edges(true, true).trim_prefix("-").trim_suffix("-")
	return out if out != "" else "isometric-map"


## --- Share link (hash-based) ---

## Compressed share hash — full 32×32 map drops from ~6.9KB base64 to ~900 chars.
## Prefix "z1" marks the compressed format; plain base64 links (v0.3.0) still load.
func export_share_hash() -> String:
	var packed := map.to_json().to_utf8_buffer()
	var compressed := packed.compress(FileAccess.COMPRESSION_ZSTD)
	return "z1" + Marshalls.raw_to_base64(compressed)


func import_share_hash(b64: String) -> bool:
	if b64.is_empty():
		return false
	if b64.begins_with("z1"):
		var raw := Marshalls.base64_to_raw(b64.substr(2))
		if raw.is_empty():
			return false
		var packed := raw.decompress(256 * 1024, FileAccess.COMPRESSION_ZSTD)
		if packed.is_empty():
			return false
		return import_json_text(packed.get_string_from_utf8())
	# legacy v0.3.0 plain base64
	var json := Marshalls.base64_to_utf8(b64)
	if json.is_empty():
		return false
	return import_json_text(json)

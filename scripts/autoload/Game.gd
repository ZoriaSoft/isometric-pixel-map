extends Node
## Global map state, tools, undo, save/load, export helpers.

const APP_VERSION := "0.3.1+9"
const AUTOSAVE_PATH := "user://autosave.json"
const MAX_UNDO := 48

signal map_changed
signal tool_changed
signal selection_changed
signal brush_changed

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


func new_from_template(template_id: String) -> void:
	_push_undo()
	map = MapTemplates.make(template_id)
	_redo.clear()
	_persist_autosave()
	map_changed.emit()


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
	# Mark seen on push so each cell enters the stack at most once —
	# a pop-count guard truncates fills larger than ~W*H/4 cells.
	var seen := {}
	var stack: Array[Vector2i] = [Vector2i(c, r)]
	seen[r * MapData.W + c] = true
	var filled := 0
	var max_cells := MapData.W * MapData.H
	while not stack.is_empty() and filled < max_cells:
		var p: Vector2i = stack.pop_back()
		if map.get_cell(layer, p.x, p.y) != target:
			continue
		if map.set_cell(layer, p.x, p.y, tid):
			filled += 1
		for n in [Vector2i(p.x + 1, p.y), Vector2i(p.x - 1, p.y), Vector2i(p.x, p.y + 1), Vector2i(p.x, p.y - 1)]:
			if not map.in_bounds(n.x, n.y):
				continue
			var key: int = n.y * MapData.W + n.x
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
	_persist_autosave()
	map_changed.emit()


func redo() -> void:
	if _redo.is_empty():
		return
	_undo.append(map.clone())
	map = _redo.pop_back()
	_persist_autosave()
	map_changed.emit()


func export_json_text() -> String:
	return map.to_json()


func import_json_text(text: String) -> bool:
	var m := MapData.from_json(text)
	if m == null:
		return false
	_push_undo()
	map = m
	_redo.clear()
	_persist_autosave()
	map_changed.emit()
	return true


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
	map = m
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


## --- Share link (hash-based) ---

func export_share_hash() -> String:
	var d := map.to_dict()
	var json := JSON.stringify(d)
	return Marshalls.utf8_to_base64(json)


func import_share_hash(b64: String) -> bool:
	if b64.is_empty():
		return false
	var json := Marshalls.base64_to_utf8(b64)
	if json.is_empty():
		return false
	return import_json_text(json)

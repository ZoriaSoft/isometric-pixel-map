class_name Palette
extends RefCounted
## Built-in tile ids + colors (procedural diamonds until real atlas).

const EMPTY := 0
# Ground
const GRASS := 1
const DIRT := 2
const SAND := 3
const WATER := 4
const PATH := 5
const STONE := 6
const WOOD := 7
const SNOW := 8
const LAVA := 9
const BRIDGE := 16
# Props
const TREE := 10
const ROCK := 11
const HOUSE := 12
const FENCE := 13
const FLOWER := 14
const CRATE := 15
const BUSH := 17
const TENT := 18
const BARREL := 19
const LAMP := 20

const LAYER_GROUND := "ground"
const LAYER_PROPS := "props"

static var _defs: Dictionary = {}


static func ensure() -> void:
	if not _defs.is_empty():
		return
	_register(EMPTY, "Empty", LAYER_GROUND, Color(0, 0, 0, 0), true)
	_register(GRASS, "Grass", LAYER_GROUND, Color(0.29, 0.62, 0.35), false)
	_register(DIRT, "Dirt", LAYER_GROUND, Color(0.55, 0.40, 0.25), false)
	_register(SAND, "Sand", LAYER_GROUND, Color(0.86, 0.75, 0.45), false)
	_register(WATER, "Water", LAYER_GROUND, Color(0.22, 0.48, 0.72), false)
	_register(PATH, "Path", LAYER_GROUND, Color(0.55, 0.52, 0.48), false)
	_register(STONE, "Stone", LAYER_GROUND, Color(0.45, 0.48, 0.52), false)
	_register(WOOD, "Wood", LAYER_GROUND, Color(0.58, 0.38, 0.22), false)
	_register(SNOW, "Snow", LAYER_GROUND, Color(0.90, 0.92, 0.95), false)
	_register(LAVA, "Lava", LAYER_GROUND, Color(0.85, 0.35, 0.12), false)
	_register(BRIDGE, "Bridge", LAYER_GROUND, Color(0.52, 0.35, 0.20), false)
	_register(TREE, "Tree", LAYER_PROPS, Color(0.18, 0.48, 0.28), false)
	_register(ROCK, "Rock", LAYER_PROPS, Color(0.40, 0.42, 0.45), false)
	_register(HOUSE, "House", LAYER_PROPS, Color(0.72, 0.35, 0.28), false)
	_register(FENCE, "Fence", LAYER_PROPS, Color(0.50, 0.32, 0.18), false)
	_register(FLOWER, "Flower", LAYER_PROPS, Color(0.85, 0.45, 0.70), false)
	_register(CRATE, "Crate", LAYER_PROPS, Color(0.62, 0.48, 0.28), false)
	_register(BUSH, "Bush", LAYER_PROPS, Color(0.20, 0.42, 0.22), false)
	_register(TENT, "Tent", LAYER_PROPS, Color(0.65, 0.25, 0.22), false)
	_register(BARREL, "Barrel", LAYER_PROPS, Color(0.48, 0.30, 0.16), false)
	_register(LAMP, "Lamp", LAYER_PROPS, Color(0.85, 0.78, 0.40), false)


static func _register(id: int, name: String, layer: String, color: Color, is_empty: bool) -> void:
	_defs[id] = {
		"id": id,
		"name": name,
		"layer": layer,
		"color": color,
		"empty": is_empty,
	}


static func get_def(id: int) -> Dictionary:
	ensure()
	return _defs.get(id, _defs[EMPTY])


static func color_of(id: int) -> Color:
	return get_def(id).get("color", Color.MAGENTA)


static func name_of(id: int) -> String:
	return str(get_def(id).get("name", "?"))


static func layer_of(id: int) -> String:
	return str(get_def(id).get("layer", LAYER_GROUND))


static func is_empty(id: int) -> bool:
	return bool(get_def(id).get("empty", id == 0))


static func ground_ids() -> Array[int]:
	return [GRASS, DIRT, SAND, WATER, PATH, STONE, WOOD, SNOW, LAVA, BRIDGE]


static func prop_ids() -> Array[int]:
	return [TREE, ROCK, HOUSE, FENCE, FLOWER, CRATE, BUSH, TENT, BARREL, LAMP]


static func all_paintable() -> Array[int]:
	var out: Array[int] = []
	out.append_array(ground_ids())
	out.append_array(prop_ids())
	return out

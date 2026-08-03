class_name MapData
extends RefCounted
## 32×32 isometric map — ground + props layers.

const VERSION := 1
const W := 32
const H := 32
const TILE_W := 32
const TILE_H := 16

var title: String = "Untitled"
var ground: PackedInt32Array
var props: PackedInt32Array

func _init() -> void:
	clear()


func clear() -> void:
	var n := W * H
	ground = PackedInt32Array()
	ground.resize(n)
	props = PackedInt32Array()
	props.resize(n)
	for i in n:
		ground[i] = 0
		props[i] = 0
	title = "Untitled"


func idx(c: int, r: int) -> int:
	return r * W + c


func in_bounds(c: int, r: int) -> bool:
	return c >= 0 and r >= 0 and c < W and r < H


func get_cell(layer: String, c: int, r: int) -> int:
	if not in_bounds(c, r):
		return 0
	var i := idx(c, r)
	return ground[i] if layer == "ground" else props[i]


func set_cell(layer: String, c: int, r: int, tile_id: int) -> bool:
	if not in_bounds(c, r):
		return false
	var i := idx(c, r)
	if layer == "ground":
		if ground[i] == tile_id:
			return false
		ground[i] = tile_id
	else:
		if props[i] == tile_id:
			return false
		props[i] = tile_id
	return true


func clone() -> MapData:
	var m := MapData.new()
	m.title = title
	m.ground = ground.duplicate()
	m.props = props.duplicate()
	return m


func apply_snapshot(other: MapData) -> void:
	title = other.title
	ground = other.ground.duplicate()
	props = other.props.duplicate()


## Classic 2:1 iso: cell → screen (top of diamond).
static func cell_to_screen(c: int, r: int) -> Vector2:
	var sx := (c - r) * (TILE_W / 2.0)
	var sy := (c + r) * (TILE_H / 2.0)
	return Vector2(sx, sy)


## Screen (relative to map origin) → nearest cell.
static func screen_to_cell(pos: Vector2) -> Vector2i:
	var a := pos.x / (TILE_W / 2.0)
	var b := pos.y / (TILE_H / 2.0)
	var c := int(floor((a + b) / 2.0))
	var r := int(floor((b - a) / 2.0))
	return Vector2i(c, r)


func to_dict() -> Dictionary:
	return {
		"v": VERSION,
		"w": W,
		"h": H,
		"tw": TILE_W,
		"th": TILE_H,
		"title": title,
		"layers": {
			"ground": Array(ground),
			"props": Array(props),
		},
	}


func to_json() -> String:
	return JSON.stringify(to_dict())


static func from_dict(d: Dictionary) -> MapData:
	var m := MapData.new()
	if int(d.get("w", W)) != W or int(d.get("h", H)) != H:
		push_warning("MapData: size mismatch, keeping %dx%d" % [W, H])
	m.title = str(d.get("title", "Untitled"))
	var layers: Dictionary = d.get("layers", {})
	_fill_layer(m.ground, layers.get("ground", []))
	_fill_layer(m.props, layers.get("props", []))
	return m


static func from_json(text: String) -> MapData:
	var parsed: Variant = JSON.parse_string(text)
	if parsed is Dictionary:
		return from_dict(parsed)
	return MapData.new()


static func _fill_layer(target: PackedInt32Array, src: Variant) -> void:
	if src is Array:
		var arr: Array = src
		var n: int = mini(target.size(), arr.size())
		for i in n:
			target[i] = int(arr[i])


## Hand-authored mini village seed (wow + no blank-page fear).
static func make_seed() -> MapData:
	var m := MapData.new()
	m.title = "Demo Village"
	# grass base
	for r in H:
		for c in W:
			m.ground[m.idx(c, r)] = Palette.GRASS
	# dirt patches
	for r in range(3, 6):
		for c in range(22, 27):
			m.ground[m.idx(c, r)] = Palette.DIRT
	# wood deck near plaza
	for r in range(18, 20):
		for c in range(16, 19):
			m.ground[m.idx(c, r)] = Palette.WOOD
	# dirt path cross
	for i in range(5, 27):
		m.ground[m.idx(i, 15)] = Palette.PATH
		m.ground[m.idx(i, 16)] = Palette.PATH
	for i in range(6, 24):
		m.ground[m.idx(14, i)] = Palette.PATH
		m.ground[m.idx(15, i)] = Palette.PATH
	# pond + shore
	for r in range(8, 13):
		for c in range(8, 13):
			m.ground[m.idx(c, r)] = Palette.WATER
	for c in range(7, 14):
		m.ground[m.idx(c, 7)] = Palette.SAND
		m.ground[m.idx(c, 13)] = Palette.SAND
	for r in range(8, 13):
		m.ground[m.idx(7, r)] = Palette.SAND
		m.ground[m.idx(13, r)] = Palette.SAND
	# stone plaza
	for r in range(20, 25):
		for c in range(18, 25):
			m.ground[m.idx(c, r)] = Palette.STONE
	# forest fringe
	for c in range(2, 8):
		m.props[m.idx(c, 3)] = Palette.TREE
		m.props[m.idx(c, 4)] = Palette.TREE if c % 2 == 0 else Palette.EMPTY
	for r in range(24, 29):
		m.props[m.idx(4, r)] = Palette.TREE
		m.props[m.idx(5, r)] = Palette.TREE if r % 2 == 0 else Palette.ROCK
	# village props
	m.props[m.idx(18, 12)] = Palette.TREE
	m.props[m.idx(20, 11)] = Palette.TREE
	m.props[m.idx(22, 14)] = Palette.TREE
	m.props[m.idx(9, 18)] = Palette.TREE
	m.props[m.idx(11, 20)] = Palette.ROCK
	m.props[m.idx(19, 20)] = Palette.HOUSE
	m.props[m.idx(21, 21)] = Palette.HOUSE
	m.props[m.idx(23, 22)] = Palette.HOUSE
	m.props[m.idx(17, 22)] = Palette.CRATE
	m.props[m.idx(18, 23)] = Palette.CRATE
	m.props[m.idx(12, 14)] = Palette.FLOWER
	m.props[m.idx(13, 17)] = Palette.FLOWER
	m.props[m.idx(16, 19)] = Palette.FLOWER
	m.props[m.idx(16, 18)] = Palette.FENCE
	m.props[m.idx(17, 18)] = Palette.FENCE
	m.props[m.idx(18, 18)] = Palette.FENCE
	return m

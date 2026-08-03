class_name MapTemplates
extends RefCounted
## Built-in starting maps for general use (not only Demo Village).

const ID_BLANK := "blank"
const ID_VILLAGE := "village"
const ID_FOREST := "forest"
const ID_ISLAND := "island"
const ID_DESERT := "desert"
const ID_LAKE := "lake"
const ID_OUTPOST := "outpost"

## id, title, short blurb (EN)
static func catalog() -> Array[Dictionary]:
	return [
		{"id": ID_BLANK, "title": "Blank Grass", "blurb": "Empty field — start from scratch"},
		{"id": ID_VILLAGE, "title": "Demo Village", "blurb": "Paths, pond, houses — tutorial vibe"},
		{"id": ID_FOREST, "title": "Deep Forest", "blurb": "Trees, clearing, winding path"},
		{"id": ID_ISLAND, "title": "Island", "blurb": "Water around a sandy shore"},
		{"id": ID_DESERT, "title": "Desert Ruins", "blurb": "Sand, stone scraps, sparse rocks"},
		{"id": ID_LAKE, "title": "Lakeside", "blurb": "Big lake + grass banks"},
		{"id": ID_OUTPOST, "title": "Stone Outpost", "blurb": "Fort plaza and approach road"},
	]


static func make(template_id: String) -> MapData:
	match template_id:
		ID_BLANK:
			return _blank()
		ID_VILLAGE:
			return _village()
		ID_FOREST:
			return _forest()
		ID_ISLAND:
			return _island()
		ID_DESERT:
			return _desert()
		ID_LAKE:
			return _lake()
		ID_OUTPOST:
			return _outpost()
		_:
			return _blank()


static func title_of(template_id: String) -> String:
	for e in catalog():
		if str(e.get("id", "")) == template_id:
			return str(e.get("title", template_id))
	return template_id


static func _fill_ground(m: MapData, tile_id: int) -> void:
	for i in m.ground.size():
		m.ground[i] = tile_id
		m.props[i] = Palette.EMPTY


static func _set_g(m: MapData, c: int, r: int, tid: int) -> void:
	if m.in_bounds(c, r):
		m.ground[m.idx(c, r)] = tid


static func _set_p(m: MapData, c: int, r: int, tid: int) -> void:
	if m.in_bounds(c, r):
		m.props[m.idx(c, r)] = tid


static func _rect_g(m: MapData, c0: int, r0: int, c1: int, r1: int, tid: int) -> void:
	for r in range(r0, r1 + 1):
		for c in range(c0, c1 + 1):
			_set_g(m, c, r, tid)


static func _blank() -> MapData:
	var m := MapData.new()
	m.title = "Blank Grass"
	_fill_ground(m, Palette.GRASS)
	return m


static func _village() -> MapData:
	# Legacy seed — keep hand-authored look
	return MapData.make_seed()


static func _forest() -> MapData:
	var m := MapData.new()
	m.title = "Deep Forest"
	_fill_ground(m, Palette.GRASS)
	# dirt clearing center
	_rect_g(m, 12, 12, 19, 19, Palette.DIRT)
	_rect_g(m, 13, 13, 18, 18, Palette.PATH)
	# winding path
	for i in range(4, 28):
		_set_g(m, i, 15 + int(sin(i * 0.35) * 2), Palette.PATH)
		_set_g(m, i, 16 + int(sin(i * 0.35) * 2), Palette.PATH)
	# tree density (skip clearing)
	for r in MapData.H:
		for c in MapData.W:
			if c >= 12 and c <= 19 and r >= 12 and r <= 19:
				continue
			var n := (c * 17 + r * 31) % 7
			if n == 0 or n == 3:
				_set_p(m, c, r, Palette.TREE)
			elif n == 5 and (c + r) % 11 == 0:
				_set_p(m, c, r, Palette.ROCK)
			elif n == 2 and (c * r) % 13 == 0:
				_set_p(m, c, r, Palette.FLOWER)
	# small camp
	_set_p(m, 15, 15, Palette.CRATE)
	_set_p(m, 16, 16, Palette.CRATE)
	_set_p(m, 14, 16, Palette.FENCE)
	return m


static func _island() -> MapData:
	var m := MapData.new()
	m.title = "Island"
	_fill_ground(m, Palette.WATER)
	var cx := 15.5
	var cy := 15.5
	for r in MapData.H:
		for c in MapData.W:
			var dx := float(c) - cx
			var dy := float(r) - cy
			var d := sqrt(dx * dx + dy * dy * 1.05)
			if d < 7.5:
				_set_g(m, c, r, Palette.GRASS)
			elif d < 9.2:
				_set_g(m, c, r, Palette.SAND)
			elif d < 10.5:
				_set_g(m, c, r, Palette.WATER)
	# path across island
	for c in range(10, 22):
		_set_g(m, c, 15, Palette.PATH)
		_set_g(m, c, 16, Palette.PATH)
	_set_p(m, 14, 13, Palette.TREE)
	_set_p(m, 18, 14, Palette.TREE)
	_set_p(m, 12, 17, Palette.TREE)
	_set_p(m, 16, 18, Palette.ROCK)
	_set_p(m, 15, 14, Palette.HOUSE)
	_set_p(m, 17, 17, Palette.FLOWER)
	_set_p(m, 13, 15, Palette.CRATE)
	return m


static func _desert() -> MapData:
	var m := MapData.new()
	m.title = "Desert Ruins"
	_fill_ground(m, Palette.SAND)
	# darker sand patches (dirt as dry earth)
	_rect_g(m, 4, 4, 9, 8, Palette.DIRT)
	_rect_g(m, 20, 18, 27, 24, Palette.DIRT)
	# stone ruin
	_rect_g(m, 12, 11, 19, 17, Palette.STONE)
	_rect_g(m, 13, 12, 18, 16, Palette.SAND)  # hollow courtyard
	# road
	for i in range(2, 30):
		_set_g(m, i, 20, Palette.PATH)
		_set_g(m, 14, i if i < 22 else 21, Palette.PATH)
	for r in range(11, 18):
		_set_g(m, 14, r, Palette.PATH)
	# sparse props
	for r in range(0, 32, 3):
		for c in range(0, 32, 4):
			if (c + r) % 5 == 0 and m.get_cell("ground", c, r) == Palette.SAND:
				_set_p(m, c, r, Palette.ROCK)
	_set_p(m, 15, 13, Palette.CRATE)
	_set_p(m, 16, 14, Palette.CRATE)
	_set_p(m, 17, 13, Palette.FENCE)
	_set_p(m, 11, 20, Palette.ROCK)
	_set_p(m, 22, 12, Palette.ROCK)
	return m


static func _lake() -> MapData:
	var m := MapData.new()
	m.title = "Lakeside"
	_fill_ground(m, Palette.GRASS)
	var cx := 14.0
	var cy := 14.0
	for r in MapData.H:
		for c in MapData.W:
			var dx := float(c) - cx
			var dy := float(r) - cy
			var d := sqrt(dx * dx * 0.85 + dy * dy)
			if d < 6.5:
				_set_g(m, c, r, Palette.WATER)
			elif d < 8.0:
				_set_g(m, c, r, Palette.SAND)
	# dock
	for c in range(14, 20):
		_set_g(m, c, 20, Palette.WOOD)
		_set_g(m, c, 21, Palette.WOOD)
	for r in range(18, 22):
		_set_g(m, 19, r, Palette.WOOD)
	# shore path
	for c in range(6, 26):
		_set_g(m, c, 22, Palette.PATH)
	_set_p(m, 8, 10, Palette.TREE)
	_set_p(m, 9, 18, Palette.TREE)
	_set_p(m, 22, 12, Palette.TREE)
	_set_p(m, 24, 20, Palette.TREE)
	_set_p(m, 20, 19, Palette.HOUSE)
	_set_p(m, 18, 23, Palette.FLOWER)
	_set_p(m, 12, 23, Palette.FLOWER)
	_set_p(m, 10, 22, Palette.ROCK)
	return m


static func _outpost() -> MapData:
	var m := MapData.new()
	m.title = "Stone Outpost"
	_fill_ground(m, Palette.GRASS)
	# approach road
	for r in range(0, 22):
		_set_g(m, 15, r, Palette.PATH)
		_set_g(m, 16, r, Palette.PATH)
	# outer wall ring (stone)
	_rect_g(m, 10, 18, 21, 28, Palette.STONE)
	_rect_g(m, 11, 19, 20, 27, Palette.DIRT)
	_rect_g(m, 12, 20, 19, 26, Palette.STONE)
	_rect_g(m, 13, 21, 18, 25, Palette.PATH)
	# gate opening
	_set_g(m, 15, 18, Palette.PATH)
	_set_g(m, 16, 18, Palette.PATH)
	_set_g(m, 15, 19, Palette.PATH)
	_set_g(m, 16, 19, Palette.PATH)
	# buildings
	_set_p(m, 14, 22, Palette.HOUSE)
	_set_p(m, 17, 23, Palette.HOUSE)
	_set_p(m, 15, 24, Palette.CRATE)
	_set_p(m, 16, 24, Palette.CRATE)
	_set_p(m, 13, 23, Palette.FENCE)
	_set_p(m, 18, 22, Palette.FENCE)
	# trees outside
	for c in [6, 8, 24, 26]:
		_set_p(m, c, 10, Palette.TREE)
		_set_p(m, c, 14, Palette.TREE)
	_set_p(m, 12, 12, Palette.ROCK)
	_set_p(m, 20, 8, Palette.FLOWER)
	return m

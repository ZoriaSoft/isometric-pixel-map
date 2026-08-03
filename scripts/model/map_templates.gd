class_name MapTemplates
extends RefCounted
## Job-driven starters only — every template must earn its place for real users
## (game jam, level mockup, worldbuilding, shareable art). No scenic filler.

const ID_BLANK := "blank"
const ID_SETTLEMENT := "settlement"
const ID_WILDERNESS := "wilderness"
const ID_CROSSROADS := "crossroads"
const ID_COAST := "coast"
const ID_STRONGHOLD := "stronghold"

# Legacy aliases (old saves / links)
const ID_VILLAGE := ID_SETTLEMENT
const ID_FOREST := ID_WILDERNESS
const ID_ISLAND := ID_COAST
const ID_OUTPOST := ID_STRONGHOLD


## Catalog: id + title + use-case (who needs this).
static func catalog() -> Array[Dictionary]:
	return [
		{
			"id": ID_BLANK,
			"title": "Blank",
			"blurb": "Empty grass — full control from zero",
			"use": "Any custom layout; clean canvas",
		},
		{
			"id": ID_SETTLEMENT,
			"title": "Settlement",
			"blurb": "Town hub — paths, homes, plaza",
			"use": "RPG towns, NPC hubs, story mockups",
		},
		{
			"id": ID_WILDERNESS,
			"title": "Wilderness",
			"blurb": "Outdoor wilds — trees, trail, clearing",
			"use": "Exploration, travel, nature levels",
		},
		{
			"id": ID_CROSSROADS,
			"title": "Crossroads",
			"blurb": "Overworld junction — roads meet",
			"use": "World map nodes, route planning",
		},
		{
			"id": ID_COAST,
			"title": "Coast",
			"blurb": "Land + water — shore and island shape",
			"use": "Harbor, sea, island levels",
		},
		{
			"id": ID_STRONGHOLD,
			"title": "Stronghold",
			"blurb": "Fort layout — walls, gate, yard",
			"use": "Bases, sieges, combat arenas",
		},
	]


static func make(template_id: String) -> MapData:
	var id := _normalize(template_id)
	match id:
		ID_BLANK:
			return _blank()
		ID_SETTLEMENT:
			return _settlement()
		ID_WILDERNESS:
			return _wilderness()
		ID_CROSSROADS:
			return _crossroads()
		ID_COAST:
			return _coast()
		ID_STRONGHOLD:
			return _stronghold()
		_:
			return _blank()


static func _normalize(template_id: String) -> String:
	match template_id:
		"village", "demo", "demo_village":
			return ID_SETTLEMENT
		"forest", "deep_forest":
			return ID_WILDERNESS
		"island", "lake", "lakeside":
			return ID_COAST
		"outpost", "fort", "desert":
			# desert retired → nearest useful job is stronghold / blank; map old desert → blank-ish sand via coast? better blank
			if template_id == "desert":
				return ID_BLANK
			return ID_STRONGHOLD
		_:
			return template_id


static func title_of(template_id: String) -> String:
	var id := _normalize(template_id)
	for e in catalog():
		if str(e.get("id", "")) == id:
			return str(e.get("title", id))
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
	m.title = "Blank"
	_fill_ground(m, Palette.GRASS)
	return m


static func _settlement() -> MapData:
	## Town / hub — same craft as former Demo Village (proven starter).
	var m := MapData.make_seed()
	m.title = "Settlement"
	return m


static func _wilderness() -> MapData:
	var m := MapData.new()
	m.title = "Wilderness"
	_fill_ground(m, Palette.GRASS)
	_rect_g(m, 12, 12, 19, 19, Palette.DIRT)
	_rect_g(m, 13, 13, 18, 18, Palette.PATH)
	for i in range(4, 28):
		var off := int(sin(i * 0.35) * 2)
		_set_g(m, i, 15 + off, Palette.PATH)
		_set_g(m, i, 16 + off, Palette.PATH)
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
	_set_p(m, 15, 15, Palette.CRATE)
	_set_p(m, 16, 16, Palette.CRATE)
	return m


static func _crossroads() -> MapData:
	## Overworld junction — maximum path clarity, light landmarks only.
	var m := MapData.new()
	m.title = "Crossroads"
	_fill_ground(m, Palette.GRASS)
	# N-S and E-W roads (2 tiles wide)
	for i in range(0, MapData.W):
		_set_g(m, i, 15, Palette.PATH)
		_set_g(m, i, 16, Palette.PATH)
		_set_g(m, 15, i, Palette.PATH)
		_set_g(m, 16, i, Palette.PATH)
	# center plaza
	_rect_g(m, 13, 13, 18, 18, Palette.STONE)
	_rect_g(m, 14, 14, 17, 17, Palette.PATH)
	# four approach dirt shoulders
	for d in range(3, 6):
		_set_g(m, 15 - d, 14, Palette.DIRT)
		_set_g(m, 15 + d + 1, 17, Palette.DIRT)
	# landmarks (sparse — not clutter)
	_set_p(m, 12, 12, Palette.SIGN if false else Palette.ROCK)  # no sign tile
	_set_p(m, 12, 12, Palette.ROCK)
	_set_p(m, 19, 12, Palette.TREE)
	_set_p(m, 12, 19, Palette.TREE)
	_set_p(m, 19, 19, Palette.CRATE)
	_set_p(m, 14, 14, Palette.FENCE)
	_set_p(m, 17, 14, Palette.FENCE)
	_set_p(m, 10, 10, Palette.FLOWER)
	_set_p(m, 21, 21, Palette.FLOWER)
	return m


static func _coast() -> MapData:
	## Water + land — island silhouette (clearest for harbor/sea mockups).
	var m := MapData.new()
	m.title = "Coast"
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
	for c in range(10, 22):
		_set_g(m, c, 15, Palette.PATH)
		_set_g(m, c, 16, Palette.PATH)
	# small dock
	for c in range(18, 23):
		_set_g(m, c, 17, Palette.WOOD)
	_set_p(m, 14, 13, Palette.TREE)
	_set_p(m, 18, 14, Palette.TREE)
	_set_p(m, 12, 17, Palette.TREE)
	_set_p(m, 16, 18, Palette.ROCK)
	_set_p(m, 15, 14, Palette.HOUSE)
	_set_p(m, 17, 17, Palette.FLOWER)
	_set_p(m, 13, 15, Palette.CRATE)
	return m


static func _stronghold() -> MapData:
	var m := MapData.new()
	m.title = "Stronghold"
	_fill_ground(m, Palette.GRASS)
	for r in range(0, 22):
		_set_g(m, 15, r, Palette.PATH)
		_set_g(m, 16, r, Palette.PATH)
	_rect_g(m, 10, 18, 21, 28, Palette.STONE)
	_rect_g(m, 11, 19, 20, 27, Palette.DIRT)
	_rect_g(m, 12, 20, 19, 26, Palette.STONE)
	_rect_g(m, 13, 21, 18, 25, Palette.PATH)
	_set_g(m, 15, 18, Palette.PATH)
	_set_g(m, 16, 18, Palette.PATH)
	_set_g(m, 15, 19, Palette.PATH)
	_set_g(m, 16, 19, Palette.PATH)
	_set_p(m, 14, 22, Palette.HOUSE)
	_set_p(m, 17, 23, Palette.HOUSE)
	_set_p(m, 15, 24, Palette.CRATE)
	_set_p(m, 16, 24, Palette.CRATE)
	_set_p(m, 13, 23, Palette.FENCE)
	_set_p(m, 18, 22, Palette.FENCE)
	for c in [6, 8, 24, 26]:
		_set_p(m, c, 10, Palette.TREE)
		_set_p(m, c, 14, Palette.TREE)
	_set_p(m, 12, 12, Palette.ROCK)
	return m

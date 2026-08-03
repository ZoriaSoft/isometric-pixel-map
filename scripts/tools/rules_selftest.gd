extends SceneTree
## Headless selftest — iso math, map IO, paint/fill/undo, PNG export.

func _init() -> void:
	var failed := 0
	failed += _test_iso_math()
	failed += _test_map_json()
	failed += _test_paint_fill_undo()
	failed += _test_atlas()
	failed += _test_png()
	failed += _test_seed()
	failed += _test_templates()
	if failed == 0:
		print("SELFTEST PASS")
		quit(0)
	else:
		print("SELFTEST FAIL count=", failed)
		quit(1)


func _test_atlas() -> int:
	print("== tile atlas ==")
	TileAtlas.ensure()
	for id in Palette.all_paintable():
		var tex := TileAtlas.texture_of(id)
		if tex == null:
			print("FAIL missing texture id=", id)
			return 1
		var img := tex.get_image()
		if img == null or img.get_width() != 32:
			print("FAIL texture size id=", id)
			return 1
		# at least some opaque pixels
		var opaque := 0
		for y in 32:
			for x in 32:
				if img.get_pixel(x, y).a > 0.5:
					opaque += 1
		if opaque < 20:
			print("FAIL texture empty id=", id, " opaque=", opaque)
			return 1
	print("OK tile atlas")
	return 0


func _test_iso_math() -> int:
	print("== iso math ==")
	var fails := 0
	for c in range(0, 32, 5):
		for r in range(0, 32, 5):
			var p := MapData.cell_to_screen(c, r)
			# hit center of diamond
			var center := p + Vector2(0, MapData.TILE_H / 2.0)
			var back := MapData.screen_to_cell(center)
			if back.x != c or back.y != r:
				print("FAIL roundtrip c,r=", c, r, " got=", back, " center=", center)
				fails += 1
	if fails == 0:
		print("OK iso math")
	return fails


func _test_map_json() -> int:
	print("== map json ==")
	var m := MapData.make_seed()
	m.set_cell("ground", 3, 4, Palette.DIRT)
	m.set_cell("props", 5, 6, Palette.TREE)
	var text := m.to_json()
	var m2 := MapData.from_json(text)
	if m2.get_cell("ground", 3, 4) != Palette.DIRT:
		print("FAIL ground roundtrip")
		return 1
	if m2.get_cell("props", 5, 6) != Palette.TREE:
		print("FAIL props roundtrip")
		return 1
	if m2.ground.size() != MapData.W * MapData.H:
		print("FAIL size")
		return 1
	print("OK map json")
	return 0


func _test_paint_fill_undo() -> int:
	print("== paint fill undo ==")
	# Simulate Game without full tree: use MapData directly + mini logic
	var m := MapData.new()
	for i in m.ground.size():
		m.ground[i] = Palette.GRASS
	m.set_cell("ground", 10, 10, Palette.DIRT)
	# flood fill dirt region of 1 cell to water
	var target := m.get_cell("ground", 10, 10)
	var tid := Palette.WATER
	var stack: Array[Vector2i] = [Vector2i(10, 10)]
	var seen := {}
	while not stack.is_empty():
		var p: Vector2i = stack.pop_back()
		var key := p.x * 1000 + p.y
		if seen.has(key):
			continue
		seen[key] = true
		if not m.in_bounds(p.x, p.y):
			continue
		if m.get_cell("ground", p.x, p.y) != target:
			continue
		m.set_cell("ground", p.x, p.y, tid)
		stack.append(Vector2i(p.x + 1, p.y))
		stack.append(Vector2i(p.x - 1, p.y))
		stack.append(Vector2i(p.x, p.y + 1))
		stack.append(Vector2i(p.x, p.y - 1))
	if m.get_cell("ground", 10, 10) != Palette.WATER:
		print("FAIL fill")
		return 1
	# clone/undo style
	var snap := m.clone()
	m.set_cell("ground", 10, 10, Palette.STONE)
	m.apply_snapshot(snap)
	if m.get_cell("ground", 10, 10) != Palette.WATER:
		print("FAIL undo snapshot")
		return 1
	print("OK paint fill undo")
	return 0


func _test_png() -> int:
	print("== png export ==")
	var m := MapData.make_seed()
	var img := PngExporter.render_map(m, 1)
	if img.get_width() < 32 or img.get_height() < 32:
		print("FAIL png size ", img.get_width(), "x", img.get_height())
		return 1
	var path := "user://selftest_map.png"
	var err := img.save_png(path)
	if err != OK:
		print("FAIL save png ", err)
		return 1
	print("OK png export ", img.get_width(), "x", img.get_height())
	return 0


func _test_seed() -> int:
	print("== seed ==")
	var m := MapData.make_seed()
	var non_empty_props := 0
	for i in m.props.size():
		if m.props[i] != 0:
			non_empty_props += 1
	if non_empty_props < 5:
		print("FAIL seed props too few ", non_empty_props)
		return 1
	if m.get_cell("ground", 10, 10) != Palette.WATER:
		print("FAIL seed pond")
		return 1
	print("OK seed props=", non_empty_props)
	return 0


func _test_templates() -> int:
	print("== templates ==")
	var cat := MapTemplates.catalog()
	# Job-driven set: exactly the useful six (no filler)
	if cat.size() != 6:
		print("FAIL catalog size want 6 got ", cat.size())
		return 1
	var required := [
		MapTemplates.ID_BLANK,
		MapTemplates.ID_SETTLEMENT,
		MapTemplates.ID_WILDERNESS,
		MapTemplates.ID_CROSSROADS,
		MapTemplates.ID_COAST,
		MapTemplates.ID_STRONGHOLD,
	]
	for rid in required:
		var found := false
		for e in cat:
			if str(e.get("id", "")) == rid:
				found = true
				if str(e.get("use", "")).strip_edges() == "":
					print("FAIL missing use-case for ", rid)
					return 1
				break
		if not found:
			print("FAIL missing template ", rid)
			return 1
	for e in cat:
		var id := str(e.get("id", ""))
		var m := MapTemplates.make(id)
		if m == null or m.ground.size() != MapData.W * MapData.H:
			print("FAIL template ", id)
			return 1
		if m.title.strip_edges() == "":
			print("FAIL empty title ", id)
			return 1
	var coast := MapTemplates.make(MapTemplates.ID_COAST)
	if coast.get_cell("ground", 0, 0) != Palette.WATER:
		print("FAIL coast corner not water")
		return 1
	var blank := MapTemplates.make(MapTemplates.ID_BLANK)
	if blank.get_cell("ground", 5, 5) != Palette.GRASS:
		print("FAIL blank not grass")
		return 1
	# crossroads center should be path/stone
	var cr := MapTemplates.make(MapTemplates.ID_CROSSROADS)
	var mid := cr.get_cell("ground", 15, 15)
	if mid != Palette.PATH and mid != Palette.STONE:
		print("FAIL crossroads center ", mid)
		return 1
	# legacy alias still works
	var legacy := MapTemplates.make("village")
	if legacy.title != "Settlement":
		print("FAIL legacy village alias title=", legacy.title)
		return 1
	print("OK templates count=", cat.size())
	return 0

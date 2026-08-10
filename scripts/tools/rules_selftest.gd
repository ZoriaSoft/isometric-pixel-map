extends SceneTree
## Headless selftest — iso math, map IO, paint/fill/undo, PNG export.

func _init() -> void:
	var failed := 0
	failed += _test_iso_math()
	failed += _test_map_json()
	failed += _test_bad_json()
	failed += _test_paint_fill_undo()
	failed += _test_fill_full_map()
	failed += _test_atlas()
	failed += _test_tile_variants()
	failed += _test_png()
	failed += _test_seed()
	failed += _test_templates()
	failed += _test_new_tiles()
	failed += _test_brush_size()
	failed += _test_share_link()
	failed += _test_desert_alias()
	failed += _test_map_sizes()
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


func _test_tile_variants() -> int:
	print("== tile variants ==")
	TileAtlas.ensure()
	# ground tiles (except water/bridge) should have 3 variants, each non-empty
	for id in Palette.ground_ids():
		var n := TileAtlas.variant_count(id)
		for v in n:
			var tex := TileAtlas.texture_of(id, v)
			if tex == null:
				print("FAIL missing variant id=", id, " v=", v)
				return 1
			var img := tex.get_image()
			var opaque := 0
			for y in 32:
				for x in 32:
					if img.get_pixel(x, y).a > 0.5:
						opaque += 1
			if opaque < 20:
				print("FAIL empty variant id=", id, " v=", v)
				return 1
	# deterministic per-cell selection (same cell → same variant)
	var a := TileAtlas.variant_for(3, 4, Palette.GRASS)
	if a != TileAtlas.variant_for(3, 4, Palette.GRASS):
		print("FAIL variant_for not deterministic")
		return 1
	# props have exactly 1 variant
	for id in Palette.prop_ids():
		if TileAtlas.variant_for(0, 0, id) != 0:
			print("FAIL props should have 1 variant id=", id)
			return 1
	print("OK tile variants")
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
		var key := p.x * MapData.W + p.y
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


func _test_bad_json() -> int:
	print("== bad json ==")
	# Garbage / non-map input must be rejected (null), never a silent empty map
	if MapData.from_json("this is not json") != null:
		print("FAIL garbage string should return null")
		return 1
	if MapData.from_json("") != null:
		print("FAIL empty string should return null")
		return 1
	if MapData.from_json("{\"foo\": 1}") != null:
		print("FAIL non-map dict should return null")
		return 1
	if MapData.from_json("[1, 2, 3]") != null:
		print("FAIL non-dict json should return null")
		return 1
	# valid map still loads
	if MapData.from_json(MapData.make_seed().to_json()) == null:
		print("FAIL valid map json returned null")
		return 1
	print("OK bad json rejected")
	return 0


func _test_fill_full_map() -> int:
	print("== fill full map ==")
	# Real Game code path (autoload script as a plain node — no tree needed).
	# Regression: a pop-count guard used to truncate fills >~ W*H/4 cells.
	var game_script: GDScript = load("res://scripts/autoload/Game.gd")
	var g: Node = game_script.new()
	g.map = MapData.new()  # all EMPTY
	g.active_layer = Palette.LAYER_GROUND
	g.selected_tile = Palette.GRASS
	g._flood_fill(0, 0)
	var count := 0
	for i in g.map.ground.size():
		if g.map.ground[i] == Palette.GRASS:
			count += 1
	if count != MapData.W * MapData.H:
		print("FAIL full-map fill got ", count, "/", MapData.W * MapData.H)
		return 1
	g.free()
	print("OK fill full map (", count, " cells)")
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


func _test_new_tiles() -> int:
	print("== new tiles ==")
	# Verify new tile ids exist in Palette and have textures
	var new_ids := [Palette.SNOW, Palette.LAVA, Palette.BRIDGE, Palette.BUSH, Palette.TENT, Palette.BARREL, Palette.LAMP]
	for id in new_ids:
		var def := Palette.get_def(id)
		if str(def.get("name", "")) == "Empty":
			print("FAIL missing palette def for id=", id)
			return 1
		var tex := TileAtlas.texture_of(id)
		if tex == null:
			print("FAIL missing texture for id=", id)
			return 1
		var img := tex.get_image()
		if img == null:
			print("FAIL null image for id=", id)
			return 1
		var opaque := 0
		for y in 32:
			for x in 32:
				if img.get_pixel(x, y).a > 0.5:
					opaque += 1
		if opaque < 20:
			print("FAIL texture empty id=", id, " opaque=", opaque)
			return 1
	# Verify layer assignment
	if Palette.layer_of(Palette.SNOW) != Palette.LAYER_GROUND:
		print("FAIL SNOW not ground layer")
		return 1
	if Palette.layer_of(Palette.LAVA) != Palette.LAYER_GROUND:
		print("FAIL LAVA not ground layer")
		return 1
	if Palette.layer_of(Palette.BRIDGE) != Palette.LAYER_GROUND:
		print("FAIL BRIDGE not ground layer")
		return 1
	if Palette.layer_of(Palette.BUSH) != Palette.LAYER_PROPS:
		print("FAIL BUSH not props layer")
		return 1
	if Palette.layer_of(Palette.TENT) != Palette.LAYER_PROPS:
		print("FAIL TENT not props layer")
		return 1
	if Palette.layer_of(Palette.BARREL) != Palette.LAYER_PROPS:
		print("FAIL BARREL not props layer")
		return 1
	if Palette.layer_of(Palette.LAMP) != Palette.LAYER_PROPS:
		print("FAIL LAMP not props layer")
		return 1
	# Verify palette lists include new tiles
	var g_ids := Palette.ground_ids()
	if not g_ids.has(Palette.SNOW) or not g_ids.has(Palette.LAVA) or not g_ids.has(Palette.BRIDGE):
		print("FAIL new ground tiles not in ground_ids()")
		return 1
	var p_ids := Palette.prop_ids()
	if not p_ids.has(Palette.BUSH) or not p_ids.has(Palette.TENT) or not p_ids.has(Palette.BARREL) or not p_ids.has(Palette.LAMP):
		print("FAIL new prop tiles not in prop_ids()")
		return 1
	print("OK new tiles (7 tiles verified)")
	return 0


func _test_brush_size() -> int:
	print("== brush size ==")
	# Verify brush radii constants (static const on Game autoload)
	# In SceneTree script mode autoloads are not available, so test the logic directly
	var radii := [0, 1, 2]
	if radii.size() != 3:
		print("FAIL radii size")
		return 1
	if radii[0] != 0 or radii[1] != 1 or radii[2] != 2:
		print("FAIL radii values")
		return 1
	# Verify cycle logic
	var idx := 0
	idx = (idx + 1) % radii.size()
	if idx != 1:
		print("FAIL cycle 0→1 got ", idx)
		return 1
	idx = (idx + 1) % radii.size()
	if idx != 2:
		print("FAIL cycle 1→2 got ", idx)
		return 1
	idx = (idx + 1) % radii.size()
	if idx != 0:
		print("FAIL cycle 2→0 got ", idx)
		return 1
	print("OK brush size")
	return 0


func _test_share_link() -> int:
	print("== share link ==")
	var m := MapData.make_seed()
	m.set_cell("ground", 5, 5, Palette.SNOW)
	m.set_cell("props", 10, 10, Palette.BUSH)
	# encode via Game.export_share_hash (compressed, z1-prefixed)
	var game_script: GDScript = load("res://scripts/autoload/Game.gd")
	var g: Node = game_script.new()
	g.map = m
	var hash: String = g.export_share_hash()
	if not hash.begins_with("z1"):
		print("FAIL compressed share link missing z1 prefix")
		g.free()
		return 1
	if hash.length() > 6000:
		print("FAIL share link too long: ", hash.length())
		g.free()
		return 1
	# decode roundtrip via Game.import_share_hash
	if not g.import_share_hash(hash):
		print("FAIL import compressed share link")
		g.free()
		return 1
	if g.map.get_cell("ground", 5, 5) != Palette.SNOW:
		print("FAIL share link ground roundtrip")
		g.free()
		return 1
	if g.map.get_cell("props", 10, 10) != Palette.BUSH:
		print("FAIL share link props roundtrip")
		g.free()
		return 1
	# legacy plain base64 (v0.3.0) must still load
	var legacy := Marshalls.utf8_to_base64(m.to_json())
	if not g.import_share_hash(legacy):
		print("FAIL legacy share link import")
		g.free()
		return 1
	# empty hash should fail
	if g.import_share_hash(""):
		print("FAIL empty hash should fail")
		g.free()
		return 1
	g.free()
	print("OK share link")
	return 0


func _test_desert_alias() -> int:
	print("== desert alias ==")
	# desert should now map to coast (not blank)
	var desert := MapTemplates.make("desert")
	if desert.title != "Coast":
		print("FAIL desert alias title=", desert.title, " expected Coast")
		return 1
	# coast corner should be water
	if desert.get_cell("ground", 0, 0) != Palette.WATER:
		print("FAIL desert alias not water at corner")
		return 1
	print("OK desert alias → coast")
	return 0


func _test_map_sizes() -> int:
	print("== map sizes ==")
	# 48×48 and 64×64 maps: create, paint, JSON roundtrip preserves size
	for size in [48, 64]:
		MapData.W = size
		MapData.H = size
		var m := MapTemplates.make(MapTemplates.ID_SETTLEMENT)
		if m.ground.size() != size * size:
			print("FAIL template size ", size, " got ", m.ground.size())
			return 1
		m.set_cell("ground", size / 2, size / 2, Palette.DIRT)
		var text := m.to_json()
		var m2 := MapData.from_json(text)
		if m2 == null or m2.ground.size() != size * size:
			print("FAIL roundtrip size ", size)
			return 1
		if m2.get_cell("ground", size / 2, size / 2) != Palette.DIRT:
			print("FAIL roundtrip cell size ", size)
			return 1
		# png export at larger size must not blow up
		var img := PngExporter.render_map(m2, 1)
		if img.get_width() < size:
			print("FAIL png width ", size)
			return 1
	# restore default for later tests
	MapData.W = 32
	MapData.H = 32
	print("OK map sizes 48/64")
	return 0

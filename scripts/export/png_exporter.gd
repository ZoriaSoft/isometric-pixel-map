class_name PngExporter
extends RefCounted
## Software-rasterize map using TileAtlas (matches on-screen look).
## Uses Image.blend_rect for fast alpha compositing (C++ level, not per-pixel GDScript).

static func render_map(map: MapData, scale: int = 2) -> Image:
	return render_map_software(map, scale)


static func save_png(path: String, map: MapData, scale: int = 2) -> Error:
	var img := render_map_software(map, scale)
	return img.save_png(path)


static func render_map_software(map: MapData, scale: int = 2) -> Image:
	TileAtlas.ensure()
	var min_x := INF
	var max_x := -INF
	var min_y := INF
	var max_y := -INF
	for r in MapData.H:
		for c in MapData.W:
			var p := MapData.cell_to_screen(c, r)
			min_x = minf(min_x, p.x - 16)
			max_x = maxf(max_x, p.x + 16)
			min_y = minf(min_y, p.y - 16)
			max_y = maxf(max_y, p.y + 32)
	var pad := 8.0
	min_x -= pad
	max_x += pad
	min_y -= pad
	max_y += pad
	var w := int(ceil((max_x - min_x) * scale))
	var h := int(ceil((max_y - min_y) * scale))
	w = maxi(w, 16)
	h = maxi(h, 16)
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.043, 0.059, 0.078, 1))

	var order: Array[Vector2i] = []
	for r in MapData.H:
		for c in MapData.W:
			order.append(Vector2i(c, r))
	order.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		return (a.x + a.y) < (b.x + b.y) or ((a.x + a.y) == (b.x + b.y) and a.x < b.x)
	)

	# Pre-render scaled tile cache: id -> Image
	var tile_cache: Dictionary = {}

	# ground pass
	for cell in order:
		var p := MapData.cell_to_screen(cell.x, cell.y)
		var gid := map.get_cell(Palette.LAYER_GROUND, cell.x, cell.y)
		if gid == Palette.EMPTY:
			continue
		_blit_tile_cached(img, p, min_x, min_y, scale, gid, cell, tile_cache)
	# props pass
	for cell in order:
		var pid := map.get_cell(Palette.LAYER_PROPS, cell.x, cell.y)
		if pid == Palette.EMPTY:
			continue
		var p2 := MapData.cell_to_screen(cell.x, cell.y)
		_blit_tile_cached(img, p2, min_x, min_y, scale, pid, cell, tile_cache)
	return img


static func _blit_tile_cached(dst: Image, top: Vector2, min_x: float, min_y: float, scale: int, id: int, cell: Vector2i, cache: Dictionary) -> void:
	var variant := TileAtlas.variant_for(cell.x, cell.y, id)
	var tex := TileAtlas.texture_of(id, variant)
	if tex == null:
		return
	var src: Image = tex.get_image()
	if src == null:
		return
	# Get or create scaled version (cache key includes variant)
	var ckey := id * 100 + variant
	var scaled: Image
	if cache.has(ckey):
		scaled = cache[ckey]
	else:
		if scale == 1:
			scaled = src
		else:
			scaled = Image.create(src.get_width() * scale, src.get_height() * scale, false, Image.FORMAT_RGBA8)
			scaled.fill(Color(0, 0, 0, 0))
			# Nearest-neighbor scale by blitting each pixel as a scale×scale block
			for sy in src.get_height():
				for sx in src.get_width():
					var c := src.get_pixel(sx, sy)
					if c.a < 0.05:
						continue
					for dy in scale:
						for dx in scale:
							scaled.set_pixel(sx * scale + dx, sy * scale + dy, c)
		cache[ckey] = scaled
	# Composite using blend_rect (native C++ alpha blend)
	var ox := int((top.x - 16 - min_x) * scale)
	var oy := int((top.y - 16 - min_y) * scale)
	var sw := scaled.get_width()
	var sh := scaled.get_height()
	# Clamp to dst bounds
	var src_x := maxi(0, -ox)
	var src_y := maxi(0, -oy)
	var dst_x := maxi(0, ox)
	var dst_y := maxi(0, oy)
	var blit_w := mini(sw - src_x, dst.get_width() - dst_x)
	var blit_h := mini(sh - src_y, dst.get_height() - dst_y)
	if blit_w <= 0 or blit_h <= 0:
		return
	dst.blend_rect(scaled, Rect2i(src_x, src_y, blit_w, blit_h), Vector2i(dst_x, dst_y))

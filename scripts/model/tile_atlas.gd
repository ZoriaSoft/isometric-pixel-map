class_name TileAtlas
extends RefCounted
## Runtime-generated pixel-art iso tiles (nearest filter). No external PNGs needed.
## Ground tiles have 3 visual variants (GRASS/DIRT/SAND/PATH/STONE/WOOD/SNOW/LAVA);
## water/bridge/props stay single so they read as distinct landmarks.

const TEX_W := 32
const TEX_H := 32  # includes height for props; ground uses lower diamond

const GROUND_VARIANTS := 3
const PROP_VARIANTS := 1

static var _textures: Dictionary = {}  # id*100+variant -> ImageTexture
static var _initialized: bool = false


static func ensure() -> void:
	if _initialized:
		return
	Palette.ensure()
	_textures.clear()
	for id in Palette.all_paintable():
		var n := variant_count(id)
		for v in n:
			_textures[_key(id, v)] = _make_texture(id, v)
	_textures[_key(Palette.EMPTY, 0)] = _make_empty()
	_initialized = true


static func variant_count(id: int) -> int:
	if Palette.is_custom(id):
		return PROP_VARIANTS
	var def := Palette.get_def(id)
	if str(def.get("layer", Palette.LAYER_GROUND)) == Palette.LAYER_PROPS:
		return PROP_VARIANTS
	match id:
		Palette.WATER, Palette.BRIDGE:
			return PROP_VARIANTS
		_:
			return GROUND_VARIANTS


## Register a user-uploaded PNG as a paintable tile. Returns false on decode failure.
static func register_custom_texture(id: int, png_b64: String) -> bool:
	var raw := Marshalls.base64_to_raw(png_b64)
	if raw.is_empty():
		return false
	var img := Image.new()
	var err := img.load_png_from_buffer(raw)
	if err != OK:
		return false
	if img.get_width() != TEX_W or img.get_height() != TEX_H:
		img.resize(TEX_W, TEX_H, Image.INTERPOLATE_NEAREST)
	_textures[_key(id, 0)] = ImageTexture.create_from_image(img)
	return true


## Drop custom textures when a new map loads.
static func clear_custom() -> void:
	for id in Palette.custom_ids():
		_textures.erase(_key(id, 0))


## Deterministic per-cell variant (same cell → same tile on every redraw/export).
static func variant_for(c: int, r: int, id: int) -> int:
	var n := variant_count(id)
	if n <= 1:
		return 0
	return (c * 7 + r * 13 + id * 5) % n


static func _key(id: int, variant: int) -> int:
	return id * 100 + variant


static func texture_of(id: int, variant: int = 0) -> Texture2D:
	ensure()
	return _textures.get(_key(id, variant), _textures.get(_key(Palette.EMPTY, 0))) as Texture2D


static func _make_empty() -> ImageTexture:
	var img := Image.create(TEX_W, TEX_H, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	return ImageTexture.create_from_image(img)


static func _make_texture(id: int, variant: int = 0) -> ImageTexture:
	var img := Image.create(TEX_W, TEX_H, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var base := Palette.color_of(id)
	# Derive per-variant detail offsets so speckles/waves shift between variants.
	var vo := variant * 41
	match id:
		Palette.GRASS:
			_draw_ground_diamond(img, base, base.lightened(0.12), base.darkened(0.18))
			_speckle(img, base.lightened(0.25), 22, 0xA11 + vo)
			_speckle(img, base.darkened(0.10), 14, 0xB33 + vo)
		Palette.DIRT:
			_draw_ground_diamond(img, base, base.lightened(0.1), base.darkened(0.2))
			_speckle(img, base.darkened(0.15), 16, 0xB22 + vo)
			_speckle(img, base.lightened(0.08), 8, 0xC44 + vo)
		Palette.SAND:
			_draw_ground_diamond(img, base, base.lightened(0.15), base.darkened(0.12))
			_speckle(img, Color(0.95, 0.88, 0.6), 14, 0xC33 + vo)
			_speckle(img, base.darkened(0.08), 10, 0xD55 + vo)
		Palette.WATER:
			_draw_ground_diamond(img, base, base.lightened(0.2), base.darkened(0.25))
			_wave_lines(img, base.lightened(0.35))
			_wave_lines(img, base.lightened(0.20), 4.0)
		Palette.PATH:
			_draw_ground_diamond(img, base, base.lightened(0.08), base.darkened(0.15))
			_speckle(img, base.darkened(0.25), 10, 0xD44 + vo)
			_speckle(img, base.lightened(0.10), 6, 0xE66 + vo)
		Palette.STONE:
			_draw_ground_diamond(img, base, base.lightened(0.12), base.darkened(0.22))
			_stone_cracks(img, base.darkened(0.3))
			_speckle(img, base.lightened(0.08), 6, 0xF22 + vo)
		Palette.WOOD:
			_draw_ground_diamond(img, base, base.lightened(0.1), base.darkened(0.2))
			_wood_grain(img, base.darkened(0.25), 3.0 + float(variant % 2))
			_wood_grain(img, base.lightened(0.08), 6.0)
		Palette.SNOW:
			_draw_ground_diamond(img, base, base.lightened(0.05), base.darkened(0.08))
			_speckle(img, Color(1, 1, 1), 16, 0xA77 + vo)
			_speckle(img, base.darkened(0.05), 8, 0xB99 + vo)
		Palette.LAVA:
			_draw_ground_diamond(img, base, base.lightened(0.15), base.darkened(0.2))
			_lava_cracks(img, base.lightened(0.3), float(variant))
		Palette.BRIDGE:
			_draw_ground_diamond(img, base, base.lightened(0.1), base.darkened(0.2))
			_wood_grain(img, base.darkened(0.25))
			# planks — horizontal lines
			for y in [20, 24, 28]:
				for x in range(4, 28):
					if img.get_pixel(x, y).a > 0.1:
						img.set_pixel(x, y, base.darkened(0.35))
		Palette.TREE:
			_draw_prop_tree(img)
		Palette.ROCK:
			_draw_prop_rock(img, base)
		Palette.HOUSE:
			_draw_prop_house(img, base)
		Palette.FENCE:
			_draw_prop_fence(img, base)
		Palette.FLOWER:
			_draw_prop_flower(img, base)
		Palette.CRATE:
			_draw_prop_crate(img, base)
		Palette.BUSH:
			_draw_prop_bush(img, base)
		Palette.TENT:
			_draw_prop_tent(img, base)
		Palette.BARREL:
			_draw_prop_barrel(img, base)
		Palette.LAMP:
			_draw_prop_lamp(img, base)
		_:
			_draw_ground_diamond(img, base, base, base.darkened(0.2))
	var tex := ImageTexture.create_from_image(img)
	return tex


## Classic iso diamond in 32×16 band at y=16..31 (bottom of 32px canvas for ground).
static func _draw_ground_diamond(img: Image, top_c: Color, left_c: Color, right_c: Color) -> void:
	var ox := 16
	var oy := 16  # top of diamond
	for y in 16:
		var t := float(y) / 16.0
		var half: float
		if t < 0.5:
			half = 16.0 * (t / 0.5)
		else:
			half = 16.0 * ((1.0 - t) / 0.5)
		var y_i := oy + y
		var x0 := int(ox - half)
		var x1 := int(ox + half)
		for x in range(x0, x1 + 1):
			if x < 0 or x >= TEX_W or y_i < 0 or y_i >= TEX_H:
				continue
			var color: Color
			if y < 8:
				# top face
				color = top_c if x < ox else top_c.darkened(0.06)
			else:
				color = left_c if x < ox else right_c
			# pixel edge outline
			if x == x0 or x == x1 or y == 0 or y == 15:
				color = color.darkened(0.35)
			img.set_pixel(x, y_i, color)


static func _speckle(img: Image, c: Color, count: int, rng_seed: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = rng_seed
	for i in count:
		var x := rng.randi_range(4, 27)
		var y := rng.randi_range(18, 30)
		if img.get_pixel(x, y).a > 0.1:
			img.set_pixel(x, y, c)


static func _wave_lines(img: Image, c: Color, y_offset: float = 0.0) -> void:
	for x in range(6, 26):
		var y := 22 + int(sin(x * 0.7 + y_offset) * 1.5)
		if img.get_pixel(x, y).a > 0.1:
			img.set_pixel(x, y, c)
		y = 26 + int(sin(x * 0.55 + 1.0 + y_offset) * 1.2)
		if img.get_pixel(x, y).a > 0.1:
			img.set_pixel(x, y, c)


static func _stone_cracks(img: Image, c: Color) -> void:
	for x in range(10, 18):
		var y := 20 + (x % 3)
		if img.get_pixel(x, y).a > 0.1:
			img.set_pixel(x, y, c)
	for y in range(22, 28):
		if img.get_pixel(20, y).a > 0.1:
			img.set_pixel(20, y, c)
	# extra crack for organic feel
	for x in range(12, 22):
		var y := 27 + ((x + 3) % 2)
		if img.get_pixel(x, y).a > 0.1:
			img.set_pixel(x, y, c.darkened(0.1))


static func _wood_grain(img: Image, c: Color, spacing: float = 3.0) -> void:
	for y in range(18, 30):
		for x in range(8, 24, int(spacing)):
			if img.get_pixel(x, y).a > 0.1:
				img.set_pixel(x, y, c)


static func _lava_cracks(img: Image, c: Color, off: float = 0.0) -> void:
	# glowing cracks in lava (phase offset gives variant variation)
	for x in range(8, 24):
		var y := 21 + int(sin(x * 0.5 + off * 2.0) * 2)
		if img.get_pixel(x, y).a > 0.1:
			img.set_pixel(x, y, c)
	for x in range(10, 22):
		var y := 26 + int(cos(x * 0.4 + off * 1.7) * 1.5)
		if img.get_pixel(x, y).a > 0.1:
			img.set_pixel(x, y, c.lightened(0.1))
	# bright spots
	img.set_pixel(14 + (int(off) % 5), 23, c.lightened(0.3))
	img.set_pixel(19 - (int(off) % 4), 25, c.lightened(0.25))


static func _draw_prop_tree(img: Image) -> void:
	# trunk — slightly thicker, with shading
	var trunk := Color(0.40, 0.26, 0.14)
	var trunk_d := trunk.darkened(0.15)
	for y in range(20, 29):
		img.set_pixel(15, y, trunk_d)
		img.set_pixel(16, y, trunk)
		img.set_pixel(17, y, trunk_d)
	# shadow under tree
	for x in range(11, 22):
		if img.get_pixel(x, 29).a < 0.1:
			img.set_pixel(x, 29, Color(0, 0, 0, 0.25))
	# foliage — layered blobs with depth
	var green := Color(0.18, 0.52, 0.26)
	var green2 := Color(0.30, 0.68, 0.36)
	var green3 := Color(0.14, 0.42, 0.22)
	var green_d := Color(0.10, 0.32, 0.16)
	# dark base
	_fill_circle(img, 16, 15, 8, green_d)
	# mid layer
	_fill_circle(img, 16, 14, 7, green)
	_fill_circle(img, 11, 16, 5, green3)
	_fill_circle(img, 21, 16, 5, green3)
	# highlights
	_fill_circle(img, 16, 9, 5, green2)
	_fill_circle(img, 13, 12, 3, green2.lightened(0.08))
	_fill_circle(img, 19, 12, 3, green2.lightened(0.05))
	# sparkle pixels
	img.set_pixel(14, 10, green2.lightened(0.25))
	img.set_pixel(15, 9, green2.lightened(0.15))
	img.set_pixel(17, 8, Color(0.5, 0.8, 0.4))
	img.set_pixel(16, 6, green.darkened(0.25))


static func _draw_prop_rock(img: Image, base: Color) -> void:
	# more organic shape — asymmetric polygon
	var pts := [
		Vector2i(10, 25), Vector2i(12, 17), Vector2i(15, 15), Vector2i(20, 16),
		Vector2i(24, 21), Vector2i(23, 27), Vector2i(17, 29), Vector2i(11, 28),
	]
	_fill_poly_approx(img, pts, base)
	# highlight ridge
	img.set_pixel(15, 18, base.lightened(0.25))
	img.set_pixel(16, 17, base.lightened(0.2))
	img.set_pixel(17, 18, base.lightened(0.15))
	img.set_pixel(14, 19, base.lightened(0.1))
	# shadow edges
	for x in range(12, 22):
		img.set_pixel(x, 27, base.darkened(0.3))
		img.set_pixel(x, 28, base.darkened(0.35))
	# crack
	img.set_pixel(18, 22, base.darkened(0.25))
	img.set_pixel(19, 23, base.darkened(0.2))


static func _draw_prop_house(img: Image, base: Color) -> void:
	var wall := base
	var wall_d := base.darkened(0.08)
	var roof := Color(0.45, 0.18, 0.16)
	var roof_d := roof.darkened(0.12)
	var roof_l := roof.lightened(0.08)
	var door := Color(0.30, 0.18, 0.12)
	# walls with subtle texture
	for y in range(18, 28):
		for x in range(10, 22):
			var c := wall if (x + y) % 5 != 0 else wall_d
			img.set_pixel(x, y, c)
	# roof — steeper triangle with shading
	for y in range(7, 18):
		var half := (y - 7)
		for x in range(16 - half - 2, 16 + half + 3):
			if x >= 0 and x < TEX_W:
				var rc := roof_l if x < 14 else (roof if x < 17 else roof_d)
				img.set_pixel(x, y, rc)
	# roof apex highlight
	img.set_pixel(16, 7, roof.lightened(0.15))
	img.set_pixel(16, 8, roof_l)
	# door with frame
	for y in range(22, 28):
		img.set_pixel(15, y, door)
		img.set_pixel(16, y, door)
	img.set_pixel(15, 22, door.lightened(0.2))
	img.set_pixel(16, 22, door.lightened(0.2))
	# windows with glow
	var win := Color(0.75, 0.85, 0.95)
	var win_glow := Color(0.85, 0.92, 1.0)
	img.set_pixel(12, 20, win)
	img.set_pixel(13, 20, win_glow)
	img.set_pixel(18, 20, win)
	img.set_pixel(19, 20, win_glow)
	# window frames
	img.set_pixel(12, 19, wall_d)
	img.set_pixel(13, 19, wall_d)
	img.set_pixel(18, 19, wall_d)
	img.set_pixel(19, 19, wall_d)


static func _draw_prop_fence(img: Image, base: Color) -> void:
	# horizontal rails
	for x in range(6, 26):
		img.set_pixel(x, 22, base)
		img.set_pixel(x, 23, base.darkened(0.15))
	# posts
	for x in [8, 16, 24]:
		for y in range(18, 28):
			img.set_pixel(x, y, base)
			img.set_pixel(x + 1, y, base.darkened(0.1))
	# post tops
	img.set_pixel(8, 17, base.lightened(0.1))
	img.set_pixel(16, 17, base.lightened(0.1))
	img.set_pixel(24, 17, base.lightened(0.1))


static func _draw_prop_flower(img: Image, base: Color) -> void:
	var stem := Color(0.22, 0.55, 0.28)
	var stem_d := stem.darkened(0.15)
	for y in range(18, 26):
		img.set_pixel(16, y, stem if y % 2 == 0 else stem_d)
	# leaf
	img.set_pixel(15, 22, stem)
	img.set_pixel(17, 23, stem_d)
	# petals
	_fill_circle(img, 16, 16, 3, base)
	img.set_pixel(16, 16, Color(0.95, 0.9, 0.4))
	img.set_pixel(13, 16, base.lightened(0.1))
	img.set_pixel(19, 16, base.lightened(0.1))
	img.set_pixel(16, 13, base.lightened(0.1))
	img.set_pixel(16, 19, base.darkened(0.1))
	# extra petal highlights
	img.set_pixel(14, 15, base.lightened(0.05))
	img.set_pixel(18, 15, base.lightened(0.05))


static func _draw_prop_crate(img: Image, base: Color) -> void:
	var dark := base.darkened(0.35)
	var mid := base.darkened(0.15)
	# box
	for y in range(16, 28):
		for x in range(10, 22):
			var c := base
			if x == 10 or x == 21 or y == 16 or y == 27:
				c = dark
			elif (x - 10) == (y - 16) or (21 - x) == (y - 16):
				c = mid
			img.set_pixel(x, y, c)
	# top edge highlight
	for x in range(11, 21):
		img.set_pixel(x, 16, base.lightened(0.1))


static func _draw_prop_bush(img: Image, base: Color) -> void:
	# shadow
	for x in range(10, 23):
		if img.get_pixel(x, 28).a < 0.1:
			img.set_pixel(x, 28, Color(0, 0, 0, 0.2))
	# foliage — small clustered blobs
	var g := base
	var g_d := base.darkened(0.15)
	var g_l := base.lightened(0.12)
	_fill_circle(img, 13, 22, 4, g_d)
	_fill_circle(img, 19, 22, 4, g_d)
	_fill_circle(img, 16, 20, 5, g)
	_fill_circle(img, 14, 21, 3, g_l)
	_fill_circle(img, 18, 21, 3, g_l)
	# berries
	img.set_pixel(15, 19, Color(0.7, 0.2, 0.2))
	img.set_pixel(18, 20, Color(0.7, 0.2, 0.2))
	img.set_pixel(13, 23, Color(0.6, 0.15, 0.15))


static func _draw_prop_tent(img: Image, base: Color) -> void:
	var roof := base
	var roof_d := base.darkened(0.15)
	var roof_l := base.lightened(0.1)
	# triangle tent
	for y in range(10, 28):
		var half := (y - 10) * 1
		for x in range(16 - half, 16 + half + 1):
			if x >= 0 and x < TEX_W and y < 28:
				var c := roof_l if x < 16 else roof_d
				if x == 16 - half or x == 16 + half:
					c = roof_d.darkened(0.1)
				img.set_pixel(x, y, c)
	# door opening
	for y in range(22, 28):
		for x in range(14, 19):
			if img.get_pixel(x, y).a > 0.1:
				img.set_pixel(x, y, Color(0.15, 0.10, 0.08))
	# door flap
	img.set_pixel(14, 22, roof_d)
	img.set_pixel(18, 22, roof_d)
	# peak
	img.set_pixel(16, 10, roof.lightened(0.15))
	# guyline
	img.set_pixel(10, 27, Color(0.4, 0.35, 0.3))
	img.set_pixel(11, 26, Color(0.4, 0.35, 0.3))
	img.set_pixel(12, 25, Color(0.4, 0.35, 0.3))


static func _draw_prop_barrel(img: Image, base: Color) -> void:
	var dark := base.darkened(0.25)
	var light := base.lightened(0.1)
	# barrel body — curved sides
	for y in range(16, 28):
		var x0 := 12
		var x1 := 20
		if y < 18:
			x0 = 13
			x1 = 19
		elif y > 26:
			x0 = 13
			x1 = 19
		for x in range(x0, x1 + 1):
			var c := base
			if x == x0 or x == x1:
				c = dark
			if x == x0 + 1:
				c = base.darkened(0.08)
			if x == x1 - 1:
				c = base.lightened(0.05)
			img.set_pixel(x, y, c)
	# metal bands
	for x in range(12, 21):
		if img.get_pixel(x, 19).a > 0.1:
			img.set_pixel(x, 19, dark)
		if img.get_pixel(x, 24).a > 0.1:
			img.set_pixel(x, 24, dark)
	# top
	for x in range(13, 20):
		img.set_pixel(x, 16, light)
		img.set_pixel(x, 17, base)
	# highlight
	img.set_pixel(14, 21, light)
	img.set_pixel(14, 22, light)


static func _draw_prop_lamp(img: Image, base: Color) -> void:
	# post
	var post := Color(0.25, 0.22, 0.20)
	var post_d := post.darkened(0.2)
	for y in range(18, 29):
		img.set_pixel(15, y, post_d)
		img.set_pixel(16, y, post)
		img.set_pixel(17, y, post_d)
	# base
	for x in range(13, 20):
		img.set_pixel(x, 28, post_d)
		img.set_pixel(x, 29, post.darkened(0.3))
	# lamp head — glowing
	var glow := Color(1.0, 0.92, 0.5)
	var glow_d := Color(0.85, 0.78, 0.4)
	_fill_circle(img, 16, 14, 4, glow_d)
	_fill_circle(img, 16, 14, 3, glow)
	_fill_circle(img, 16, 14, 2, Color(1.0, 0.98, 0.7))
	# light rays (subtle)
	img.set_pixel(12, 14, Color(1.0, 0.92, 0.5, 0.4))
	img.set_pixel(20, 14, Color(1.0, 0.92, 0.5, 0.4))
	img.set_pixel(16, 10, Color(1.0, 0.92, 0.5, 0.3))
	# arm connecting post to lamp
	img.set_pixel(16, 17, post)
	img.set_pixel(16, 18, post_d)


static func _fill_circle(img: Image, cx: int, cy: int, r: int, c: Color) -> void:
	var r2 := r * r
	for y in range(cy - r, cy + r + 1):
		for x in range(cx - r, cx + r + 1):
			if x < 0 or y < 0 or x >= TEX_W or y >= TEX_H:
				continue
			var dx := x - cx
			var dy := y - cy
			if dx * dx + dy * dy <= r2:
				var col := c
				if dx * dx + dy * dy > (r - 1) * (r - 1) and r > 2:
					col = c.darkened(0.2)
				img.set_pixel(x, y, col)


static func _fill_poly_approx(img: Image, pts: Array, c: Color) -> void:
	# bbox scan + ray cast
	var min_x := 999
	var max_x := -999
	var min_y := 999
	var max_y := -999
	for p in pts:
		min_x = mini(min_x, p.x)
		max_x = maxi(max_x, p.x)
		min_y = mini(min_y, p.y)
		max_y = maxi(max_y, p.y)
	for y in range(min_y, max_y + 1):
		for x in range(min_x, max_x + 1):
			if _point_in_poly(Vector2(x + 0.5, y + 0.5), pts):
				img.set_pixel(x, y, c if x + y < (min_x + max_x + min_y + max_y) / 2 else c.darkened(0.12))


static func _point_in_poly(p: Vector2, pts: Array) -> bool:
	var inside := false
	var j := pts.size() - 1
	for i in pts.size():
		var pi: Vector2i = pts[i]
		var pj: Vector2i = pts[j]
		if ((pi.y > p.y) != (pj.y > p.y)) and (p.x < (pj.x - pi.x) * (p.y - pi.y) / float(pj.y - pi.y + 0.0001) + pi.x):
			inside = not inside
		j = i
	return inside

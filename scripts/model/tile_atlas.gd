class_name TileAtlas
extends RefCounted
## Runtime-generated pixel-art iso tiles (nearest filter). No external PNGs needed.

const TEX_W := 32
const TEX_H := 32  # includes height for props; ground uses lower diamond

static var _textures: Dictionary = {}  # id -> ImageTexture
static var _initialized: bool = false


static func ensure() -> void:
	if _initialized:
		return
	Palette.ensure()
	_textures.clear()
	for id in Palette.all_paintable():
		_textures[id] = _make_texture(id)
	_textures[Palette.EMPTY] = _make_empty()
	_initialized = true


static func texture_of(id: int) -> Texture2D:
	ensure()
	return _textures.get(id, _textures.get(Palette.EMPTY)) as Texture2D


static func _make_empty() -> ImageTexture:
	var img := Image.create(TEX_W, TEX_H, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	return ImageTexture.create_from_image(img)


static func _make_texture(id: int) -> ImageTexture:
	var img := Image.create(TEX_W, TEX_H, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var base := Palette.color_of(id)
	match id:
		Palette.GRASS:
			_draw_ground_diamond(img, base, base.lightened(0.12), base.darkened(0.18))
			_speckle(img, base.lightened(0.25), 18, 0xA11)
		Palette.DIRT:
			_draw_ground_diamond(img, base, base.lightened(0.1), base.darkened(0.2))
			_speckle(img, base.darkened(0.15), 12, 0xB22)
		Palette.SAND:
			_draw_ground_diamond(img, base, base.lightened(0.15), base.darkened(0.12))
			_speckle(img, Color(0.95, 0.88, 0.6), 10, 0xC33)
		Palette.WATER:
			_draw_ground_diamond(img, base, base.lightened(0.2), base.darkened(0.25))
			_wave_lines(img, base.lightened(0.35))
		Palette.PATH:
			_draw_ground_diamond(img, base, base.lightened(0.08), base.darkened(0.15))
			_speckle(img, base.darkened(0.25), 8, 0xD44)
		Palette.STONE:
			_draw_ground_diamond(img, base, base.lightened(0.12), base.darkened(0.22))
			_stone_cracks(img, base.darkened(0.3))
		Palette.WOOD:
			_draw_ground_diamond(img, base, base.lightened(0.1), base.darkened(0.2))
			_wood_grain(img, base.darkened(0.25))
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


static func _wave_lines(img: Image, c: Color) -> void:
	for x in range(6, 26):
		var y := 22 + int(sin(x * 0.7) * 1.5)
		if img.get_pixel(x, y).a > 0.1:
			img.set_pixel(x, y, c)
		y = 26 + int(sin(x * 0.55 + 1.0) * 1.2)
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


static func _wood_grain(img: Image, c: Color) -> void:
	for y in range(18, 30):
		for x in range(8, 24, 3):
			if img.get_pixel(x, y).a > 0.1:
				img.set_pixel(x, y, c)


static func _draw_prop_tree(img: Image) -> void:
	# trunk
	var trunk := Color(0.40, 0.26, 0.14)
	for y in range(20, 29):
		img.set_pixel(15, y, trunk)
		img.set_pixel(16, y, trunk.darkened(0.1))
		img.set_pixel(14, y, trunk.darkened(0.15))
	# shadow under tree
	for x in range(12, 21):
		if img.get_pixel(x, 29).a < 0.1:
			img.set_pixel(x, 29, Color(0, 0, 0, 0.25))
	# foliage blobs (pixel circles)
	var green := Color(0.18, 0.52, 0.26)
	var green2 := Color(0.30, 0.68, 0.36)
	var green3 := Color(0.14, 0.42, 0.22)
	_fill_circle(img, 16, 14, 7, green)
	_fill_circle(img, 11, 16, 5, green2)
	_fill_circle(img, 21, 16, 5, green3)
	_fill_circle(img, 16, 9, 5, green2.lightened(0.05))
	# highlight pixels
	img.set_pixel(14, 10, green2.lightened(0.2))
	img.set_pixel(15, 9, green2.lightened(0.15))
	img.set_pixel(16, 6, green.darkened(0.25))


static func _draw_prop_rock(img: Image, base: Color) -> void:
	var pts := [
		Vector2i(10, 24), Vector2i(14, 16), Vector2i(20, 15), Vector2i(24, 22),
		Vector2i(22, 28), Vector2i(12, 28),
	]
	_fill_poly_approx(img, pts, base)
	# highlight
	img.set_pixel(16, 18, base.lightened(0.2))
	img.set_pixel(17, 19, base.lightened(0.15))
	# shadow edge
	for x in range(12, 22):
		img.set_pixel(x, 27, base.darkened(0.3))


static func _draw_prop_house(img: Image, base: Color) -> void:
	var wall := base
	var roof := Color(0.45, 0.18, 0.16)
	var door := Color(0.30, 0.18, 0.12)
	# walls
	for y in range(18, 28):
		for x in range(10, 22):
			img.set_pixel(x, y, wall if (x + y) % 5 != 0 else wall.darkened(0.08))
	# roof triangle
	for y in range(8, 18):
		var half := (y - 8)
		for x in range(16 - half - 2, 16 + half + 3):
			if x >= 0 and x < TEX_W:
				img.set_pixel(x, y, roof if x < 16 else roof.darkened(0.12))
	# door
	for y in range(22, 28):
		img.set_pixel(15, y, door)
		img.set_pixel(16, y, door)
	# window
	var win := Color(0.75, 0.85, 0.95)
	img.set_pixel(12, 20, win)
	img.set_pixel(13, 20, win)
	img.set_pixel(18, 20, win)
	img.set_pixel(19, 20, win)


static func _draw_prop_fence(img: Image, base: Color) -> void:
	for x in range(6, 26):
		img.set_pixel(x, 22, base)
		img.set_pixel(x, 23, base.darkened(0.15))
	for x in [8, 16, 24]:
		for y in range(18, 28):
			img.set_pixel(x, y, base)
			img.set_pixel(x + 1, y, base.darkened(0.1))


static func _draw_prop_flower(img: Image, base: Color) -> void:
	var stem := Color(0.22, 0.55, 0.28)
	for y in range(18, 26):
		img.set_pixel(16, y, stem)
	_fill_circle(img, 16, 16, 3, base)
	img.set_pixel(16, 16, Color(0.95, 0.9, 0.4))
	img.set_pixel(13, 16, base.lightened(0.1))
	img.set_pixel(19, 16, base.lightened(0.1))
	img.set_pixel(16, 13, base.lightened(0.1))
	img.set_pixel(16, 19, base.darkened(0.1))


static func _draw_prop_crate(img: Image, base: Color) -> void:
	for y in range(16, 28):
		for x in range(10, 22):
			var c := base
			if x == 10 or x == 21 or y == 16 or y == 27:
				c = base.darkened(0.35)
			elif (x - 10) == (y - 16) or (21 - x) == (y - 16):
				c = base.darkened(0.15)
			img.set_pixel(x, y, c)


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

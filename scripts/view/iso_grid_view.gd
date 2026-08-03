extends Node2D
## Draws isometric ground + props with TileAtlas; paint input + pan/zoom/touch.

signal hover_cell_changed(cell: Vector2i)

var hover_cell: Vector2i = Vector2i(-1, -1)
var show_grid: bool = true
var origin: Vector2 = Vector2.ZERO
var space_pan: bool = false

var _dragging: bool = false
var _panning: bool = false
var _pan_last: Vector2 = Vector2.ZERO
var _camera: Camera2D
var _touch_pan_id: int = -1
var _order_cache: Array[Vector2i] = []
var _pinch_dist: float = -1.0
var _touches: Dictionary = {}  # index -> Vector2


func _ready() -> void:
	TileAtlas.ensure()
	_camera = get_parent().get_node_or_null("Camera2D") as Camera2D
	Game.map_changed.connect(queue_redraw)
	_rebuild_order()
	var mid := MapData.cell_to_screen(MapData.W / 2, MapData.H / 2)
	origin = Vector2.ZERO
	if _camera:
		_camera.position = mid + Vector2(0, MapData.TILE_H)
	queue_redraw()


func _rebuild_order() -> void:
	_order_cache.clear()
	for r in MapData.H:
		for c in MapData.W:
			_order_cache.append(Vector2i(c, r))
	_order_cache.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		return (a.x + a.y) < (b.x + b.y) or ((a.x + a.y) == (b.x + b.y) and a.x < b.x)
	)


func _draw() -> void:
	if Game.map == null:
		return
	TileAtlas.ensure()
	var m := Game.map
	# ground
	for cell in _order_cache:
		var base := MapData.cell_to_screen(cell.x, cell.y) + origin
		var gid := m.get_cell(Palette.LAYER_GROUND, cell.x, cell.y)
		_draw_tile(base, gid)
		if show_grid:
			_draw_diamond_outline(base, Color(0, 0, 0, 0.12))
	# props
	for cell in _order_cache:
		var pid := m.get_cell(Palette.LAYER_PROPS, cell.x, cell.y)
		if pid == Palette.EMPTY:
			continue
		var base2 := MapData.cell_to_screen(cell.x, cell.y) + origin
		_draw_tile(base2, pid)
	# hover ghost
	if m.in_bounds(hover_cell.x, hover_cell.y):
		var hb := MapData.cell_to_screen(hover_cell.x, hover_cell.y) + origin
		if Game.current_tool == Game.Tool.ERASE:
			_draw_diamond_outline(hb, Color(1, 0.35, 0.35, 0.9))
			_draw_diamond_fill(hb, Color(1, 0.25, 0.25, 0.25))
		else:
			var tex := TileAtlas.texture_of(Game.selected_tile)
			if tex:
				var dest := Rect2(hb.x - 16, hb.y - 16, 32, 32)
				draw_texture_rect(tex, dest, false, Color(1, 1, 1, 0.5))


func _draw_tile(top: Vector2, id: int) -> void:
	if id == Palette.EMPTY:
		return
	var tex := TileAtlas.texture_of(id)
	if tex == null:
		return
	# Atlas: diamond top is at y=16 in 32×32 → shift up by 16 so it meets `top`.
	var dest := Rect2(top.x - 16, top.y - 16, 32, 32)
	draw_texture_rect(tex, dest, false)


func _draw_diamond_fill(top: Vector2, color: Color) -> void:
	var tw := MapData.TILE_W
	var th := MapData.TILE_H
	var pts := PackedVector2Array([
		top + Vector2(0, 0),
		top + Vector2(tw / 2.0, th / 2.0),
		top + Vector2(0, th),
		top + Vector2(-tw / 2.0, th / 2.0),
	])
	draw_colored_polygon(pts, color)


func _draw_diamond_outline(top: Vector2, color: Color) -> void:
	var tw := MapData.TILE_W
	var th := MapData.TILE_H
	var pts := PackedVector2Array([
		top + Vector2(0, 0),
		top + Vector2(tw / 2.0, th / 2.0),
		top + Vector2(0, th),
		top + Vector2(-tw / 2.0, th / 2.0),
		top + Vector2(0, 0),
	])
	draw_polyline(pts, color, 1.0, true)


func world_to_cell(world: Vector2) -> Vector2i:
	return MapData.screen_to_cell(world - origin)


func zoom_by(factor: float) -> void:
	_zoom_by(factor)


func _unhandled_input(event: InputEvent) -> void:
	if _camera == null:
		_camera = get_parent().get_node_or_null("Camera2D") as Camera2D

	if event is InputEventScreenTouch:
		var st := event as InputEventScreenTouch
		if st.pressed:
			_touches[st.index] = st.position
			if _touches.size() >= 2:
				_dragging = false
				Game.end_stroke()
				_pinch_dist = _touch_distance()
			elif st.index == 0:
				_dragging = true
				Game.begin_stroke()
				_paint_at_screen(st.position)
		else:
			_touches.erase(st.index)
			if st.index == 0:
				_dragging = false
				Game.end_stroke()
			if _touches.size() < 2:
				_pinch_dist = -1.0
		get_viewport().set_input_as_handled()
		return

	if event is InputEventScreenDrag:
		var sd := event as InputEventScreenDrag
		_touches[sd.index] = sd.position
		if _touches.size() >= 2 and _camera:
			# two-finger pan + pinch zoom
			var z := _camera.zoom.x
			_camera.position -= sd.relative / z * 0.5
			var d := _touch_distance()
			if _pinch_dist > 0.0 and d > 0.0:
				var factor := d / _pinch_dist
				# dampen
				factor = lerpf(1.0, factor, 0.35)
				_zoom_by(factor)
				_pinch_dist = d
		elif _dragging:
			_paint_at_screen(sd.position)
		get_viewport().set_input_as_handled()
		return

	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_MIDDLE or mb.button_index == MOUSE_BUTTON_RIGHT:
			_panning = mb.pressed
			_pan_last = mb.position
			get_viewport().set_input_as_handled()
			return
		if mb.button_index == MOUSE_BUTTON_WHEEL_UP and mb.pressed:
			_zoom_by(1.1)
			get_viewport().set_input_as_handled()
			return
		if mb.button_index == MOUSE_BUTTON_WHEEL_DOWN and mb.pressed:
			_zoom_by(1.0 / 1.1)
			get_viewport().set_input_as_handled()
			return
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				if space_pan:
					_panning = true
					_pan_last = mb.position
				else:
					_dragging = true
					Game.begin_stroke()
					_paint_at_screen(mb.position)
			else:
				_dragging = false
				_panning = false
				Game.end_stroke()
			get_viewport().set_input_as_handled()
			return

	if event is InputEventMouseMotion:
		var mm := event as InputEventMouseMotion
		if (_panning or (space_pan and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT))) and _camera:
			var z := _camera.zoom.x
			_camera.position -= mm.relative / z
			get_viewport().set_input_as_handled()
			return
		var cell := _screen_to_cell(mm.position)
		if cell != hover_cell:
			hover_cell = cell
			hover_cell_changed.emit(cell)
			queue_redraw()
		if _dragging:
			_paint_at_screen(mm.position)
			get_viewport().set_input_as_handled()


func _touch_distance() -> float:
	if _touches.size() < 2:
		return -1.0
	var pts: Array = _touches.values()
	return pts[0].distance_to(pts[1])


func _zoom_by(factor: float) -> void:
	if _camera == null:
		return
	var z := clampf(_camera.zoom.x * factor, 0.35, 3.0)
	_camera.zoom = Vector2(z, z)


func _screen_to_cell(screen_pos: Vector2) -> Vector2i:
	var canvas := get_canvas_transform().affine_inverse() * screen_pos
	return world_to_cell(canvas)


func _paint_at_screen(screen_pos: Vector2) -> void:
	var cell := _screen_to_cell(screen_pos)
	Game.paint_at(cell.x, cell.y)
	queue_redraw()

extends HBoxContainer
## Palette buttons with TileAtlas previews.


func _ready() -> void:
	TileAtlas.ensure()
	_rebuild()
	Game.selection_changed.connect(_highlight)


func _rebuild() -> void:
	for c in get_children():
		c.queue_free()
	_add_group(Palette.ground_ids())
	var sep := VSeparator.new()
	add_child(sep)
	_add_group(Palette.prop_ids())
	_highlight()


func _add_group(ids: Array[int]) -> void:
	for id in ids:
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(40, 40)
		btn.tooltip_text = Palette.name_of(id)
		btn.toggle_mode = true
		btn.set_meta("tile_id", id)
		btn.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		btn.expand_icon = true
		var tex := TileAtlas.texture_of(id)
		if tex:
			btn.icon = tex
		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.07, 0.09, 0.12, 0.95)
		style.set_corner_radius_all(6)
		style.set_border_width_all(2)
		style.border_color = Color(0, 0, 0, 0.35)
		style.content_margin_left = 2
		style.content_margin_right = 2
		style.content_margin_top = 2
		style.content_margin_bottom = 2
		btn.add_theme_stylebox_override("normal", style)
		var style_h := style.duplicate() as StyleBoxFlat
		style_h.border_color = Color(0.24, 0.86, 0.59)
		btn.add_theme_stylebox_override("hover", style_h)
		btn.add_theme_stylebox_override("pressed", style_h)
		btn.pressed.connect(_on_pressed.bind(id))
		add_child(btn)


func _on_pressed(id: int) -> void:
	Game.select_tile(id)


func _highlight() -> void:
	for c in get_children():
		if c is Button and c.has_meta("tile_id"):
			var id: int = c.get_meta("tile_id")
			var btn := c as Button
			btn.button_pressed = (id == Game.selected_tile)
			var style := btn.get_theme_stylebox("normal") as StyleBoxFlat
			if style:
				var s := style.duplicate() as StyleBoxFlat
				s.border_color = Color(0.24, 0.86, 0.59) if id == Game.selected_tile else Color(0, 0, 0, 0.35)
				btn.add_theme_stylebox_override("normal", s)

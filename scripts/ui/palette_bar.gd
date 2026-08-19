extends FlowContainer
## Palette buttons with TileAtlas previews; dim tiles not on active layer.


func _ready() -> void:
	TileAtlas.ensure()
	_rebuild()
	Game.selection_changed.connect(_highlight)
	Game.tool_changed.connect(_highlight)
	Game.custom_changed.connect(_on_custom_changed)
	# layer changes emit selection_changed via Game.set_layer → auto-pick fires it
	set_process(false)


func _on_custom_changed() -> void:
	# a custom tile was added/removed — rebuild palette buttons
	_rebuild()


func _rebuild() -> void:
	for c in get_children():
		c.queue_free()
	_add_group(Palette.ground_ids(), Palette.LAYER_GROUND)
	_add_group(Palette.prop_ids(), Palette.LAYER_PROPS)
	_highlight()


func _add_group(ids: Array[int], layer: String) -> void:
	for id in ids:
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(44, 44)
		btn.tooltip_text = "%s (%s)" % [Palette.name_of(id), layer]
		btn.toggle_mode = true
		btn.set_meta("tile_id", id)
		btn.set_meta("layer", layer)
		btn.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		btn.expand_icon = true
		var tex := TileAtlas.texture_of(id)
		if tex:
			btn.icon = tex
		_style_btn(btn, false, false)
		btn.pressed.connect(_on_pressed.bind(id))
		add_child(btn)


func _style_btn(btn: Button, selected: bool, dimmed: bool) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.10, 0.088, 0.071, 0.95 if not dimmed else 0.55)
	style.set_corner_radius_all(6)
	style.set_border_width_all(2)
	if selected:
		style.border_color = Color(0.788, 0.663, 0.38)
	else:
		style.border_color = Color(0, 0, 0, 0.35)
	style.content_margin_left = 2
	style.content_margin_right = 2
	style.content_margin_top = 2
	style.content_margin_bottom = 2
	btn.add_theme_stylebox_override("normal", style)
	var style_h := style.duplicate() as StyleBoxFlat
	style_h.border_color = Color(0.898, 0.788, 0.561)
	style_h.bg_color = Color(0.16, 0.14, 0.11, 0.95 if not dimmed else 0.55)
	btn.add_theme_stylebox_override("hover", style_h)
	btn.add_theme_stylebox_override("pressed", style_h)
	btn.modulate = Color(1, 1, 1, 0.42 if dimmed and not selected else 1.0)


func _on_pressed(id: int) -> void:
	Game.select_tile(id)
	_highlight()


func _highlight() -> void:
	var active_layer := Game.active_layer
	for c in get_children():
		if c is Button and c.has_meta("tile_id"):
			var id: int = c.get_meta("tile_id")
			var layer: String = str(c.get_meta("layer"))
			var selected := id == Game.selected_tile
			var dimmed := layer != active_layer
			(c as Button).button_pressed = selected
			_style_btn(c as Button, selected, dimmed)

extends Control
## Editor shell — grouped toolbar, distinct tool/layer styles, cheatsheet about.

@onready var status_label: Label = %StatusLabel
@onready var about_panel: PanelContainer = %AboutPanel
@onready var about_body: Label = %AboutBody
@onready var about_shortcuts: Label = %AboutShortcuts
@onready var hint_label: Label = %HintLabel
@onready var splash: ColorRect = %Splash
@onready var splash_label: Label = %SplashLabel
@onready var toast_label: Label = %ToastLabel
@onready var dimmer: ColorRect = %Dimmer

@onready var btn_pen: Button = %BtnPen
@onready var btn_erase: Button = %BtnErase
@onready var btn_fill: Button = %BtnFill
@onready var btn_ground: Button = %BtnGround
@onready var btn_props: Button = %BtnProps
@onready var btn_grid: Button = %BtnGrid
@onready var btn_png: Button = %BtnPng
@onready var btn_brush: Button = %BtnBrush
@onready var btn_share: Button = %BtnShare
@onready var title_input: LineEdit = %TitleInput

var _file_dialog: FileDialog
var _save_dialog: FileDialog
var _png_dialog: FileDialog
var _template_menu: PopupMenu
var _space_down: bool = false
var _toast_tween: Tween
var _template_ids: Array[String] = []
var _grid_on: bool = true


func _ready() -> void:
	TileAtlas.ensure()
	theme = ThemeApply.make_theme()
	_style_primary_png()
	_build_template_menu()
	_build_file_dialogs()
	_refresh_labels()
	_refresh_chrome_styles()
	Game.map_changed.connect(_on_map_changed)
	Game.selection_changed.connect(_on_selection)
	Game.tool_changed.connect(_refresh_chrome_styles)
	Game.brush_changed.connect(_on_brush_changed)
	_set_about_open(false)
	if about_body:
		about_body.text = "%s\n\n%s\nv%s" % [L.t("about_body"), L.t("about_free"), Game.APP_VERSION]
	if about_shortcuts:
		about_shortcuts.text = L.t("shortcuts")
	if has_node("%GridView"):
		var gv = %GridView
		if gv.has_signal("hover_cell_changed"):
			gv.hover_cell_changed.connect(_on_hover)
		_grid_on = gv.show_grid
	if title_input:
		title_input.text = Game.map.title
		title_input.text_changed.connect(_on_title_changed)
	if WebBridge.is_web():
		WebBridge.ensure_load_hook(_on_web_json_text)
		WebBridge.block_context_menu()
		_try_load_share_hash()
	if toast_label:
		toast_label.modulate.a = 0.0
	_run_splash()
	_update_brush_label()
	if not FileAccess.file_exists(Game.AUTOSAVE_PATH):
		await get_tree().create_timer(1.2).timeout
		show_toast(L.t("welcome"))


func _on_title_changed(new_text: String) -> void:
	Game.set_title(new_text)


func _on_brush_changed() -> void:
	_update_brush_label()


func _update_brush_label() -> void:
	if btn_brush:
		btn_brush.text = Game.BRUSH_LABELS[Game.brush_index]


func _try_load_share_hash() -> void:
	if not WebBridge.is_web():
		return
	var hash: Variant = JavaScriptBridge.eval("window.location.hash.slice(1);", true)
	if hash == null:
		return
	var s := str(hash)
	if s.begins_with("m="):
		var b64 := s.substr(2)
		if not b64.is_empty() and Game.import_share_hash(b64):
			show_toast(L.t("loaded"))


func _style_primary_png() -> void:
	if btn_png == null:
		return
	btn_png.add_theme_stylebox_override("normal", ThemeApply.primary_style())
	btn_png.add_theme_stylebox_override("hover", ThemeApply.primary_hover_style())
	btn_png.add_theme_stylebox_override("pressed", ThemeApply.primary_style())
	btn_png.add_theme_stylebox_override("focus", ThemeApply.primary_hover_style())


func _on_selection() -> void:
	_refresh_labels()
	_refresh_chrome_styles()


func _refresh_chrome_styles() -> void:
	_apply_tool_btn(btn_pen, Game.current_tool == Game.Tool.PEN)
	_apply_tool_btn(btn_erase, Game.current_tool == Game.Tool.ERASE)
	_apply_tool_btn(btn_fill, Game.current_tool == Game.Tool.FILL)
	_apply_layer_btn(btn_ground, Game.active_layer == Palette.LAYER_GROUND)
	_apply_layer_btn(btn_props, Game.active_layer == Palette.LAYER_PROPS)
	_apply_grid_btn()


func _apply_tool_btn(btn: Button, active: bool) -> void:
	if btn == null:
		return
	if active:
		btn.add_theme_stylebox_override("normal", ThemeApply.tool_active_style())
		btn.add_theme_stylebox_override("hover", ThemeApply.tool_active_hover_style())
		btn.add_theme_stylebox_override("pressed", ThemeApply.tool_active_style())
	else:
		# clear overrides → theme defaults (with hover)
		btn.remove_theme_stylebox_override("normal")
		btn.remove_theme_stylebox_override("hover")
		btn.remove_theme_stylebox_override("pressed")


func _apply_layer_btn(btn: Button, active: bool) -> void:
	if btn == null:
		return
	if active:
		btn.add_theme_stylebox_override("normal", ThemeApply.layer_active_style())
		btn.add_theme_stylebox_override("hover", ThemeApply.layer_active_style())
		btn.add_theme_stylebox_override("pressed", ThemeApply.layer_active_style())
	else:
		btn.add_theme_stylebox_override("normal", ThemeApply.layer_inactive_style())
		btn.add_theme_stylebox_override("hover", ThemeApply.layer_inactive_style())
		btn.add_theme_stylebox_override("pressed", ThemeApply.layer_inactive_style())


func _apply_grid_btn() -> void:
	if btn_grid == null:
		return
	if _grid_on:
		btn_grid.add_theme_stylebox_override("normal", ThemeApply.toggle_on_style())
		btn_grid.add_theme_stylebox_override("hover", ThemeApply.toggle_on_style())
		btn_grid.add_theme_stylebox_override("pressed", ThemeApply.toggle_on_style())
	else:
		btn_grid.remove_theme_stylebox_override("normal")
		btn_grid.remove_theme_stylebox_override("hover")
		btn_grid.remove_theme_stylebox_override("pressed")


func _run_splash() -> void:
	if splash == null:
		return
	splash.visible = true
	splash.modulate.a = 1.0
	if splash_label:
		splash_label.text = L.t("app_name")
	var tw := create_tween()
	tw.tween_interval(0.3)
	tw.tween_property(splash, "modulate:a", 0.0, 0.3)
	tw.tween_callback(func() -> void:
		splash.visible = false
	)


func show_toast(msg: String) -> void:
	if toast_label == null:
		print("TOAST: ", msg)
		return
	toast_label.text = msg
	toast_label.modulate.a = 1.0
	if _toast_tween and _toast_tween.is_valid():
		_toast_tween.kill()
	_toast_tween = create_tween()
	_toast_tween.tween_interval(1.5)
	_toast_tween.tween_property(toast_label, "modulate:a", 0.0, 0.35)


func _build_file_dialogs() -> void:
	_file_dialog = FileDialog.new()
	_file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	_file_dialog.access = FileDialog.ACCESS_FILESYSTEM
	_file_dialog.filters = PackedStringArray(["*.json ; JSON Map"])
	_file_dialog.title = "Load JSON"
	_file_dialog.file_selected.connect(_on_load_selected)
	add_child(_file_dialog)

	_save_dialog = FileDialog.new()
	_save_dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	_save_dialog.access = FileDialog.ACCESS_FILESYSTEM
	_save_dialog.filters = PackedStringArray(["*.json ; JSON Map"])
	_save_dialog.title = "Save JSON"
	_save_dialog.file_selected.connect(_on_save_selected)
	add_child(_save_dialog)

	_png_dialog = FileDialog.new()
	_png_dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	_png_dialog.access = FileDialog.ACCESS_FILESYSTEM
	_png_dialog.filters = PackedStringArray(["*.png ; PNG Image"])
	_png_dialog.title = "Export PNG"
	_png_dialog.file_selected.connect(_on_png_selected)
	add_child(_png_dialog)


func _build_template_menu() -> void:
	_template_menu = PopupMenu.new()
	add_child(_template_menu)
	_template_ids.clear()
	var i := 0
	for entry in MapTemplates.catalog():
		var id := str(entry.get("id", ""))
		var title := str(entry.get("title", id))
		var use := str(entry.get("use", entry.get("blurb", "")))
		_template_menu.add_item("%s — %s" % [title, use], i)
		_template_ids.append(id)
		i += 1
	_template_menu.id_pressed.connect(_on_template_chosen)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey:
		var k := event as InputEventKey
		if k.keycode == KEY_SPACE:
			_space_down = k.pressed
			if has_node("%GridView"):
				%GridView.set("space_pan", _space_down)
			return
		if k.keycode == KEY_ESCAPE and k.pressed:
			if about_panel and about_panel.visible:
				_set_about_open(false)
				get_viewport().set_input_as_handled()
				return
			if Game.current_tool != Game.Tool.PEN:
				Game.set_tool(Game.Tool.PEN)
				_refresh_chrome_styles()
				get_viewport().set_input_as_handled()
				return
		if not k.pressed or k.echo:
			return
		if k.ctrl_pressed and k.keycode == KEY_Z:
			Game.undo()
			show_toast(L.t("undo"))
			get_viewport().set_input_as_handled()
		elif k.ctrl_pressed and k.keycode == KEY_Y:
			Game.redo()
			show_toast(L.t("redo"))
			get_viewport().set_input_as_handled()
		elif k.ctrl_pressed and k.keycode == KEY_S:
			_on_save_pressed()
			get_viewport().set_input_as_handled()
		elif k.ctrl_pressed and k.keycode == KEY_E:
			_on_export_png_pressed()
			get_viewport().set_input_as_handled()
		elif k.ctrl_pressed and k.keycode == KEY_N:
			_on_new_pressed()
			get_viewport().set_input_as_handled()
		elif k.keycode == KEY_P:
			Game.set_tool(Game.Tool.PEN)
			_refresh_chrome_styles()
		elif k.keycode == KEY_E:
			Game.set_tool(Game.Tool.ERASE)
			_refresh_chrome_styles()
		elif k.keycode == KEY_F:
			Game.set_tool(Game.Tool.FILL)
			_refresh_chrome_styles()
		elif k.keycode == KEY_B:
			Game.cycle_brush()
		elif k.keycode == KEY_G:
			_on_grid_toggle()
		elif k.keycode == KEY_1:
			Game.set_layer(Palette.LAYER_GROUND)
			_refresh_chrome_styles()
		elif k.keycode == KEY_2:
			Game.set_layer(Palette.LAYER_PROPS)
			_refresh_chrome_styles()
		elif k.keycode == KEY_EQUAL or k.keycode == KEY_KP_ADD:
			_zoom_ui(1.1)
		elif k.keycode == KEY_MINUS or k.keycode == KEY_KP_SUBTRACT:
			_zoom_ui(1.0 / 1.1)


func _zoom_ui(factor: float) -> void:
	if has_node("%GridView") and %GridView.has_method("zoom_by"):
		%GridView.zoom_by(factor)


func _refresh_labels() -> void:
	if hint_label:
		hint_label.text = L.t("hint")
	_on_map_changed()


func _on_map_changed() -> void:
	if status_label == null or Game.map == null:
		return
	# Tool name not repeated — toolbar shows it
	status_label.text = "%s · %s · %s" % [
		Game.map.title,
		Game.active_layer,
		Palette.name_of(Game.selected_tile),
	]
	if title_input and title_input.text != Game.map.title:
		title_input.text = Game.map.title


func _on_hover(cell: Vector2i) -> void:
	if status_label == null or Game.map == null:
		return
	if Game.map.in_bounds(cell.x, cell.y):
		var g := Palette.name_of(Game.map.get_cell(Palette.LAYER_GROUND, cell.x, cell.y))
		var p := Game.map.get_cell(Palette.LAYER_PROPS, cell.x, cell.y)
		var prop_s := Palette.name_of(p) if p != Palette.EMPTY else "—"
		status_label.text = "%d,%d · %s / %s" % [cell.x, cell.y, g, prop_s]


func _on_pen_pressed() -> void:
	Game.set_tool(Game.Tool.PEN)
	_refresh_chrome_styles()


func _on_erase_pressed() -> void:
	Game.set_tool(Game.Tool.ERASE)
	_refresh_chrome_styles()


func _on_fill_pressed() -> void:
	Game.set_tool(Game.Tool.FILL)
	_refresh_chrome_styles()


func _on_undo_pressed() -> void:
	Game.undo()
	show_toast(L.t("undo"))


func _on_redo_pressed() -> void:
	Game.redo()
	show_toast(L.t("redo"))


func _on_zoom_in() -> void:
	_zoom_ui(1.15)


func _on_zoom_out() -> void:
	_zoom_ui(1.0 / 1.15)


func _on_layer_ground() -> void:
	Game.set_layer(Palette.LAYER_GROUND)
	_refresh_chrome_styles()


func _on_layer_props() -> void:
	Game.set_layer(Palette.LAYER_PROPS)
	_refresh_chrome_styles()


func _on_grid_toggle() -> void:
	if has_node("%GridView"):
		var gv = %GridView
		gv.show_grid = not gv.show_grid
		_grid_on = gv.show_grid
		gv.queue_redraw()
		_apply_grid_btn()
		show_toast(L.t("grid_on") if _grid_on else L.t("grid_off"))


func _on_new_pressed() -> void:
	if _template_menu == null:
		Game.new_from_template(MapTemplates.ID_BLANK)
		show_toast(L.t("new_map"))
		return
	var btn := get_node_or_null("UI/TopBar/Margin/HBox/File/BtnNew") as Button
	if btn:
		var g := btn.get_global_rect()
		_template_menu.position = Vector2i(int(g.position.x), int(g.position.y + g.size.y + 2))
	else:
		_template_menu.position = Vector2i(80, 56)
	_template_menu.popup()


func _on_template_chosen(index: int) -> void:
	if index < 0 or index >= _template_ids.size():
		return
	var tid := _template_ids[index]
	Game.new_from_template(tid)
	show_toast("%s: %s" % [L.t("template_loaded"), MapTemplates.title_of(tid)])


func _on_load_pressed() -> void:
	if WebBridge.is_web():
		WebBridge.ensure_load_hook(_on_web_json_text)
		WebBridge.pick_json()
	else:
		_file_dialog.popup_centered_ratio(0.6)


func _on_save_pressed() -> void:
	if WebBridge.is_web():
		WebBridge.download_text("%s.json" % Game.filename_base(), Game.export_json_text(), "application/json")
		show_toast(L.t("saved"))
	else:
		_save_dialog.current_file = "%s.json" % Game.filename_base()
		_save_dialog.popup_centered_ratio(0.6)


func _on_export_png_pressed() -> void:
	if WebBridge.is_web():
		_export_png_web()
	else:
		_png_dialog.current_file = "%s.png" % Game.filename_base()
		_png_dialog.popup_centered_ratio(0.6)


func _on_brush_pressed() -> void:
	Game.cycle_brush()


func _on_share_pressed() -> void:
	if not WebBridge.is_web():
		show_toast(L.t("share_web_only"))
		return
	var b64 := Game.export_share_hash()
	if b64.length() > 6000:
		show_toast(L.t("share_too_large"))
		return
	JavaScriptBridge.eval("""
(function(){
	var url = window.location.origin + window.location.pathname + '#m=' + '%s';
	history.replaceState(null, '', url);
	if (navigator.clipboard) {
		navigator.clipboard.writeText(url).then(function(){
			console.log('share link copied');
		}).catch(function(){});
	}
})();
""" % b64)
	show_toast(L.t("share_copied"))


func _on_about_pressed() -> void:
	_set_about_open(not about_panel.visible)


func _on_about_close() -> void:
	_set_about_open(false)


func _on_dimmer_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		_set_about_open(false)


func _set_about_open(open: bool) -> void:
	if about_panel:
		about_panel.visible = open
	if dimmer:
		dimmer.visible = open


func _on_load_selected(path: String) -> void:
	var err := Game.load_json_from_path(path)
	show_toast(L.t("loaded") if err == OK else L.t("load_fail"))


func _on_save_selected(path: String) -> void:
	if not path.ends_with(".json"):
		path += ".json"
	var err := Game.save_json_to_path(path)
	show_toast(L.t("saved") if err == OK else L.t("save_fail"))


func _on_png_selected(path: String) -> void:
	if not path.ends_with(".png"):
		path += ".png"
	var err := PngExporter.save_png(path, Game.map, 2)
	show_toast(L.t("exported") if err == OK else L.t("export_fail"))


func _export_png_web() -> void:
	var img := PngExporter.render_map(Game.map, 2)
	var buf := img.save_png_to_buffer()
	WebBridge.download_bytes("%s.png" % Game.filename_base(), buf, "image/png")
	show_toast(L.t("exported"))


func _on_web_json_text(text: String) -> void:
	if Game.import_json_text(text):
		show_toast(L.t("loaded"))
	else:
		show_toast(L.t("load_fail"))

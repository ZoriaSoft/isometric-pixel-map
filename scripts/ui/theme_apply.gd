class_name ThemeApply
extends RefCounted
## Dark tool UI — teal accent, no purple gradients.


static func make_theme() -> Theme:
	var t := Theme.new()
	var font_color := Color(0.88, 0.91, 0.94)
	var muted := Color(0.55, 0.60, 0.66)
	var accent := Color(0.24, 0.86, 0.59)
	var panel_bg := Color(0.07, 0.09, 0.12, 0.94)
	var btn_bg := Color(0.12, 0.15, 0.19, 1)
	var btn_hover := Color(0.16, 0.20, 0.26, 1)
	var btn_press := Color(0.10, 0.28, 0.22, 1)

	t.set_color("font_color", "Label", font_color)
	t.set_color("font_color", "Button", font_color)
	t.set_color("font_hover_color", "Button", Color.WHITE)
	t.set_color("font_pressed_color", "Button", accent)
	t.set_color("font_focus_color", "Button", accent)

	var panel := StyleBoxFlat.new()
	panel.bg_color = panel_bg
	panel.set_content_margin_all(6)
	panel.set_border_width_all(1)
	panel.border_color = Color(1, 1, 1, 0.06)
	t.set_stylebox("panel", "PanelContainer", panel)

	var normal := _btn_style(btn_bg, Color(1, 1, 1, 0.08))
	var hover := _btn_style(btn_hover, accent.darkened(0.35))
	var pressed := _btn_style(btn_press, accent)
	var focus := _btn_style(btn_bg, accent)
	t.set_stylebox("normal", "Button", normal)
	t.set_stylebox("hover", "Button", hover)
	t.set_stylebox("pressed", "Button", pressed)
	t.set_stylebox("focus", "Button", focus)
	t.set_stylebox("disabled", "Button", _btn_style(Color(0.1, 0.1, 0.12), Color(0, 0, 0, 0.2)))

	t.set_constant("separation", "HBoxContainer", 6)
	t.set_constant("separation", "VBoxContainer", 6)
	t.set_color("font_color", "TooltipLabel", muted)
	return t


static func _btn_style(bg: Color, border: Color) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.set_corner_radius_all(6)
	s.set_content_margin_all(8)
	s.content_margin_left = 10
	s.content_margin_right = 10
	s.set_border_width_all(1)
	s.border_color = border
	return s


static func active_tool_style() -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.10, 0.28, 0.22, 1)
	s.set_corner_radius_all(6)
	s.set_content_margin_all(8)
	s.content_margin_left = 10
	s.content_margin_right = 10
	s.set_border_width_all(1)
	s.border_color = Color(0.24, 0.86, 0.59)
	return s

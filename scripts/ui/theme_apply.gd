class_name ThemeApply
extends RefCounted
## Dark tool UI — teal accent, grouped toolbar styles. No purple.


static func make_theme() -> Theme:
	var t := Theme.new()
	var font_color := Color(0.88, 0.91, 0.94)
	var muted := Color(0.55, 0.60, 0.66)
	var accent := Color(0.24, 0.86, 0.59)
	var panel_bg := Color(0.07, 0.09, 0.12, 0.96)
	var btn_bg := Color(0.11, 0.14, 0.18, 1)
	var btn_hover := Color(0.15, 0.19, 0.24, 1)
	var btn_press := Color(0.09, 0.24, 0.20, 1)

	t.set_color("font_color", "Label", font_color)
	t.set_color("font_color", "Button", font_color)
	t.set_color("font_hover_color", "Button", Color.WHITE)
	t.set_color("font_pressed_color", "Button", accent)
	t.set_color("font_focus_color", "Button", accent)

	var panel := StyleBoxFlat.new()
	panel.bg_color = panel_bg
	panel.set_content_margin_all(4)
	panel.set_border_width_all(0)
	panel.border_color = Color(1, 1, 1, 0.0)
	# subtle bottom edge on bars
	panel.border_width_bottom = 1
	panel.border_color = Color(1, 1, 1, 0.06)
	t.set_stylebox("panel", "PanelContainer", panel)

	var normal := _btn_style(btn_bg, Color(1, 1, 1, 0.07), 6)
	var hover := _btn_style(btn_hover, accent.darkened(0.4), 6)
	var pressed := _btn_style(btn_press, accent, 6)
	var focus := _btn_style(btn_bg, accent.darkened(0.2), 6)
	t.set_stylebox("normal", "Button", normal)
	t.set_stylebox("hover", "Button", hover)
	t.set_stylebox("pressed", "Button", pressed)
	t.set_stylebox("focus", "Button", focus)
	t.set_stylebox("disabled", "Button", _btn_style(Color(0.1, 0.1, 0.12), Color(0, 0, 0, 0.2), 6))

	t.set_constant("separation", "HBoxContainer", 4)
	t.set_constant("separation", "VBoxContainer", 4)
	t.set_color("font_color", "TooltipLabel", muted)
	return t


static func _btn_style(bg: Color, border: Color, radius: int) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.set_corner_radius_all(radius)
	s.content_margin_left = 8
	s.content_margin_right = 8
	s.content_margin_top = 6
	s.content_margin_bottom = 6
	s.set_border_width_all(1)
	s.border_color = border
	return s


## Primary CTA (Export PNG)
static func primary_style() -> StyleBoxFlat:
	var s := _btn_style(Color(0.12, 0.42, 0.32, 1), Color(0.24, 0.86, 0.59), 6)
	return s


static func primary_hover_style() -> StyleBoxFlat:
	return _btn_style(Color(0.16, 0.50, 0.38, 1), Color(0.45, 0.95, 0.70), 6)


## Active drawing tool
static func tool_active_style() -> StyleBoxFlat:
	return _btn_style(Color(0.10, 0.28, 0.22, 1), Color(0.24, 0.86, 0.59), 6)


static func tool_active_hover_style() -> StyleBoxFlat:
	return _btn_style(Color(0.12, 0.34, 0.26, 1), Color(0.45, 0.95, 0.70), 6)


## Layer segmented (different from tools — quieter fill)
static func layer_active_style() -> StyleBoxFlat:
	var s := _btn_style(Color(0.14, 0.18, 0.24, 1), Color(0.24, 0.86, 0.59), 6)
	s.border_width_bottom = 2
	return s


static func layer_inactive_style() -> StyleBoxFlat:
	return _btn_style(Color(0.09, 0.11, 0.14, 1), Color(1, 1, 1, 0.05), 6)


## Toggle on (grid)
static func toggle_on_style() -> StyleBoxFlat:
	return _btn_style(Color(0.16, 0.20, 0.14, 1), Color(0.70, 0.85, 0.40), 6)


static func toggle_off_style() -> StyleBoxFlat:
	return _btn_style(Color(0.11, 0.14, 0.18, 1), Color(1, 1, 1, 0.07), 6)


## Compact icon button size helper
static func compact_min_size() -> Vector2:
	return Vector2(36, 32)

class_name ThemeApply
extends RefCounted
## "Pixel Atelier" — Luxury/Refined chrome.
## Warm obsidian canvas + champagne-gold accents + hairline gold borders.
## Serif display (Fraunces) for brand/section titles; mono (JetBrains Mono) for data.
## No purple, no Inter/Roboto/Arial, no generic teal.

## Palette (single source of truth for the editor chrome)
const BG_CANVAS := Color("12100d")      # clear color — warm obsidian
const PANEL := Color("1a1612")          # bars / panels
const PANEL_2 := Color("221c15")        # button / hover surfaces
const PANEL_3 := Color("2b241b")        # pressed / active fill
const GOLD := Color("c9a961")           # primary accent
const GOLD_BRIGHT := Color("e0c98f")
const CHAMPAGNE := Color("e5d4a1")      # bright text on gold / hover
const INK := Color("ede3ce")            # main text — warm ivory
const MUTED := Color("8f8470")          # hints, status
const DANGER := Color("d98a5f")         # erase ghost — warm terracotta
const HAIRLINE := Color(0.788, 0.663, 0.38, 0.20)

static var _brand: Font
static var _brand_light: Font
static var _mono: Font


static func brand_font() -> Font:
	if _brand == null:
		_brand = load("res://assets/fonts/fraunces-600.ttf")
	return _brand


static func brand_light_font() -> Font:
	if _brand_light == null:
		_brand_light = load("res://assets/fonts/fraunces-500.ttf")
	return _brand_light


static func mono_font() -> Font:
	if _mono == null:
		_mono = load("res://assets/fonts/jetbrains-mono-400.ttf")
	return _mono


## Letterspaced small-caps section header (used for TILES / section labels).
static func style_section_label(lbl: Label, size: int = 11) -> void:
	if lbl == null:
		return
	lbl.add_theme_font_override("font", brand_font())
	lbl.add_theme_font_size_override("font_size", size)
	lbl.add_theme_color_override("font_color", CHAMPAGNE.darkened(0.12))
	lbl.add_theme_constant_override("spacing_glyph", 3)
	lbl.text = lbl.text.to_upper()


static func make_theme() -> Theme:
	var t := Theme.new()

	# --- colors ---
	t.set_color("font_color", "Label", INK)
	t.set_color("font_color", "Button", INK)
	t.set_color("font_hover_color", "Button", CHAMPAGNE)
	t.set_color("font_pressed_color", "Button", CHAMPAGNE)
	t.set_color("font_focus_color", "Button", GOLD)
	t.set_color("font_disabled_color", "Button", MUTED.darkened(0.25))
	t.set_color("font_color", "LineEdit", INK)
	t.set_color("font_placeholder_color", "LineEdit", MUTED.darkened(0.15))
	t.set_color("font_caret_color", "LineEdit", GOLD)
	t.set_color("font_color", "TooltipLabel", INK)

	# --- panel bars ---
	var panel := StyleBoxFlat.new()
	panel.bg_color = PANEL
	panel.set_content_margin_all(6)
	panel.set_border_width_all(0)
	panel.border_color = HAIRLINE
	# hairline bottom edge (gold, faint)
	panel.border_width_bottom = 1
	t.set_stylebox("panel", "PanelContainer", panel)

	# --- floating cards (about) — applied per-node via card_style() ---

	# --- buttons ---
	var normal := _btn_style(PANEL_2, Color(1, 1, 1, 0.05), 5)
	var hover := _btn_style(PANEL_3, GOLD.darkened(0.35), 5)
	var pressed := _btn_style(GOLD.darkened(0.45), GOLD, 5)
	var focus := _btn_style(PANEL_2, GOLD.darkened(0.2), 5)
	var disabled := _btn_style(Color(0.15, 0.13, 0.10), Color(0, 0, 0, 0.3), 5)
	t.set_stylebox("normal", "Button", normal)
	t.set_stylebox("hover", "Button", hover)
	t.set_stylebox("pressed", "Button", pressed)
	t.set_stylebox("focus", "Button", focus)
	t.set_stylebox("disabled", "Button", disabled)

	# --- line edit ---
	var le := StyleBoxFlat.new()
	le.bg_color = Color(0.10, 0.088, 0.071, 1)
	le.set_corner_radius_all(5)
	le.set_border_width_all(1)
	le.border_color = Color(1, 1, 1, 0.07)
	le.content_margin_left = 10
	le.content_margin_right = 10
	le.content_margin_top = 5
	le.content_margin_bottom = 5
	t.set_stylebox("normal", "LineEdit", le)
	var le_focus := le.duplicate() as StyleBoxFlat
	le_focus.border_color = GOLD.darkened(0.15)
	t.set_stylebox("focus", "LineEdit", le_focus)

	# --- tooltips ---
	var tip := StyleBoxFlat.new()
	tip.bg_color = PANEL_2
	tip.set_corner_radius_all(4)
	tip.set_border_width_all(1)
	tip.border_color = HAIRLINE
	tip.content_margin_left = 8
	tip.content_margin_right = 8
	tip.content_margin_top = 5
	tip.content_margin_bottom = 5
	t.set_stylebox("panel", "TooltipPanel", tip)
	t.set_font_size("font_size", "TooltipLabel", 12)
	t.set_color("font_color", "TooltipLabel", CHAMPAGNE)

	# --- spacing ---
	t.set_constant("separation", "HBoxContainer", 6)
	t.set_constant("separation", "VBoxContainer", 6)
	t.set_font_size("font_size", "Button", 12)
	t.set_color("font_color", "PopupMenu", INK)
	t.set_color("font_hover_color", "PopupMenu", GOLD)
	return t


static func _btn_style(bg: Color, border: Color, radius: int) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.set_corner_radius_all(radius)
	s.content_margin_left = 9
	s.content_margin_right = 9
	s.content_margin_top = 6
	s.content_margin_bottom = 6
	s.set_border_width_all(1)
	s.border_color = border
	return s


## Floating card style (about panel) — rounded, hairline gold border, soft shadow.
static func card_style() -> StyleBoxFlat:
	var card := StyleBoxFlat.new()
	card.bg_color = PANEL
	card.set_corner_radius_all(10)
	card.set_border_width_all(1)
	card.border_color = HAIRLINE
	card.set_content_margin_all(6)
	card.shadow_color = Color(0, 0, 0, 0.5)
	card.shadow_size = 24
	card.shadow_offset = Vector2(0, 6)
	return card


## Primary CTA (Export PNG) — gold button, dark text.
static func primary_style() -> StyleBoxFlat:
	var s := _btn_style(GOLD, GOLD_BRIGHT, 5)
	s.content_margin_left = 14
	s.content_margin_right = 14
	return s


static func primary_hover_style() -> StyleBoxFlat:
	return _btn_style(GOLD_BRIGHT, Color(1, 0.93, 0.78), 5)


## Active drawing tool — gold-tinted fill + gold border.
static func tool_active_style() -> StyleBoxFlat:
	return _btn_style(GOLD.darkened(0.42), GOLD, 5)


static func tool_active_hover_style() -> StyleBoxFlat:
	return _btn_style(GOLD.darkened(0.34), GOLD_BRIGHT, 5)


## Layer segmented — quieter than tools; champagne underline when active.
static func layer_active_style() -> StyleBoxFlat:
	var s := _btn_style(PANEL_3, GOLD.darkened(0.3), 5)
	s.border_width_bottom = 2
	return s


static func layer_inactive_style() -> StyleBoxFlat:
	return _btn_style(Color(0.14, 0.12, 0.095, 1), Color(1, 1, 1, 0.05), 5)


## Toggle on (grid) — warm gold tint.
static func toggle_on_style() -> StyleBoxFlat:
	return _btn_style(GOLD.darkened(0.45), GOLD.darkened(0.1), 5)


static func toggle_off_style() -> StyleBoxFlat:
	return _btn_style(Color(0.14, 0.12, 0.095, 1), Color(1, 1, 1, 0.06), 5)


## Compact icon button size helper
static func compact_min_size() -> Vector2:
	return Vector2(36, 30)

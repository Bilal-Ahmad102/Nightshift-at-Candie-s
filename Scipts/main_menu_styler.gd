extends Node

# Tweak these to taste.
const LABEL_FONT_COLOR := Color(0.7, 0.7, 0.7)   # slightly darker than white
const BUTTON_FONT_COLOR := Color(0.7, 0.7, 0.7)

func _ready() -> void:
	style_children_recursive(get_parent())

func style_children_recursive(node: Node) -> void:
	for child in node.get_children():
		if child is Label:
			_style_label(child)
		elif child is Button:
			_style_button(child)
		style_children_recursive(child)

func _style_label(label: Label) -> void:
	label.add_theme_color_override("font_color", LABEL_FONT_COLOR)

func _style_button(button: Button) -> void:
	# Buttons have separate colors per state.
	button.add_theme_color_override("font_color",          BUTTON_FONT_COLOR)
	button.add_theme_color_override("font_hover_color",    BUTTON_FONT_COLOR.lightened(0.2))
	button.add_theme_color_override("font_pressed_color",  BUTTON_FONT_COLOR.darkened(0.2))
	button.add_theme_color_override("font_focus_color",    BUTTON_FONT_COLOR)
	button.add_theme_color_override("font_disabled_color", BUTTON_FONT_COLOR.darkened(0.4))


# ─────────────────────────────────────────────────────────────
# Reference: other styling options you can use
# ─────────────────────────────────────────────────────────────
#
# COLORS  →  add_theme_color_override(name, Color)
#   Label:   "font_color", "font_shadow_color", "font_outline_color"
#   Button:  "font_color", "font_hover_color", "font_pressed_color",
#            "font_focus_color", "font_disabled_color",
#            "font_outline_color", "icon_normal_color",
#            "icon_hover_color", "icon_pressed_color"
#
# NUMBERS →  add_theme_constant_override(name, int)
#   Label:   "shadow_offset_x", "shadow_offset_y", "shadow_outline_size",
#            "outline_size", "line_spacing"
#   Button:  "outline_size", "h_separation" (gap between icon and text)
#
# FONT SIZE → add_theme_font_size_override("font_size", int)
# FONT FILE → add_theme_font_override("font", preload("res://font.ttf"))
#
# BACKGROUND / BORDER  →  add_theme_stylebox_override(name, StyleBox)
#   Button states: "normal", "hover", "pressed", "focus", "disabled"
#   Example:
#       var sb := StyleBoxFlat.new()
#       sb.bg_color = Color(0.1, 0.1, 0.1, 0.6)
#       sb.set_corner_radius_all(6)
#       sb.set_border_width_all(1)
#       sb.border_color = Color(1, 1, 1, 0.2)
#       button.add_theme_stylebox_override("normal", sb)
#
# DIRECT PROPERTIES (no override needed)
#   Label:   text, horizontal_alignment, vertical_alignment,
#            autowrap_mode, clip_text, uppercase, modulate
#   Button:  text, icon, alignment, flat, toggle_mode, modulate
#
# TIP: for consistent styling across the whole project, build a Theme
# resource once and assign it to the root Control instead of overriding
# per-node. Overrides are best for one-offs.

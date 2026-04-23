extends Resource
class_name PresentationPalette

@export var surface_background := Color(0.047, 0.066, 0.086, 1.0)
@export var surface_background_alt := Color(0.064, 0.09, 0.117, 1.0)
@export var surface_panel := Color(0.102, 0.145, 0.18, 0.96)
@export var surface_panel_elevated := Color(0.124, 0.171, 0.211, 0.98)
@export var surface_overlay := Color(0.026, 0.039, 0.051, 0.9)
@export var text_primary := Color(0.917, 0.949, 0.968, 1.0)
@export var text_secondary := Color(0.63, 0.711, 0.759, 1.0)
@export var accent_warm := Color(0.953, 0.761, 0.404, 1.0)
@export var accent_cool := Color(0.459, 0.741, 0.859, 1.0)
@export var accent_focus := Color(0.984, 0.878, 0.522, 1.0)
@export var accent_danger := Color(0.882, 0.396, 0.361, 1.0)
@export var shadow_color := Color(0.0, 0.0, 0.0, 0.55)


func make_panel_style(background: Color, border: Color, border_width: int = 1, corner_radius: int = 16) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_width_left = border_width
	style.border_width_top = border_width
	style.border_width_right = border_width
	style.border_width_bottom = border_width
	style.border_color = border
	style.corner_radius_top_left = corner_radius
	style.corner_radius_top_right = corner_radius
	style.corner_radius_bottom_right = corner_radius
	style.corner_radius_bottom_left = corner_radius
	style.shadow_color = shadow_color
	style.shadow_size = 4
	style.content_margin_left = 12
	style.content_margin_top = 10
	style.content_margin_right = 12
	style.content_margin_bottom = 10
	return style


func make_button_style(background: Color, border: Color, text_tint: Color, corner_radius: int = 12) -> StyleBoxFlat:
	var style := make_panel_style(background, border, 1, corner_radius)
	style.content_margin_left = 18
	style.content_margin_top = 10
	style.content_margin_right = 18
	style.content_margin_bottom = 10
	style.shadow_size = 0
	style.shadow_color = Color(0, 0, 0, 0)
	style.expand_margin_bottom = 1
	style.expand_margin_top = 1
	style.border_color = border.blend(text_tint.darkened(0.35))
	return style

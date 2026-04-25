extends Theme
class_name FzUiTheme

const PresentationPalette = preload("res://scripts/presentation/presentation_palette.gd")

@export var palette: PresentationPalette:
	set(value):
		palette = value
		_rebuild()


func _init() -> void:
	_rebuild()


func _rebuild() -> void:
	clear()
	if palette == null:
		return

	var panel_border := palette.accent_cool.lerp(palette.text_secondary, 0.45)
	var elevated_border := palette.accent_warm.lerp(palette.accent_cool, 0.35)
	var callout_border := palette.accent_cool.lightened(0.15)
	var hud_border := palette.accent_cool.darkened(0.18)

	set_color("font_color", "Label", palette.text_primary)
	set_color("font_shadow_color", "Label", palette.shadow_color)
	set_constant("shadow_offset_x", "Label", 1)
	set_constant("shadow_offset_y", "Label", 2)

	set_color("font_color", "Button", palette.text_primary)
	set_color("font_focus_color", "Button", palette.text_primary)
	set_color("font_hover_color", "Button", palette.text_primary)
	set_color("font_pressed_color", "Button", palette.text_primary)
	set_color("font_disabled_color", "Button", palette.text_secondary.darkened(0.1))
	set_font_size("font_size", "Button", 16)

	set_stylebox("normal", "Button", palette.make_button_style(palette.surface_panel, panel_border, palette.text_primary))
	set_stylebox("hover", "Button", palette.make_button_style(palette.surface_panel_elevated, palette.accent_cool, palette.text_primary))
	set_stylebox("pressed", "Button", palette.make_button_style(palette.surface_overlay, palette.accent_warm, palette.text_primary))
	set_stylebox("disabled", "Button", palette.make_button_style(palette.surface_overlay, panel_border.darkened(0.25), palette.text_secondary))

	var button_focus := StyleBoxFlat.new()
	button_focus.draw_center = false
	button_focus.border_width_left = 2
	button_focus.border_width_top = 2
	button_focus.border_width_right = 2
	button_focus.border_width_bottom = 2
	button_focus.border_color = palette.accent_focus
	button_focus.corner_radius_top_left = 14
	button_focus.corner_radius_top_right = 14
	button_focus.corner_radius_bottom_right = 14
	button_focus.corner_radius_bottom_left = 14
	set_stylebox("focus", "Button", button_focus)

	set_color("font_color", "ItemList", palette.text_primary)
	set_color("font_selected_color", "ItemList", palette.surface_background)
	set_color("font_hovered_color", "ItemList", palette.text_primary)
	set_color("guide_color", "ItemList", panel_border)
	set_color("selection_fill", "ItemList", palette.accent_cool)
	set_color("selection_rect", "ItemList", palette.accent_focus)
	set_stylebox("panel", "ItemList", palette.make_panel_style(palette.surface_overlay, panel_border.darkened(0.15), 1, 12))
	set_stylebox("focus", "ItemList", button_focus.duplicate())

	set_stylebox("panel", "PanelContainer", palette.make_panel_style(palette.surface_panel, panel_border, 1, 18))

	set_font_size("font_size", "ShellTitle", 38)
	set_color("font_color", "ShellTitle", palette.accent_warm)
	set_font_size("font_size", "ShellSubtitle", 16)
	set_color("font_color", "ShellSubtitle", palette.text_secondary)
	set_font_size("font_size", "ShellSectionTitle", 18)
	set_color("font_color", "ShellSectionTitle", palette.accent_warm.lightened(0.08))
	set_font_size("font_size", "ShellBodyStrong", 28)
	set_color("font_color", "ShellBodyStrong", palette.text_primary)
	set_font_size("font_size", "ShellBodyMuted", 15)
	set_color("font_color", "ShellBodyMuted", palette.text_secondary)

	set_stylebox("panel", "ShellPanel", palette.make_panel_style(palette.surface_panel, panel_border, 1, 18))
	set_stylebox("panel", "ShellPanelElevated", palette.make_panel_style(palette.surface_panel_elevated, elevated_border, 1, 22))
	set_stylebox("panel", "ShellCalloutPanel", palette.make_panel_style(palette.surface_overlay, callout_border, 1, 16))

	set_stylebox("normal", "ShellButtonPrimary", palette.make_button_style(palette.accent_warm.darkened(0.22), palette.accent_warm, palette.text_primary))
	set_stylebox("hover", "ShellButtonPrimary", palette.make_button_style(palette.accent_warm.darkened(0.08), palette.accent_focus, palette.text_primary))
	set_stylebox("pressed", "ShellButtonPrimary", palette.make_button_style(palette.accent_warm.darkened(0.32), palette.accent_focus, palette.text_primary))
	set_stylebox("disabled", "ShellButtonPrimary", palette.make_button_style(palette.surface_overlay, palette.text_secondary.darkened(0.2), palette.text_secondary))
	set_stylebox("focus", "ShellButtonPrimary", button_focus.duplicate())

	set_stylebox("normal", "ShellButtonSecondary", palette.make_button_style(palette.surface_overlay, palette.accent_cool, palette.text_primary))
	set_stylebox("hover", "ShellButtonSecondary", palette.make_button_style(palette.surface_panel, palette.accent_cool.lightened(0.1), palette.text_primary))
	set_stylebox("pressed", "ShellButtonSecondary", palette.make_button_style(palette.surface_overlay, palette.accent_focus, palette.text_primary))
	set_stylebox("disabled", "ShellButtonSecondary", palette.make_button_style(palette.surface_overlay, palette.text_secondary.darkened(0.2), palette.text_secondary))
	set_stylebox("focus", "ShellButtonSecondary", button_focus.duplicate())

	set_color("font_color", "ShellButtonUnavailable", palette.accent_danger.lightened(0.2))
	set_color("font_focus_color", "ShellButtonUnavailable", palette.accent_danger.lightened(0.25))
	set_color("font_hover_color", "ShellButtonUnavailable", palette.accent_danger.lightened(0.25))
	set_color("font_pressed_color", "ShellButtonUnavailable", palette.accent_danger.lightened(0.25))
	set_stylebox("normal", "ShellButtonUnavailable", palette.make_button_style(palette.surface_overlay, palette.accent_danger.darkened(0.08), palette.accent_danger))
	set_stylebox("hover", "ShellButtonUnavailable", palette.make_button_style(palette.surface_panel, palette.accent_danger, palette.accent_danger.lightened(0.2)))
	set_stylebox("pressed", "ShellButtonUnavailable", palette.make_button_style(palette.surface_overlay, palette.accent_danger, palette.accent_danger.lightened(0.2)))
	set_stylebox("disabled", "ShellButtonUnavailable", palette.make_button_style(palette.surface_overlay, palette.accent_danger.darkened(0.2), palette.accent_danger))
	set_stylebox("focus", "ShellButtonUnavailable", button_focus.duplicate())

	set_stylebox("panel", "HudPanel", palette.make_panel_style(palette.surface_overlay, hud_border, 1, 14))
	set_font_size("font_size", "HudTitle", 20)
	set_color("font_color", "HudTitle", palette.accent_warm)
	set_font_size("font_size", "HudBody", 17)
	set_color("font_color", "HudBody", palette.text_primary)
	set_font_size("font_size", "HudStatus", 16)
	set_color("font_color", "HudStatus", palette.text_secondary.lightened(0.06))

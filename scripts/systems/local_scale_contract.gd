extends RefCounted
class_name LocalScaleContract

const MatchController = preload("res://scripts/systems/match_controller.gd")

enum ScaleTier { POLISHED_2_4, VALIDATION_5_8 }

const PRIMARY_VIEWPORT := "1920x1080"
const SECONDARY_VIEWPORT := "1280x720"


static func get_scale_tier(active_slots: int) -> int:
	var clamped_slots := clampi(active_slots, 1, 8)
	if clamped_slots <= 4:
		return ScaleTier.POLISHED_2_4
	return ScaleTier.VALIDATION_5_8


static func is_polished_scale(active_slots: int) -> bool:
	return get_scale_tier(active_slots) == ScaleTier.POLISHED_2_4


static func get_scale_tier_label(active_slots: int) -> String:
	if is_polished_scale(active_slots):
		return "2-4 pulido"
	return "5-8 validacion"


static func get_mode_scale_label(active_slots: int, match_mode: int) -> String:
	var clamped_slots := clampi(active_slots, 1, 8)
	if match_mode == MatchController.MatchMode.TEAMS and clamped_slots >= 8:
		return "Teams 4v4"
	if match_mode == MatchController.MatchMode.TEAMS:
		return "Teams %sP" % clamped_slots
	return "FFA %sP" % clamped_slots


static func get_setup_status_line(active_slots: int, match_mode: int) -> String:
	var mode_label := get_mode_scale_label(active_slots, match_mode)
	var tier_label := get_scale_tier_label(active_slots)
	if is_polished_scale(active_slots):
		return "Escala | %s | %s | objetivo de UX actual" % [mode_label, tier_label]
	return "Escala | %s | %s | soportado, requiere playtest humano" % [mode_label, tier_label]


static func get_shared_screen_budget(active_slots: int) -> Dictionary:
	var clamped_slots := clampi(active_slots, 1, 8)
	if clamped_slots <= 4:
		return {
			"tier": get_scale_tier_label(clamped_slots),
			"visible_rosters": clamped_slots,
			"max_hud_line_chars": 96,
			"compact_standings": false,
			"device_summary": "pausa",
			"camera_priority": "leer duelos y bordes",
		}
	return {
		"tier": get_scale_tier_label(clamped_slots),
		"visible_rosters": clamped_slots,
		"max_hud_line_chars": 72,
		"compact_standings": true,
		"device_summary": "pausa",
		"camera_priority": "mantener grupos y rutas, no detalle fino",
	}


static func get_performance_budget(viewport_id: String) -> Dictionary:
	match viewport_id:
		PRIMARY_VIEWPORT:
			return {
				"viewport": PRIMARY_VIEWPORT,
				"target_fps": 60.0,
				"frame_budget_ms": 16.7,
				"warning_frame_ms": 20.0,
				"primary_reference": true,
			}
		SECONDARY_VIEWPORT:
			return {
				"viewport": SECONDARY_VIEWPORT,
				"target_fps": 60.0,
				"frame_budget_ms": 16.7,
				"warning_frame_ms": 20.0,
				"primary_reference": false,
			}
	return {
		"viewport": viewport_id,
		"target_fps": 60.0,
		"frame_budget_ms": 16.7,
		"warning_frame_ms": 20.0,
		"primary_reference": false,
	}

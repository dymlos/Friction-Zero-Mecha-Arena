extends SceneTree

const FfaAftermathRules = preload("res://scripts/systems/ffa_aftermath_rules.gd")
const MatchController = preload("res://scripts/systems/match_controller.gd")
const MatchModeVariantCatalog = preload("res://scripts/systems/match_mode_variant_catalog.gd")
const RobotBase = preload("res://scripts/robots/robot_base.gd")
const ROBOT_SCENE := preload("res://scenes/robots/robot_base.tscn")
const AGUJA_CONFIG := preload("res://data/config/robots/aguja_archetype.tres")

var _failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_assert(FfaAftermathRules.should_spawn_aftermath(MatchController.MatchMode.FFA, true, 2), "Aftermath deberia aparecer en FFA con ronda activa y dos rivales restantes.")
	_assert(FfaAftermathRules.should_spawn_aftermath(MatchController.MatchMode.FFA, true, 2, MatchModeVariantCatalog.VARIANT_SCORE_BY_CAUSE), "Aftermath deberia aparecer en FFA score_by_cause con dos rivales restantes.")
	_assert(FfaAftermathRules.should_spawn_aftermath(MatchController.MatchMode.FFA, true, 2, MatchModeVariantCatalog.VARIANT_LAST_ALIVE), "Aftermath deberia aparecer en FFA Ultimo vivo con dos rivales restantes.")
	_assert(not FfaAftermathRules.should_spawn_aftermath(MatchController.MatchMode.FFA, true, 1, MatchModeVariantCatalog.VARIANT_LAST_ALIVE), "Aftermath no deberia aparecer en la baja final de Ultimo vivo.")
	_assert(not FfaAftermathRules.should_spawn_aftermath(MatchController.MatchMode.TEAMS, true, 2, MatchModeVariantCatalog.VARIANT_SCORE_BY_CAUSE), "Aftermath no deberia aparecer en Teams score_by_cause.")
	_assert(not FfaAftermathRules.should_spawn_aftermath(MatchController.MatchMode.TEAMS, true, 2), "Aftermath no deberia aparecer en Teams.")
	_assert(not FfaAftermathRules.should_spawn_aftermath(MatchController.MatchMode.FFA, false, 2), "Aftermath no deberia aparecer con ronda cerrada.")
	_assert(not FfaAftermathRules.should_spawn_aftermath(MatchController.MatchMode.FFA, true, 1), "Aftermath no deberia aparecer en la baja que cierra ronda.")

	var robot := ROBOT_SCENE.instantiate() as RobotBase
	root.add_child(robot)
	robot.apply_runtime_loadout(AGUJA_CONFIG, RobotBase.ControlMode.EASY)
	_assert(
		FfaAftermathRules.choose_payload(robot, null, 1, 1) == FfaAftermathRules.PAYLOAD_CHARGE,
		"Un eliminado con skill de cargas deberia preferir botin de carga."
	)
	robot.free()
	_finish()


func _assert(condition: bool, message: String) -> void:
	if condition:
		return

	_failed = true
	push_error(message)


func _finish() -> void:
	quit(1 if _failed else 0)

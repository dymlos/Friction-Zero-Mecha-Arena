extends SceneTree

const PRACTICE_SETUP_SCENE := preload("res://scenes/shell/practice_setup.tscn")
const HOW_TO_PLAY_SCENE := preload("res://scenes/shell/how_to_play_screen.tscn")
const PRACTICE_HUD_SCENE := preload("res://scenes/ui/practice_hud.tscn")

var _failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var practice_setup := PRACTICE_SETUP_SCENE.instantiate()
	var how_to_play := HOW_TO_PLAY_SCENE.instantiate()
	var practice_hud := PRACTICE_HUD_SCENE.instantiate()

	root.add_child(practice_setup)
	root.add_child(how_to_play)
	root.add_child(practice_hud)
	current_scene = practice_setup

	await process_frame
	await process_frame

	_assert(practice_setup.has_method("get_selected_module_id"), "PracticeSetup deberia exponer el modulo activo.")
	_assert(practice_setup.has_method("get_recommended_robot_label"), "PracticeSetup deberia exponer el robot recomendado.")
	_assert(practice_setup.has_method("get_related_topic_labels"), "PracticeSetup deberia exponer los temas relacionados.")
	_assert(
		practice_setup.get_node_or_null("Frame/VBox/Body/DetailPanel/DetailMargin/DetailVBox/ContextCardValueLabel") != null,
		"PracticeSetup deberia tener label de tarjeta contextual."
	)
	_assert(
		practice_setup.get_node_or_null("Frame/VBox/Body/DetailPanel/DetailMargin/DetailVBox/PlayerScopeValueLabel") != null,
		"PracticeSetup deberia tener label visible para 1-2P/HUD explicito."
	)
	_assert(how_to_play.has_method("focus_practice_button"), "How to Play deberia poder devolver el foco al CTA de Practica.")
	_assert(practice_hud.has_method("set_callout_lines"), "PracticeHud deberia poder mostrar callouts cortos.")

	practice_hud.call("set_module_title", "Movimiento")
	practice_hud.call("set_objective_lines", ["Cruza el arco con control."])
	practice_hud.call("set_progress_lines", ["P1 | Easy | en ruta"])
	practice_hud.call("set_controls_lines", ["P1 | move WASD"])
	practice_hud.call("set_callout_lines", ["Arranque pesado y frenado legible."])
	practice_hud.call("set_pause_lines", ["Sin pausa"])

	_assert(String(practice_setup.get_node_or_null("Frame/VBox/Body/DetailPanel/DetailMargin/DetailVBox/SummaryValueLabel").text) != "", "PracticeSetup deberia conservar un resumen visible.")
	_assert(String(how_to_play.get_node_or_null("Frame/VBox/Footer/PracticeButton").text).begins_with("Probar"), "How to Play deberia usar un CTA corto y contextual.")

	await _cleanup_node(practice_setup)
	await _cleanup_node(how_to_play)
	await _cleanup_node(practice_hud)
	_finish()


func _cleanup_node(node: Node) -> void:
	if node == null or not is_instance_valid(node):
		return
	var parent := node.get_parent()
	if parent != null:
		parent.remove_child(node)
	node.free()
	await process_frame


func _assert(condition: bool, message: String) -> void:
	if condition:
		return

	_failed = true
	push_error(message)


func _finish() -> void:
	quit(1 if _failed else 0)

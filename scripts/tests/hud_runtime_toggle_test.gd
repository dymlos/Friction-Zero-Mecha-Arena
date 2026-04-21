extends SceneTree

const MAIN_SCENE := preload("res://scenes/main/main.tscn")

var _failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var main := MAIN_SCENE.instantiate()
	root.add_child(main)

	await process_frame
	await process_frame

	var round_label := main.get_node_or_null("UI/MatchHud/Root/RoundLabel")
	var status_label := main.get_node_or_null("UI/MatchHud/Root/StatusLabel")
	_assert(round_label is Label, "La escena principal deberia seguir exponiendo RoundLabel.")
	_assert(status_label is Label, "La escena principal deberia seguir exponiendo StatusLabel.")
	_assert(main.has_method("cycle_hud_detail_mode"), "Main deberia exponer un toggle runtime para el HUD.")
	if not (round_label is Label) or not (status_label is Label) or not main.has_method("cycle_hud_detail_mode"):
		await _cleanup_main(main)
		_finish()
		return

	var explicit_round := (round_label as Label).text
	_assert(explicit_round.contains("Modo |"), "El HUD deberia arrancar en modo explicito por defecto.")

	main.call("cycle_hud_detail_mode")
	await process_frame

	var contextual_round := (round_label as Label).text
	var status_text := (status_label as Label).text
	_assert(not contextual_round.contains("Modo |"), "El toggle runtime deberia poder llevar el HUD al modo contextual.")
	_assert(status_text.contains("HUD contextual"), "El HUD deberia anunciar el modo activo tras alternarlo.")

	await _cleanup_main(main)

	var fresh_main := MAIN_SCENE.instantiate()
	root.add_child(fresh_main)

	await process_frame
	await process_frame

	var fresh_round_label := fresh_main.get_node_or_null("UI/MatchHud/Root/RoundLabel")
	_assert(fresh_round_label is Label, "Una nueva instancia deberia seguir exponiendo RoundLabel.")
	if fresh_round_label is Label:
		var fresh_round := (fresh_round_label as Label).text
		_assert(
			fresh_round.contains("Modo |"),
			"El toggle runtime no deberia mutar el recurso compartido del match ni cambiar el default de nuevas escenas."
		)

	await _cleanup_main(fresh_main)
	_finish()


func _assert(condition: bool, message: String) -> void:
	if condition:
		return

	_failed = true
	push_error(message)


func _cleanup_main(main: Node) -> void:
	if not is_instance_valid(main):
		return

	var parent := main.get_parent()
	if parent != null:
		parent.remove_child(main)
	main.free()
	await process_frame


func _finish() -> void:
	quit(1 if _failed else 0)

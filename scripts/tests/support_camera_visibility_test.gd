extends SceneTree

const TEAM_SCENES := [
	"res://scenes/main/main.tscn",
	"res://scenes/main/main_teams_validation.tscn",
	"res://scenes/main/main_teams_large_validation.tscn",
]
const MatchController = preload("res://scripts/systems/match_controller.gd")
const RobotBase = preload("res://scripts/robots/robot_base.gd")

var _failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	await _apply_viewport(Vector2i(1280, 720))
	for scene_path in TEAM_SCENES:
		await _verify_support_ship_stays_in_camera_view(scene_path)
	_finish()


func _verify_support_ship_stays_in_camera_view(scene_path: String) -> void:
	var main := await _instantiate_scene(scene_path)
	var match_controller := main.get_node_or_null("Systems/MatchController") as MatchController
	var support_root := main.get_node_or_null("SupportRoot") as Node3D
	var camera := main.get_node_or_null("Camera3D") as Camera3D
	var robots := _get_scene_robots(main)
	_assert(match_controller != null, "%s deberia exponer MatchController." % scene_path)
	_assert(support_root != null, "%s deberia exponer SupportRoot." % scene_path)
	_assert(camera != null, "%s deberia exponer la camara compartida." % scene_path)
	_assert(robots.size() >= 4, "%s deberia seguir ofreciendo cuatro robots." % scene_path)
	if match_controller == null or support_root == null or camera == null or robots.size() < 4:
		await _cleanup_main(main)
		return

	robots[1].fall_into_void()
	await _wait_frames(4)

	_assert(
		support_root.get_child_count() == 1,
		"Al caer un aliado en Teams deberia aparecer la nave de apoyo para validar su framing."
	)
	if support_root.get_child_count() == 0:
		await _cleanup_main(main)
		return

	var support_ship := support_root.get_child(0) as Node3D
	_assert(support_ship != null, "La nave de apoyo deberia existir como Node3D.")
	if support_ship == null:
		await _cleanup_main(main)
		return

	var viewport_rect := camera.get_viewport().get_visible_rect().grow(-24.0)
	var screen_point := camera.unproject_position(support_ship.global_position)
	_assert(
		not camera.is_position_behind(support_ship.global_position),
		"La nave de apoyo no deberia quedar por detras de la camara compartida."
	)
	_assert(
		viewport_rect.has_point(screen_point),
		"La camara compartida de %s deberia mantener en cuadro a la nave de apoyo activa." % scene_path
	)

	await _cleanup_main(main)


func _instantiate_scene(scene_path: String) -> Node:
	var packed_scene := load(scene_path)
	_assert(packed_scene is PackedScene, "La escena %s deberia existir." % scene_path)
	if not (packed_scene is PackedScene):
		return Node.new()

	var main := (packed_scene as PackedScene).instantiate()
	var match_controller_preload := main.get_node_or_null("Systems/MatchController") as MatchController
	if match_controller_preload != null:
		match_controller_preload.round_intro_duration = 0.0
		if match_controller_preload.match_config != null:
			match_controller_preload.match_config.round_intro_duration_teams = 0.0
			match_controller_preload.match_config.progressive_space_reduction = false
			match_controller_preload.match_config.round_time_seconds = maxf(
				float(match_controller_preload.match_config.round_time_seconds),
				120.0
			)
	root.add_child(main)
	await process_frame
	await process_frame
	return main


func _apply_viewport(size: Vector2i) -> void:
	var root_window := get_root()
	if root_window.has_method("set_size_2d_override"):
		root_window.call("set_size_2d_override", size)
	if root_window.has_method("set_size_2d_override_stretch"):
		root_window.call("set_size_2d_override_stretch", true)
	root_window.min_size = size
	root_window.size = size
	root_window.content_scale_size = size
	await process_frame
	RenderingServer.force_draw(false)
	await process_frame


func _get_scene_robots(main: Node) -> Array[RobotBase]:
	var robots: Array[RobotBase] = []
	var robot_root := main.get_node_or_null("RobotRoot")
	if robot_root == null:
		return robots

	for child in robot_root.get_children():
		if child is RobotBase:
			robots.append(child as RobotBase)

	return robots


func _wait_frames(frame_count: int) -> void:
	for _index in range(maxi(frame_count, 0)):
		await process_frame


func _cleanup_main(main: Node) -> void:
	if not is_instance_valid(main):
		return

	var parent := main.get_parent()
	if parent != null:
		parent.remove_child(main)
	main.free()
	await process_frame


func _assert(condition: bool, message: String) -> void:
	if condition:
		return

	_failed = true
	push_error(message)


func _finish() -> void:
	quit(1 if _failed else 0)

extends SceneTree

const QaArgs = preload("res://addons/godot_qa/qa_args.gd")
const QaBridge = preload("res://addons/godot_qa/qa_bridge.gd")
const QaProtocol = preload("res://addons/godot_qa/qa_protocol.gd")

var _bridge: Node = null
var _request := {}
var _scene_instance: Node = null
var _server := TCPServer.new()


func _initialize() -> void:
	var parsed_args := QaArgs.parse_user_args(OS.get_cmdline_user_args())
	var options: Dictionary = parsed_args.get("options", {})
	var request_path := str(options.get("session_request", ""))
	if request_path == "":
		print(JSON.stringify(QaProtocol.error(
			"missing_session_request",
			"qa_session_runner requires --qa-session-request=<abs-path>",
			{"qa_args": parsed_args},
		)))
		quit(1)
		return

	_request = _read_json_file(request_path)
	if _request.is_empty():
		print(JSON.stringify(QaProtocol.error(
			"request_read_failed",
			"qa_session_runner could not load request.json",
			{"request_path": request_path},
		)))
		quit(1)
		return

	await _run()


func _run() -> void:
	var session_request: Dictionary = _request.get("session", {})
	var artifacts: Dictionary = _request.get("artifacts", {})
	var scene_path := str(session_request.get("scene", ""))
	var packed_scene := load(scene_path)
	if packed_scene == null or not packed_scene is PackedScene:
		print(JSON.stringify(QaProtocol.error(
			"scene_load_failed",
			"live session scene could not be loaded",
			{"scene": scene_path},
		)))
		quit(1)
		return

	_scene_instance = packed_scene.instantiate()
	if _scene_instance == null:
		print(JSON.stringify(QaProtocol.error(
			"scene_instantiate_failed",
			"live session scene could not be instantiated",
			{"scene": scene_path},
		)))
		quit(1)
		return

	get_root().add_child(_scene_instance)
	await _apply_requested_viewport(session_request.get("viewport", []))
	await process_frame

	_bridge = QaBridge.new()
	_bridge.name = "GodotQaBridge"
	get_root().add_child(_bridge)
	await process_frame
	if _bridge.has_method("configure_live_session"):
		_bridge.call(
			"configure_live_session",
			{
				"session_id": str(session_request.get("id", "")),
				"scene": scene_path,
				"viewport": session_request.get("viewport", []),
				"started_at": str(session_request.get("started_at", "")),
				"snapshots_dir": str(artifacts.get("snapshots_dir", "")),
				"screenshots_dir": str(artifacts.get("screenshots_dir", "")),
				"recorder_enabled": bool(session_request.get("recorder_enabled", false)),
			},
		)

	var port := int(session_request.get("port", 0))
	var listen_error := _server.listen(port, "127.0.0.1")
	if listen_error != OK:
		print(JSON.stringify(QaProtocol.error(
			"session_listen_failed",
			"live session TCP server could not bind",
			{
				"port": port,
				"actual": listen_error,
			},
		)))
		quit(1)
		return

	while true:
		if _bridge != null and _bridge.has_method("consume_stop_requested") and bool(_bridge.call("consume_stop_requested")):
			break
		if _server.is_connection_available():
			var peer := _server.take_connection()
			await _handle_connection(peer)
			continue
		await process_frame

	_server.stop()
	quit(0)


func _apply_requested_viewport(viewport_values: Variant) -> void:
	if not viewport_values is Array or viewport_values.size() < 2:
		return
	var width := int(viewport_values[0])
	var height := int(viewport_values[1])
	if width <= 0 or height <= 0:
		return

	var root_window := get_root()
	if root_window.has_method("set_size_2d_override"):
		root_window.call("set_size_2d_override", Vector2i(width, height))
	if root_window.has_method("set_size_2d_override_stretch"):
		root_window.call("set_size_2d_override_stretch", true)
	root_window.min_size = Vector2i(width, height)
	root_window.size = Vector2i(width, height)
	root_window.content_scale_size = Vector2i(width, height)
	await process_frame
	RenderingServer.force_draw(false)
	await process_frame


func _handle_connection(peer: StreamPeerTCP) -> void:
	var request_text := await _read_request_line(peer)
	var response := {}
	if request_text == "":
		response = QaProtocol.error("protocol_error", "live session request was empty", {})
	else:
		var parser := JSON.new()
		var parse_error := parser.parse(request_text)
		if parse_error != OK or not parser.data is Dictionary:
			response = QaProtocol.error(
				"protocol_error",
				"live session request must be a JSON object",
				{"actual": request_text},
			)
		else:
			response = await _bridge.handle_command(parser.data)

	var response_text := "%s\n" % JSON.stringify(response)
	peer.put_data(response_text.to_utf8_buffer())
	peer.disconnect_from_host()


func _read_request_line(peer: StreamPeerTCP) -> String:
	var buffer := ""
	var started_at := Time.get_ticks_msec()
	while Time.get_ticks_msec() - started_at < 5000:
		peer.poll()
		var available := peer.get_available_bytes()
		if available > 0:
			buffer += peer.get_utf8_string(available)
			var newline_index := buffer.find("\n")
			if newline_index != -1:
				return buffer.substr(0, newline_index)
		if peer.get_status() != StreamPeerTCP.STATUS_CONNECTED and available == 0:
			break
		await process_frame
	return buffer.strip_edges()


func _read_json_file(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parser := JSON.new()
	var parse_error := parser.parse(file.get_as_text())
	if parse_error != OK or not parser.data is Dictionary:
		return {}
	return parser.data

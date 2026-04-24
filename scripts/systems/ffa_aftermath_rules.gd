extends RefCounted
class_name FfaAftermathRules

const MatchController = preload("res://scripts/systems/match_controller.gd")
const RobotBase = preload("res://scripts/robots/robot_base.gd")

const PAYLOAD_SCRAP := "chatarra"
const PAYLOAD_CHARGE := "carga"
const PAYLOAD_SURGE := "impulso"
const PICKUP_LIFETIME_SECONDS := 8.0
const SCRAP_REPAIR_RATIO := 0.10
const SURGE_DURATION_SECONDS := 0.8


static func should_spawn_aftermath(
	match_mode: int,
	round_active: bool,
	remaining_competitors_after_elimination: int,
	_mode_variant_id: String = ""
) -> bool:
	return match_mode == MatchController.MatchMode.FFA and round_active and remaining_competitors_after_elimination >= 2


static func choose_payload(eliminated_robot: RobotBase, _source_robot: RobotBase, round_number: int, elimination_order: int) -> String:
	var candidates: Array[String] = []
	if eliminated_robot != null and eliminated_robot.has_core_skill():
		candidates.append(PAYLOAD_CHARGE)
	if _count_destroyed_parts(eliminated_robot) >= 2:
		candidates.append(PAYLOAD_SCRAP)
	if candidates.is_empty():
		return PAYLOAD_SURGE
	if candidates.size() == 1:
		return candidates[0]
	return candidates[wrapi(round_number + elimination_order, 0, candidates.size())]


static func describe_zone(world_position: Vector3) -> String:
	if absf(world_position.x) > absf(world_position.z):
		return "este" if world_position.x > 0.0 else "oeste"
	return "sur" if world_position.z > 0.0 else "norte"


static func _count_destroyed_parts(robot: RobotBase) -> int:
	if robot == null:
		return 0
	var count := 0
	for part_name in RobotBase.BODY_PARTS:
		if robot.get_part_health(part_name) <= 0.0:
			count += 1
	return count

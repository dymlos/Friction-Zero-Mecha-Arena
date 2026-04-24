extends RefCounted
class_name JoypadScrollHelper

const SCROLL_DEADZONE := 0.38
const SCROLL_SPEED := 620.0


static func apply_right_stick_scroll(root: Node, delta: float) -> bool:
	if root == null:
		return false

	var axis_value := _get_strongest_right_stick_y()
	if absf(axis_value) < SCROLL_DEADZONE:
		return false

	var scroll_container := _find_best_visible_scroll_container(root)
	if scroll_container == null:
		return false

	var bar := scroll_container.get_v_scroll_bar()
	if bar == null or bar.max_value <= bar.page:
		return false

	bar.value = clampf(bar.value + axis_value * SCROLL_SPEED * delta, bar.min_value, bar.max_value)
	return true


static func _get_strongest_right_stick_y() -> float:
	var strongest := 0.0
	for device_id in Input.get_connected_joypads():
		var axis_value := Input.get_joy_axis(int(device_id), JOY_AXIS_RIGHT_Y)
		if absf(axis_value) > absf(strongest):
			strongest = axis_value
	return strongest


static func _find_best_visible_scroll_container(root: Node) -> ScrollContainer:
	var focus_owner := root.get_viewport().gui_get_focus_owner() if root.get_viewport() != null else null
	var focused_scroll := _find_scroll_container_ancestor(focus_owner, root)
	if _is_scrollable(focused_scroll):
		return focused_scroll

	var candidates := _collect_visible_scroll_containers(root)
	for candidate in candidates:
		if _is_scrollable(candidate):
			return candidate
	return null


static func _find_scroll_container_ancestor(node: Node, root: Node) -> ScrollContainer:
	var current := node
	while current != null:
		if current is ScrollContainer:
			return current as ScrollContainer
		if current == root:
			break
		current = current.get_parent()
	return null


static func _collect_visible_scroll_containers(root: Node) -> Array[ScrollContainer]:
	var result: Array[ScrollContainer] = []
	if root is ScrollContainer and _is_effectively_visible(root as CanvasItem):
		result.append(root as ScrollContainer)
	for child in root.get_children():
		result.append_array(_collect_visible_scroll_containers(child))
	return result


static func _is_scrollable(scroll_container: ScrollContainer) -> bool:
	if scroll_container == null or not _is_effectively_visible(scroll_container):
		return false
	var bar := scroll_container.get_v_scroll_bar()
	return bar != null and bar.max_value > bar.page


static func _is_effectively_visible(item: CanvasItem) -> bool:
	return item != null and item.is_visible_in_tree()

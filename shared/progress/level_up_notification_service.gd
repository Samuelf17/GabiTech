extends Node

const LEVEL_UP_POPUP = preload("res://shared/ui/level_up_popup.gd")

var progression: Node
var last_seen_level: int = 1
var pending_level_changes: Array = []
var active_popup: CanvasLayer
var active_activity_scene: Node
var completion_scene: Node


func _ready() -> void:
	progression = get_node_or_null("/root/Progression")
	if progression == null:
		return
	var current_state: Dictionary = progression.call("get_state")
	last_seen_level = int(current_state.get("level", 1))
	progression.connect("progress_changed", self, "_on_progress_changed")


func _on_progress_changed(current_state: Dictionary) -> void:
	var current_level: int = int(current_state.get("level", last_seen_level))
	if current_level > last_seen_level:
		for reached_level in range(last_seen_level + 1, current_level + 1):
			pending_level_changes.append({
				"previous_level": reached_level - 1,
				"reached_level": reached_level
			})
	last_seen_level = current_level
	call_deferred("_show_next_level_change")


func begin_activity(scene: Node) -> void:
	active_activity_scene = scene
	completion_scene = null


func mark_completion_visible(scene: Node) -> void:
	if scene == null or scene != active_activity_scene:
		return
	completion_scene = scene
	call_deferred("_show_next_level_change")


func _show_next_level_change() -> void:
	if active_popup != null or pending_level_changes.empty() or progression == null:
		return
	if not _is_active_completion_visible():
		return
	if not progression.call("get_pending_badge_notifications").empty():
		return
	var level_change: Dictionary = pending_level_changes.pop_front()
	active_popup = LEVEL_UP_POPUP.new()
	active_popup.connect("dismissed", self, "_on_level_popup_dismissed")
	add_child(active_popup)
	if not active_popup.present(int(level_change["previous_level"]), int(level_change["reached_level"])):
		active_popup.queue_free()
		active_popup = null
		call_deferred("_show_next_level_change")


func _is_active_completion_visible() -> bool:
	if completion_scene == null or not is_instance_valid(completion_scene):
		return false
	return get_tree().current_scene == completion_scene


func _on_level_popup_dismissed() -> void:
	if active_popup != null:
		active_popup.queue_free()
		active_popup = null
	call_deferred("_show_next_level_change")

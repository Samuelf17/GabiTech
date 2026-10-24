extends SceneTree

const NAVIGATION_HISTORY = preload("res://shared/navigation/navigation_history.gd")

var failures: Array = []


func _initialize() -> void:
	var navigation = NAVIGATION_HISTORY.new()
	navigation.remember_previous_scene("res://app/menus/home_screen.tscn")
	navigation.remember_previous_scene("res://app/menus/map_screen.tscn")
	_check(navigation.take_previous_scene() == "res://app/menus/map_screen.tscn", "back returns to the most recently visited screen")
	_check(navigation.take_previous_scene() == "res://app/menus/home_screen.tscn", "back preserves earlier navigation history")
	_check(navigation.take_previous_scene().empty(), "empty navigation history is reported")
	navigation.remember_previous_scene("res://app/menus/home_screen.tscn")
	navigation.remember_previous_scene("res://app/menus/home_screen.tscn")
	_check(navigation.previous_scene_paths.size() == 1, "consecutive duplicate history entries are ignored")
	navigation.free()
	if failures.empty():
		print("Navigation history tests passed")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)

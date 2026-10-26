extends SceneTree

const MAP_SCENE = preload("res://app/menus/map_screen.tscn")
const MAP_SCRIPT = preload("res://app/menus/map_screen.gd")
const DATA_PROTECTION_SCENE_PATH = "res://games/data_protection/scenes/data_protection_screen.tscn"

var failures: Array = []


func _initialize() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	_check(MAP_SCRIPT.DISTRICTS[2].get("scene", "") == DATA_PROTECTION_SCENE_PATH, "Security district points to the data protection minigame")
	_check(ResourceLoader.exists(DATA_PROTECTION_SCENE_PATH), "data protection scene exists")
	var map_screen = MAP_SCENE.instance()
	get_root().add_child(map_screen)
	yield(self, "idle_frame")
	map_screen._activate_district(2)
	yield(self, "idle_frame")
	var launched_scene: Node = get_current_scene()
	_check(launched_scene != null and launched_scene.filename == DATA_PROTECTION_SCENE_PATH, "activating Security opens the data protection minigame")
	if launched_scene != null and launched_scene.has_method("get"):
		_check(launched_scene.phase == "ready", "opening Security does not start the game before a movement command")
		_check(launched_scene.intro_popup, "opening Security starts with the intro awaiting the player")
	if failures.empty():
		print("Security district tests passed")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)

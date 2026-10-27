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
	var navigation = get_root().get_node("NavigationHistory")
	_check(navigation.last_transition_type == "fade", "Security opens with the fade scene transition")
	_check(not navigation.transition_overlay.visible, "map remains interactive during the launch delay")
	yield(create_timer(1.2), "timeout")
	var launched_scene: Node = get_current_scene()
	_check(launched_scene != null and launched_scene.filename == DATA_PROTECTION_SCENE_PATH, "activating Security opens the data protection minigame")
	_check(not navigation.transition_in_progress and not navigation.transition_overlay.visible and navigation.transition_overlay.mouse_filter == Control.MOUSE_FILTER_IGNORE, "opening the game releases the transition overlay without blocking input")
	if launched_scene != null and launched_scene.has_method("get"):
		_check(launched_scene.phase == "ready", "opening Security does not start the game before a movement command")
		_check(launched_scene.intro_popup, "opening Security starts with the intro awaiting the player")
		launched_scene._on_intro_close_pressed()
		_check(not launched_scene.intro_popup and not launched_scene.ui["modal_backdrop"].visible, "data protection tutorial closes after the map transition")
		launched_scene._finish_round(false)
		_check(launched_scene.ui["map"].visible, "data-protection result exposes the return-to-map button")
		launched_scene.ui["map"].emit_signal("pressed")
		yield(create_timer(0.5), "timeout")
		var returned_map: Node = get_current_scene()
		_check(returned_map != null and returned_map.filename == "res://app/menus/map_screen.tscn", "data-protection result button returns to the map")
		if returned_map != null:
			returned_map._activate_district(2)
			yield(create_timer(1.2), "timeout")
			var second_game: Node = get_current_scene()
			_check(second_game != null and second_game.filename == DATA_PROTECTION_SCENE_PATH, "Security can be reopened from the returned map")
			if second_game != null:
				_check(not navigation.transition_in_progress, "reopening Security completes its transition before user input")
				second_game.ui["back"].emit_signal("pressed")
				yield(create_timer(0.5), "timeout")
				var back_button_map: Node = get_current_scene()
				_check(back_button_map != null and back_button_map.filename == "res://app/menus/map_screen.tscn", "data-protection back button returns to the map")
				if back_button_map != null:
					back_button_map._activate_district(2)
					yield(create_timer(1.2), "timeout")
					var third_game: Node = get_current_scene()
					if third_game != null:
							_navigation_back(navigation)
							yield(create_timer(0.5), "timeout")
							var system_back_map: Node = get_current_scene()
							_check(system_back_map != null and system_back_map.filename == "res://app/menus/map_screen.tscn", "system back request from data protection returns to the map")
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


func _navigation_back(navigation: Node) -> void:
	navigation.go_back()

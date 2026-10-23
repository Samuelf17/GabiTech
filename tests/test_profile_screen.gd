extends SceneTree

const PROFILE_SCREEN = preload("res://app/menus/profile_screen.tscn")
const PROFILE_SCREEN_SCRIPT = preload("res://app/menus/profile_screen.gd")
const BOTTOM_NAVIGATION_SCRIPT = preload("res://shared/ui/bottom_navigation.gd")
const SHIELD_ICON = preload("res://shared/ui/assets/icons/shield_icon.svg")

var failures: Array = []


func _initialize() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	var screen = PROFILE_SCREEN.instance()
	get_root().add_child(screen)
	yield(self, "idle_frame")
	for viewport_size in [Vector2(720, 1280), Vector2(1280, 720), Vector2(960, 540), Vector2(360, 800), Vector2(320, 568)]:
		_test_layout(screen, viewport_size)
	_test_progress_values(screen)
	_test_tabs(screen)
	if failures.empty():
		print("Profile screen tests passed")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func _test_layout(screen, viewport_size: Vector2) -> void:
	screen.anchor_right = 0.0
	screen.anchor_bottom = 0.0
	screen.rect_size = viewport_size
	screen._layout_screen(viewport_size)
	var navigation = screen.ui["navigation"]
	_check(navigation.active_item == "profile", "Profile is the active menu item at %s" % viewport_size)
	for index in range(BOTTOM_NAVIGATION_SCRIPT.ITEM_IDS.size()):
		var item_id: String = BOTTOM_NAVIGATION_SCRIPT.ITEM_IDS[index]
		_check(navigation.labels[item_id].text == BOTTOM_NAVIGATION_SCRIPT.ITEM_LABELS[index], "%s label is present at %s" % [item_id, viewport_size])
		_check(navigation.icons[item_id].texture != null, "%s icon loads at %s" % [item_id, viewport_size])
		_check(_fits_viewport(navigation.buttons[item_id], viewport_size), "%s navigation control fits at %s" % [item_id, viewport_size])
	for key in ["header", "hero_panel", "hero_shield", "points_label", "points", "support", "level_panel", "level_caption", "xp_value", "xp_track", "tabs_panel", "challenge_panel", "challenge_title", "challenge_text", "challenge_count", "challenge_track", "status"]:
		_check(_fits_viewport(screen.ui[key], viewport_size), "%s stays inside the viewport at %s" % [key, viewport_size])
	_check(screen.ui["hero_shield"].texture == SHIELD_ICON, "guardian emblem uses the temporary shield asset")
	_check(screen.badge_controls.size() == 6, "six reward badges are displayed")
	for index in range(screen.badge_controls.size()):
		var badge: Dictionary = screen.badge_controls[index]
		_check(badge["icon"].texture == SHIELD_ICON, "%s uses the temporary shield icon" % PROFILE_SCREEN_SCRIPT.BADGES[index]["name"])
		_check(_fits_viewport(badge["icon"], viewport_size), "%s badge icon stays inside the viewport at %s" % [PROFILE_SCREEN_SCRIPT.BADGES[index]["name"], viewport_size])
		_check(_fits_viewport(badge["name"], viewport_size), "%s badge name stays inside the viewport at %s" % [PROFILE_SCREEN_SCRIPT.BADGES[index]["name"], viewport_size])
	for tab_name in ["DISTINTIVOS", "CONQUISTAS", "COLEÇÃO"]:
		_check(screen.ui["tabs"][tab_name].focus_mode == Control.FOCUS_ALL, "%s tab supports focus navigation" % tab_name)
		_check(_fits_viewport(screen.ui["tabs"][tab_name], viewport_size), "%s tab stays inside the viewport at %s" % [tab_name, viewport_size])


func _test_tabs(screen) -> void:
	screen._on_tab_pressed("CONQUISTAS")
	_check(screen.ui["status"].text == "A aba Conquistas estará disponível em breve.", "unimplemented reward tabs give feedback")
	screen._on_tab_pressed("DISTINTIVOS")
	_check(screen.ui["status"].text.empty(), "badge tab clears temporary feedback")
	_check(screen.selected_tab == "DISTINTIVOS", "badge tab remains selected")
	screen._on_nav_pressed("missions")
	_check(screen.ui["status"].text == "A tela de Missões estará disponível em breve.", "Missions menu gives temporary feedback")


func _test_progress_values(screen) -> void:
	var progress: Dictionary = Progression.get_state()
	var total_xp: int = Progression.get_total_experience()
	var item_count: int = progress["unlocked_items"].size()
	_check(screen.ui["points"].text == Progression.format_number(total_xp), "profile total experience comes from saved progress")
	_check(screen.ui["support"].text == "Itens desbloqueados: %d" % item_count, "profile item count comes from saved progress")
	_check(screen.ui["level_caption"].text == "NÍVEL %d" % progress["level"], "profile level comes from saved progress")
	_check(screen.ui["xp_value"].text == "%s / %s XP" % [Progression.format_number(progress["experience"]), Progression.format_number(Progression.experience_per_level)], "profile XP comes from saved progress")
	var original_path: String = Progression.storage_path
	var test_path: String = "user://profile_progress_test.json"
	_remove_progress_test_file(test_path)
	Progression.storage_path = test_path
	Progression.load_progress()
	Progression.add_experience(2000)
	_check(screen.ui["level_caption"].text == "NÍVEL 2", "profile level updates after a level-up signal")
	_check(screen.ui["points"].text == "2.000", "profile total experience updates after a level-up signal")
	_check(screen.ui["support"].text == "Itens desbloqueados: 1", "profile reward count updates after a level-up signal")
	Progression.storage_path = original_path
	Progression.load_progress()
	_remove_progress_test_file(test_path)


func _remove_progress_test_file(path: String) -> void:
	var file := File.new()
	if file.file_exists(path):
		var directory := Directory.new()
		directory.remove(path)


func _fits_viewport(control: Control, viewport_size: Vector2) -> bool:
	var rect: Rect2 = control.get_global_rect()
	return rect.position.x >= -1.0 and rect.position.y >= -1.0 and rect.end.x <= viewport_size.x + 1.0 and rect.end.y <= viewport_size.y + 1.0


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)

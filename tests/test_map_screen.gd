extends SceneTree

const MAP_SCREEN = preload("res://app/menus/map_screen.tscn")
const MAP_SCREEN_SCRIPT = preload("res://app/menus/map_screen.gd")
const BOTTOM_NAVIGATION_SCRIPT = preload("res://shared/ui/bottom_navigation.gd")

var failures: Array = []


func _initialize() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	var screen = MAP_SCREEN.instance()
	get_root().add_child(screen)
	yield(self, "idle_frame")
	for viewport_size in [Vector2(720, 1280), Vector2(1280, 720), Vector2(960, 540), Vector2(360, 800), Vector2(320, 568)]:
		_test_layout(screen, viewport_size)
	_test_district_selection(screen)
	_test_navigation(screen)
	if failures.empty():
		print("Map screen tests passed")
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
	_check(screen.ui["background"].texture != null, "map illustration loads at %s" % viewport_size)
	_check(screen.ui["background"].stretch_mode == TextureRect.STRETCH_KEEP_ASPECT_COVERED, "map art fills its background area at %s" % viewport_size)
	_check(screen.ui["prompt"].text == "Escolha um bairro para aceitar a missão!", "mission prompt stays present at %s" % viewport_size)
	_check(screen.ui["areas"].focus_mode == Control.FOCUS_ALL, "district layer supports keyboard/controller focus at %s" % viewport_size)
	var navigation = screen.ui["navigation"]
	navigation.layout_for_viewport(viewport_size)
	_check(navigation.active_item == "map", "map is the active menu item at %s" % viewport_size)
	for index in range(BOTTOM_NAVIGATION_SCRIPT.ITEM_IDS.size()):
		var item_id: String = BOTTOM_NAVIGATION_SCRIPT.ITEM_IDS[index]
		var button: Button = navigation.buttons[item_id]
		_check(button.text.ends_with(BOTTOM_NAVIGATION_SCRIPT.ITEM_LABELS[index]), "%s appears in the bottom menu at %s" % [item_id, viewport_size])
		_check(button.get_meta("font_role") == "navigation", "%s uses shared menu typography at %s" % [item_id, viewport_size])
		_check(button.focus_mode == Control.FOCUS_ALL, "%s remains focusable at %s" % [item_id, viewport_size])
		_check(_fits_viewport(button, viewport_size), "%s stays inside the viewport at %s" % [item_id, viewport_size])
	for district in MAP_SCREEN_SCRIPT.DISTRICTS:
		_check(screen.ui[district["id"] + "_title"].visible, "%s title is visible at %s" % [district["id"], viewport_size])
		_check(screen.ui[district["id"] + "_progress"].visible, "%s progress is visible at %s" % [district["id"], viewport_size])


func _test_district_selection(screen) -> void:
	for viewport_size in [Vector2(720, 1280), Vector2(1280, 720)]:
		screen._layout_screen(viewport_size)
		for index in range(MAP_SCREEN_SCRIPT.DISTRICTS.size()):
			var center: Vector2
			if viewport_size.x > viewport_size.y:
				var centers := [Vector2(0.18, 0.40), Vector2(0.50, 0.40), Vector2(0.82, 0.40), Vector2(0.34, 0.73), Vector2(0.67, 0.73)]
				center = Vector2(centers[index].x * viewport_size.x, centers[index].y * viewport_size.y)
			else:
				var normalized_center: Vector2 = MAP_SCREEN_SCRIPT.DISTRICTS[index]["center"]
				center = Vector2(normalized_center.x * viewport_size.x, normalized_center.y * viewport_size.y)
			_check(screen._district_at_point(center) == index, "district %s is independently interactive at %s" % [MAP_SCREEN_SCRIPT.DISTRICTS[index]["id"], viewport_size])
			screen._select_district(index)
			_check(screen.selected_district == index, "district selection state updates")


func _test_navigation(screen) -> void:
	screen._on_nav_pressed("missions")
	_check(screen.ui["status"].text == "Escolha um bairro para aceitar a missão!", "Missions menu preserves the prompt")
	screen._on_nav_pressed("profile")
	_check(screen.ui["status"].text.find("Perfil") >= 0, "Profile menu gives feedback")


func _fits_viewport(control: Control, viewport_size: Vector2) -> bool:
	var rect: Rect2 = control.get_global_rect()
	return rect.position.x >= -1.0 and rect.position.y >= -1.0 and rect.end.x <= viewport_size.x + 1.0 and rect.end.y <= viewport_size.y + 1.0


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)

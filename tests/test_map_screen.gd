extends SceneTree

const MAP_SCREEN = preload("res://app/menus/map_screen.tscn")
const MAP_SCREEN_SCRIPT = preload("res://app/menus/map_screen.gd")

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
	for title in ["Inicio", "Mapa", "Missões", "Perfil"]:
		var found: bool = false
		for index in range(4):
			if screen.ui["nav_" + str(index)].text.ends_with(title):
				found = true
		_check(found, "%s appears in the bottom navigation at %s" % [title, viewport_size])
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
	screen._on_nav_pressed("Missões", "")
	_check(screen.ui["status"].text == "Escolha um bairro para aceitar a missão!", "Missions menu preserves the prompt")
	screen._on_nav_pressed("Perfil", "")
	_check(screen.ui["status"].text.find("Perfil") >= 0, "Profile menu gives feedback")


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)

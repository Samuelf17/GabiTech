extends SceneTree

const MAP_SCREEN = preload("res://app/menus/map_screen.tscn")
const MAP_SCREEN_SCRIPT = preload("res://app/menus/map_screen.gd")
const BOTTOM_NAVIGATION_SCRIPT = preload("res://shared/ui/bottom_navigation.gd")
const PORTRAIT_MAP_BACKGROUND = preload("res://shared/map/assets/mapa.png")
const LANDSCAPE_MAP_BACKGROUND = preload("res://shared/map/assets/mapa_horizontal.png")

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
	var expected_background = LANDSCAPE_MAP_BACKGROUND if viewport_size.x > viewport_size.y else PORTRAIT_MAP_BACKGROUND
	_check(screen.ui["background"].texture == expected_background, "map illustration matches viewport orientation at %s" % viewport_size)
	_check(screen.ui["background"].stretch_mode == TextureRect.STRETCH_KEEP_ASPECT_COVERED, "map art fills its background area at %s" % viewport_size)
	_check(screen.ui["prompt"].text == "Escolha um bairro para aceitar a missão!", "mission prompt stays present at %s" % viewport_size)
	_check(screen.ui["areas"].focus_mode == Control.FOCUS_ALL, "district layer supports keyboard/controller focus at %s" % viewport_size)
	var navigation = screen.ui["navigation"]
	navigation.layout_for_viewport(viewport_size)
	_check(navigation.active_item == "map", "map is the active menu item at %s" % viewport_size)
	for index in range(BOTTOM_NAVIGATION_SCRIPT.ITEM_IDS.size()):
		var item_id: String = BOTTOM_NAVIGATION_SCRIPT.ITEM_IDS[index]
		var button: Button = navigation.buttons[item_id]
		_check(navigation.labels[item_id].text == BOTTOM_NAVIGATION_SCRIPT.ITEM_LABELS[index], "%s appears in the bottom menu at %s" % [item_id, viewport_size])
		_check(navigation.icons[item_id].texture != null, "%s icon loads in the bottom menu at %s" % [item_id, viewport_size])
		_check(button.get_meta("font_role") == "navigation", "%s uses shared menu typography at %s" % [item_id, viewport_size])
		_check(button.focus_mode == Control.FOCUS_ALL, "%s remains focusable at %s" % [item_id, viewport_size])
		_check(_fits_viewport(button, viewport_size), "%s stays inside the viewport at %s" % [item_id, viewport_size])
	for district in MAP_SCREEN_SCRIPT.DISTRICTS:
		_check(screen.ui[district["id"] + "_title"].visible, "%s title is visible at %s" % [district["id"], viewport_size])
		_check(screen.ui[district["id"] + "_progress"].visible, "%s progress is visible at %s" % [district["id"], viewport_size])
	for district_id in ["privacy", "communication", "security", "respect"]:
		var icon: TextureRect = screen.ui[district_id + "_icon"]
		_check(icon.texture != null and icon.visible, "%s district icon loads and is visible at %s" % [district_id, viewport_size])
		_check(_fits_viewport(icon, viewport_size), "%s district icon stays inside the viewport at %s" % [district_id, viewport_size])
	var regions: Array = screen._district_layout(viewport_size, viewport_size.x > viewport_size.y)
	for index in range(regions.size()):
		var polygon: Array = regions[index]["points"]
		_check(polygon.size() == 8, "%s uses an eight-point octagon at %s" % [MAP_SCREEN_SCRIPT.DISTRICTS[index]["id"], viewport_size])
		_check(regions[index]["size"].x > 0.0 and regions[index]["size"].y > 0.0, "%s octagon dimensions adapt to the viewport" % MAP_SCREEN_SCRIPT.DISTRICTS[index]["id"])
		var center: Vector2 = regions[index]["center"]
		_check(polygon[0].x < center.x and polygon[0].y < center.y, "octagon has an upper-left vertex at %s" % viewport_size)
		_check(is_equal_approx(polygon[0].y, polygon[1].y) and polygon[1].x > center.x, "octagon has a flat upper edge at %s" % viewport_size)
		_check(is_equal_approx(polygon[2].x, polygon[3].x) and polygon[2].x > center.x, "octagon has a flat right edge at %s" % viewport_size)
		for point in polygon:
			_check(point.x >= 0.0 and point.x <= 1.0 and point.y >= 0.0 and point.y <= 1.0, "octagon stays inside the viewport at %s" % viewport_size)


func _test_district_selection(screen) -> void:
	var large_portrait: Array = screen._district_layout(Vector2(720, 1280), false)
	var compact_portrait: Array = screen._district_layout(Vector2(360, 800), false)
	_check(large_portrait[0]["size"].x > compact_portrait[0]["size"].x, "portrait district width scales with viewport width")
	_check(large_portrait[0]["size"].y > compact_portrait[0]["size"].y, "portrait district height scales with viewport height")
	_check(is_equal_approx(large_portrait[0]["size"].y, min(1280.0 * 0.19, 720.0 * 0.42) * 1.10), "portrait district height is 10% larger than the previous scale")
	var large_landscape: Array = screen._district_layout(Vector2(1280, 720), true)
	var compact_landscape: Array = screen._district_layout(Vector2(960, 540), true)
	_check(is_equal_approx(large_landscape[3]["center"].x, 0.20), "Knowledge district moves toward the left edge in landscape")
	_check(is_equal_approx(large_landscape[4]["center"].x, 0.80), "Respect district moves toward the right edge in landscape")
	_check(large_landscape[0]["size"].x > compact_landscape[0]["size"].x, "landscape district width scales with viewport width")
	_check(large_landscape[0]["size"].y > compact_landscape[0]["size"].y, "landscape district height scales with viewport height")
	_check(is_equal_approx(large_landscape[0]["size"].y, min(720.0 * 0.27, 720.0 * 0.36) * 1.10), "landscape district height is 10% larger than the previous scale")
	for viewport_size in [Vector2(720, 1280), Vector2(1280, 720), Vector2(960, 540), Vector2(360, 800), Vector2(320, 568)]:
		screen._layout_screen(viewport_size)
		var regions: Array = screen._district_layout(viewport_size, viewport_size.x > viewport_size.y)
		for index in range(MAP_SCREEN_SCRIPT.DISTRICTS.size()):
			var normalized_center: Vector2 = regions[index]["center"]
			var center := Vector2(normalized_center.x * viewport_size.x, normalized_center.y * viewport_size.y)
			_check(screen._district_at_point(center) == index, "district %s is independently interactive at %s" % [MAP_SCREEN_SCRIPT.DISTRICTS[index]["id"], viewport_size])
			screen._select_district(index)
			_check(screen.selected_district == index, "district selection state updates")


func _test_navigation(screen) -> void:
	screen._on_nav_pressed("missions")
	_check(screen.ui["status"].text == "A tela de Missões estará disponível em breve.", "Missions menu does not route to the map content")


func _fits_viewport(control: Control, viewport_size: Vector2) -> bool:
	var rect: Rect2 = control.get_global_rect()
	return rect.position.x >= -1.0 and rect.position.y >= -1.0 and rect.end.x <= viewport_size.x + 1.0 and rect.end.y <= viewport_size.y + 1.0


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)

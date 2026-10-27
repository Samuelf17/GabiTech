extends SceneTree

const MAP_SCREEN = preload("res://app/menus/map_screen.tscn")
const MAP_SCREEN_SCRIPT = preload("res://app/menus/map_screen.gd")
const BOTTOM_NAVIGATION_SCRIPT = preload("res://shared/ui/bottom_navigation.gd")
const TYPOGRAPHY_SCRIPT = preload("res://shared/ui/typography.gd")
const TYPOGRAPHY_TEST_UTILS = preload("res://tests/typography_test_utils.gd")
const PORTRAIT_MAP_BACKGROUND_PATH = "res://shared/map/assets/mapa.png"
const LANDSCAPE_MAP_BACKGROUND_PATH = "res://shared/map/assets/mapa_horizontal.png"
const QUIZ_SCENE_PATH = "res://games/quiz/scenes/quiz_screen.tscn"
const HOME_SCENE_PATH = "res://app/menus/home_screen.tscn"

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
	yield(_test_navigation(screen), "completed")
	yield(self, "idle_frame")
	var launched_scene: Node = get_current_scene()
	_check(launched_scene != null and launched_scene.filename == "res://games/anti_bullying/scenes/anti_bullying_screen.tscn", "activating Respect opens the anti-bullying minigame")
	var navigation = get_root().get_node("NavigationHistory")
	launched_scene._show_completion()
	_check(launched_scene.ui["return_to_map"].visible, "anti-bullying result shows the map return button")
	launched_scene.ui["return_to_map"].emit_signal("pressed")
	yield(create_timer(0.5), "timeout")
	_check(get_current_scene() != null and get_current_scene().filename == "res://app/menus/map_screen.tscn", "anti-bullying result button returns to the map")
	navigation.call("navigate_to", HOME_SCENE_PATH)
	yield(self, "idle_frame")
	_check(navigation.last_transition_type == "fade", "normal screen navigation selects the fade transition")
	yield(create_timer(0.45), "timeout")
	_check(not navigation.transition_in_progress and get_current_scene().filename == HOME_SCENE_PATH, "fade transition completes after changing screens")
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
	var typography_failures: Array = TYPOGRAPHY_TEST_UTILS.get_uniform_body_size_failures(screen, screen.typography, min(viewport_size.x, viewport_size.y))
	for typography_failure in typography_failures:
		_check(false, "%s at %s" % [typography_failure, viewport_size])
	_check(screen.ui["background"].texture != null, "map illustration loads at %s" % viewport_size)
	var expected_background_path: String = LANDSCAPE_MAP_BACKGROUND_PATH if viewport_size.x > viewport_size.y else PORTRAIT_MAP_BACKGROUND_PATH
	_check(screen.active_background_path == expected_background_path, "map illustration matches viewport orientation at %s" % viewport_size)
	_check(screen.active_background_path == expected_background_path, "only the active orientation is tracked at %s" % viewport_size)
	var inactive_background_path: String = PORTRAIT_MAP_BACKGROUND_PATH if viewport_size.x > viewport_size.y else LANDSCAPE_MAP_BACKGROUND_PATH
	_check(not ResourceLoader.has_cached(inactive_background_path), "inactive orientation texture is not cached at %s" % viewport_size)
	var expected_dimensions: Vector2 = Vector2(1672, 941) if viewport_size.x > viewport_size.y else Vector2(1024, 1536)
	_check(Vector2(screen.ui["background"].texture.get_width(), screen.ui["background"].texture.get_height()) == expected_dimensions, "map compression keeps source resolution at %s" % viewport_size)
	_check(screen.ui["background"].stretch_mode == TextureRect.STRETCH_KEEP_ASPECT_COVERED, "map art fills its background area at %s" % viewport_size)
	var header_rect: Rect2 = screen.ui["header_panel"].get_global_rect()
	var prompt_rect: Rect2 = screen.ui["prompt_panel"].get_global_rect()
	_check(is_equal_approx(header_rect.position.y, viewport_size.y * 0.05), "map title panel keeps a five percent top margin at %s" % viewport_size)
	_check(header_rect.end.y <= prompt_rect.position.y, "map title and prompt panels do not overlap at %s" % viewport_size)
	_check(screen.ui["prompt"].text == "Escolha um bairro para aceitar a missão!", "mission prompt stays present at %s" % viewport_size)
	var typography = TYPOGRAPHY_SCRIPT.new()
	_check(is_equal_approx(typography.get_role_ratio("body"), TYPOGRAPHY_SCRIPT.BASE_BODY_RATIO * TYPOGRAPHY_SCRIPT.BODY_SCALE_ADJUSTMENT), "map typography uses the adjusted shared greeting text base")
	_check(is_equal_approx(typography.get_role_ratio("prompt"), typography.get_role_ratio("body")), "map prompt matches the greeting body size")
	_check(is_equal_approx(typography.get_role_ratio("district"), typography.get_role_ratio("body")), "district names match the greeting body size")
	_check(typography.has_role(screen.ui["screen_title"].get_meta("font_role")), "map title uses the shared typography scale")
	_check(typography.has_role(screen.ui["prompt"].get_meta("font_role")), "map prompt uses the shared typography scale")
	_check(typography.has_role(screen.ui["status"].get_meta("font_role")), "map status uses the shared typography scale")
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
		_check(not screen.ui.has(district["id"] + "_progress"), "%s has no mission-count label at %s" % [district["id"], viewport_size])
		_check(typography.has_role(screen.ui[district["id"] + "_title"].get_meta("font_role")), "%s title uses shared typography" % district["id"])
		if not district.has("scene"):
			var coming_soon: Control = screen.ui[district["id"] + "_coming_soon"]
			_check(coming_soon.visible and coming_soon.text == "Em Breve", "%s shows its coming-soon message at %s" % [district["id"], viewport_size])
			_check(_fits_viewport(coming_soon, viewport_size), "%s coming-soon message fits at %s" % [district["id"], viewport_size])
			var gray_color: Color = screen._district_display_color(district)
			_check(is_equal_approx(gray_color.r, gray_color.g) and is_equal_approx(gray_color.g, gray_color.b), "%s district artwork is desaturated" % district["id"])
			_check(screen.ui[district["id"] + "_title"].get_color("font_color") == MAP_SCREEN_SCRIPT.UNAVAILABLE_TEXT_COLOR, "%s title is muted while unavailable" % district["id"])
		else:
			_check(not screen.ui.has(district["id"] + "_coming_soon"), "%s has no coming-soon message" % district["id"])
	var title: Control = screen.ui["screen_title"]
	screen._place(title, 0.0, 0.0, 10000.0, 10000.0, 720.0)
	_check(abs(title.get_font("font").get_height() - typography.get_target_height(title.get_meta("font_role"), 720.0) * 1.10) <= 1.0, "map screen title is enlarged by ten percent")
	for district_id in ["privacy", "communication", "security", "respect"]:
		var icon: TextureRect = screen.ui[district_id + "_icon"]
		_check(icon.texture != null and icon.visible, "%s district icon loads and is visible at %s" % [district_id, viewport_size])
		_check(_fits_viewport(icon, viewport_size), "%s district icon stays inside the viewport at %s" % [district_id, viewport_size])
		if district_id == "privacy" or district_id == "communication":
			_check(icon.modulate == MAP_SCREEN_SCRIPT.UNAVAILABLE_DISTRICT_COLOR, "%s icon is desaturated" % district_id)
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
	_check(screen.district_tap_player.stream.resource_path == "res://shared/audio/assets/map_tap.wav", "map selection uses the copied WAV audio asset")
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
			_check(screen.district_tap_player.is_playing(), "selecting %s plays the district tap sound" % MAP_SCREEN_SCRIPT.DISTRICTS[index]["id"])
	for unavailable_id in ["privacy", "communication", "knowledge"]:
		var unavailable_index: int = -1
		for index in range(MAP_SCREEN_SCRIPT.DISTRICTS.size()):
			if MAP_SCREEN_SCRIPT.DISTRICTS[index]["id"] == unavailable_id:
				unavailable_index = index
				break
		screen._activate_district(unavailable_index)
		_check(screen.ui["status"].text == "Em Breve", "%s activation shows the coming-soon status" % unavailable_id)


func _test_navigation(screen):
	_check(ResourceLoader.exists(QUIZ_SCENE_PATH), "Missions destination scene exists")
	_check(ResourceLoader.exists(MAP_SCREEN_SCRIPT.DISTRICTS[2].get("scene", "")), "Security district destination scene exists")
	_check(ResourceLoader.exists(MAP_SCREEN_SCRIPT.DISTRICTS[4].get("scene", "")), "Respect district destination scene exists")
	screen._activate_district(4)
	yield(self, "idle_frame")
	var navigation = get_root().get_node("NavigationHistory")
	_check(navigation.last_transition_type == "fade", "opening a district minigame selects the fade transition")
	_check(navigation.transition_in_progress, "fade transition remains active while the new game enters")
	_check(not navigation.transition_overlay.visible, "map stays visible during the half-second launch delay")
	yield(create_timer(0.55), "timeout")
	_check(navigation.transition_overlay.visible, "fade transition begins after the map launch delay")
	yield(create_timer(0.65), "timeout")
	_check(not navigation.transition_in_progress, "fade transition finishes after entering the game")
	_check(not navigation.transition_overlay.visible and navigation.transition_overlay.mouse_filter == Control.MOUSE_FILTER_IGNORE, "transition overlay is hidden and ignores game input")
	var incoming_scene: Control = get_current_scene() as Control
	_check(is_equal_approx(incoming_scene.rect_scale.x, 1.0) and is_equal_approx(incoming_scene.modulate.a, 1.0), "game scene keeps its normal size and opacity after fade")
	_check(incoming_scene.phase == "intro", "anti-bullying intro is ready for user input after scene transition")
	incoming_scene._on_intro_close_pressed()
	_check(incoming_scene.phase == "choosing" and not incoming_scene.ui["intro_backdrop"].visible, "anti-bullying game accepts tutorial close input after map launch")
	_check(incoming_scene.answer_buttons[0].visible, "anti-bullying choices become interactive after closing the tutorial")


func _fits_viewport(control: Control, viewport_size: Vector2) -> bool:
	var position: Vector2 = control.rect_position
	var size: Vector2 = control.rect_size * control.rect_scale
	var parent = control.get_parent()
	while parent is Control:
		position = parent.rect_position + position * parent.rect_scale
		size *= parent.rect_scale
		parent = parent.get_parent()
	return position.x >= -1.0 and position.y >= -1.0 and position.x + size.x <= viewport_size.x + 1.0 and position.y + size.y <= viewport_size.y + 1.0


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)

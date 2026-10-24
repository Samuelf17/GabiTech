extends SceneTree

const HOME_SCREEN = preload("res://app/menus/home_screen.tscn")
const BOTTOM_NAVIGATION_SCRIPT = preload("res://shared/ui/bottom_navigation.gd")
const TYPOGRAPHY_SCRIPT = preload("res://shared/ui/typography.gd")
const QUIZ_SCENE_PATH = "res://games/quiz/scenes/quiz_screen.tscn"

const PROGRESSION_SCRIPT = preload("res://shared/progress/progression_service.gd")

var progression: Node
var failures: Array = []


func _initialize() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	_setup_progression()
	var screen = HOME_SCREEN.instance()
	get_root().add_child(screen)
	yield(self, "idle_frame")

	_test_layout(screen, Vector2(720, 1280), "portrait")
	_test_layout(screen, Vector2(1280, 720), "landscape")
	_test_layout(screen, Vector2(960, 540), "compact landscape")
	_test_layout(screen, Vector2(360, 800), "narrow portrait")
	_test_layout(screen, Vector2(320, 568), "compact portrait")
	_test_progress_values(screen)
	_test_adaptive_font_sizes(screen)
	_test_landscape_greeting_hierarchy(screen)
	_test_landscape_action_and_level_alignment(screen)
	_test_text_fits_controls(screen)
	_test_action_feedback(screen)

	if failures.empty():
		print("Home screen tests passed")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func _test_layout(screen, viewport_size: Vector2, layout_name: String) -> void:
	screen.anchor_right = 0.0
	screen.anchor_bottom = 0.0
	screen.rect_size = viewport_size
	screen._layout_screen(viewport_size)

	for key in ["start", "greeting_panel", "progress_panel", "level_ring", "mascot"]:
		var control: Control = screen.ui[key]
		_check(control.visible, "%s: %s is visible" % [layout_name, key])
		_check(control.rect_size.x > 0.0 and control.rect_size.y > 0.0, "%s: %s has positive size" % [layout_name, key])
		_check(_fits_viewport(control, viewport_size), "%s: %s stays inside the viewport" % [layout_name, key])

	var mascot: TextureRect = screen.ui["mascot"]
	_check(mascot.texture != null, "%s: mascot sprite texture is loaded" % layout_name)
	_check(mascot.stretch_mode == TextureRect.STRETCH_KEEP_ASPECT_CENTERED, "%s: mascot sprite preserves its aspect ratio" % layout_name)

	var start_button: Button = screen.ui["start"]
	_check(not start_button.text.empty(), "%s: mission button text is present" % layout_name)
	_check(start_button.icon == null, "%s: mission button has no icon" % layout_name)
	_check(start_button.align == Button.ALIGN_CENTER, "%s: mission button text is centered" % layout_name)
	_check(start_button.has_meta("font_role"), "%s: mission button uses an adaptive font role" % layout_name)

	_check(not screen.ui.has("nav_games"), "%s: old shortcut buttons are removed" % layout_name)
	_check(not screen.ui.has("nav_missions_title"), "%s: separate shortcut labels are removed" % layout_name)
	var navigation = screen.ui["navigation"]
	navigation.layout_for_viewport(viewport_size)
	_check(navigation.active_item == "home", "%s: home is the active menu item" % layout_name)
	var progress_rect: Rect2 = screen.ui["progress_panel"].get_global_rect()
	var nav_background_rect: Rect2 = navigation.background.get_global_rect()
	_check(nav_background_rect.position.y >= progress_rect.end.y, "%s: bottom menu does not overlap progress" % layout_name)
	_check(_fits_viewport(navigation.background, viewport_size), "%s: bottom menu background stays inside the viewport" % layout_name)
	for item_id in BOTTOM_NAVIGATION_SCRIPT.ITEM_IDS:
		var button: Button = navigation.buttons[item_id]
		var label: Label = navigation.labels[item_id]
		_check(button.visible, "%s: %s menu item is visible" % [layout_name, item_id])
		_check(label.text == BOTTOM_NAVIGATION_SCRIPT.ITEM_LABELS[BOTTOM_NAVIGATION_SCRIPT.ITEM_IDS.find(item_id)], "%s: %s label appears in the menu" % [layout_name, item_id])
		_check(navigation.icons[item_id].texture != null, "%s: %s icon texture loads" % [layout_name, item_id])
		_check(button.get_parent() == navigation, "%s: %s menu item is owned by the shared menu" % [layout_name, item_id])
		_check(button.get_meta("font_role") == "navigation", "%s: %s uses shared menu typography" % [layout_name, item_id])
		_check(button.focus_mode == Control.FOCUS_ALL, "%s: %s remains keyboard/controller focusable" % [layout_name, item_id])
		_check(_fits_viewport(button, viewport_size), "%s: %s stays inside the viewport" % [layout_name, item_id])
	_check(navigation.buttons["home"].get_color("font_color") == Color("#18d6d2"), "%s: Inicio is highlighted as the current page" % layout_name)


func _test_adaptive_font_sizes(screen) -> void:
	screen._layout_screen(Vector2(720, 1280))
	var large_portrait_scale: float = screen.ui["brand_top"].rect_scale.x
	screen._layout_screen(Vector2(360, 800))
	var narrow_portrait_scale: float = screen.ui["brand_top"].rect_scale.x
	screen._layout_screen(Vector2(1280, 720))
	var tv_landscape_scale: float = screen.ui["brand_top"].rect_scale.x
	screen._layout_screen(Vector2(960, 540))
	var compact_landscape_scale: float = screen.ui["brand_top"].rect_scale.x
	_check(narrow_portrait_scale < large_portrait_scale, "font size decreases with a smaller portrait viewport")
	_check(compact_landscape_scale < tv_landscape_scale, "font size decreases with a smaller landscape viewport")
	_check(narrow_portrait_scale > 0.0 and compact_landscape_scale > 0.0, "adaptive font sizes remain positive in portrait and landscape")
	var typography = TYPOGRAPHY_SCRIPT.new()
	_check(is_equal_approx(typography.get_role_ratio("body"), 0.035995), "greeting message remains the shared typography base")
	_check(is_equal_approx(typography.get_role_ratio("navigation"), typography.get_role_ratio("body")), "shared menu typography matches the greeting body size")
	_check(is_equal_approx(typography.get_role_ratio("brand_title"), 0.0485 * 1.3), "main brand title keeps its 30% larger role")
	_check(is_equal_approx(typography.get_role_ratio("brand"), 0.0485), "brand icon keeps its previous role")
	_check(is_equal_approx(typography.get_role_ratio("brand_secondary"), 0.038 * 1.3), "secondary brand title keeps its 30% larger role")
	_check(is_equal_approx(typography.get_role_ratio("heading"), 0.0333 * 1.15), "greeting title keeps its 15% larger role")
	_check(is_equal_approx(typography.get_role_ratio("button"), typography.get_role_ratio("body")), "main action matches the greeting body size")
	for role in ["caption", "display_number", "progress_value", "progress_caption", "prompt", "district", "district_progress", "status", "points_label", "points", "support", "level", "tab", "badge", "badge_level", "challenge_body", "reward_progress"]:
		_check(is_equal_approx(typography.get_role_ratio(role), typography.get_role_ratio("body")), "%s matches the greeting body size" % role)
	screen._layout_screen(Vector2(720, 1280))
	var navigation = screen.ui["navigation"]
	navigation.layout_for_viewport(Vector2(720, 1280))
	var large_nav_label_scale: float = navigation.buttons["home"].rect_scale.x
	screen._layout_screen(Vector2(320, 568))
	navigation.layout_for_viewport(Vector2(320, 568))
	var compact_nav_label_scale: float = navigation.buttons["home"].rect_scale.x
	_check(compact_nav_label_scale < large_nav_label_scale, "shared bottom menu font adapts to a compact viewport")


func _test_progress_values(screen) -> void:
	var progress: Dictionary = progression.get_state()
	_check(screen.ui["level_number"].text == str(progress["level"]), "home level number comes from saved progress")
	_check(abs(screen.ui["level_ring"].get("progress_ratio") - progression.get_progress_ratio()) < 0.0001, "home level ring reflects saved XP progress")
	_check(screen.ui["progress_value"].text == "%s / %s XP" % [progression.format_number(progress["experience"]), progression.format_number(progression.experience_per_level)], "home XP value comes from saved progress")
	_check(screen.ui["progress_hint"].text == "Faltam %s XP para o próximo nível" % progression.format_number(progression.experience_per_level - progress["experience"]), "home XP hint comes from saved progress")
	var original_path: String = progression.storage_path
	var test_path: String = "user://home_progress_test.json"
	_remove_progress_test_file(test_path)
	progression.storage_path = test_path
	progression.load_progress()
	progression.add_experience(500)
	_check(abs(screen.ui["level_ring"].get("progress_ratio") - 0.25) < 0.0001, "home level ring updates after a partial XP change")
	progression.add_experience(1500)
	_check(screen.ui["level_number"].text == "2", "home level display updates after a level-up signal")
	_check(screen.ui["progress_value"].text == "0 / 2.000 XP", "home XP display updates after a level-up signal")
	_check(abs(progression.get_progress_ratio()) < 0.0001, "level-up resets the XP progress ratio")
	_check(abs(screen.ui["level_ring"].get("progress_ratio")) < 0.0001, "level-up resets the home level ring")
	progression.storage_path = original_path
	progression.load_progress()
	_remove_progress_test_file(test_path)


func _remove_progress_test_file(path: String) -> void:
	var file := File.new()
	if file.file_exists(path):
		var directory := Directory.new()
		directory.remove(path)


func _test_landscape_greeting_hierarchy(screen) -> void:
	for viewport_size in [Vector2(1280, 720), Vector2(960, 540)]:
		screen._layout_screen(viewport_size)
		var title: Control = screen.ui["greeting_title"]
		var message: Control = screen.ui["greeting_text"]
		_check(title.rect_scale.x > message.rect_scale.x, "landscape greeting title is larger than its message at %s" % viewport_size)
		_check(_text_fits_control(title), "landscape greeting title fits at %s" % viewport_size)
		_check(_text_fits_control(message), "landscape greeting message fits at %s" % viewport_size)


func _test_landscape_action_and_level_alignment(screen) -> void:
	for viewport_size in [Vector2(1280, 720), Vector2(960, 540)]:
		screen._layout_screen(viewport_size)
		var start_rect: Rect2 = _layout_rect(screen.ui["start"])
		var progress_rect: Rect2 = _layout_rect(screen.ui["progress_panel"])
		var greeting_rect: Rect2 = _layout_rect(screen.ui["greeting_panel"])
		var group_center_y: float = (start_rect.position.y + progress_rect.end.y) * 0.5
		var greeting_center_y: float = greeting_rect.position.y + greeting_rect.size.y * 0.5
		var gap: float = progress_rect.position.y - start_rect.end.y
		_check(gap >= -1.0 and gap <= viewport_size.y * 0.05, "landscape mission button gap %.2f fits at %s" % [gap, viewport_size])
		_check(abs(group_center_y - greeting_center_y) <= 1.0, "landscape action and level group centers on the mascot speech area at %s" % viewport_size)


func _test_text_fits_controls(screen) -> void:
	for viewport_size in [Vector2(720, 1280), Vector2(1280, 720), Vector2(960, 540), Vector2(360, 800), Vector2(320, 568)]:
		screen._layout_screen(viewport_size)
		for key in ["menu", "notification", "logo_icon", "brand_top", "brand_bottom", "greeting_title", "greeting_text", "start", "level_caption", "level_number", "progress_title", "progress_value", "progress_hint", "status"]:
			var control: Control = screen.ui[key]
			_check(control.has_meta("font_role"), "%s uses an adaptive font role at %s" % [key, viewport_size])
			_check(screen.typography.has_role(control.get_meta("font_role")), "%s uses the shared typography scale at %s" % [key, viewport_size])
			_check(_text_fits_control(control), "%s text fits its allocated area at %s" % [key, viewport_size])
		var navigation = screen.ui["navigation"]
		navigation.layout_for_viewport(viewport_size)
		for item_id in BOTTOM_NAVIGATION_SCRIPT.ITEM_IDS:
			_check(navigation.labels[item_id].rect_size.x > 0.0 and navigation.labels[item_id].rect_size.y > 0.0, "%s menu label has space at %s" % [item_id, viewport_size])


func _fits_inside(child: Control, parent: Control) -> bool:
	var right: float = child.rect_position.x + child.rect_size.x * child.rect_scale.x
	var bottom: float = child.rect_position.y + child.rect_size.y * child.rect_scale.y
	return child.rect_position.x >= 0.0 and child.rect_position.y >= 0.0 and right <= parent.rect_size.x + 1.0 and bottom <= parent.rect_size.y + 1.0


func _fits_viewport(control: Control, viewport_size: Vector2) -> bool:
	var position: Vector2 = control.rect_position
	var size: Vector2 = control.rect_size * control.rect_scale
	var parent = control.get_parent()
	while parent is Control:
		position = parent.rect_position + position * parent.rect_scale
		size *= parent.rect_scale
		parent = parent.get_parent()
	return position.x >= -1.0 and position.y >= -1.0 and position.x + size.x <= viewport_size.x + 1.0 and position.y + size.y <= viewport_size.y + 1.0


func _layout_rect(control: Control) -> Rect2:
	return Rect2(control.rect_position, control.rect_size * control.rect_scale)


func _text_fits_control(control: Control) -> bool:
	var text: String = ""
	if control is Label:
		text = (control as Label).text
	elif control is Button:
		text = (control as Button).text
	if text.empty():
		return true
	var font: Font = control.get_font("font")
	var scale: float = control.rect_scale.x
	if control is Button:
		var max_line_width: float = 0.0
		for line in text.split("\n"):
			max_line_width = max(max_line_width, font.get_string_size(line).x)
		return max_line_width * scale <= control.rect_size.x * scale + 1.0
	var wrapped_size: Vector2 = font.get_wordwrap_string_size(text, control.rect_size.x)
	return wrapped_size.x * scale <= control.rect_size.x * scale + 1.0 and wrapped_size.y * scale <= control.rect_size.y * scale + 1.0


func _test_action_feedback(screen) -> void:
	screen._on_action_pressed("Teste de feedback")
	_check(screen.status_label.text == "Teste de feedback", "action feedback updates status label")
	_check(_text_fits_control(screen.status_label), "action feedback text adapts to the available status area")
	_check(ResourceLoader.exists(QUIZ_SCENE_PATH), "Missions destination scene exists")


func _setup_progression() -> void:
	progression = get_root().get_node("Progression")
	progression.set("storage_path", "user://screen_progress_test.json")
	progression.load_progress()

func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)

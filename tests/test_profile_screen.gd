extends SceneTree

const PROFILE_SCREEN = preload("res://app/menus/profile_screen.tscn")
const PROFILE_SCREEN_SCRIPT = preload("res://app/menus/profile_screen.gd")
const BOTTOM_NAVIGATION_SCRIPT = preload("res://shared/ui/bottom_navigation.gd")
const TYPOGRAPHY_SCRIPT = preload("res://shared/ui/typography.gd")
const TYPOGRAPHY_TEST_UTILS = preload("res://tests/typography_test_utils.gd")
const QUIZ_SCENE_PATH = "res://games/quiz/scenes/quiz_screen.tscn"
const DAILY_PROGRESS_SCRIPT = preload("res://games/quiz/scripts/quiz_daily_progress.gd")
const QUESTION_REPOSITORY_SCRIPT = preload("res://games/quiz/scripts/quiz_question_repository.gd")
const DAILY_TEST_PATH = "user://profile_daily_quiz_test.json"

const PROGRESSION_SCRIPT = preload("res://shared/progress/progression_service.gd")

var progression: Node
var failures: Array = []


func _initialize() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	_setup_progression()
	_seed_daily_quiz_progress(2)
	var screen = PROFILE_SCREEN.instance()
	screen.daily_progress_storage_path = DAILY_TEST_PATH
	get_root().add_child(screen)
	yield(self, "idle_frame")
	for viewport_size in [Vector2(720, 1280), Vector2(1280, 720), Vector2(960, 540), Vector2(360, 800), Vector2(320, 568)]:
		_test_layout(screen, viewport_size)
	_test_badge_unlock_display(screen)
	_test_progress_values(screen)
	_test_daily_quiz_progress(screen)
	_test_tabs(screen)
	_remove_progress_test_file("user://screen_progress_test.json")
	_remove_progress_test_file(DAILY_TEST_PATH)
	_test_daily_quiz_click(screen)
	yield(create_timer(0.5), "timeout")
	_check(get_current_scene() != null and get_current_scene().filename == QUIZ_SCENE_PATH, "clicking the daily quiz label opens the quiz scene")
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
	var typography_failures: Array = TYPOGRAPHY_TEST_UTILS.get_uniform_body_size_failures(screen, screen.typography, min(viewport_size.x, viewport_size.y))
	for typography_failure in typography_failures:
		_check(false, "%s at %s" % [typography_failure, viewport_size])
	var expected_header_y: float = viewport_size.y * (0.055 if viewport_size.x > viewport_size.y else 0.045)
	_check(is_equal_approx(screen.ui["header"].rect_position.y, expected_header_y), "Recompensas has two percent more top spacing at %s" % viewport_size)
	var background: TextureRect = screen.ui["background"]
	_check(background.texture != null, "profile test background image loads at %s" % viewport_size)
	_check(background.texture.resource_path == "res://shared/ui/assets/backgrounds/fundo.png", "profile uses the permanent background image at %s" % viewport_size)
	_check(background.stretch_mode == TextureRect.STRETCH_KEEP_ASPECT_COVERED, "profile test background covers both screen orientations at %s" % viewport_size)
	_check(_fits_viewport(background, viewport_size), "profile test background covers the viewport at %s" % viewport_size)
	var navigation = screen.ui["navigation"]
	_check(navigation.active_item == "profile", "Profile is the active menu item at %s" % viewport_size)
	for index in range(BOTTOM_NAVIGATION_SCRIPT.ITEM_IDS.size()):
		var item_id: String = BOTTOM_NAVIGATION_SCRIPT.ITEM_IDS[index]
		_check(navigation.labels[item_id].text == BOTTOM_NAVIGATION_SCRIPT.ITEM_LABELS[index], "%s label is present at %s" % [item_id, viewport_size])
		_check(navigation.icons[item_id].texture != null, "%s icon loads at %s" % [item_id, viewport_size])
		_check(_fits_viewport(navigation.buttons[item_id], viewport_size), "%s navigation control fits at %s" % [item_id, viewport_size])
	for key in ["header", "hero_panel", "hero_mascot", "user_name", "points_label", "points", "support", "level_panel", "level_caption", "xp_value", "xp_track", "tabs_panel", "challenge_panel", "challenge_title", "challenge_text", "challenge_count", "challenge_track", "status"]:
		_check(_fits_viewport(screen.ui[key], viewport_size), "%s stays inside the viewport at %s" % [key, viewport_size])
	_check(screen.ui.has("challenge_panel"), "daily quiz progress section is present")
	_check(screen.ui["tabs"].size() == 2, "profile keeps only Distintivos and Equipamento tabs")
	_check(screen.ui["tabs"].has("EQUIPAMENTO") and screen.ui["tabs"]["EQUIPAMENTO"].text == "EQUIPAMENTO", "the gadget tab is labeled Equipamento")
	_check(not screen.ui["tabs"].has("CONQUISTAS"), "Conquistas tab is removed")
	_check(screen.ui["hero_mascot"].texture.resource_path == "res://shared/mascot/levels/1.png", "profile avatar uses the level-one capybara artwork")
	_check(screen.ui["hero_mascot"].modulate == Color.white, "profile avatar keeps the capybara artwork in color")
	_check(screen.ui["user_name"].text == "Gabivara" and screen.ui["user_name"].visible, "profile displays the Gabivara name")
	_check(screen.ui["user_name"].get_global_rect().end.y <= screen.ui["points_label"].get_global_rect().position.y, "profile name stays above the experience summary")
	var typography = TYPOGRAPHY_SCRIPT.new()
	_check(is_equal_approx(typography.get_role_ratio("body"), TYPOGRAPHY_SCRIPT.BASE_BODY_RATIO * TYPOGRAPHY_SCRIPT.BODY_SCALE_ADJUSTMENT), "profile typography uses the adjusted greeting text base")
	var profile_title: Control = screen.ui["header"]
	screen._place(profile_title, 0.0, 0.0, 10000.0, 10000.0, 720.0)
	_check(abs(profile_title.get_font("font").get_height() - typography.get_target_height(profile_title.get_meta("font_role"), 720.0) * 1.10) <= 1.0, "profile screen title is enlarged by ten percent")
	for key in ["header", "user_name", "points_label", "points", "support", "level_caption", "xp_value", "challenge_title", "challenge_text", "challenge_count"]:
		_check(typography.has_role(screen.ui[key].get_meta("font_role")), "%s uses the shared typography scale" % key)
	_check(screen.badge_controls.size() == 6, "six reward badges are displayed")
	_check(screen.collection_controls.size() == 9, "collection displays the nine gadgets for levels two through ten")
	for gadget in screen.collection_controls:
		var gadget_level: int = gadget["required_level"]
		_check(gadget["icon"].texture == null, "level %d gadget is not loaded before its tab is opened" % gadget_level)
		_check(gadget["label"].text == "NÍVEL %d" % gadget_level, "level %d gadget shows its unlock level" % gadget_level)
		_check(is_equal_approx(gadget["material"].get_shader_param("grayscale_amount"), 1.0), "level %d gadget is grayscale while locked" % gadget_level)
		_check(not gadget["icon"].visible, "collection items stay hidden on the Distintivos tab")
		_check(_fits_viewport(gadget["icon"], viewport_size), "level %d gadget icon fits the viewport at %s" % [gadget_level, viewport_size])
		_check(_fits_viewport(gadget["label"], viewport_size), "level %d gadget label fits the viewport at %s" % [gadget_level, viewport_size])
		_check(is_equal_approx(gadget["icon"].rect_size.x, screen.collection_controls[0]["icon"].rect_size.x), "all gadget icons share the same size at %s" % viewport_size)
	for index in range(screen.badge_controls.size()):
		var badge: Dictionary = screen.badge_controls[index]
		_check(typography.has_role(badge["name"].get_meta("font_role")), "%s name uses shared typography" % PROFILE_SCREEN_SCRIPT.BADGES[index]["name"])
		_check(typography.has_role(badge["level"].get_meta("font_role")), "%s level uses shared typography" % PROFILE_SCREEN_SCRIPT.BADGES[index]["name"])
		_check(badge["icon"].texture == PROFILE_SCREEN_SCRIPT.BADGES[index]["texture"], "%s uses its dedicated badge artwork" % PROFILE_SCREEN_SCRIPT.BADGES[index]["name"])
		_check(badge["icon"].texture != null and badge["icon"].texture.get_width() > 0 and badge["icon"].texture.get_height() > 0, "%s artwork is fully loaded" % PROFILE_SCREEN_SCRIPT.BADGES[index]["name"])
		_check(badge["icon"].visible, "%s appears on the profile screen" % PROFILE_SCREEN_SCRIPT.BADGES[index]["name"])
		_check(badge["level"].text == "NÍVEL 0", "%s starts at level zero" % PROFILE_SCREEN_SCRIPT.BADGES[index]["name"])
		_check(is_equal_approx(badge["material"].get_shader_param("grayscale_amount"), 1.0), "%s starts grayscale" % PROFILE_SCREEN_SCRIPT.BADGES[index]["name"])
		_check(_fits_viewport(badge["icon"], viewport_size), "%s badge icon stays inside the viewport at %s" % [PROFILE_SCREEN_SCRIPT.BADGES[index]["name"], viewport_size])
		var gadget_icon: Control = screen.collection_controls[0]["icon"]
		_check(is_equal_approx(badge["icon"].rect_size.x, gadget_icon.rect_size.x), "%s badge matches gadget width at %s" % [PROFILE_SCREEN_SCRIPT.BADGES[index]["name"], viewport_size])
		_check(is_equal_approx(badge["icon"].rect_size.y, gadget_icon.rect_size.y), "%s badge matches gadget height at %s" % [PROFILE_SCREEN_SCRIPT.BADGES[index]["name"], viewport_size])
		_check(is_equal_approx(typography.get_role_ratio(badge["name"].get_meta("font_role")), typography.get_role_ratio("body")), "%s badge name uses the shared body size" % PROFILE_SCREEN_SCRIPT.BADGES[index]["name"])
		_check(is_equal_approx(typography.get_role_ratio(badge["level"].get_meta("font_role")), typography.get_role_ratio("body")), "%s badge level uses the shared body size" % PROFILE_SCREEN_SCRIPT.BADGES[index]["name"])
		_check(_fits_viewport(badge["name"], viewport_size), "%s badge name stays inside the viewport at %s" % [PROFILE_SCREEN_SCRIPT.BADGES[index]["name"], viewport_size])
	for tab_name in ["DISTINTIVOS", "EQUIPAMENTO"]:
		_check(screen.ui["tabs"][tab_name].focus_mode == Control.FOCUS_ALL, "%s tab supports focus navigation" % tab_name)
		_check(typography.has_role(screen.ui["tabs"][tab_name].get_meta("font_role")), "%s tab uses shared typography" % tab_name)
		_check(_fits_viewport(screen.ui["tabs"][tab_name], viewport_size), "%s tab stays inside the viewport at %s" % [tab_name, viewport_size])


func _test_badge_unlock_display(screen) -> void:
	for index in range(3):
		_check(progression.record_quiz_correct_answer("profile_badge_test:%d" % index), "profile test records a correct quiz answer")
	var knowledge_badge: Dictionary = screen.badge_controls[3]
	_check(knowledge_badge["id"] == "knowledge", "knowledge badge is linked to its progress identifier")
	_check(knowledge_badge["level"].text == "NÍVEL 1", "knowledge badge shows level one after three correct answers")
	_check(is_equal_approx(knowledge_badge["material"].get_shader_param("grayscale_amount"), 0.0), "knowledge badge shows its full color artwork when unlocked")
	for index in [0, 1, 2, 4, 5]:
		var locked_badge: Dictionary = screen.badge_controls[index]
		_check(locked_badge["level"].text == "NÍVEL 0", "%s remains at level zero without an unlock rule" % locked_badge["id"])
		_check(is_equal_approx(locked_badge["material"].get_shader_param("grayscale_amount"), 1.0), "%s remains grayscale without an unlock rule" % locked_badge["id"])


func _test_tabs(screen) -> void:
	screen._on_tab_pressed("EQUIPAMENTO")
	_check(screen.selected_tab == "EQUIPAMENTO", "equipment tab becomes active")
	_check(screen.collection_controls[0]["icon"].visible, "collection items appear after selecting the collection tab")
	for gadget in screen.collection_controls:
		var gadget_level: int = gadget["required_level"]
		_check(gadget["icon"].texture != null, "level %d gadget loads on demand when the collection opens" % gadget_level)
		_check(gadget["icon"].texture.resource_path == "res://shared/progress/assets/gadgets/%d.png" % gadget_level, "level %d gadget comes from its copied runtime asset" % gadget_level)
	_check(not screen.badge_controls[0]["icon"].visible, "badges are hidden while viewing the collection")
	_check(screen.ui["status"].text.empty(), "collection tab leaves the status label clear")
	_check(progression.add_experience(6000), "profile test advances through the configured level thresholds")
	_check(screen.ui["hero_mascot"].texture.resource_path == "res://shared/mascot/levels/5.png", "profile avatar updates to the capybara for the new level")
	for gadget in screen.collection_controls:
		var required_level: int = gadget["required_level"]
		var expected_grayscale: float = 0.0 if required_level <= 5 else 1.0
		_check(is_equal_approx(gadget["material"].get_shader_param("grayscale_amount"), expected_grayscale), "level %d gadget color follows the profile level" % required_level)
	screen._on_tab_pressed("DISTINTIVOS")
	_check(screen.ui["status"].text.empty(), "badge tab clears temporary feedback")
	_check(screen.selected_tab == "DISTINTIVOS", "badge tab remains selected")
	_check(screen.badge_controls[0]["icon"].visible and not screen.collection_controls[0]["icon"].visible, "switching tabs restores badges and hides gadgets")
	_check(screen.collection_controls[0]["icon"].texture == null, "gadget textures are released when the collection tab closes")
	_check(ResourceLoader.exists(QUIZ_SCENE_PATH), "Missions destination scene exists")


func _seed_daily_quiz_progress(answer_count: int) -> void:
	_remove_progress_test_file(DAILY_TEST_PATH)
	var repository = QUESTION_REPOSITORY_SCRIPT.new()
	if not repository.load_questions():
		_check(false, "daily quiz question data loads for Profile tests")
		return
	var daily_progress = DAILY_PROGRESS_SCRIPT.new()
	daily_progress.storage_path = DAILY_TEST_PATH
	daily_progress.load_progress(repository.questions.size())
	for index in range(answer_count):
		_check(daily_progress.record_answer(index, repository.questions.size(), false), "test stores a daily quiz answer")


func _test_daily_quiz_progress(screen) -> void:
	_check(screen.ui["challenge_title"].text == "QUIZ DIÁRIO", "profile reward section is relabeled for the daily quiz")
	_check(screen.ui["challenge_count"].text == "2 / 5", "profile shows the number of quiz questions answered today")
	_check(screen.ui["challenge_text"].text == "Perguntas respondidas hoje", "profile describes the daily answer count")
	_check(is_equal_approx(screen.ui["challenge_fill"].rect_size.x / screen.ui["challenge_track"].rect_size.x, 0.4), "daily quiz progress bar matches two of five answers")
	var repository = QUESTION_REPOSITORY_SCRIPT.new()
	_check(repository.load_questions(), "daily quiz data loads for the completion check")
	for index in range(2, DAILY_PROGRESS_SCRIPT.DAILY_LIMIT):
		_check(screen.daily_progress.record_answer(index, repository.questions.size(), false), "test stores another daily answer")
	screen._refresh_daily_quiz_ui()
	_check(screen.ui["challenge_count"].text == "5 / 5", "profile shows all five daily answers")
	_check(screen.ui["challenge_text"].text == "Parabéns! Você completou o quiz de hoje!", "profile congratulates the user after finishing today's quiz")
	_check(is_equal_approx(screen.ui["challenge_fill"].rect_size.x / screen.ui["challenge_track"].rect_size.x, 1.0), "daily quiz progress bar reaches full after five answers")


func _test_daily_quiz_click(screen) -> void:
	for key in ["challenge_title", "challenge_text", "challenge_count"]:
		var label: Label = screen.ui[key]
		_check(label.mouse_filter == Control.MOUSE_FILTER_STOP, "%s accepts pointer input" % key)
		_check(label.focus_mode == Control.FOCUS_ALL, "%s supports keyboard and controller focus" % key)
		_check(label.is_connected("gui_input", screen, "_on_daily_quiz_gui_input"), "%s opens the quiz on activation" % key)
	var click := InputEventMouseButton.new()
	click.button_index = BUTTON_LEFT
	click.pressed = false
	screen.ui["challenge_title"].emit_signal("gui_input", click)


func _test_progress_values(screen) -> void:
	var progress: Dictionary = progression.get_state()
	var total_xp: int = progression.get_total_experience()
	var item_count: int = progress["unlocked_items"].size()
	_check(screen.ui["points"].text == progression.format_number(total_xp), "profile total experience comes from saved progress")
	_check(screen.ui["support"].text == "Itens desbloqueados: %d" % item_count, "profile item count comes from saved progress")
	_check(screen.ui["level_caption"].text == "NÍVEL %d" % progress["level"], "profile level comes from saved progress")
	_check(screen.ui["xp_value"].text == "%s / %s XP" % [progression.format_number(progress["experience"]), progression.format_number(progression.experience_per_level)], "profile XP comes from saved progress")
	var original_path: String = progression.storage_path
	var test_path: String = "user://profile_progress_test.json"
	_remove_progress_test_file(test_path)
	progression.storage_path = test_path
	progression.load_progress()
	progression.add_experience(2000)
	_check(screen.ui["level_caption"].text == "NÍVEL 2", "profile level updates after a level-up signal")
	_check(screen.ui["points"].text == "2.000", "profile total experience updates after a level-up signal")
	_check(screen.ui["support"].text == "Itens desbloqueados: 1", "profile reward count updates after a level-up signal")
	progression.storage_path = original_path
	progression.load_progress()
	_remove_progress_test_file(test_path)


func _remove_progress_test_file(path: String) -> void:
	var file := File.new()
	if file.file_exists(path):
		var directory := Directory.new()
		directory.remove(path)


func _fits_viewport(control: Control, viewport_size: Vector2) -> bool:
	var position: Vector2 = control.rect_position
	var size: Vector2 = control.rect_size * control.rect_scale
	var parent = control.get_parent()
	while parent is Control:
		position = parent.rect_position + position * parent.rect_scale
		size *= parent.rect_scale
		parent = parent.get_parent()
	return position.x >= -1.0 and position.y >= -1.0 and position.x + size.x <= viewport_size.x + 1.0 and position.y + size.y <= viewport_size.y + 1.0


func _setup_progression() -> void:
	progression = get_root().get_node("Progression")
	_remove_progress_test_file("user://screen_progress_test.json")
	progression.set("storage_path", "user://screen_progress_test.json")
	progression.load_progress()

func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)

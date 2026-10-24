extends SceneTree

const QUIZ_SCREEN = preload("res://games/quiz/scenes/quiz_screen.tscn")
const QUESTION_REPOSITORY = preload("res://games/quiz/scripts/quiz_question_repository.gd")
const DAILY_PROGRESS = preload("res://games/quiz/scripts/quiz_daily_progress.gd")
const QUIZ_DATA_PATH = "res://games/quiz/data/perguntas_e_respostas.json"
const ARROW_BACK_PATH = "res://shared/ui/assets/icons/arrow_back_icon.svg"
const TYPOGRAPHY_SCRIPT = preload("res://shared/ui/typography.gd")
const TEST_SAVE_PATH = "user://quiz_screen_test_progress.json"

var failures: Array = []


func _initialize() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	_test_question_repository()
	_test_daily_limit_and_persistence()
	yield(self, "idle_frame")
	_test_screen_flow()
	if failures.empty():
		print("Quiz screen tests passed")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func _test_question_repository() -> void:
	var repository = QUESTION_REPOSITORY.new()
	_check(repository.load_questions(), "question JSON loads and validates")
	_check(repository.questions.size() == 50, "all 50 questions are imported")
	var only_available: Array = []
	for index in range(repository.questions.size()):
		if index != 17:
			only_available.append(index)
	_check(repository.get_random_question_index(only_available) == 17, "random question selection skips questions answered today")
	var first_question: Dictionary = repository.questions[0]
	_check(first_question["opcoes"].size() == 4, "question schema contains four selectable options")
	_check(first_question["explicacao"] != "", "question schema contains an explanation")
	var data_file := File.new()
	_check(data_file.file_exists(QUIZ_DATA_PATH), "quiz JSON is stored in the feature data folder")


func _test_daily_limit_and_persistence() -> void:
	_remove_test_file()
	var progress = DAILY_PROGRESS.new()
	progress.storage_path = TEST_SAVE_PATH
	progress.load_progress(20, "2026-01-01")
	_check(progress.get_answered_count() == 0, "a new date starts with no answered questions")
	for index in range(5):
		_check(progress.record_answer(index, 20), "daily answer %d is recorded" % (index + 1))
		if index == 0:
			_check(not progress.record_answer(index, 20), "the same question cannot be recorded twice")
	_check(not progress.can_answer(), "daily limit blocks a sixth question")
	_check(not progress.record_answer(5, 20), "a sixth answer is rejected")
	var restored = DAILY_PROGRESS.new()
	restored.storage_path = TEST_SAVE_PATH
	restored.load_progress(20, "2026-01-01")
	_check(restored.get_answered_count() == 5, "daily limit persists after reloading")
	var next_day = DAILY_PROGRESS.new()
	next_day.storage_path = TEST_SAVE_PATH
	next_day.load_progress(20, "2026-01-02")
	_check(next_day.get_answered_count() == 0, "daily allowance resets on the next date")
	_remove_test_file()


func _test_screen_flow() -> void:
	_remove_test_file()
	var screen = QUIZ_SCREEN.instance()
	screen.daily_progress.storage_path = TEST_SAVE_PATH
	screen.anchor_right = 0.0
	screen.anchor_bottom = 0.0
	screen.rect_size = Vector2(720, 1000)
	get_root().add_child(screen)
	yield(self, "idle_frame")
	_check(screen.current_question_index >= 0, "screen selects a question on entry")
	_check(screen.ui["mission_title"].text.find(String(screen.current_question["tema"]).to_upper()) >= 0, "screen displays the question topic")
	_check(screen.explanation_timer.wait_time == 10.0, "explanation popup closes after ten seconds")
	_check(screen.ui["back_icon"].texture.resource_path == ARROW_BACK_PATH, "quiz question screen uses the shared arrow back asset")
	_check(ResourceLoader.exists("res://ideias/arrow_back_icon.svg"), "original arrow back reference remains in ideas")
	_check(not screen.ui["navigation"].visible and screen.ui["back"].visible, "question screen preserves its back button and hides completion navigation")
	_test_shared_typography(screen)
	for viewport_size in [Vector2(720, 1280), Vector2(1280, 720), Vector2(960, 540), Vector2(360, 800), Vector2(320, 568)]:
		screen.rect_size = viewport_size
		screen._layout_screen(viewport_size)
		for row in screen.answer_rows:
			_check(_fits_viewport(row["button"], viewport_size), "answer option fits at %s" % viewport_size)
			_check(row["button"].focus_mode == Control.FOCUS_ALL, "answer option supports keyboard/controller focus")
		_check(_fits_viewport(screen.ui["confirm"], viewport_size), "confirm button fits at %s" % viewport_size)

	var first_index: int = screen.current_question_index
	var correct_index: int = int(screen.current_question["respostaCorreta"])
	var wrong_index: int = (correct_index + 1) % screen.current_question["opcoes"].size()
	screen._on_option_pressed(wrong_index)
	screen._on_confirm_pressed()
	_check(screen.daily_progress.get_answered_count() == 1, "answer submission advances the daily count")
	_check(screen.answer_rows[wrong_index]["label"].get_color("font_color") == Color("#e95b63"), "selected wrong answer becomes red")
	_check(screen.answer_rows[correct_index]["label"].get_color("font_color") == Color("#32bb78"), "correct answer becomes green")
	_check(screen.ui["explanation_text"].text == screen.current_question["explicacao"], "explanation popup uses the JSON explanation")
	_check(screen.ui["explanation_overlay"].visible, "explanation popup opens after answering")
	screen._on_explanation_timeout()
	_check(screen.ui["next_prompt"].visible, "next question prompt appears after explanation is dismissed")
	_check(screen.ui["next_prompt_title"].text.find("próxima questão") >= 0, "next prompt asks before continuing")
	screen._on_next_prompt_yes()
	_check(screen.current_question_index != first_index, "next randomized question differs from the previous one")
	var second_correct_index: int = int(screen.current_question["respostaCorreta"])
	screen._on_option_pressed(second_correct_index)
	screen._on_confirm_pressed()
	var outside_click := InputEventMouseButton.new()
	outside_click.button_index = BUTTON_LEFT
	outside_click.pressed = true
	outside_click.position = Vector2(5, 5)
	screen._on_explanation_overlay_input(outside_click)
	_check(not screen.ui["explanation_overlay"].visible, "clicking outside closes the explanation popup")
	_check(screen.ui["next_prompt"].visible, "next question prompt appears after an outside click")
	screen._on_next_prompt_yes()

	while screen.daily_progress.can_answer():
		var answer_index: int = int(screen.current_question["respostaCorreta"])
		screen._on_option_pressed(answer_index)
		screen._on_confirm_pressed()
		screen._dismiss_explanation()
		if screen.daily_progress.can_answer():
			screen._on_next_prompt_yes()
	_check(screen.ui["completion_title"].visible, "fifth answer shows the daily completion message")
	_check(screen.ui["completion_message"].text.find("Volte amanhã") >= 0, "completion message points to tomorrow")
	_check(screen.daily_progress.get_answered_count() == 5, "screen stops after five answers")
	_check(screen.ui["navigation"].visible and screen.ui["navigation"].active_item == "missions", "completed quiz shows the shared menu with Missions active")
	_check(not screen.ui["back"].visible, "completed quiz hides the upper-left back button")
	_check(not screen.ui.has("completion_back"), "completed quiz no longer has a separate map return button")
	_check(screen.ui["completion_message"].get_meta("font_role") == "body", "completion message uses the shared body typography role")
	var typography = TYPOGRAPHY_SCRIPT.new()
	_check(is_equal_approx(typography.get_role_ratio(screen.ui["completion_message"].get_meta("font_role")), typography.get_role_ratio("body")), "completion message font matches the standard body role")
	for item_id in screen.ui["navigation"].labels:
		_check(screen.ui["navigation"].labels[item_id].get_meta("font_role") == "navigation", "completion menu %s uses shared navigation typography" % item_id)
	for viewport_size in [Vector2(720, 1280), Vector2(1280, 720), Vector2(960, 540), Vector2(360, 800), Vector2(320, 568)]:
		screen.rect_size = viewport_size
		screen._layout_screen(viewport_size)
		for item_id in screen.ui["navigation"].buttons:
			_check(_fits_viewport(screen.ui["navigation"].buttons[item_id], viewport_size), "completion menu %s fits at %s" % [item_id, viewport_size])
	screen.queue_free()
	yield(self, "idle_frame")
	var reopened = QUIZ_SCREEN.instance()
	reopened.daily_progress.storage_path = TEST_SAVE_PATH
	reopened.anchor_right = 0.0
	reopened.anchor_bottom = 0.0
	reopened.rect_size = Vector2(720, 1000)
	get_root().add_child(reopened)
	yield(self, "idle_frame")
	_check(reopened.ui["completion_title"].visible, "daily completion persists after reopening the screen")
	_check(reopened.ui["navigation"].visible and not reopened.ui["back"].visible, "reopened completed quiz keeps the shared menu and hides back controls")
	reopened.queue_free()
	_remove_test_file()


func _remove_test_file() -> void:
	var file := File.new()
	if file.file_exists(TEST_SAVE_PATH):
		var directory := Directory.new()
		directory.remove(TEST_SAVE_PATH)


func _test_shared_typography(screen) -> void:
	var typography = TYPOGRAPHY_SCRIPT.new()
	for key in ["mission_title", "completion_title", "explanation_title"]:
		_check(screen.ui[key].get_meta("font_role") == "body", "quiz %s uses the mascot speech typography role" % key)
	_check_typography_baseline(screen, typography)


func _check_typography_baseline(node: Node, typography) -> void:
	if node is Control and node.has_meta("font_role"):
		var role: String = node.get_meta("font_role")
		_check(typography.has_role(role), "%s uses a known typography role" % node.name)
		_check(is_equal_approx(typography.get_role_ratio(role), typography.get_role_ratio("body")), "%s matches the mascot speech font ratio" % node.name)
	for child in node.get_children():
		_check_typography_baseline(child, typography)


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

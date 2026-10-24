extends SceneTree

const QUIZ_SCREEN = preload("res://games/quiz/scenes/quiz_screen.tscn")
const QUESTION_REPOSITORY = preload("res://games/quiz/scripts/quiz_question_repository.gd")
const DAILY_PROGRESS = preload("res://games/quiz/scripts/quiz_daily_progress.gd")
const QUIZ_DATA_PATH = "res://games/quiz/data/perguntas_e_respostas.json"
const ARROW_BACK_PATH = "res://shared/ui/assets/icons/arrow_back_icon.svg"
const TYPOGRAPHY_SCRIPT = preload("res://shared/ui/typography.gd")
const TYPOGRAPHY_TEST_UTILS = preload("res://tests/typography_test_utils.gd")
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
	for row in screen.answer_rows:
		_check(not row.has("marker"), "answer option has no numbered marker")
	_test_shared_typography(screen)
	_test_mission_typography(screen)
	for viewport_size in [Vector2(720, 1280), Vector2(1280, 720), Vector2(960, 540), Vector2(360, 800), Vector2(320, 568)]:
		screen.rect_size = viewport_size
		screen._layout_screen(viewport_size)
		var typography_failures: Array = TYPOGRAPHY_TEST_UTILS.get_uniform_body_size_failures(screen, screen.typography, min(viewport_size.x, viewport_size.y))
		for typography_failure in typography_failures:
			_check(false, "%s at %s" % [typography_failure, viewport_size])
		var short_side: float = min(viewport_size.x, viewport_size.y)
		_check(
			is_equal_approx(screen.ui["shield"].rect_size.x, short_side * 0.075 * 1.10),
			"mission shield is enlarged by 10% at %s" % viewport_size
		)
		var title_right: float = screen.ui["mission_title"].rect_position.x + screen.ui["mission_title"].rect_size.x * screen.ui["mission_title"].rect_scale.x
		_check(title_right < screen.ui["shield"].rect_position.x, "mission title does not overlap the shield at %s" % viewport_size)
		var question_scale: float = screen.ui["question"].rect_scale.x
		var answer_scale: float = screen.answer_rows[0]["label"].rect_scale.x
		for row in screen.answer_rows:
			_check(_fits_viewport(row["button"], viewport_size), "answer option fits at %s" % viewport_size)
			_check(row["button"].focus_mode == Control.FOCUS_ALL, "answer option supports keyboard/controller focus")
			_check(is_equal_approx(row["label"].rect_scale.x, answer_scale), "answer text has a uniform font size at %s" % viewport_size)
			_check(is_equal_approx(question_scale, answer_scale), "question and answers share a font size at %s" % viewport_size)
			_check(
				row["label"].rect_size.x * row["label"].rect_scale.x / row["button"].rect_size.x > 0.9,
				"answer text uses over 90% of the button width at %s" % viewport_size
			)
			_check(
				row["label"].rect_size.y * row["label"].rect_scale.y / row["button"].rect_size.y > 0.9,
				"answer text uses over 90% of the button height at %s" % viewport_size
			)
		if viewport_size == Vector2(360, 800) or viewport_size == Vector2(320, 568):
			var font: Font = screen.ui["question"].get_font("font")
			var baseline_scale: float = screen.typography.get_target_height("body", min(viewport_size.x, viewport_size.y)) / font.get_height()
			_check(question_scale >= baseline_scale * 1.12, "mobile question and answer font is larger than the previous 12% scale")
		_check(_fits_viewport(screen.ui["confirm"], viewport_size), "confirm button fits at %s" % viewport_size)
		_check(_fits_viewport(screen.ui["explanation_close"], viewport_size), "explanation close button fits at %s" % viewport_size)

	var first_index: int = screen.current_question_index
	var correct_index: int = int(screen.current_question["respostaCorreta"])
	var wrong_index: int = (correct_index + 1) % screen.current_question["opcoes"].size()
	screen._on_option_pressed(wrong_index)
	screen._on_confirm_pressed()
	_check(screen.daily_progress.get_answered_count() == 1, "answer submission advances the daily count")
	_check(screen.answer_rows[wrong_index]["label"].get_color("font_color") == Color("#000000"), "selected wrong answer text stays black")
	_check(screen.answer_rows[correct_index]["label"].get_color("font_color") == Color("#000000"), "correct answer text stays black")
	_check(_answer_fill_color(screen.answer_rows[wrong_index]) == Color("#e95b63"), "selected wrong answer button fills red")
	_check(_answer_fill_color(screen.answer_rows[correct_index]) == Color("#32bb78"), "correct answer button fills green")
	for state in ["normal", "hover", "focus", "pressed", "disabled"]:
		var green_count: int = 0
		var red_count: int = 0
		for index in range(screen.answer_rows.size()):
			var fill_color: Color = _answer_fill_color(screen.answer_rows[index], state)
			if index == correct_index:
				_check(fill_color == Color("#32bb78"), "only the correct answer is green in the %s state" % state)
			elif index == wrong_index:
				_check(fill_color == Color("#e95b63"), "selected wrong answer is red in the %s state" % state)
			else:
				_check(fill_color == Color("#ffffff"), "unselected answer resets to white in the %s state" % state)
			if fill_color == Color("#32bb78"):
				green_count += 1
			if fill_color == Color("#e95b63"):
				red_count += 1
		_check(green_count == 1 and red_count == 1, "wrong answer feedback has one green and one red option in the %s state" % state)
	_check(screen.ui["explanation_text"].text == screen.current_question["explicacao"], "explanation popup uses the JSON explanation")
	_check(screen.ui["explanation_overlay"].visible, "explanation popup opens after a wrong answer")
	_check(screen.ui["explanation_close"].focus_mode == Control.FOCUS_ALL, "explanation close button supports keyboard/controller focus")
	screen.ui["explanation_close"].emit_signal("pressed")
	_check(not screen.ui["explanation_overlay"].visible, "explanation close button dismisses the popup")
	_check(screen.ui["next_prompt"].visible, "next question prompt appears after explanation is dismissed")
	_check(screen.ui["next_prompt_title"].text.find("próxima questão") >= 0, "next prompt asks before continuing")
	screen.ui["explanation_overlay"].visible = true
	_check(screen.handle_back_request(), "back request is handled while the explanation popup is open")
	_check(not screen.ui["explanation_overlay"].visible, "back request dismisses the explanation popup")
	screen._on_next_prompt_yes()
	_check(screen.current_question_index != first_index, "next randomized question differs from the previous one")
	for state in ["normal", "hover", "focus", "pressed", "disabled"]:
		for row in screen.answer_rows:
			_check(_answer_fill_color(row, state) == Color("#ffffff"), "new question resets every answer to white in the %s state" % state)
	var second_correct_index: int = int(screen.current_question["respostaCorreta"])
	screen._on_option_pressed(second_correct_index)
	screen._on_confirm_pressed()
	_check(not screen.ui["explanation_overlay"].visible, "correct answer does not show the explanation popup")
	_check(screen.ui["next_prompt"].visible, "correct answer opens the next-question prompt directly")
	_check(screen.answer_rows[second_correct_index]["label"].get_color("font_color") == Color("#000000"), "correct answer text stays black")
	_check(_answer_fill_color(screen.answer_rows[second_correct_index]) == Color("#32bb78"), "selected correct answer button fills green")
	screen._on_next_prompt_yes()

	while screen.daily_progress.can_answer():
		var answer_index: int = int(screen.current_question["respostaCorreta"])
		if screen.daily_progress.get_answered_count() == 4:
			answer_index = (answer_index + 1) % screen.current_question["opcoes"].size()
		screen._on_option_pressed(answer_index)
		screen._on_confirm_pressed()
		screen._dismiss_explanation()
		if screen.daily_progress.can_answer():
			screen._on_next_prompt_yes()
	_check(screen.ui["next_prompt"].visible, "last answer opens a confirmation prompt before completion")
	_check(not screen.ui["completion_title"].visible, "completion screen waits for confirmation after the last answer")
	_check(screen.ui["next_prompt_title"].text.find("todas as perguntas") >= 0, "last-answer prompt explains that all questions were answered")
	_check(screen.ui["next_prompt_yes"].text == "VER CONCLUSÃO", "last-answer confirmation offers to view completion")
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
		var role: String = screen.ui[key].get_meta("font_role")
		_check(typography.is_title_role(role) or screen.ui[key].has_meta("title_text"), "quiz %s remains in the title hierarchy" % key)
	_check_typography_baseline(screen, typography)
	var question: Label = screen.ui["question"]
	var original_text: String = question.text
	var answer_label: Label = screen.answer_rows[0]["label"]
	var original_answer_text: String = answer_label.text
	var font: Font = question.get_font("font")
	question.text = "Texto"
	screen._place(question, 0.0, 0.0, 720.0, 120.0, 720.0)
	var expected_base: float = typography.get_target_height("body", 720.0) / font.get_height()
	_check(is_equal_approx(question.rect_scale.x, expected_base), "question exactly matches the mascot speech body size")
	answer_label.text = "Resposta"
	screen._place(answer_label, 0.0, 0.0, 720.0, 120.0, 720.0)
	_check(is_equal_approx(answer_label.rect_scale.x, expected_base), "answer exactly matches the mascot speech body size")
	var progress_text: Label = screen.ui["progress_text"]
	progress_text.text = "PERGUNTA 1 DE 5"
	screen._place(progress_text, 0.0, 0.0, 720.0, 120.0, 720.0)
	_check(is_equal_approx(progress_text.rect_scale.x, expected_base), "question progress exactly matches the mascot speech body size")
	question.text = original_text
	answer_label.text = original_answer_text
	screen._layout_screen(Vector2(720, 1280))


func _test_mission_typography(screen) -> void:
	var font: Font = screen.ui["question"].get_font("font")
	var body_scale: float = screen.typography.get_target_height("body", 720.0) / font.get_height()
	_check(is_equal_approx(float(screen.ui["mission_title"].get_meta("font_scale")), 1.15), "mission title remains enlarged")
	_check(is_equal_approx(float(screen.ui["explanation_title"].get_meta("font_scale")), 1.25), "explanation title remains enlarged")
	for control in [
		screen.ui["progress_text"],
		screen.ui["question"],
		screen.ui["instruction"],
		screen.ui["hint"],
		screen.ui["confirm"],
		screen.ui["explanation_text"],
		screen.ui["explanation_close_hint"],
		screen.ui["explanation_close"],
		screen.ui["next_prompt_title"],
		screen.ui["next_prompt_yes"],
		screen.ui["next_prompt_no"]
	]:
		_check(not control.has_meta("font_scale"), "%s uses the shared body size without a local override" % control.name)
	_check(body_scale > 0.0, "shared body typography is available for the mission")


func _check_typography_baseline(node: Node, typography) -> void:
	var has_text := node is Label or node is Button and not (node as Button).text.empty()
	if has_text and node.has_meta("font_role"):
		var role: String = node.get_meta("font_role")
		_check(typography.has_role(role), "%s uses a known typography role" % node.name)
		if typography.is_uniform_body_role(role):
			_check(is_equal_approx(typography.get_role_ratio(role), typography.get_role_ratio("body")), "%s matches the mascot speech font ratio" % node.name)
	for child in node.get_children():
		_check_typography_baseline(child, typography)


func _answer_fill_color(row: Dictionary, state: String = "normal") -> Color:
	var style: StyleBoxFlat = row["button"].get_stylebox(state)
	return style.bg_color


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

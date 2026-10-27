extends Control

const TYPOGRAPHY = preload("res://shared/ui/typography.gd")
const BOTTOM_NAVIGATION = preload("res://shared/ui/bottom_navigation.tscn")
const QUESTION_REPOSITORY = preload("res://games/quiz/scripts/quiz_question_repository.gd")
const DAILY_PROGRESS = preload("res://games/quiz/scripts/quiz_daily_progress.gd")
const BADGE_UNLOCK_POPUP = preload("res://shared/ui/badge_unlock_popup.gd")
const SHIELD_ICON = preload("res://shared/ui/assets/icons/shield_icon.svg")
const ARROW_BACK_ICON = preload("res://shared/ui/assets/icons/arrow_back_icon.svg")
const NAVY = Color("#071126")
const PANEL = Color("#0c1740")
const PANEL_LIGHT = Color("#171e5b")
const CYAN = Color("#19d6d2")
const WHITE = Color("#f3f7ff")
const MUTED = Color("#9aa9ce")
const GREEN = Color("#32bb78")
const RED = Color("#e95b63")
const ANSWER_TEXT = Color("#000000")
const DAILY_LIMIT: int = DAILY_PROGRESS.DAILY_LIMIT
const NON_HOME_TITLE_SCALE: float = 1.10
const MISSION_TITLE_FONT_SCALE: float = 1.15
const EXPLANATION_FONT_SCALE: float = 1.25
const LANDSCAPE_PROGRESS_FONT_SCALE: float = 0.90
const LANDSCAPE_QUESTION_FONT_SCALE: float = 0.90

var ui: Dictionary = {}
var answer_rows: Array = []
var repository = QUESTION_REPOSITORY.new()
var daily_progress = DAILY_PROGRESS.new()
var typography = TYPOGRAPHY.new()
var current_question: Dictionary = {}
var current_question_index: int = -1
var selected_option: int = -1
var answer_submitted: bool = false
var last_answer_was_correct: bool = false
var current_viewport_size := Vector2.ZERO
var explanation_timer: Timer
var progression_service: Node
var badge_popup: CanvasLayer


func _ready() -> void:
	var level_notifications = get_node_or_null("/root/LevelUpNotifications")
	if level_notifications != null:
		level_notifications.call("begin_activity", self)
	progression_service = get_node_or_null("/root/Progression")
	_build_screen()
	get_viewport().connect("size_changed", self, "_on_viewport_size_changed")
	_layout_screen(get_viewport_rect().size)
	if not repository.load_questions():
		_show_error(repository.load_error)
		return
	daily_progress.load_progress(repository.questions.size())
	if not daily_progress.last_error.empty():
		_show_error(daily_progress.last_error)
		return
	_reconcile_correct_answers()
	if daily_progress.can_answer():
		_show_next_question()
	else:
		_show_daily_completion()


func _build_screen() -> void:
	var background := ColorRect.new()
	background.name = "Background"
	background.color = NAVY
	background.anchor_right = 1.0
	background.anchor_bottom = 1.0
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)
	ui["background"] = background

	ui["frame"] = _new_panel("MissionFrame", NAVY, Color("#344776"), 26, 2)
	ui["back"] = _new_button("", "icon")
	ui["back"].connect("pressed", self, "_on_back_pressed")
	var back_icon := TextureRect.new()
	back_icon.name = "ArrowBackIcon"
	back_icon.texture = ARROW_BACK_ICON
	back_icon.expand = true
	back_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	back_icon.modulate = CYAN
	back_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	back_icon.anchor_right = 1.0
	back_icon.anchor_bottom = 1.0
	ui["back"].add_child(back_icon)
	ui["back_icon"] = back_icon
	ui["mission_title"] = _new_label("MISSÃO: ...", CYAN, "body", Label.ALIGN_LEFT)
	ui["mission_title"].set_meta("font_scale", MISSION_TITLE_FONT_SCALE)
	ui["mission_title"].set_meta("title_text", true)
	ui["shield"] = TextureRect.new()
	ui["shield"].texture = SHIELD_ICON
	ui["shield"].expand = true
	ui["shield"].stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ui["shield"].modulate = Color("#f4dc70")
	ui["shield"].mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(ui["shield"])

	ui["progress_panel"] = _new_panel("QuestionProgress", PANEL, Color("#424c91"), 18, 1)
	ui["progress_text"] = _new_label("PERGUNTA 1 DE 5", MUTED, "body", Label.ALIGN_CENTER)
	ui["progress_segments"] = []
	for index in range(DAILY_LIMIT):
		var segment := _new_panel("ProgressSegment%d" % index, PANEL_LIGHT, PANEL_LIGHT, 12, 0)
		ui["progress_segments"].append(segment)

	ui["question"] = _new_label("", WHITE, "body", Label.ALIGN_CENTER)
	ui["instruction"] = _new_label("Toque na opção correta.", CYAN, "body", Label.ALIGN_CENTER)
	for index in range(4):
		var row_button := _new_button("", "body")
		row_button.remove_meta("font_role")
		row_button.name = "AnswerOption%d" % index
		row_button.add_stylebox_override("normal", _stylebox(Color("#f2f6ff"), Color("#d7e3ff"), 16, 1))
		row_button.add_stylebox_override("hover", _stylebox(Color("#e5f8fa"), CYAN, 16, 2))
		row_button.add_stylebox_override("focus", _stylebox(Color("#e5f8fa"), CYAN, 16, 2))
		row_button.add_stylebox_override("pressed", _stylebox(Color("#d8f5f4"), CYAN, 16, 2))
		row_button.add_color_override("font_color", NAVY)
		row_button.connect("pressed", self, "_on_option_pressed", [index])
		var option_label := _new_label("", NAVY, "body", Label.ALIGN_LEFT)
		option_label.name = "OptionText%d" % index
		option_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		remove_child(option_label)
		row_button.add_child(option_label)
		answer_rows.append({"button": row_button, "label": option_label})

	ui["hint_panel"] = _new_panel("SafetyHint", PANEL_LIGHT, Color("#39327a"), 16, 1)
	ui["hint_icon"] = TextureRect.new()
	ui["hint_icon"].texture = SHIELD_ICON
	ui["hint_icon"].expand = true
	ui["hint_icon"].stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ui["hint_icon"].modulate = Color("#f4dc70")
	ui["hint_icon"].mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(ui["hint_icon"])
	ui["hint"] = _new_label("Leia cada opção com atenção antes de confirmar sua resposta.", WHITE, "body")
	ui["confirm"] = _new_button("CONFIRMAR RESPOSTA", "body")
	ui["confirm"].add_stylebox_override("normal", _stylebox(Color("#f06467"), Color("#f06467"), 18, 0))
	ui["confirm"].add_stylebox_override("hover", _stylebox(Color("#ff7779"), WHITE, 18, 1))
	ui["confirm"].add_stylebox_override("focus", _stylebox(Color("#ff7779"), WHITE, 18, 1))
	ui["confirm"].add_color_override("font_color", WHITE)
	ui["confirm"].connect("pressed", self, "_on_confirm_pressed")
	ui["completion_title"] = _new_label("", CYAN, "title", Label.ALIGN_CENTER)
	ui["completion_message"] = _new_label("", WHITE, "body", Label.ALIGN_CENTER)
	ui["status"] = _new_label("", Color("#ffaaa9"), "body", Label.ALIGN_CENTER)
	ui["navigation"] = BOTTOM_NAVIGATION.instance()
	ui["navigation"].active_item = "missions"
	ui["navigation"].visible = false
	ui["navigation"].connect("item_selected", self, "_on_navigation_item_selected")
	add_child(ui["navigation"])

	ui["next_prompt"] = _new_panel("NextQuestionPrompt", PANEL_LIGHT, Color("#5d62a5"), 18, 2)
	ui["next_prompt_title"] = _new_label("Quer ir para a próxima questão?", WHITE, "body", Label.ALIGN_CENTER)
	ui["next_prompt_yes"] = _new_button("SIM, CONTINUAR", "body")
	remove_child(ui["next_prompt_yes"])
	ui["next_prompt_yes"].add_stylebox_override("normal", _stylebox(CYAN, CYAN, 12, 0))
	ui["next_prompt_yes"].add_stylebox_override("hover", _stylebox(Color("#63f0e9"), WHITE, 12, 1))
	ui["next_prompt_yes"].add_color_override("font_color", NAVY)
	ui["next_prompt_yes"].connect("pressed", self, "_on_next_prompt_yes")
	ui["next_prompt_no"] = _new_button("SAIR", "body")
	remove_child(ui["next_prompt_no"])
	ui["next_prompt_no"].add_stylebox_override("normal", _stylebox(PANEL, Color("#747fac"), 12, 1))
	ui["next_prompt_no"].add_stylebox_override("hover", _stylebox(PANEL_LIGHT, WHITE, 12, 1))
	ui["next_prompt_no"].add_color_override("font_color", WHITE)
	ui["next_prompt_no"].connect("pressed", self, "_on_back_pressed")
	remove_child(ui["next_prompt_title"])
	ui["next_prompt"].add_child(ui["next_prompt_title"])
	ui["next_prompt"].add_child(ui["next_prompt_no"])
	ui["next_prompt"].add_child(ui["next_prompt_yes"])
	ui["next_prompt_no"].visible = false
	ui["next_prompt"].visible = false

	ui["explanation_overlay"] = Control.new()
	ui["explanation_overlay"].name = "ExplanationOverlay"
	ui["explanation_overlay"].anchor_right = 1.0
	ui["explanation_overlay"].anchor_bottom = 1.0
	ui["explanation_overlay"].mouse_filter = Control.MOUSE_FILTER_STOP
	ui["explanation_overlay"].connect("gui_input", self, "_on_explanation_overlay_input")
	var dim := ColorRect.new()
	dim.color = Color(0.01, 0.02, 0.08, 0.78)
	dim.anchor_right = 1.0
	dim.anchor_bottom = 1.0
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui["explanation_overlay"].add_child(dim)
	ui["explanation_panel"] = _new_panel("ExplanationPanel", Color("#101d4b"), Color("#34dedb"), 24, 2)
	remove_child(ui["explanation_panel"])
	ui["explanation_panel"].mouse_filter = Control.MOUSE_FILTER_PASS
	ui["explanation_title"] = _new_label("EXPLICAÇÃO", CYAN, "title", Label.ALIGN_CENTER)
	ui["explanation_title"].set_meta("font_scale", EXPLANATION_FONT_SCALE)
	ui["explanation_text"] = _new_label("", WHITE, "body", Label.ALIGN_CENTER)
	ui["explanation_close_hint"] = _new_label("Toque fora ou use o botão para fechar.", MUTED, "body", Label.ALIGN_CENTER)
	ui["explanation_close"] = _new_button("FECHAR", "body")
	ui["explanation_close"].add_stylebox_override("normal", _stylebox(CYAN, CYAN, 12, 0))
	ui["explanation_close"].add_stylebox_override("hover", _stylebox(Color("#63f0e9"), WHITE, 12, 1))
	ui["explanation_close"].add_stylebox_override("focus", _stylebox(Color("#63f0e9"), WHITE, 12, 1))
	ui["explanation_close"].add_color_override("font_color", NAVY)
	ui["explanation_close"].connect("pressed", self, "_dismiss_explanation")
	remove_child(ui["explanation_title"])
	remove_child(ui["explanation_text"])
	remove_child(ui["explanation_close_hint"])
	remove_child(ui["explanation_close"])
	ui["explanation_panel"].add_child(ui["explanation_title"])
	ui["explanation_panel"].add_child(ui["explanation_text"])
	ui["explanation_panel"].add_child(ui["explanation_close_hint"])
	ui["explanation_panel"].add_child(ui["explanation_close"])
	ui["explanation_overlay"].add_child(ui["explanation_panel"])
	add_child(ui["explanation_overlay"])
	ui["explanation_overlay"].visible = false

	explanation_timer = Timer.new()
	explanation_timer.one_shot = true
	explanation_timer.wait_time = 10.0
	explanation_timer.connect("timeout", self, "_on_explanation_timeout")
	add_child(explanation_timer)


func _layout_screen(viewport_size: Vector2) -> void:
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		return
	current_viewport_size = viewport_size
	var width: float = viewport_size.x
	var height: float = viewport_size.y
	var short_side: float = min(width, height)
	var margin: float = short_side * 0.035
	_place(ui["background"], 0.0, 0.0, width, height)
	_place(ui["frame"], margin * 0.35, height * 0.015, width - margin * 0.70, height * 0.97)
	_place(ui["back"], margin, height * 0.077, short_side * 0.12, height * 0.064, short_side)
	_place(ui["mission_title"], margin + short_side * 0.13, height * 0.08, width - margin * 2.0 - short_side * 0.28, height * 0.055, short_side)
	var shield_size: float = short_side * 0.075 * 1.10
	_place(ui["shield"], width - margin - shield_size, height * 0.082, shield_size, shield_size)
	var progress_y: float = height * 0.155
	var progress_h: float = height * 0.082
	_place(ui["progress_panel"], margin, progress_y, width - margin * 2.0, progress_h)
	var progress_font_scale: float = _get_common_content_font_scale(short_side)
	if width > height:
		progress_font_scale *= LANDSCAPE_PROGRESS_FONT_SCALE
	_place(ui["progress_text"], margin * 1.4, progress_y + progress_h * 0.04, width - margin * 2.8, progress_h * 0.34, short_side, progress_font_scale)
	var segment_gap: float = short_side * 0.012
	var segments_width: float = width - margin * 2.0 - short_side * 0.10
	var segment_width: float = (segments_width - segment_gap * 4.0) / 5.0
	for index in range(DAILY_LIMIT):
		_place(ui["progress_segments"][index], margin * 1.4 + segment_width * index + segment_gap * index, progress_y + progress_h * 0.52, segment_width, progress_h * 0.30)

	var question_width: float = width - margin * 3.0
	var question_height: float = height * 0.115
	_place(ui["instruction"], margin * 1.5, height * 0.325, width - margin * 3.0, height * 0.045, short_side)
	var option_top: float = height * 0.385
	var option_height: float = height * 0.091
	var option_gap: float = height * 0.012
	var row_width: float = width - margin * 1.8
	var answer_label_x: float = short_side * 0.015
	var answer_label_width: float = row_width - answer_label_x - short_side * 0.015
	var answer_label_height: float = option_height * 0.92
	var question_font_scale: float = _get_common_content_font_scale(short_side)
	if width > height:
		question_font_scale *= LANDSCAPE_QUESTION_FONT_SCALE
	var answer_font_scale: float = _get_common_content_font_scale(short_side)
	_place(
		ui["question"],
		margin * 1.5,
		height * 0.215,
		question_width,
		question_height,
		short_side,
		question_font_scale
	)
	for index in range(answer_rows.size()):
		var row: Dictionary = answer_rows[index]
		var row_y: float = option_top + float(index) * (option_height + option_gap)
		var row_x: float = margin * 0.9
		_place(row["button"], row_x, row_y, row_width, option_height)
		_place(
			row["label"],
			answer_label_x,
			option_height * 0.04,
			answer_label_width,
			answer_label_height,
			short_side,
			answer_font_scale
		)
	var hint_y: float = height * 0.815
	var hint_height: float = height * 0.072
	_place(ui["hint_panel"], margin * 0.9, hint_y, width - margin * 1.8, hint_height)
	var hint_icon_size: float = min(short_side * 0.075, hint_height * 0.74)
	_place(ui["hint_icon"], margin * 1.35, hint_y + (hint_height - hint_icon_size) * 0.5, hint_icon_size, hint_icon_size)
	_place(ui["hint"], margin * 1.35 + hint_icon_size + short_side * 0.025, hint_y + hint_height * 0.08, width - margin * 2.7 - hint_icon_size - short_side * 0.025, hint_height * 0.84, short_side)
	_place(ui["confirm"], margin * 0.9, height * 0.902, width - margin * 1.8, height * 0.078, short_side)
	_place(ui["completion_title"], margin * 1.5, height * 0.34, width - margin * 3.0, height * 0.09, short_side)
	_place(ui["completion_message"], margin * 1.5, height * 0.44, width - margin * 3.0, height * 0.16, short_side)
	_place(ui["status"], margin, height * 0.875, width - margin * 2.0, height * 0.035, short_side)
	ui["navigation"].rect_size = viewport_size
	ui["navigation"].layout_for_viewport(viewport_size)
	_layout_next_prompt(viewport_size, margin)
	_layout_explanation(viewport_size, margin)


func _layout_next_prompt(viewport_size: Vector2, margin: float) -> void:
	var width: float = viewport_size.x
	var height: float = viewport_size.y
	var prompt_y: float = height * 0.77
	var prompt_height: float = height * 0.20
	_place(ui["next_prompt"], margin, prompt_y, width - margin * 2.0, prompt_height)
	_place(ui["next_prompt_title"], margin * 0.6, prompt_height * 0.08, width - margin * 3.2, prompt_height * 0.30, min(width, height))
	var button_y: float = prompt_height * 0.54
	var button_gap: float = margin * 0.45
	var button_width: float = (width - margin * 2.0 - button_gap * 3.0) / 2.0
	if ui["next_prompt_no"].visible:
		_place(ui["next_prompt_no"], button_gap, button_y, button_width, prompt_height * 0.34, min(width, height))
		_place(ui["next_prompt_yes"], button_gap * 2.0 + button_width, button_y, button_width, prompt_height * 0.34, min(width, height))
	else:
		var combined_button_width: float = button_width * 2.0 + button_gap
		_place(ui["next_prompt_yes"], button_gap, button_y, combined_button_width, prompt_height * 0.34, min(width, height))


func _layout_explanation(viewport_size: Vector2, margin: float) -> void:
	var width: float = min(viewport_size.x * 0.86, min(viewport_size.x, viewport_size.y) * 1.75)
	var height: float = min(viewport_size.y * 0.42, min(viewport_size.x, viewport_size.y) * 1.35)
	var x: float = (viewport_size.x - width) * 0.5
	var y: float = (viewport_size.y - height) * 0.5
	_place(ui["explanation_panel"], x, y, width, height)
	_place(ui["explanation_title"], margin, height * 0.10, width - margin * 2.0, height * 0.18, min(viewport_size.x, viewport_size.y))
	_place(ui["explanation_text"], margin * 1.5, height * 0.28, width - margin * 3.0, height * 0.40, min(viewport_size.x, viewport_size.y))
	_place(ui["explanation_close_hint"], margin, height * 0.70, width - margin * 2.0, height * 0.10, min(viewport_size.x, viewport_size.y))
	_place(ui["explanation_close"], width * 0.28, height * 0.83, width * 0.44, height * 0.13, min(viewport_size.x, viewport_size.y))


func _show_next_question() -> void:
	if not daily_progress.can_answer():
		_show_daily_completion()
		return
	current_question_index = repository.get_random_question_index(daily_progress.answered_question_indices)
	if current_question_index < 0:
		_show_daily_completion()
		return
	current_question = repository.questions[current_question_index]
	selected_option = -1
	answer_submitted = false
	last_answer_was_correct = false
	ui["mission_title"].text = "MISSÃO: " + String(current_question["tema"]).to_upper()
	ui["progress_text"].text = "PERGUNTA %d DE %d" % [daily_progress.get_answered_count() + 1, DAILY_LIMIT]
	for progress_index in range(DAILY_LIMIT):
		var active_segment: bool = progress_index <= daily_progress.get_answered_count()
		ui["progress_segments"][progress_index].add_stylebox_override("panel", _stylebox(CYAN if active_segment else PANEL_LIGHT, CYAN if active_segment else PANEL_LIGHT, 12, 0))
	ui["question"].text = String(current_question["pergunta"])
	ui["completion_title"].visible = false
	ui["completion_message"].visible = false
	ui["back"].visible = true
	ui["navigation"].visible = false
	ui["next_prompt"].visible = false
	ui["question"].visible = true
	ui["instruction"].visible = true
	ui["hint_panel"].visible = true
	ui["hint_icon"].visible = true
	ui["hint"].visible = true
	ui["confirm"].visible = true
	ui["confirm"].disabled = false
	ui["status"].text = ""
	var options: Array = current_question["opcoes"]
	for index in range(answer_rows.size()):
		var row: Dictionary = answer_rows[index]
		var button: Button = row["button"]
		var default_style := _stylebox(Color("#ffffff"), Color("#d7e3ff"), 16, 1)
		if index < options.size():
			button.show()
			button.disabled = false
			row["label"].text = String(options[index])
			row["label"].add_color_override("font_color", NAVY)
			for state in ["normal", "hover", "focus", "pressed", "disabled"]:
				button.add_stylebox_override(state, default_style)
		else:
			button.hide()
	if current_viewport_size.x > 0.0 and current_viewport_size.y > 0.0:
		_layout_screen(current_viewport_size)
	answer_rows[0]["button"].grab_focus()


func _on_option_pressed(option_index: int) -> void:
	if answer_submitted or option_index < 0 or option_index >= current_question.get("opcoes", []).size():
		return
	selected_option = option_index
	for index in range(answer_rows.size()):
		var button: Button = answer_rows[index]["button"]
		var fill_color: Color = Color("#dff8f6") if index == selected_option else Color("#ffffff")
		var border_color: Color = CYAN if index == selected_option else Color("#d7e3ff")
		var style := _stylebox(fill_color, border_color, 16, 2 if index == selected_option else 1)
		for state in ["normal", "hover", "focus", "pressed", "disabled"]:
			button.add_stylebox_override(state, style)


func _on_confirm_pressed() -> void:
	if answer_submitted or selected_option < 0:
		return
	var correct_index: int = int(current_question["respostaCorreta"])
	var was_correct: bool = selected_option == correct_index
	last_answer_was_correct = was_correct
	if not daily_progress.record_answer(current_question_index, repository.questions.size(), was_correct):
		ui["status"].text = daily_progress.last_error if not daily_progress.last_error.empty() else "Não foi possível registrar sua resposta. Tente novamente."
		return
	answer_submitted = true
	if was_correct:
		_record_correct_answer(current_question_index)
	if daily_progress.get_answered_count() >= DAILY_LIMIT:
		_finalize_quiz_session()
	for index in range(answer_rows.size()):
		var row: Dictionary = answer_rows[index]
		var button: Button = row["button"]
		button.disabled = true
		row["label"].add_color_override("font_color", ANSWER_TEXT)
		if index == correct_index:
			_set_answer_feedback_style(button, GREEN)
		elif index == selected_option:
			_set_answer_feedback_style(button, RED)
		else:
			_set_answer_default_style(button)
	ui["confirm"].disabled = true
	ui["progress_text"].text = "PERGUNTAS RESPONDIDAS: %d DE %d" % [daily_progress.get_answered_count(), DAILY_LIMIT]
	for index in range(DAILY_LIMIT):
		ui["progress_segments"][index].add_stylebox_override("panel", _stylebox(CYAN if index < daily_progress.get_answered_count() else PANEL_LIGHT, CYAN if index < daily_progress.get_answered_count() else PANEL_LIGHT, 12, 0))
	if selected_option != correct_index:
		ui["explanation_text"].text = String(current_question["explicacao"])
		ui["explanation_overlay"].visible = true
		explanation_timer.start(10.0)
		_layout_screen(current_viewport_size)
		ui["explanation_close"].grab_focus()
	else:
		_show_next_prompt()


func _on_explanation_overlay_input(event: InputEvent) -> void:
	var position := Vector2(-1, -1)
	if event is InputEventMouseButton and event.pressed and event.button_index == BUTTON_LEFT:
		position = (event as InputEventMouseButton).position
	elif event is InputEventScreenTouch and event.pressed:
		position = (event as InputEventScreenTouch).position
	if position.x >= 0.0 and not ui["explanation_panel"].get_global_rect().has_point(position):
		_dismiss_explanation()
		ui["explanation_overlay"].accept_event()


func _on_explanation_timeout() -> void:
	_dismiss_explanation()


func handle_back_request() -> bool:
	if ui["explanation_overlay"].visible:
		_dismiss_explanation()
		return true
	return false


func _dismiss_explanation() -> void:
	if not ui["explanation_overlay"].visible:
		return
	explanation_timer.stop()
	ui["explanation_overlay"].visible = false
	_show_next_prompt()


func _show_next_prompt() -> void:
	var has_more_questions: bool = daily_progress.can_answer()
	if has_more_questions:
		ui["next_prompt_title"].text = "Acertou!!!" if last_answer_was_correct else "Que pena!"
		ui["next_prompt_title"].add_color_override("font_color", GREEN if last_answer_was_correct else RED)
		ui["next_prompt_yes"].text = "SIM, CONTINUAR"
	else:
		ui["next_prompt_title"].text = "Você respondeu todas as perguntas de hoje.\nDeseja ver a conclusão?"
		ui["next_prompt_title"].add_color_override("font_color", WHITE)
		ui["next_prompt_yes"].text = "Continuar"
	ui["next_prompt_no"].visible = has_more_questions
	ui["next_prompt"].visible = true
	_layout_screen(current_viewport_size)
	ui["next_prompt_yes"].grab_focus()


func _set_answer_feedback_style(button: Button, color: Color) -> void:
	var feedback_style := _stylebox(color, color, 16, 2)
	for state in ["normal", "hover", "focus", "pressed", "disabled"]:
		button.add_stylebox_override(state, feedback_style)


func _set_answer_default_style(button: Button) -> void:
	var default_style := _stylebox(Color("#ffffff"), Color("#d7e3ff"), 16, 1)
	for state in ["normal", "hover", "focus", "pressed", "disabled"]:
		button.add_stylebox_override(state, default_style)


func _on_next_prompt_yes() -> void:
	if daily_progress.can_answer():
		_show_next_question()
	else:
		_show_daily_completion()


func _show_daily_completion() -> void:
	var points_saved: bool = _finalize_quiz_session()
	ui["next_prompt"].visible = false
	ui["question"].visible = false
	ui["instruction"].visible = false
	ui["hint_panel"].visible = false
	ui["hint_icon"].visible = false
	ui["hint"].visible = false
	ui["confirm"].visible = false
	for row in answer_rows:
		row["button"].visible = false
	ui["completion_title"].text = "MISSÃO CONCLUÍDA POR HOJE"
	ui["completion_message"].text = (
		"As perguntas de hoje foram respondidas.\nVolte amanhã para mais!"
		if points_saved
		else "Não foi possível salvar os pontos agora.\nReabra a missão para tentar novamente."
	)
	ui["completion_title"].visible = true
	ui["completion_message"].visible = true
	ui["back"].visible = false
	ui["navigation"].visible = true
	ui["progress_text"].text = "5 DE 5 PERGUNTAS RESPONDIDAS"
	for index in range(DAILY_LIMIT):
		ui["progress_segments"][index].add_stylebox_override("panel", _stylebox(CYAN, CYAN, 12, 0))
	ui["navigation"].buttons["missions"].grab_focus()
	var level_notifications = get_node_or_null("/root/LevelUpNotifications")
	if level_notifications != null:
		level_notifications.call("mark_completion_visible", self)
	_show_next_pending_badge_notification()


func _record_correct_answer(question_index: int) -> void:
	if progression_service == null:
		push_error("O serviço de progressão não está disponível; o acerto será reconciliado ao reabrir o quiz.")
		return
	var answer_id: String = "%s:%d" % [daily_progress.date_key, question_index]
	if not progression_service.record_quiz_correct_answer(answer_id):
		push_error("Não foi possível salvar o acerto do quiz; ele será reconciliado ao reabrir a missão.")


func _reconcile_correct_answers() -> void:
	if progression_service == null:
		return
	for question_index in daily_progress.correct_question_indices:
		_record_correct_answer(int(question_index))


func _finalize_quiz_session() -> bool:
	if progression_service == null:
		return false
	return progression_service.complete_quiz_session(daily_progress.date_key, daily_progress.get_correct_count())


func _show_next_pending_badge_notification() -> void:
	if not ui.has("completion_title") or not ui["completion_title"].visible:
		return
	if progression_service == null or badge_popup != null:
		return
	var notifications: Array = progression_service.get_pending_badge_notifications()
	if notifications.empty():
		return
	badge_popup = BADGE_UNLOCK_POPUP.new()
	badge_popup.connect("dismissed", self, "_on_badge_popup_dismissed")
	add_child(badge_popup)
	if not badge_popup.present(notifications[0]):
		badge_popup.queue_free()
		badge_popup = null


func _on_badge_popup_dismissed(event_id: String) -> void:
	var acknowledged: bool = progression_service != null and progression_service.acknowledge_badge_notification(event_id)
	if badge_popup != null:
		badge_popup.queue_free()
		badge_popup = null
	if acknowledged:
		call_deferred("_show_next_pending_badge_notification")


func _show_error(message: String) -> void:
	ui["question"].visible = false
	ui["instruction"].visible = false
	ui["hint_panel"].visible = false
	ui["hint_icon"].visible = false
	ui["hint"].visible = false
	ui["confirm"].visible = false
	for row in answer_rows:
		row["button"].visible = false
	ui["completion_title"].text = "NÃO FOI POSSÍVEL ABRIR A MISSÃO"
	ui["completion_message"].text = message
	ui["completion_title"].visible = true
	ui["completion_message"].visible = true
	ui["back"].visible = true
	ui["navigation"].visible = false
	ui["back"].grab_focus()


func _on_back_pressed() -> void:
	get_node("/root/NavigationHistory").call("go_back")


func _on_navigation_item_selected(item_id: String) -> void:
	var destinations := {
		"home": "res://app/menus/home_screen.tscn",
		"map": "res://app/menus/map_screen.tscn",
		"missions": "res://games/quiz/scenes/quiz_screen.tscn",
		"profile": "res://app/menus/profile_screen.tscn"
	}
	if not destinations.has(item_id) or item_id == "missions":
		return
	get_node("/root/NavigationHistory").call("navigate_to", destinations[item_id])


func _on_viewport_size_changed() -> void:
	_layout_screen(get_viewport_rect().size)


func _new_label(text: String, color: Color, role: String, alignment: int = Label.ALIGN_LEFT) -> Label:
	var label := Label.new()
	label.text = text
	label.align = alignment
	label.valign = Label.VALIGN_CENTER
	label.autowrap = true
	label.clip_text = true
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_color_override("font_color", color)
	label.set_meta("font_role", role)
	add_child(label)
	return label


func _new_button(text: String, role: String) -> Button:
	var button := Button.new()
	button.text = text
	button.focus_mode = Control.FOCUS_ALL
	button.set_meta("font_role", role)
	button.add_stylebox_override("normal", _stylebox(PANEL, PANEL, 12, 0))
	button.add_stylebox_override("hover", _stylebox(PANEL_LIGHT, CYAN, 12, 1))
	button.add_stylebox_override("focus", _stylebox(PANEL_LIGHT, CYAN, 12, 1))
	button.add_color_override("font_color", WHITE)
	add_child(button)
	return button


func _new_panel(node_name: String, fill: Color, border: Color, radius: int, border_width: int) -> Panel:
	var panel := Panel.new()
	panel.name = node_name
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_stylebox_override("panel", _stylebox(fill, border, radius, border_width))
	add_child(panel)
	return panel


func _stylebox(fill: Color, border: Color, radius: int, border_width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(radius)
	return style


func _get_common_content_font_scale(font_basis: float) -> float:
	var content_font: Font = typography.get_base_font(ui["question"])
	if content_font == null:
		return 1.0
	return typography.get_target_height("body", font_basis) / content_font.get_height()


func _place(
	control: Control,
	x: float,
	y: float,
	width: float,
	height: float,
	font_basis: float = 720.0,
	scale_override: float = -1.0
) -> void:
	var scale: float = 1.0
	if control.has_meta("font_role"):
		var font: Font = typography.get_base_font(control)
		var role: String = control.get_meta("font_role")
		if font != null and typography.has_role(role):
			var font_scale: float = 1.0
			if control.has_meta("font_scale") and (control.has_meta("title_text") or not typography.is_uniform_body_role(role)):
				font_scale = float(control.get_meta("font_scale"))
			var target_role: String = role
			if typography.is_uniform_body_role(role) and not control.has_meta("title_text"):
				target_role = "body"
			var target_height: float = typography.get_target_height(target_role, font_basis) * font_scale
			if control.has_meta("title_text") or typography.is_title_role(role):
				target_height *= NON_HOME_TITLE_SCALE
			scale = target_height / font.get_height()
			if not typography.is_uniform_body_role(role) or control.has_meta("title_text"):
				scale = min(scale, _fit_text_scale(control, font, width, height, scale))
	if scale_override > 0.0:
		scale = scale_override
	if control.has_meta("font_role"):
		typography.apply_font_scale(control, scale)
	control.anchor_left = 0.0
	control.anchor_top = 0.0
	control.anchor_right = 0.0
	control.anchor_bottom = 0.0
	control.rect_scale = Vector2.ONE
	control.margin_left = x
	control.margin_top = y
	control.margin_right = x + width
	control.margin_bottom = y + height


func _fit_text_scale(control: Control, font: Font, width: float, height: float, maximum_scale: float = 1.0) -> float:
	var text: String = ""
	if control is Label:
		text = (control as Label).text
	elif control is Button:
		text = (control as Button).text
	return _fit_text_string_scale(text, font, width, height, maximum_scale)


func _fit_text_string_scale(
	text: String,
	font: Font,
	width: float,
	height: float,
	maximum_scale: float
) -> float:
	var fitting_scale: float = 0.01
	var non_fitting_scale: float = maximum_scale
	for iteration in range(14):
		var candidate_scale: float = (fitting_scale + non_fitting_scale) * 0.5
		if _text_fits_at_scale(text, font, width, height, candidate_scale):
			fitting_scale = candidate_scale
		else:
			non_fitting_scale = candidate_scale
	return fitting_scale


func _text_fits_at_scale(
	text: String,
	font: Font,
	width: float,
	height: float,
	scale: float
) -> bool:
	var total_lines: int = 0
	for explicit_line in text.split("\n"):
		var line_width: float = 0.0
		total_lines += 1
		for word in explicit_line.split(" "):
			if word.empty():
				continue
			var word_width: float = font.get_string_size(word).x * scale
			if word_width > width:
				return false
			var space_width: float = font.get_string_size(" ").x * scale if line_width > 0.0 else 0.0
			if line_width > 0.0 and line_width + space_width + word_width > width:
				total_lines += 1
				line_width = word_width
			else:
				line_width += space_width + word_width
	return font.get_height() * scale * total_lines <= height

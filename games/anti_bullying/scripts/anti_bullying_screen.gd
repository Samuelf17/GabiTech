extends Control

const TYPOGRAPHY = preload("res://shared/ui/typography.gd")
const SITUATION_REPOSITORY = preload("res://games/anti_bullying/scripts/situation_repository.gd")
const BACKGROUND_TEXTURE = preload("res://shared/ui/assets/backgrounds/fundo.png")
const RESPECT_BADGE_TEXTURE = preload("res://shared/progress/assets/badges/respect.png")
const BACK_ICON = preload("res://shared/ui/assets/icons/arrow_back_icon.svg")
const MAP_SCENE_PATH = "res://app/menus/map_screen.tscn"
const BADGE_UNLOCK_POPUP = preload("res://shared/ui/badge_unlock_popup.gd")
const PANEL = Color("#142436")
const GREEN_BUBBLE = Color("#006b5b")
const WHITE = Color("#f3f7ff")
const CYAN = Color("#55e8e2")
const MUTED = Color("#afbddc")
const GREEN = Color("#75e6a6")
const RED = Color("#ff858a")
const TYPOGRAPHY_ROLE_MAP = {"small": "challenge", "chat_title": "heading", "answer": "body"}
const SPEAKER_COLORS = {
	"Leo": Color("#8ecbff"), "Nina": Color("#f2a0d2"),
	"Bia": Color("#c7a5ff"), "Caio": Color("#7de0df"),
	"Rafa": Color("#ffd166"), "Júlia": Color("#ff9f91"),
	"Duda": Color("#d1a4ff"), "Pedro": Color("#a5e887"),
	"Gui": Color("#ffc46b"), "Lara": Color("#ff9ec4")
}

var ui: Dictionary = {}
var incoming_bubbles: Array = []
var answer_buttons: Array = []
var answer_labels: Array = []
var repository = SITUATION_REPOSITORY.new()
var selected_situations: Array = []
var speaker_colors: Dictionary = {}
var typography = TYPOGRAPHY.new()
var situation_index: int = 0
var correct_choices: int = 0
var phase: String = "choosing"
var current_viewport_size := Vector2.ZERO
var badge_popup: CanvasLayer
var round_id: String = ""
var round_xp_earned: int = 0
var round_xp_lost: int = 0
var round_xp_applied: int = 0


func _ready() -> void:
	var level_notifications = get_node_or_null("/root/LevelUpNotifications")
	if level_notifications != null:
		level_notifications.call("begin_activity", self)
	_build_screen()
	get_viewport().connect("size_changed", self, "_on_viewport_size_changed")
	if repository.load_situations():
		_build_speaker_colors()
		_start_round()
		_show_situation()
		_show_intro_popup()
	else:
		ui["incoming_bubbles"][0]["label"].text = repository.load_error
		ui["status"].text = "conteúdo indisponível"
	_layout_screen(get_viewport_rect().size)


func _build_screen() -> void:
	var background := TextureRect.new()
	background.name = "CircuitChatBackground"
	background.texture = BACKGROUND_TEXTURE
	background.expand = true
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.anchor_right = 1.0
	background.anchor_bottom = 1.0
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)
	ui["background"] = background

	var overlay := ColorRect.new()
	overlay.name = "ChatBackgroundShade"
	overlay.color = Color(0.015, 0.035, 0.07, 0.30)
	overlay.anchor_right = 1.0
	overlay.anchor_bottom = 1.0
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(overlay)
	ui["overlay"] = overlay
	ui["completion_overlay"] = ColorRect.new()
	ui["completion_overlay"].name = "CompletionBackdrop"
	ui["completion_overlay"].color = Color(0.01, 0.025, 0.06, 0.78)
	ui["completion_overlay"].anchor_right = 1.0
	ui["completion_overlay"].anchor_bottom = 1.0
	ui["completion_overlay"].mouse_filter = Control.MOUSE_FILTER_STOP
	ui["completion_overlay"].visible = false
	add_child(ui["completion_overlay"])

	ui["status_bar"] = _new_label("MISSÃO EDUCATIVA", MUTED, "small", Label.ALIGN_LEFT)
	ui["header"] = _new_panel("ChatHeader", Color("#0a1725"), Color("#0a1725"))
	ui["back"] = _new_button("", "button")
	ui["back"].connect("pressed", self, "_on_back_pressed")
	var back_icon := TextureRect.new()
	back_icon.name = "BackIcon"
	back_icon.texture = BACK_ICON
	back_icon.expand = true
	back_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	back_icon.modulate = WHITE
	back_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	back_icon.anchor_right = 1.0
	back_icon.anchor_bottom = 1.0
	ui["back"].add_child(back_icon)
	ui["back_icon"] = back_icon

	ui["chat_avatar"] = TextureRect.new()
	ui["chat_avatar"].name = "RespectBadgeAvatar"
	ui["chat_avatar"].texture = RESPECT_BADGE_TEXTURE
	ui["chat_avatar"].expand = true
	ui["chat_avatar"].stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ui["chat_avatar"].mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(ui["chat_avatar"])
	ui["chat_title"] = _new_label("Chat da turma", WHITE, "chat_title", Label.ALIGN_LEFT)
	ui["status"] = _new_label("• online", GREEN, "small", Label.ALIGN_LEFT)
	ui["status"].set_meta("font_scale_multiplier", 1.20 * 1.15)
	ui["more"] = _new_label("...", WHITE, "chat_title", Label.ALIGN_CENTER)
	ui["progress"] = _new_label("", MUTED, "small", Label.ALIGN_CENTER)
	ui["instruction"] = _new_label("Escolha como agir nesta conversa", WHITE, "small", Label.ALIGN_LEFT)
	ui["instruction"].set_meta("font_scale_multiplier", 1.15)

	ui["incoming_bubbles"] = []
	for index in range(2):
		var bubble := _create_chat_message("IncomingMessage%d" % index)
		incoming_bubbles.append(bubble)
		ui["incoming_bubbles"].append(bubble)
	ui["outgoing"] = _create_bubble("ChosenAction", GREEN_BUBBLE, WHITE, "answer", Label.ALIGN_LEFT)
	_set_bubble_visible(ui["outgoing"], false)
	ui["feedback"] = _create_bubble("ConsequenceMessage", PANEL, WHITE, "body", Label.ALIGN_LEFT)
	_set_bubble_visible(ui["feedback"], false)
	ui["end_message"] = _create_bubble("LearningMessage", PANEL, WHITE, "body", Label.ALIGN_LEFT)
	_set_bubble_visible(ui["end_message"], false)
	ui["end_mascot"] = TextureRect.new()
	ui["end_mascot"].name = "CompletionCapybara"
	ui["end_mascot"].texture = preload("res://shared/mascot/levels/1.png")
	ui["end_mascot"].expand = true
	ui["end_mascot"].stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ui["end_mascot"].mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui["end_mascot"].visible = false
	add_child(ui["end_mascot"])

	for index in range(SITUATION_REPOSITORY.OPTIONS_PER_SITUATION):
		var answer := _new_button("", "button")
		answer.name = "ActionOption%d" % index
		answer.add_stylebox_override("normal", _stylebox(GREEN_BUBBLE, GREEN_BUBBLE, 18, 0))
		answer.add_stylebox_override("hover", _stylebox(Color("#078472"), CYAN, 18, 2))
		answer.add_stylebox_override("focus", _stylebox(Color("#078472"), CYAN, 18, 2))
		answer.add_stylebox_override("pressed", _stylebox(Color("#055c51"), CYAN, 18, 2))
		answer.connect("pressed", self, "_on_answer_pressed", [index])
		answer_buttons.append(answer)
		var answer_label := _new_label("", WHITE, "answer", Label.ALIGN_LEFT)
		answer_label.name = "ActionText%d" % index
		remove_child(answer_label)
		answer.add_child(answer_label)
		answer_labels.append(answer_label)

	ui["continue"] = _new_button("CONTINUAR", "button")
	ui["continue"].connect("pressed", self, "_on_continue_pressed")
	ui["continue"].visible = false
	ui["restart"] = _new_button("JOGAR NOVAMENTE", "button")
	ui["restart"].connect("pressed", self, "_on_restart_pressed")
	ui["restart"].visible = false
	ui["return_to_map"] = _new_button("VOLTAR PARA O MAPA", "button")
	ui["return_to_map"].connect("pressed", self, "_on_map_pressed")
	ui["return_to_map"].visible = false

	ui["composer"] = _new_panel("MessageComposer", Color("#162838"), Color("#24384b"))
	ui["composer_text"] = _new_label("Escolha uma resposta acima...", MUTED, "small", Label.ALIGN_LEFT)
	ui["composer_text"].set_meta("font_scale_multiplier", 1.15)
	ui["send_button"] = _new_button(">", "button")
	var send_button_style: StyleBoxFlat = _stylebox(Color("#008b6d"), Color("#008b6d"), 32, 0)
	ui["send_button"].add_stylebox_override("disabled", send_button_style)
	ui["send_button"].add_color_override("font_color_disabled", WHITE)
	ui["send_button"].disabled = true
	ui["status_bar"].visible = true

	_build_intro_popup()


func _build_intro_popup() -> void:
	ui["intro_backdrop"] = ColorRect.new()
	ui["intro_backdrop"].name = "AntiBullyingIntroBackdrop"
	ui["intro_backdrop"].color = Color(0.0, 0.0, 0.0, 0.82)
	ui["intro_backdrop"].anchor_right = 1.0
	ui["intro_backdrop"].anchor_bottom = 1.0
	ui["intro_backdrop"].mouse_filter = Control.MOUSE_FILTER_STOP
	ui["intro_backdrop"].visible = false
	add_child(ui["intro_backdrop"])
	ui["intro_panel"] = _new_panel("AntiBullyingIntroPanel", Color("#0a1725"), Color("#2675d8"))
	ui["intro_title"] = _new_label("Como funciona", WHITE, "chat_title", Label.ALIGN_CENTER)
	ui["intro_message"] = _new_label(
		"Você verá 5 situações sorteadas. Leia a conversa, escolha uma atitude e veja a consequência e o aprendizado. Respostas respeitosas ajudam a proteger quem precisa.",
		MUTED,
		"body",
		Label.ALIGN_CENTER
	)
	ui["intro_close"] = _new_button("FECHAR TUTORIAL", "button")
	ui["intro_close"].connect("pressed", self, "_on_intro_close_pressed")
	for key in ["intro_panel", "intro_title", "intro_message", "intro_close"]:
		ui[key].visible = false


func _create_bubble(bubble_name: String, fill: Color, text_color: Color, role: String, alignment: int) -> Dictionary:
	var panel := _new_panel(bubble_name, fill, fill)
	var label := _new_label("", text_color, role, alignment)
	return {"panel": panel, "label": label}


func _create_chat_message(bubble_name: String) -> Dictionary:
	var panel := _new_panel(bubble_name, PANEL, PANEL)
	var speaker := _new_label("", WHITE, "body", Label.ALIGN_LEFT)
	var body := _new_label("", WHITE, "body", Label.ALIGN_LEFT)
	return {"panel": panel, "speaker": speaker, "body": body}


func _set_bubble_visible(bubble: Dictionary, is_visible: bool) -> void:
	bubble["panel"].visible = is_visible
	if bubble.has("label"):
		bubble["label"].visible = is_visible
	if bubble.has("speaker"):
		bubble["speaker"].visible = is_visible
	if bubble.has("body"):
		bubble["body"].visible = is_visible


func _show_situation() -> void:
	phase = "choosing"
	var situation: Dictionary = selected_situations[situation_index]
	ui["progress"].text = "SITUAÇÃO %d DE %d" % [situation_index + 1, selected_situations.size()]
	ui["status"].text = "• online"
	ui["instruction"].visible = true
	ui["completion_overlay"].visible = false
	ui["end_mascot"].visible = false
	ui["end_message"]["panel"].visible = false
	ui["end_message"]["label"].visible = false
	for key in ["status_bar", "header", "back", "chat_avatar", "chat_title", "status", "more", "progress", "composer", "composer_text", "send_button"]:
		ui[key].visible = true
	for index in range(incoming_bubbles.size()):
		var bubble: Dictionary = incoming_bubbles[index]
		var message: Dictionary = situation["conversation"][index]
		bubble["speaker"].text = message["speaker"]
		bubble["speaker"].add_color_override("font_color", speaker_colors.get(message["speaker"], CYAN))
		bubble["body"].text = message["text"]
		_set_bubble_visible(bubble, true)
	_set_bubble_visible(ui["outgoing"], false)
	_set_bubble_visible(ui["feedback"], false)
	_set_bubble_visible(ui["end_message"], false)
	ui["continue"].visible = false
	ui["restart"].visible = false
	ui["return_to_map"].visible = false
	ui["composer_text"].text = "Escolha uma resposta acima..."
	for index in range(answer_buttons.size()):
		answer_labels[index].text = situation["options"][index]["text"]
		answer_buttons[index].visible = true
		answer_buttons[index].disabled = false
	_apply_phase_layout()


func _on_answer_pressed(option_index: int) -> void:
	if phase != "choosing" or situation_index >= selected_situations.size():
		return
	var situation: Dictionary = selected_situations[situation_index]
	var option: Dictionary = situation["options"][option_index]
	var is_correct: bool = _is_option_correct(option)
	if is_correct:
		correct_choices += 1
	phase = "feedback"
	ui["instruction"].visible = false
	ui["outgoing"]["label"].text = option["text"]
	_set_bubble_visible(ui["outgoing"], true)
	ui["feedback"]["label"].text = "%s\n\nAprendizado: %s" % [option["consequence"], situation["explanation"]]
	ui["feedback"]["label"].add_color_override("font_color", WHITE if is_correct else RED)
	_set_bubble_visible(ui["feedback"], true)
	for answer in answer_buttons:
		answer.visible = false
	ui["continue"].text = "CONTINUAR"
	ui["continue"].visible = true
	ui["composer_text"].text = "Resposta enviada"
	_apply_phase_layout()


func _is_option_correct(option: Dictionary) -> bool:
	return option.get("correct", false) == true


func _on_continue_pressed() -> void:
	if phase != "feedback":
		return
	situation_index += 1
	if situation_index >= selected_situations.size():
		_show_completion()
	else:
		_show_situation()


func _show_completion() -> void:
	phase = "finished"
	round_xp_earned = correct_choices * 100
	round_xp_lost = (selected_situations.size() - correct_choices) * 20
	var progression = get_node_or_null("/root/Progression")
	if progression != null:
		if not progression.call("complete_anti_bullying_round", round_id, correct_choices, selected_situations.size()):
			push_error("Não foi possível salvar a progressão da rodada Anti-Bullying.")
		else:
			round_xp_applied = max(0, round_xp_earned - round_xp_lost)
	ui["progress"].text = "MISSÃO CONCLUÍDA"
	ui["status"].text = "• conversa encerrada"
	for key in ["status_bar", "header", "back", "chat_avatar", "chat_title", "status", "more", "progress", "instruction", "composer", "composer_text", "send_button"]:
		ui[key].visible = false
	for bubble in incoming_bubbles:
		_set_bubble_visible(bubble, false)
	_set_bubble_visible(ui["outgoing"], false)
	_set_bubble_visible(ui["feedback"], false)
	ui["end_message"]["label"].text = "Respeito também é agir com empatia. Apoie quem precisa, não espalhe ofensas e peça ajuda a um adulto de confiança.\n\nVocê escolheu atitudes respeitosas em %d situações.\n\nXP ganho bruto: +%d\nXP perdido bruto: -%d\nXP aplicado ao perfil: +%d" % [correct_choices, round_xp_earned, round_xp_lost, round_xp_applied]
	_set_bubble_visible(ui["end_message"], true)
	ui["end_mascot"].visible = true
	ui["completion_overlay"].visible = true
	for answer in answer_buttons:
		answer.visible = false
	ui["continue"].visible = false
	ui["restart"].visible = true
	ui["return_to_map"].visible = true
	ui["composer_text"].text = "Missão concluída"
	_apply_phase_layout()
	var level_notifications = get_node_or_null("/root/LevelUpNotifications")
	if level_notifications != null:
		level_notifications.call("mark_completion_visible", self)
	_show_next_pending_badge_notification()


func _show_intro_popup() -> void:
	phase = "intro"
	ui["intro_backdrop"].visible = true
	for key in ["intro_panel", "intro_title", "intro_message", "intro_close"]:
		ui[key].visible = true
	_layout_screen(current_viewport_size)
	ui["intro_close"].grab_focus()


func _on_intro_close_pressed() -> void:
	if phase != "intro":
		return
	ui["intro_backdrop"].visible = false
	for key in ["intro_panel", "intro_title", "intro_message", "intro_close"]:
		ui[key].visible = false
	_show_situation()
	if not answer_buttons.empty():
		answer_buttons[0].grab_focus()


func _on_restart_pressed() -> void:
	_start_round()
	_show_situation()


func _start_round() -> void:
	var level_notifications = get_node_or_null("/root/LevelUpNotifications")
	if level_notifications != null:
		level_notifications.call("begin_activity", self)
	situation_index = 0
	correct_choices = 0
	round_xp_earned = 0
	round_xp_lost = 0
	round_xp_applied = 0
	round_id = "anti_bullying:%d:%d:%d" % [OS.get_unix_time(), OS.get_ticks_msec(), randi()]
	selected_situations = repository.select_random_situations(SITUATION_REPOSITORY.SITUATIONS_PER_GAME)
	if selected_situations.size() < SITUATION_REPOSITORY.SITUATIONS_PER_GAME:
		phase = "finished"
		ui["status"].text = "conteúdo indisponível"
		return


func _show_next_pending_badge_notification() -> void:
	if phase != "finished":
		return
	var progression = get_node_or_null("/root/Progression")
	if progression == null or badge_popup != null:
		return
	var notifications: Array = progression.call("get_pending_badge_notifications")
	if notifications.empty():
		return
	badge_popup = BADGE_UNLOCK_POPUP.new()
	badge_popup.connect("dismissed", self, "_on_badge_popup_dismissed")
	add_child(badge_popup)
	if not badge_popup.present(notifications[0]):
		badge_popup.queue_free()
		badge_popup = null


func _on_badge_popup_dismissed(event_id: String) -> void:
	var progression = get_node_or_null("/root/Progression")
	var acknowledged: bool = progression != null and progression.call("acknowledge_badge_notification", event_id)
	if badge_popup != null:
		badge_popup.queue_free()
		badge_popup = null
	if acknowledged:
		call_deferred("_show_next_pending_badge_notification")


func _build_speaker_colors() -> void:
	speaker_colors = SPEAKER_COLORS.duplicate()
	var unknown_speakers: Dictionary = {}
	for situation in repository.situations:
		for message in situation["conversation"]:
			var speaker: String = message["speaker"]
			if not speaker_colors.has(speaker):
				unknown_speakers[speaker] = true
	var names: Array = unknown_speakers.keys()
	names.sort()
	for index in range(names.size()):
		speaker_colors[names[index]] = Color.from_hsv(float(index) / max(1, names.size()), 0.62, 0.96)


func _on_map_pressed() -> void:
	get_node("/root/NavigationHistory").call("return_to", MAP_SCENE_PATH)


func _apply_phase_layout() -> void:
	if current_viewport_size.x > 0.0 and current_viewport_size.y > 0.0:
		_layout_screen(current_viewport_size)


func _layout_screen(viewport_size: Vector2) -> void:
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		return
	current_viewport_size = viewport_size
	var width: float = viewport_size.x
	var height: float = viewport_size.y
	var short_side: float = min(width, height)
	var landscape: bool = width > height
	var safe: float = short_side * 0.04
	_place(ui["status_bar"], safe, height * 0.012, width - safe * 2.0, height * 0.03, short_side)
	_place(ui["header"], 0.0, height * 0.05, width, height * 0.105)
	var header_height: float = height * 0.075
	var header_y: float = height * 0.065
	var back_x: float = safe * 0.45
	_place(ui["back"], back_x, header_y, header_height, header_height)
	var avatar_x: float = width * 0.15
	var header_text_x: float = width * 0.25
	var header_text_width: float = width * 0.60
	if not landscape:
		var header_gap: float = width * 0.025
		avatar_x = back_x + header_height + header_gap
		header_text_x = avatar_x + header_height + header_gap
		header_text_width = width * 0.90 - header_text_x
	_place(ui["chat_avatar"], avatar_x, header_y, header_height, header_height)
	_place(ui["chat_title"], header_text_x, header_y + header_height * 0.08, header_text_width, header_height * 0.50, short_side)
	_place(ui["status"], header_text_x, header_y + header_height * 0.56, header_text_width, header_height * 0.34, short_side)
	_place(ui["more"], width * 0.90, header_y, width * 0.07, header_height, short_side)
	_place(ui["progress"], safe, height * 0.16, width - safe * 2.0, height * 0.035, short_side)
	_place(ui["composer"], safe * 0.6, height * 0.905, width - safe * 1.2, height * 0.075)
	_place(ui["composer_text"], safe * 1.6, height * 0.916, width - safe * 4.7, height * 0.052, short_side)
	var send_size: float = height * 0.065
	_place(ui["send_button"], width - safe * 1.75 - send_size, height * 0.91, send_size, send_size, short_side)

	if landscape:
		_layout_landscape(width, height, short_side, safe)
	else:
		_layout_portrait(width, height, short_side, safe)
	_layout_intro_popup(width, height, short_side, landscape)


func _layout_intro_popup(width: float, height: float, short_side: float, landscape: bool) -> void:
	var panel_width: float = width * (0.62 if landscape else 0.88)
	var panel_height: float = height * (0.68 if landscape else 0.44)
	var panel_x: float = (width - panel_width) * 0.5
	var panel_y: float = (height - panel_height) * 0.5
	_place(ui["intro_panel"], panel_x, panel_y, panel_width, panel_height)
	_place(ui["intro_title"], panel_x + panel_width * 0.07, panel_y + panel_height * 0.08, panel_width * 0.86, panel_height * 0.17, short_side)
	_place(ui["intro_message"], panel_x + panel_width * 0.09, panel_y + panel_height * 0.29, panel_width * 0.82, panel_height * 0.42, short_side)
	_place(ui["intro_close"], panel_x + panel_width * 0.08, panel_y + panel_height * 0.79, panel_width * 0.84, panel_height * 0.12, short_side)


func _layout_portrait(width: float, height: float, short_side: float, safe: float) -> void:
	var bubble_x: float = safe * 1.5
	var bubble_width: float = width * 0.80
	_place_chat_message(incoming_bubbles[0], bubble_x, height * 0.205, bubble_width, height * 0.105, short_side, 0.055)
	_place_chat_message(incoming_bubbles[1], bubble_x, height * 0.325, bubble_width, height * 0.115, short_side, 0.055)
	_place(ui["instruction"], safe * 1.5, height * 0.46, width - safe * 3.0, height * 0.04, short_side)
	var action_x: float = width * 0.19
	var action_width: float = width * 0.77
	var action_y: float = height * 0.51
	var action_height: float = height * 0.083
	var action_gap: float = height * 0.012
	for index in range(answer_buttons.size()):
		_place(answer_buttons[index], action_x, action_y + (action_height + action_gap) * index, action_width, action_height, short_side)
		_place(answer_labels[index], action_width * 0.055, action_height * 0.06, action_width * 0.89, action_height * 0.88, short_side)
	_place_bubble(ui["outgoing"], width * 0.20, height * 0.49, width * 0.75, height * 0.09, short_side, 0.06)
	_place_bubble(ui["feedback"], bubble_x, height * 0.60, width * 0.87, height * 0.20, short_side, 0.055)
	_place(ui["continue"], width * 0.21, height * 0.82, width * 0.74, height * 0.075, short_side)
	_place(ui["end_mascot"], width * 0.075, height * 0.36, width * 0.25, height * 0.26)
	_place_bubble(ui["end_message"], width * 0.34, height * 0.30, width * 0.60, height * 0.43, short_side, 0.055)
	_place(ui["restart"], width * 0.04, height * 0.885, width * 0.445, height * 0.08, short_side)
	_place(ui["return_to_map"], width * 0.515, height * 0.885, width * 0.445, height * 0.08, short_side)


func _layout_landscape(width: float, height: float, short_side: float, safe: float) -> void:
	var left_x: float = width * 0.045
	var left_width: float = width * 0.43
	_place_chat_message(incoming_bubbles[0], left_x, height * 0.24, left_width, height * 0.19, short_side, 0.035)
	_place_chat_message(incoming_bubbles[1], left_x, height * 0.49, left_width, height * 0.23, short_side, 0.035)
	_place(ui["instruction"], width * 0.53, height * 0.19, width * 0.42, height * 0.045, short_side)
	var action_x: float = width * 0.55
	var action_width: float = width * 0.40
	var action_y: float = height * 0.25
	var action_height: float = height * 0.12
	var action_gap: float = height * 0.025
	for index in range(answer_buttons.size()):
		_place(answer_buttons[index], action_x, action_y + (action_height + action_gap) * index, action_width, action_height, short_side)
		_place(answer_labels[index], action_width * 0.055, action_height * 0.06, action_width * 0.89, action_height * 0.88, short_side)
	_place_bubble(ui["outgoing"], action_x, height * 0.25, action_width, height * 0.13, short_side, 0.035)
	_place_bubble(ui["feedback"], left_x, height * 0.52, left_width, height * 0.24, short_side, 0.035)
	_place(ui["continue"], action_x, height * 0.68, action_width, height * 0.10, short_side)
	_place(ui["end_mascot"], width * 0.16, height * 0.35, width * 0.19, height * 0.34)
	_place_bubble(ui["end_message"], width * 0.37, height * 0.27, width * 0.49, height * 0.47, short_side, 0.045)
	_place(ui["restart"], width * 0.23, height * 0.87, width * 0.26, height * 0.10, short_side)
	_place(ui["return_to_map"], width * 0.51, height * 0.87, width * 0.26, height * 0.10, short_side)


func _place_chat_message(bubble: Dictionary, x: float, y: float, width: float, height: float, short_side: float, horizontal_padding: float) -> void:
	_place(bubble["panel"], x, y, width, height)
	var inner_x: float = width * horizontal_padding
	var inner_width: float = width * (1.0 - horizontal_padding * 2.0)
	_place(bubble["speaker"], x + inner_x, y + height * 0.06, inner_width, height * 0.25, short_side)
	_place(bubble["body"], x + inner_x, y + height * 0.29, inner_width, height * 0.65, short_side)


func _place_bubble(bubble: Dictionary, x: float, y: float, width: float, height: float, short_side: float, horizontal_padding: float) -> void:
	_place(bubble["panel"], x, y, width, height)
	_place(bubble["label"], x + width * horizontal_padding, y + height * 0.10, width * (1.0 - horizontal_padding * 2.0), height * 0.80, short_side)


func _place(control: Control, x: float, y: float, width: float, height: float, font_basis: float = 720.0) -> void:
	if control.has_meta("font_role"):
		var font: Font = typography.get_base_font(control)
		var role: String = str(control.get_meta("font_role"))
		if TYPOGRAPHY_ROLE_MAP.has(role):
			role = TYPOGRAPHY_ROLE_MAP[role]
		if font != null and typography.has_role(role):
			var scale: float = typography.get_target_height(role, font_basis) / font.get_height()
			if control.has_meta("font_scale_multiplier"):
				scale *= float(control.get_meta("font_scale_multiplier"))
			if role == "body" or role == "button" or role == "caption" or role == "heading":
				scale = min(scale, _fit_text_scale(control, font, width, height, scale))
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


func _fit_text_scale(control: Control, font: Font, width: float, height: float, maximum_scale: float) -> float:
	var text: String = control.text if control is Label or control is Button else ""
	var scale: float = maximum_scale
	for _iteration in range(4):
		var text_size: Vector2 = font.get_wordwrap_string_size(text, max(1.0, width / scale))
		if text_size.y * scale <= height or text_size.y <= 0.0:
			break
		scale *= height / (text_size.y * scale)
	return max(0.01, scale)


func _new_label(text: String, color: Color, role: String, alignment: int) -> Label:
	var label := Label.new()
	label.text = text
	label.align = alignment
	label.valign = Label.VALIGN_CENTER
	label.autowrap = true
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
	button.add_stylebox_override("normal", _stylebox(Color("#18294f"), Color("#47608c"), 12, 1))
	button.add_stylebox_override("hover", _stylebox(Color("#223965"), CYAN, 12, 2))
	button.add_stylebox_override("focus", _stylebox(Color("#223965"), CYAN, 12, 2))
	button.add_stylebox_override("pressed", _stylebox(Color("#25436a"), CYAN, 12, 2))
	button.add_color_override("font_color", WHITE)
	button.add_color_override("font_color_disabled", MUTED)
	add_child(button)
	return button


func _new_panel(panel_name: String, fill: Color, border: Color) -> Panel:
	var panel := Panel.new()
	panel.name = panel_name
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_stylebox_override("panel", _stylebox(fill, border, 18, 0))
	add_child(panel)
	return panel


func _stylebox(fill: Color, border: Color, radius: int, border_width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(radius)
	return style


func _on_back_pressed() -> void:
	get_node("/root/NavigationHistory").call("return_to", MAP_SCENE_PATH)


func handle_back_request() -> bool:
	get_node("/root/NavigationHistory").call("return_to", MAP_SCENE_PATH)
	return true


func _on_viewport_size_changed() -> void:
	_layout_screen(get_viewport_rect().size)

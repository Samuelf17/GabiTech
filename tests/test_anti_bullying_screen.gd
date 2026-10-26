extends SceneTree

const SCREEN_SCENE = preload("res://games/anti_bullying/scenes/anti_bullying_screen.tscn")
const REPOSITORY_SCRIPT = preload("res://games/anti_bullying/scripts/situation_repository.gd")
const MAP_SCREEN_SCRIPT = preload("res://app/menus/map_screen.gd")

var failures: Array = []


func _initialize() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	_test_repository()
	var progression = get_root().get_node("Progression")
	var progression_path: String = progression.storage_path
	var test_save := File.new()
	if test_save.file_exists("user://anti_bullying_test_progress.json"):
		Directory.new().remove("user://anti_bullying_test_progress.json")
	progression.storage_path = "user://anti_bullying_test_progress.json"
	progression.load_progress()
	var xp_before_round: int = progression.get_total_experience()
	var screen = SCREEN_SCENE.instance()
	get_root().add_child(screen)
	yield(self, "idle_frame")
	_check(screen.phase == "intro", "Anti-Bullying opens with a tutorial popup")
	_check(screen.ui["intro_backdrop"].visible and screen.ui["intro_close"].visible, "tutorial darkens the screen and provides a start button")
	_check(screen.ui["intro_message"].text.find("5 situações") >= 0, "tutorial explains the five-situation round")
	screen._on_answer_pressed(0)
	_check(screen.phase == "intro", "answers remain disabled until the tutorial is closed")
	screen.anchor_right = 0.0
	screen.anchor_bottom = 0.0
	for viewport_size in [Vector2(720, 1280), Vector2(1280, 720), Vector2(960, 540), Vector2(360, 800), Vector2(320, 568)]:
		screen.rect_size = viewport_size
		screen._layout_screen(viewport_size)
		var short_side: float = min(viewport_size.x, viewport_size.y)
		var challenge_base: float = screen.typography.get_target_height("challenge", short_side)
		for text_spec in [
			{"key": "instruction", "multiplier": 1.15},
			{"key": "composer_text", "multiplier": 1.15},
			{"key": "status", "multiplier": 1.38}
		]:
			var text_control: Control = screen.ui[text_spec["key"]]
			var expected_height: float = challenge_base * float(text_spec["multiplier"])
			_check(
				abs(text_control.get_font("font").get_height() - expected_height) <= 1.0,
				"%s uses the enlarged responsive font at %s" % [text_spec["key"], viewport_size]
			)
		_check(_fits_viewport(screen.ui["header"], viewport_size), "chat header stays inside %s" % viewport_size)
		_check(_fits_viewport(screen.ui["background"], viewport_size), "circuit background covers %s" % viewport_size)
		_check(_fits_viewport(screen.ui["composer"], viewport_size), "message composer stays inside %s" % viewport_size)
		_check(_fits_viewport(screen.ui["end_mascot"], viewport_size), "completion mascot stays inside %s" % viewport_size)
		_check(_fits_viewport(screen.ui["restart"], viewport_size), "restart button stays inside %s" % viewport_size)
		_check(_fits_viewport(screen.ui["return_to_map"], viewport_size), "return-to-map button stays inside %s" % viewport_size)
		_check(_fits_viewport(screen.ui["intro_panel"], viewport_size), "tutorial panel fits %s" % viewport_size)
		_check(_fits_viewport(screen.ui["intro_message"], viewport_size), "tutorial text fits %s" % viewport_size)
		_check(_fits_viewport(screen.ui["intro_close"], viewport_size), "tutorial button fits %s" % viewport_size)
		if viewport_size.y > viewport_size.x:
			var back_right: float = screen.ui["back"].rect_position.x + screen.ui["back"].rect_size.x
			var avatar_left: float = screen.ui["chat_avatar"].rect_position.x
			var avatar_right: float = screen.ui["chat_avatar"].rect_position.x + screen.ui["chat_avatar"].rect_size.x
			var title_left: float = screen.ui["chat_title"].rect_position.x
			var arrow_avatar_gap: float = avatar_left - back_right
			var avatar_title_gap: float = title_left - avatar_right
			_check(arrow_avatar_gap > 0.0, "portrait avatar has space after the back arrow at %s" % viewport_size)
			_check(abs(arrow_avatar_gap - avatar_title_gap) <= 1.0, "portrait arrow/avatar and avatar/title gaps match at %s" % viewport_size)
		for bubble in screen.incoming_bubbles:
			_check(_fits_viewport(bubble["panel"], viewport_size), "incoming chat bubble stays inside %s" % viewport_size)
		for answer in screen.answer_buttons:
			_check(answer.focus_mode == Control.FOCUS_ALL, "answer supports focus navigation")
			_check(_fits_viewport(answer, viewport_size), "answer stays inside %s" % viewport_size)
		_check(_fits_viewport(screen.ui["continue"], viewport_size), "continue stays inside %s" % viewport_size)
	_check(
		screen.ui["status"].get_font("font").get_height() > screen.ui["progress"].get_font("font").get_height(),
		"online status uses the enlarged responsive font"
	)
	screen._on_intro_close_pressed()
	_check(screen.phase == "choosing" and not screen.ui["intro_backdrop"].visible, "closing tutorial starts the first situation")
	_check(screen.ui["background"].texture.resource_path == "res://shared/ui/assets/backgrounds/fundo.png", "chat uses the circuit background")
	_check(screen.ui["chat_title"].text == "Chat da turma", "reference chat header is shown")
	_check(not screen.ui.has("chat_avatar_backing"), "profile picture has no square backing")
	_check(screen.incoming_bubbles[1]["body"].text == screen.selected_situations[0]["conversation"][1]["text"], "a randomly selected situation renders its chat")
	_check(screen.incoming_bubbles[0]["speaker"].get_font("font").get_height() == screen.incoming_bubbles[0]["body"].get_font("font").get_height(), "participant names match message font size")
	_check(screen.incoming_bubbles[0]["speaker"].get_color("font_color") != screen.incoming_bubbles[1]["speaker"].get_color("font_color") or screen.incoming_bubbles[0]["speaker"].text == screen.incoming_bubbles[1]["speaker"].text, "different participants have distinct colors")
	for index in range(screen.selected_situations.size()):
		var situation: Dictionary = screen.selected_situations[screen.situation_index]
		if situation["conversation"][0]["speaker"] != situation["conversation"][1]["speaker"]:
			_check(screen.incoming_bubbles[0]["speaker"].get_color("font_color") != screen.incoming_bubbles[1]["speaker"].get_color("font_color"), "different participants in a conversation use different colors")
		var correct_option: int = -1
		var should_be_correct: bool = index < screen.selected_situations.size() - 1
		for option_index in range(situation["options"].size()):
			if situation["options"][option_index]["correct"] == should_be_correct:
				correct_option = option_index
				break
		_check(correct_option >= 0, "situation %s has an option matching the JSON correctness flag" % situation["id"])
		screen._on_answer_pressed(correct_option)
		var expected_correct_choices: int = min(index + 1, screen.selected_situations.size() - 1)
		_check(screen.correct_choices == expected_correct_choices, "answer outcome follows the JSON correct flag in situation %s" % situation["id"])
		_check(
			screen.ui["feedback"]["label"].get_color("font_color") == (Color("#f3f7ff") if should_be_correct else Color("#ff858a")),
			"answer feedback color follows the JSON correct flag in situation %s" % situation["id"]
		)
		_check(screen.phase == "feedback", "choice displays its consequence")
		_check(screen.ui["outgoing"]["label"].text == situation["options"][correct_option]["text"], "chosen action appears as a green chat bubble")
		_check(screen.ui["feedback"]["label"].text.find(situation["options"][correct_option]["consequence"]) >= 0, "choice consequence comes from JSON")
		_check(screen.ui["feedback"]["label"].text.find(situation["explanation"]) >= 0, "choice includes the situation learning explanation")
		screen._on_continue_pressed()
		_check(not screen.ui["feedback"]["panel"].visible and not screen.ui["feedback"]["label"].visible, "previous explanation is hidden before the next choices")
		if screen.phase == "choosing":
			for answer in screen.answer_buttons:
				_check(answer.visible, "next choices appear after the explanation is hidden")
	_check(screen.phase == "finished", "all situations end with the learning message")
	_check(screen.ui["end_message"]["label"].text.find("Respeito também") >= 0, "final learning message is present")
	_check(screen.ui["completion_overlay"].visible and screen.ui["end_mascot"].visible, "completion opens a mascot popup")
	_check(screen.ui["end_message"]["panel"].visible, "completion popup displays its message card beside the mascot")
	_check(screen.ui["end_message"]["label"].text.find("4 situações") >= 0, "completion summarizes the four correct choices")
	_check(screen.ui["end_message"]["label"].text.find("XP ganho bruto: +400") >= 0, "completion shows total earned XP")
	_check(screen.ui["end_message"]["label"].text.find("XP perdido bruto: -20") >= 0, "completion shows total lost XP")
	_check(screen.ui["end_message"]["label"].text.find("XP aplicado ao perfil: +380") >= 0, "completion shows XP actually applied to the profile")
	_check(progression.get_total_experience() == xp_before_round + 380, "four correct and one incorrect Anti-Bullying answers apply 380 XP after the round")
	_check(progression.get_badge_level("respect") == 1, "four correct Anti-Bullying answers unlock the Respect badge")
	_check(screen.badge_popup != null and screen.badge_popup.visible, "Respect unlock popup displays over the completed Anti-Bullying screen")
	_check(screen.ui["restart"].visible and screen.ui["restart"].text == "JOGAR NOVAMENTE", "completion offers replay")
	_check(screen.ui["return_to_map"].visible and screen.ui["return_to_map"].text == "VOLTAR PARA O MAPA", "completion offers return to map")
	_check(screen.has_method("_on_map_pressed") and screen.MAP_SCENE_PATH == "res://app/menus/map_screen.tscn", "return-to-map action targets the map scene")
	for viewport_size in [Vector2(720, 1280), Vector2(1280, 720), Vector2(960, 540), Vector2(360, 800), Vector2(320, 568)]:
		screen._layout_screen(viewport_size)
		_check(_fits_viewport(screen.ui["end_mascot"], viewport_size), "popup mascot fits %s" % viewport_size)
		_check(_fits_viewport(screen.ui["end_message"]["panel"], viewport_size), "popup message card fits %s" % viewport_size)
		_check(_fits_viewport(screen.ui["restart"], viewport_size), "restart button is at the screen bottom in %s" % viewport_size)
		_check(_fits_viewport(screen.ui["return_to_map"], viewport_size), "return-to-map button fits %s" % viewport_size)
		_check(screen.ui["restart"].rect_position.y + screen.ui["restart"].rect_size.y >= viewport_size.y * 0.94, "completion buttons sit at the bottom edge in %s" % viewport_size)
	screen._on_restart_pressed()
	_check(screen.situation_index == 0 and screen.phase == "choosing", "minigame can restart independently")
	_check(screen.selected_situations.size() == 5, "replay selects five situations")
	_check(MAP_SCREEN_SCRIPT.DISTRICTS[4].get("scene", "") == "res://games/anti_bullying/scenes/anti_bullying_screen.tscn", "Respect district launches the standalone minigame scene")
	progression.set("storage_path", progression_path)
	if failures.empty():
		print("Anti-bullying minigame tests passed")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func _test_repository() -> void:
	var repository = REPOSITORY_SCRIPT.new()
	_check(repository.load_situations(), "JSON situation data loads")
	_check(repository.situations.size() == 31, "JSON contains the full set of 31 situations")
	_check(repository.situations[0]["explanation"] == repository.situations[0]["feedback"], "feedback is normalized as the situation explanation")
	for situation in repository.situations:
		_check(situation["conversation"].size() >= 2, "%s has chat messages" % situation["id"])
		_check(situation["options"].size() == 4, "%s has four actions" % situation["id"])
		_check(not situation["explanation"].empty(), "%s has learning explanation" % situation["id"])
		var correct_indices: Array = []
		for option_index in range(situation["options"].size()):
			if situation["options"][option_index]["correct"]:
				correct_indices.append(option_index)
		_check(correct_indices == [0, 3], "%s marks the supportive options as correct in the JSON" % situation["id"])
	var seeded_selection: Array = repository.select_random_situations(5, 1234)
	var repeated_selection: Array = repository.select_random_situations(5, 1234)
	_check(seeded_selection.size() == 5, "repository selects five situations")
	_check(seeded_selection[0]["id"] == repeated_selection[0]["id"], "a fixed seed produces a repeatable selection")
	var selected_ids: Dictionary = {}
	for situation in seeded_selection:
		selected_ids[situation["id"]] = true
	_check(selected_ids.size() == 5, "random selection does not repeat situations")
	_check(repository.select_random_situations().size() == 5, "default selection matches the round size")
	_check(not repository.load_situations("res://games/anti_bullying/data/missing.json"), "missing JSON is reported")
	_check(not repository.load_error.empty(), "repository provides a load error")
	_check(repository.load_situations(), "valid JSON can be reloaded after an error")


func _fits_viewport(control: Control, viewport_size: Vector2) -> bool:
	var position: Vector2 = control.rect_position
	var size: Vector2 = control.rect_size * control.rect_scale
	return position.x >= -1.0 and position.y >= -1.0 and position.x + size.x <= viewport_size.x + 1.0 and position.y + size.y <= viewport_size.y + 1.0


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)

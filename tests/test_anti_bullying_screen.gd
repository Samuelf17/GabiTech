extends SceneTree

const SCREEN_SCENE = preload("res://games/anti_bullying/scenes/anti_bullying_screen.tscn")
const REPOSITORY_SCRIPT = preload("res://games/anti_bullying/scripts/situation_repository.gd")
const MAP_SCREEN_SCRIPT = preload("res://app/menus/map_screen.gd")

var failures: Array = []


func _initialize() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	_test_repository()
	var screen = SCREEN_SCENE.instance()
	get_root().add_child(screen)
	yield(self, "idle_frame")
	screen.anchor_right = 0.0
	screen.anchor_bottom = 0.0
	for viewport_size in [Vector2(720, 1280), Vector2(1280, 720), Vector2(960, 540), Vector2(360, 800), Vector2(320, 568)]:
		screen.rect_size = viewport_size
		screen._layout_screen(viewport_size)
		_check(_fits_viewport(screen.ui["header"], viewport_size), "chat header stays inside %s" % viewport_size)
		_check(_fits_viewport(screen.ui["background"], viewport_size), "circuit background covers %s" % viewport_size)
		_check(_fits_viewport(screen.ui["composer"], viewport_size), "message composer stays inside %s" % viewport_size)
		_check(_fits_viewport(screen.ui["end_mascot"], viewport_size), "completion mascot stays inside %s" % viewport_size)
		_check(_fits_viewport(screen.ui["restart"], viewport_size), "restart button stays inside %s" % viewport_size)
		_check(_fits_viewport(screen.ui["return_to_map"], viewport_size), "return-to-map button stays inside %s" % viewport_size)
		for bubble in screen.incoming_bubbles:
			_check(_fits_viewport(bubble["panel"], viewport_size), "incoming chat bubble stays inside %s" % viewport_size)
		for answer in screen.answer_buttons:
			_check(answer.focus_mode == Control.FOCUS_ALL, "answer supports focus navigation")
			_check(_fits_viewport(answer, viewport_size), "answer stays inside %s" % viewport_size)
		_check(_fits_viewport(screen.ui["continue"], viewport_size), "continue stays inside %s" % viewport_size)
	_check(screen.ui["background"].texture.resource_path == "res://shared/ui/assets/backgrounds/fundo.png", "chat uses the circuit background")
	_check(screen.ui["chat_title"].text == "Chat da turma", "reference chat header is shown")
	_check(screen.incoming_bubbles[1]["body"].text.find("Por favor") >= 0, "first situation renders a fictional chat")
	_check(screen.incoming_bubbles[0]["speaker"].get_font("font").get_height() == screen.incoming_bubbles[0]["body"].get_font("font").get_height(), "participant names match message font size")
	_check(screen.incoming_bubbles[0]["speaker"].get_color("font_color") != screen.incoming_bubbles[1]["speaker"].get_color("font_color"), "chat participants have distinct name colors")
	for index in range(screen.repository.situations.size()):
		var situation: Dictionary = screen.repository.situations[screen.situation_index]
		_check(screen.incoming_bubbles[0]["speaker"].get_color("font_color") != screen.incoming_bubbles[1]["speaker"].get_color("font_color"), "each conversation uses different colors for its participants")
		var correct_option: int = -1
		for option_index in range(situation["options"].size()):
			if situation["options"][option_index]["correct"]:
				correct_option = option_index
				break
		screen._on_answer_pressed(correct_option)
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
	_check(screen.ui["end_message"]["label"].text.find("5 situações") >= 0, "completion summarizes respectful choices")
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
	_check(MAP_SCREEN_SCRIPT.DISTRICTS[4].get("scene", "") == "res://games/anti_bullying/scenes/anti_bullying_screen.tscn", "Respect district launches the standalone minigame scene")
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
	_check(repository.situations.size() == 5, "JSON has five situations")
	for situation in repository.situations:
		_check(situation["conversation"].size() >= 2, "%s has chat messages" % situation["id"])
		_check(situation["options"].size() == 4, "%s has four actions" % situation["id"])
		_check(not situation["explanation"].empty(), "%s has learning explanation" % situation["id"])
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

extends SceneTree

const GAME_SCENE = preload("res://games/data_protection/scenes/data_protection_screen.tscn")
const MAZE_MODEL = preload("res://games/data_protection/scripts/maze_model.gd")

var failures: Array = []


func _initialize() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	_test_maze_model()
	var progression = get_root().get_node("Progression")
	var progression_path: String = progression.storage_path
	var test_save := File.new()
	if test_save.file_exists("user://data_protection_test_progress.json"):
		Directory.new().remove("user://data_protection_test_progress.json")
	progression.storage_path = "user://data_protection_test_progress.json"
	progression.load_progress()
	var screen = GAME_SCENE.instance()
	get_root().add_child(screen)
	yield(self, "idle_frame")
	_test_game_setup(screen)
	_test_audio_controls(screen)
	_test_input(screen)
	_test_layouts(screen)
	_test_turn_response(screen)
	_test_collectible_and_life(screen)
	_test_restart_cleanup(screen)
	progression.set("storage_path", progression_path)
	if failures.empty():
		print("Data protection game tests passed")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func _test_maze_model() -> void:
	var model = MAZE_MODEL.new(1229)
	_check(model.width == 21 and model.height == 15, "landscape maze uses a horizontal grid")
	_check(model.cells is PoolByteArray and model.cells.size() == model.width * model.height, "maze cells use a flat byte array")
	var open_cells: Array = model.get_open_cells()
	_check(open_cells.size() >= 100, "generated maze contains a playable set of corridors")
	_check(model.is_open(Vector2(1, 1)), "player spawn is open")
	for spawn in [Vector2(model.width - 2, model.height - 2), Vector2(model.width - 2, 1), Vector2(1, model.height - 2)]:
		_check(model.is_open(spawn), "hacker spawn %s is open" % spawn)
	var visited: Dictionary = {"1,1": true}
	var queue: Array = [Vector2(1, 1)]
	var queue_index: int = 0
	while queue_index < queue.size():
		var cell: Vector2 = queue[queue_index]
		queue_index += 1
		for direction in model.get_legal_directions(cell):
			var neighbor: Vector2 = cell + direction
			var key: String = "%d,%d" % [int(neighbor.x), int(neighbor.y)]
			if not visited.has(key):
				visited[key] = true
				queue.append(neighbor)
	_check(visited.size() == open_cells.size(), "all corridors in the generated maze are connected")
	var portrait_model = MAZE_MODEL.new(1229, 13, 21)
	_check(portrait_model.width == 13 and portrait_model.height == 21, "portrait maze uses a vertical grid")
	_check(portrait_model.get_open_cells().size() >= 100, "portrait maze contains a playable set of corridors")
	for spawn in [Vector2(portrait_model.width - 2, portrait_model.height - 2), Vector2(portrait_model.width - 2, 1), Vector2(1, portrait_model.height - 2)]:
		_check(portrait_model.is_open(spawn), "portrait hacker spawn %s is open" % spawn)


func _test_game_setup(screen) -> void:
	_check(screen.music_player != null and screen.music_player.is_playing(), "maze background music starts when the game opens")
	_check(screen.music_player.stream is AudioStreamMP3 and screen.music_player.stream.loop, "maze background music loops")
	_check(is_equal_approx(screen.music_player.volume_db, screen.MUSIC_VOLUME_DB), "maze background music starts at fifty percent volume")
	_check(screen.phase == "ready", "game waits for the player's first move")
	_check(not screen.ui.has("data_layer") and screen.ui["board"].get_node_or_null("PlayerCapybara") != null, "collectibles share the maze canvas so its redraw refreshes them")
	_check(screen.intro_popup and screen.ui["modal_backdrop"].visible, "intro story appears over a dimmed screen")
	_check(screen.ui["end_title"].text == "Proteja seus arquivos!", "intro popup introduces the story")
	_check(screen.ui["end_message"].text == "Ajude a Gabivara a coletar todos os arquivos enquanto foge dos spywares! Cuidado com os olhos pixelizados: eles estão à espreita para roubar seus dados. Colete tudo e escape sem ser capturado!", "intro popup shows the current story text")
	_check(screen.ui["intro_close"].visible, "intro popup provides a close tutorial button")
	_check(screen.hackers.size() == 3, "three hackers spawn in the maze")
	_check(screen.maze.height > screen.maze.width, "portrait screen starts with a vertical maze")
	for index in range(screen.hackers.size()):
		_check(screen.hackers[index]["node"].modulate == screen.WHITE, "hacker %d preserves the eye artwork's original colors" % index)
	_check(screen.DATA_COLOR.g > screen.DATA_COLOR.r and screen.DATA_COLOR.g > screen.DATA_COLOR.b, "spreadsheet data items receive a green tint")
	_check(screen.lives == 3, "player starts with three lives")
	_check(is_equal_approx(screen.PLAYER_SPEED_TILES_PER_SECOND / screen.HACKER_SPEED_TILES_PER_SECOND, 1.5), "player moves one and a half times faster than hackers")
	_check(screen.total_data_count == screen.maze.get_open_cells().size() - 4, "data items are placed on every available corridor except actor spawns")
	_check(screen.player["node"].texture != null, "player sprite texture is loaded")
	_check(screen.DATA_TEXTURE != null and screen.DATA_TEXTURE.get_size().x > 0.0 and screen.DATA_TEXTURE.get_size().y > 0.0, "data item uses the loaded spreadsheet icon")
	_check(screen.DATA_TEXTURE.resource_path == "res://games/data_protection/assets/planilha_icon.svg", "collectibles use the spreadsheet icon from ideias")
	var old_asset := File.new()
	_check(not old_asset.file_exists("res://games/data_protection/assets/data_item.png"), "previous collectible image was removed from the project")
	_check(screen.HACKER_TEXTURE != null and screen.HACKER_TEXTURE.get_size() == Vector2(256, 171), "eye image is imported at a lightweight size")
	_check(screen.HACKER_TEXTURE.resource_path == "res://games/data_protection/assets/olho.png", "hackers use the eye image from ideias for this visual test")
	var removed_hacker := File.new()
	_check(not removed_hacker.file_exists("res://games/data_protection/assets/hacker.png"), "unused previous hacker PNG is absent from the project")
	_check(not removed_hacker.file_exists("res://games/data_protection/assets/hacker_ideias.png"), "unused new hacker PNG is absent from the project")
	_check(screen.hackers[0]["node"].texture == screen.HACKER_TEXTURE, "hacker actor displays the raster texture")
	var progression = get_root().get_node("Progression")
	var level: int = clamp(int(progression.get_state().get("level", 1)), 1, 10)
	_check(screen.player["node"].texture.resource_path == "res://shared/mascot/levels/%d.png" % level, "player uses the capybara matching the user level")
	_check(screen.ui["score"].text == "DADOS 0 / %d" % screen.total_data_count, "data counter starts at zero")
	var first_hacker_position: Vector2 = screen.hackers[0]["cell"]
	screen._process(0.5)
	_check(screen.hackers[0]["cell"] == first_hacker_position, "hackers remain still until the first player move")
	screen.ui["intro_close"].emit_signal("pressed")
	_check(not screen.intro_popup and not screen.ui["modal_backdrop"].visible, "close tutorial button dismisses the intro")
	_check(screen.phase == "ready", "closing the tutorial does not start the game")
	screen._process(0.5)
	_check(screen.hackers[0]["cell"] == first_hacker_position, "hackers stay still after closing the tutorial")
	_test_hacker_random_walking(screen)


func _test_audio_controls(screen) -> void:
	var volume_button: TextureButton = screen.ui["volume"]
	_check(volume_button.texture_normal.resource_path == "res://games/data_protection/assets/icons/volume_up.svg", "volume button starts with the volume icon")
	_check(volume_button.focus_mode == Control.FOCUS_ALL, "volume button supports keyboard and controller focus")
	volume_button.emit_signal("pressed")
	_check(screen.audio_muted, "volume button turns mute on")
	_check(is_equal_approx(screen.music_player.volume_db, screen.MUTED_VOLUME_DB), "mute button silences the music")
	_check(is_equal_approx(screen.data_collect_player.volume_db, screen.MUTED_VOLUME_DB), "mute button silences sound effects too")
	_check(volume_button.texture_normal.resource_path == "res://games/data_protection/assets/icons/volume_off.svg", "mute button changes to the muted icon")
	volume_button.emit_signal("pressed")
	_check(not screen.audio_muted, "volume button turns mute off")
	_check(is_equal_approx(screen.music_player.volume_db, screen.MUSIC_VOLUME_DB), "unmuting restores music to fifty percent volume")
	_check(is_equal_approx(screen.data_collect_player.volume_db, 0.0), "unmuting restores sound effect volume")


func _test_hacker_random_walking(screen) -> void:
	var cell := Vector2.ZERO
	var legal: Array = []
	for candidate in screen.maze.get_open_cells():
		legal = screen.maze.get_legal_directions(candidate)
		if legal.size() >= 2 and abs(candidate.x - 19) + abs(candidate.y - 13) > 6:
			cell = candidate
			break
	if legal.size() < 2:
		_check(false, "random walking test finds a junction away from the player")
		return
	var expected_random_direction: Vector2 = Vector2.ZERO
	var random_seed: int = 1
	while expected_random_direction == Vector2.ZERO or expected_random_direction == legal[0]:
		seed(random_seed)
		expected_random_direction = legal[randi() % legal.size()]
		random_seed += 1
	var near_player_direction: Vector2 = legal[0]
	screen.player["cell"] = cell + near_player_direction
	seed(random_seed - 1)
	var direction_with_near_player: Vector2 = screen._choose_hacker_direction(cell, Vector2.ZERO)
	screen.player["cell"] = Vector2(19, 13)
	seed(random_seed - 1)
	var direction_with_far_player: Vector2 = screen._choose_hacker_direction(cell, Vector2.ZERO)
	_check(direction_with_near_player == direction_with_far_player, "hacker movement does not change based on player proximity")
	screen.player["cell"] = Vector2(1, 1)
	screen.player["offset"] = 0.0
	screen._set_actor_position(screen.player)


func _test_input(screen) -> void:
	var board_rect: Rect2 = screen.ui["board"].get_global_rect()
	var board_center: Vector2 = board_rect.position + board_rect.size * 0.5
	var release_without_press := InputEventScreenTouch.new()
	release_without_press.pressed = false
	release_without_press.position = board_center
	screen._input(release_without_press)
	_check(screen.phase == "ready", "orphan release from the district selection cannot start the game")
	var touch_outside := InputEventScreenTouch.new()
	touch_outside.pressed = true
	touch_outside.position = Vector2(1, 1)
	screen._input(touch_outside)
	release_without_press.position = board_center
	screen._input(release_without_press)
	_check(screen.phase == "ready", "a swipe that starts outside the maze cannot start the game")
	var mouse_release_without_press := InputEventMouseButton.new()
	mouse_release_without_press.button_index = BUTTON_LEFT
	mouse_release_without_press.pressed = false
	mouse_release_without_press.position = board_center
	screen._input(mouse_release_without_press)
	_check(screen.phase == "ready", "orphan mouse release cannot start the game")
	var valid_direction: Vector2 = screen.maze.get_legal_directions(screen.player_spawn)[0]
	var touch_inside := InputEventScreenTouch.new()
	touch_inside.pressed = true
	touch_inside.position = board_center
	screen._input(touch_inside)
	release_without_press.position = board_center + valid_direction * min(screen.current_viewport_size.x, screen.current_viewport_size.y) * 0.1
	screen._input(release_without_press)
	_check(screen.phase == "playing", "a valid swipe that begins and ends in the maze starts the game")
	screen._reset_round()
	screen._apply_swipe_delta(Vector2(0, -200))
	_check(screen.desired_direction == Vector2.UP, "upward swipe requests upward movement")
	screen._apply_swipe_delta(Vector2(-200, 0))
	_check(screen.desired_direction == Vector2.LEFT, "leftward swipe requests left movement")
	screen._apply_swipe_delta(Vector2(200, 0))
	_check(screen.desired_direction == Vector2.RIGHT, "rightward swipe requests right movement")
	screen._apply_swipe_delta(Vector2(0, 200))
	_check(screen.desired_direction == Vector2.DOWN, "downward swipe requests downward movement")
	var key_event := InputEventKey.new()
	key_event.pressed = true
	key_event.scancode = KEY_A
	screen._input(key_event)
	_check(screen.desired_direction == Vector2.LEFT, "A key requests left movement")
	key_event.scancode = KEY_W
	screen._input(key_event)
	_check(screen.desired_direction == Vector2.UP, "W key requests upward movement")
	key_event.scancode = KEY_S
	screen._input(key_event)
	_check(screen.desired_direction == Vector2.DOWN, "S key requests downward movement")
	key_event.scancode = KEY_D
	screen._input(key_event)
	_check(screen.desired_direction == Vector2.RIGHT, "D key requests right movement")
	_check(screen.phase == "playing", "first valid direction starts the game")
	_check(not screen.ui["modal_backdrop"].visible, "first move dismisses the introduction")


func _test_layouts(screen) -> void:
	for viewport_size in [Vector2(720, 1280), Vector2(1280, 720), Vector2(960, 540), Vector2(360, 800), Vector2(320, 568)]:
		screen._layout_screen(viewport_size)
		_check(screen.tile_size > 0.0, "maze tiles remain visible at %s" % viewport_size)
		_check(_fits_viewport(screen.ui["board"], viewport_size), "maze board fits at %s" % viewport_size)
		_check(screen.ui["board"].rect_size.x >= viewport_size.x * 0.87, "maze occupies about 90 percent of the screen width at %s (grid %s x %s, board %s)" % [viewport_size, screen.maze.width, screen.maze.height, screen.ui["board"].rect_size])
		_check(screen.ui["board"].rect_size.y >= viewport_size.y * 0.74, "maze occupies about 76 percent of the screen height at %s (grid %s x %s, board %s)" % [viewport_size, screen.maze.width, screen.maze.height, screen.ui["board"].rect_size])
		if viewport_size.y > viewport_size.x:
			_check(screen.maze.height > screen.maze.width, "portrait viewport switches to a vertical grid")
			_check(screen.ui["board"].rect_size.y >= viewport_size.y * 0.74, "portrait maze occupies about 76 percent of the screen height")
		else:
			_check(screen.maze.width > screen.maze.height, "landscape viewport switches to a horizontal grid")
			_check(screen.ui["board"].rect_size.x > screen.ui["board"].rect_size.y, "landscape maze is wider than it is tall")
			var title_center_x: float = screen.ui["title"].rect_position.x + screen.ui["title"].rect_size.x * 0.5
			var subtitle_center_x: float = screen.ui["subtitle"].rect_position.x + screen.ui["subtitle"].rect_size.x * 0.5
			_check(abs(title_center_x - viewport_size.x * 0.5) <= 1.0, "landscape game title is centered in the viewport")
			_check(abs(subtitle_center_x - viewport_size.x * 0.5) <= 1.0, "landscape subtitle is centered in the viewport")
		_check(_fits_viewport(screen.ui["title"], viewport_size), "game title fits at %s" % viewport_size)
		_check(_fits_viewport(screen.ui["volume"], viewport_size), "volume button fits at %s" % viewport_size)
		var back_rect: Rect2 = screen.ui["back"].get_rect()
		var volume_rect: Rect2 = screen.ui["volume"].get_rect()
		_check(abs(back_rect.position.y + back_rect.size.y * 0.5 - volume_rect.position.y - volume_rect.size.y * 0.5) <= 1.0, "volume button aligns vertically with Back at %s" % viewport_size)
		_check(volume_rect.position.x >= screen.ui["title"].rect_position.x + screen.ui["title"].rect_size.x, "volume button does not overlap the game title at %s" % viewport_size)
		_check(_fits_viewport(screen.ui["score"], viewport_size), "data counter fits at %s" % viewport_size)
		_check(_fits_viewport(screen.ui["lives"], viewport_size), "life counter fits at %s" % viewport_size)
		_check(_fits_viewport(screen.ui["end_panel"], viewport_size), "intro and result panel fit at %s" % viewport_size)
		_check(_fits_viewport(screen.ui["end_title"], viewport_size), "intro and result title fit at %s" % viewport_size)
		_check(_fits_viewport(screen.ui["end_message"], viewport_size), "intro and result message fit at %s" % viewport_size)
		_check(_fits_viewport(screen.ui["intro_close"], viewport_size), "close tutorial button fits at %s" % viewport_size)
		_check(not screen.ui.has("status"), "bottom play instruction is removed")
		_check(_fits_viewport(screen.player["node"], viewport_size), "capybara fits at %s" % viewport_size)
		for hacker in screen.hackers:
			_check(_fits_viewport(hacker["node"], viewport_size), "hacker fits at %s" % viewport_size)
		var body_font: Font = screen.ui["subtitle"].get_font("font")
		var expected_body_height: float = screen.typography.get_target_height("body", min(viewport_size.x, viewport_size.y)) * screen.BODY_TEXT_SCALE
		_check(abs(body_font.get_height() - expected_body_height) <= 1.5, "non-title text is enlarged by fifteen percent at %s" % viewport_size)
		var title_font: Font = screen.ui["title"].get_font("font")
		var expected_title_height: float = screen.typography.get_target_height("heading", min(viewport_size.x, viewport_size.y))
		_check(abs(title_font.get_height() - expected_title_height) <= 1.5, "game title retains its previous size at %s" % viewport_size)


func _test_collectible_and_life(screen) -> void:
	var progression = get_root().get_node("Progression")
	progression.state["protected_data_count"] = 299
	progression.state["badge_levels"]["security"] = 0
	var xp_before_collection: int = progression.get_total_experience()
	var data_cell: Vector2 = screen.data_items.values()[0]
	screen._collect_data(data_cell)
	_check(not screen.data_items.has("%d,%d" % [int(data_cell.x), int(data_cell.y)]), "collected data disappears from the maze")
	_check(screen.collected_count == 1, "collecting data increments the total")
	_check(screen.ui["score"].text == "DADOS 1 / %d" % screen.total_data_count, "data counter updates after collection")
	_check(screen.data_collect_player.is_playing(), "collecting a data item plays its sound effect")
	_check(progression.get_total_experience() == xp_before_collection, "collected data XP remains buffered until a checkpoint")
	_check(progression.pending_protected_data_count == 1, "one collected data item is held for the next save batch")
	_check(screen.badge_popup == null, "Security popup waits until the result screen")
	screen.player["cell"] = Vector2(5, 5)
	screen.player["offset"] = 0.0
	screen.hackers[0]["cell"] = Vector2(5, 5)
	screen.hackers[0]["offset"] = 0.0
	screen.respawn_grace = 0.0
	screen._check_hacker_collisions()
	_check(screen.lives == 2, "hacker contact removes exactly one life")
	_check(screen.player["cell"] == Vector2(1, 1), "player respawns after losing a life")
	_check(screen.respawn_grace > 0.0, "respawn adds a short collision grace period")


func _test_turn_response(screen) -> void:
	var progression = get_root().get_node("Progression")
	var saved_pending_data: int = progression.pending_protected_data_count
	var found_turn: bool = false
	for cell in screen.maze.get_open_cells():
		for direction in screen.maze.get_legal_directions(cell):
			var next_cell: Vector2 = cell + direction
			for desired in MAZE_MODEL.DIRECTIONS:
				if abs(direction.dot(desired)) > 0.01 or not screen.maze.is_open(next_cell + desired):
					continue
				var saved_items: Dictionary = screen.data_items.duplicate()
				var saved_count: int = screen.collected_count
				var saved_xp_from_data: int = screen.round_xp_from_data
				var saved_score: String = screen.ui["score"].text
				screen.data_items[screen._cell_key(next_cell)] = next_cell
				screen.player["cell"] = cell
				screen.player["offset"] = screen.tile_size * (1.0 - screen.TURN_EARLY_WINDOW_RATIO * 0.5)
				screen.player["direction"] = direction
				screen.desired_direction = desired
				screen.player = screen._advance_actor(screen.player, screen.PLAYER_SPEED_TILES_PER_SECOND, 0.01, true)
				_check(screen.player["cell"] == next_cell and screen.player["direction"] == desired, "buffered corner command turns shortly before reaching the junction")
				_check(screen.collected_count == saved_count + 1, "early turn still collects data at the junction")
				screen.data_items = saved_items
				screen.collected_count = saved_count
				screen.round_xp_from_data = saved_xp_from_data
				screen.ui["score"].text = saved_score
				found_turn = true
				break
			if found_turn:
				break
		if found_turn:
			break
	_check(found_turn, "maze has an intersection to validate early turning")
	progression.pending_protected_data_count = saved_pending_data
	for cell in screen.maze.get_open_cells():
		var legal: Array = screen.maze.get_legal_directions(cell)
		if legal.empty():
			continue
		var direction: Vector2 = legal[0]
		screen.player["cell"] = cell
		screen.player["offset"] = screen.tile_size * 0.4
		screen.player["direction"] = direction
		screen.desired_direction = -direction
		var before_position: Vector2 = screen._cell_local_position(cell) + direction * screen.player["offset"]
		screen.player = screen._advance_actor(screen.player, screen.PLAYER_SPEED_TILES_PER_SECOND, 0.0, true)
		var after_position: Vector2 = screen._cell_local_position(screen.player["cell"]) + screen.player["direction"] * screen.player["offset"]
		_check(screen.player["direction"] == -direction, "reverse direction command applies immediately")
		_check(before_position.distance_to(after_position) < 0.01, "immediate reversal preserves capybara position")
		return


func _test_restart_cleanup(screen) -> void:
	var progression = get_root().get_node("Progression")
	var xp_before_loss: int = progression.get_total_experience()
	screen._finish_round(false)
	_check(progression.get_total_experience() == xp_before_loss + 5, "loss flushes buffered collectible XP but grants no completion bonus")
	_check(screen.ui["end_title"].text.find("sem vidas") >= 0, "loss result explains that Gabivara ran out of lives")
	_check(screen.ui["end_message"].text.find("%d de %d dados" % [screen.collected_count, screen.total_data_count]) >= 0, "loss result reports how many data items were protected")
	_check(screen.ui["end_message"].text.find("evitar golpes") >= 0, "loss result explains why personal data needs protection")
	_check(screen.ui["end_message"].text.find("XP pelos dados: +5") >= 0, "loss result shows XP earned from collected data")
	_check(screen.ui["end_message"].text.find("Bônus de vitória: +0") >= 0, "loss result shows that no completion bonus was granted")
	_check(screen.ui["end_xp_total"].visible and screen.ui["end_xp_total"].text == "Total de XP ganho: +5", "loss result places total XP in its own label")
	_test_xp_result_spacing(screen)
	_check(screen.badge_popup != null and screen.badge_popup.visible, "Security unlock popup appears over the result screen")
	_check(is_equal_approx(screen.badge_popup.body_text_multiplier, screen.BODY_TEXT_SCALE), "badge popup body text uses the data-protection font increase")
	var previous_seed: int = screen.current_maze_seed
	var old_hacker_nodes: Array = []
	for hacker in screen.hackers:
		old_hacker_nodes.append(hacker["node"])
	screen._on_restart_pressed()
	yield(self, "idle_frame")
	var active_hacker_count: int = 0
	for child in screen.ui["board"].get_children():
		if child.name.begins_with("Hacker"):
			active_hacker_count += 1
	_check(active_hacker_count == 3, "restarting leaves exactly three hacker sprites in the maze")
	_check(screen.current_maze_seed != previous_seed, "restarting generates the maze with a new random seed")
	_check(screen.phase == "ready" and not screen.intro_popup, "replay waits for movement without showing the intro popup")
	_check(not screen.ui["modal_backdrop"].visible, "replay has no intro popup backdrop")
	for node in old_hacker_nodes:
		_check(not is_instance_valid(node), "restarting removes each previous hacker sprite")
	var xp_before_win: int = progression.get_total_experience()
	screen._finish_round(true)
	_check(progression.get_total_experience() == xp_before_win + 200, "winning grants the 200 XP data-protection bonus")
	screen._finish_round(true)
	_check(progression.get_total_experience() == xp_before_win + 200, "repeated round finish cannot grant the bonus twice")
	_check(screen.ui["end_title"].text.find("Parabéns") >= 0, "win result congratulates Gabivara")
	_check(screen.ui["end_message"].text.find("Todos os %d dados estão protegidos" % screen.total_data_count) >= 0, "win result confirms all data is protected")
	_check(screen.ui["end_message"].text.find("Bônus de vitória: +200") >= 0, "win result shows its XP completion bonus")
	_check(screen.ui["end_xp_total"].text == "Total de XP ganho: +200", "win result shows total XP earned")
	_test_xp_result_spacing(screen)
	var xp_before_exit: int = progression.get_total_experience()
	var seed_before_exit: int = screen.current_maze_seed
	_check(not screen.handle_back_request(), "system back returns control to navigation after resetting the round")
	_check(screen.phase == "ready" and screen.collected_count == 0 and screen.lives == screen.INITIAL_LIVES, "back resets temporary round state")
	_check(screen.data_items.size() == screen.total_data_count, "back resets all uncollected data into a fresh maze")
	_check(screen.current_maze_seed != seed_before_exit, "back prepares a newly generated maze")
	_check(progression.get_total_experience() == xp_before_exit, "back reset does not alter already persisted XP")


func _test_xp_result_spacing(screen) -> void:
	for viewport_size in [Vector2(720, 1280), Vector2(1280, 720), Vector2(320, 568)]:
		screen._layout_screen(viewport_size)
		var xp_label: Control = screen.ui["end_xp_total"]
		var restart: Control = screen.ui["restart"]
		var gap: float = restart.rect_position.y - (xp_label.rect_position.y + xp_label.rect_size.y)
		_check(is_equal_approx(gap, viewport_size.y * 0.05), "result leaves a five-percent viewport-height gap below total XP at %s" % viewport_size)
		_check(_fits_viewport(xp_label, viewport_size), "total XP label fits at %s" % viewport_size)


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

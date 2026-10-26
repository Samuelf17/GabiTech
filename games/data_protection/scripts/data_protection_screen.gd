extends Control

const TYPOGRAPHY = preload("res://shared/ui/typography.gd")
const MAZE_MODEL = preload("res://games/data_protection/scripts/maze_model.gd")
const DATA_TEXTURE = preload("res://games/data_protection/assets/planilha_icon.svg")
const HACKER_TEXTURE = preload("res://games/data_protection/assets/olho.png")
const BADGE_UNLOCK_POPUP = preload("res://shared/ui/badge_unlock_popup.gd")
const MAP_SCENE_PATH = "res://app/menus/map_screen.tscn"
const PLAYER_SPEED_TILES_PER_SECOND: float = 4.5
const HACKER_SPEED_TILES_PER_SECOND: float = 3.0
const INITIAL_LIVES: int = 3
const RESPAWN_GRACE_SECONDS: float = 1.0
const TURN_EARLY_WINDOW_RATIO: float = 0.12
const WALL_COLOR = Color("#06102b")
const WALL_NEON = Color("#1266ff")
const BACKGROUND_COLOR = Color("#020611")
const WHITE = Color("#f3f7ff")
const MUTED = Color("#a8b5d2")
const CYAN = Color("#55e8e2")
const GREEN = Color("#7de889")
const RED = Color("#ff647d")
const DATA_COLOR = Color("#34d399")
var ui: Dictionary = {}
var typography = TYPOGRAPHY.new()
var maze = MAZE_MODEL.new()
var maze_seed_rng := RandomNumberGenerator.new()
var current_maze_seed: int = 0
var current_maze_dimensions := Vector2.ZERO
var player: Dictionary = {}
var hackers: Array = []
var data_items: Dictionary = {}
var player_spawn := Vector2(1, 1)
var desired_direction := Vector2.ZERO
var lives: int = INITIAL_LIVES
var collected_count: int = 0
var total_data_count: int = 0
var phase: String = "playing"
var tile_size: float = 0.0
var board_position := Vector2.ZERO
var current_viewport_size := Vector2.ZERO
var touch_start := Vector2.ZERO
var mouse_start := Vector2.ZERO
var touch_started_on_board: bool = false
var mouse_started_on_board: bool = false
var respawn_grace: float = 0.0
var current_landscape: bool = false
var intro_popup: bool = false
var badge_popup: CanvasLayer
var round_id: String = ""
var round_xp_from_data: int = 0
var round_xp_completion_bonus: int = 0


func _ready() -> void:
	_build_screen()
	get_viewport().connect("size_changed", self, "_on_viewport_size_changed")
	current_viewport_size = get_viewport_rect().size
	current_landscape = current_viewport_size.x > current_viewport_size.y
	maze_seed_rng.randomize()
	_reset_round(true)
	_layout_screen(current_viewport_size)


func _build_screen() -> void:
	var background := ColorRect.new()
	background.name = "NeonMazeBackground"
	background.color = BACKGROUND_COLOR
	background.anchor_right = 1.0
	background.anchor_bottom = 1.0
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)
	ui["background"] = background

	ui["back"] = _new_button("VOLTAR", "button")
	ui["back"].connect("pressed", self, "_on_map_pressed")
	ui["title"] = _new_label("DEFESA DOS DADOS", WHITE, "heading", Label.ALIGN_CENTER)
	ui["subtitle"] = _new_label("Fuja dos hackers e recupere todos os dados", MUTED, "body", Label.ALIGN_CENTER)
	ui["score"] = _new_label("DADOS 0 / 0", CYAN, "body", Label.ALIGN_LEFT)
	ui["lives"] = _new_label("VIDAS 3", GREEN, "body", Label.ALIGN_RIGHT)

	var board := Control.new()
	board.name = "NeonMazeBoard"
	board.mouse_filter = Control.MOUSE_FILTER_IGNORE
	board.connect("draw", self, "_draw_board")
	add_child(board)
	ui["board"] = board

	var modal_backdrop := ColorRect.new()
	modal_backdrop.name = "MazeModalBackdrop"
	modal_backdrop.color = Color(0.0, 0.0, 0.0, 0.78)
	modal_backdrop.anchor_right = 1.0
	modal_backdrop.anchor_bottom = 1.0
	modal_backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	modal_backdrop.visible = false
	add_child(modal_backdrop)
	ui["modal_backdrop"] = modal_backdrop

	ui["end_panel"] = _new_panel("RoundEndPanel", Color("#09152d"), Color("#2c5fb5"))
	ui["end_panel"].visible = false
	ui["end_title"] = _new_label("", WHITE, "heading", Label.ALIGN_CENTER)
	ui["end_message"] = _new_label("", MUTED, "body", Label.ALIGN_CENTER)
	ui["end_xp_total"] = _new_label("", WHITE, "body", Label.ALIGN_CENTER)
	ui["intro_close"] = _new_button("FECHAR TUTORIAL", "button")
	ui["intro_close"].connect("pressed", self, "_on_intro_close_pressed")
	ui["restart"] = _new_button("JOGAR NOVAMENTE", "button")
	ui["restart"].connect("pressed", self, "_on_restart_pressed")
	ui["map"] = _new_button("VOLTAR AO MAPA", "button")
	ui["map"].connect("pressed", self, "_on_map_pressed")
	for key in ["end_title", "end_message", "end_xp_total", "intro_close", "restart", "map"]:
		ui[key].visible = false

	ui["board"].focus_mode = Control.FOCUS_ALL
	ui["board"].grab_focus()
	ui["background"].raise()
	ui["board"].raise()
	for key in ["back", "title", "subtitle", "score", "lives", "modal_backdrop", "end_panel", "end_title", "end_message", "end_xp_total", "intro_close", "restart", "map"]:
		ui[key].raise()


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
	button.add_stylebox_override("normal", _stylebox(Color("#122348"), Color("#2675d8"), 12, 2))
	button.add_stylebox_override("hover", _stylebox(Color("#1b3568"), CYAN, 12, 2))
	button.add_stylebox_override("focus", _stylebox(Color("#1b3568"), CYAN, 12, 2))
	button.add_stylebox_override("pressed", _stylebox(Color("#0c1b3b"), CYAN, 12, 2))
	button.add_color_override("font_color", WHITE)
	button.add_color_override("font_color_hover", CYAN)
	add_child(button)
	return button


func _new_panel(panel_name: String, fill: Color, border: Color) -> Panel:
	var panel := Panel.new()
	panel.name = panel_name
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_stylebox_override("panel", _stylebox(fill, border, 22, 2))
	add_child(panel)
	return panel


func _stylebox(fill: Color, border: Color, radius: int, border_width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(radius)
	return style


func _reset_round(show_intro: bool = false) -> void:
	phase = "ready"
	round_id = _new_round_id()
	round_xp_from_data = 0
	round_xp_completion_bonus = 0
	intro_popup = show_intro
	lives = INITIAL_LIVES
	collected_count = 0
	desired_direction = Vector2.ZERO
	touch_started_on_board = false
	mouse_started_on_board = false
	respawn_grace = 0.8
	var maze_dimensions: Vector2 = _maze_dimensions_for_viewport(current_viewport_size)
	current_maze_dimensions = maze_dimensions
	current_maze_seed = maze_seed_rng.randi()
	maze = MAZE_MODEL.new(current_maze_seed, int(maze_dimensions.x), int(maze_dimensions.y))
	data_items.clear()
	var hacker_spawns: Array = _hacker_spawns()
	for cell in maze.get_open_cells():
		if cell != player_spawn and not hacker_spawns.has(cell):
			data_items[_cell_key(cell)] = cell
	total_data_count = data_items.size()
	if player.has("node") and is_instance_valid(player["node"]):
		player["node"].queue_free()
	player = _create_actor(player_spawn, load(_mascot_texture_path()), WHITE, "PlayerCapybara")
	for hacker in hackers:
		if hacker.has("node") and is_instance_valid(hacker["node"]):
			hacker["node"].queue_free()
	hackers.clear()
	for index in range(hacker_spawns.size()):
		var hacker := _create_actor(hacker_spawns[index], HACKER_TEXTURE, WHITE, "Hacker%d" % index)
		hackers.append(hacker)
	ui["modal_backdrop"].visible = show_intro
	ui["end_panel"].visible = show_intro
	ui["end_title"].text = "Proteja seus arquivos!" if show_intro else ""
	ui["end_message"].text = "Ajude a Gabivara a coletar todos os arquivos enquanto foge dos spywares! Cuidado com os olhos pixelizados: eles estão à espreita para roubar seus dados. Colete tudo e escape sem ser capturado!" if show_intro else ""
	ui["end_title"].visible = show_intro
	ui["end_message"].visible = show_intro
	ui["end_xp_total"].visible = false
	ui["intro_close"].visible = show_intro
	ui["restart"].visible = false
	ui["map"].visible = false
	ui["subtitle"].text = "Fuja dos hackers e recupere todos os dados" if show_intro else "Mova para começar"
	_update_hud()
	ui["board"].update()
	_apply_actor_positions()
	ui["board"].grab_focus()


func _mascot_texture_path() -> String:
	var progression = get_node_or_null("/root/Progression")
	var level: int = 1
	if progression != null:
		var state: Dictionary = progression.call("get_state")
		level = int(state.get("level", 1))
	level = clamp(level, 1, 10)
	return "res://shared/mascot/levels/%d.png" % level


func _new_round_id() -> String:
	return "data_protection:%d:%d:%d" % [OS.get_unix_time(), OS.get_ticks_msec(), randi()]


func _hacker_spawns() -> Array:
	return [
		Vector2(maze.width - 2, maze.height - 2),
		Vector2(maze.width - 2, 1),
		Vector2(1, maze.height - 2)
	]


func _maze_dimensions_for_viewport(viewport_size: Vector2) -> Vector2:
	var target_ratio: float = (viewport_size.x * 0.90) / max(1.0, viewport_size.y * 0.76)
	var best_size := Vector2(15, 21) if viewport_size.y >= viewport_size.x else Vector2(21, 9)
	var smallest_error: float = 1000000.0
	var min_width: int = 11 if viewport_size.y >= viewport_size.x else 15
	var max_width: int = 17 if viewport_size.y >= viewport_size.x else 27
	var min_height: int = 17 if viewport_size.y >= viewport_size.x else 9
	var max_height: int = 25 if viewport_size.y >= viewport_size.x else 15
	for candidate_height in range(min_height, max_height + 1, 2):
		for candidate_width in range(min_width, max_width + 1, 2):
			var ratio: float = float(candidate_width) / float(candidate_height)
			var error: float = abs(ratio - target_ratio)
			if error < smallest_error:
				smallest_error = error
				best_size = Vector2(candidate_width, candidate_height)
	return best_size


func _create_actor(cell: Vector2, texture: Texture, tint: Color, actor_name: String) -> Dictionary:
	var actor_node := TextureRect.new()
	actor_node.name = actor_name
	actor_node.texture = texture
	actor_node.expand = true
	actor_node.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	actor_node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	actor_node.modulate = tint
	ui["board"].add_child(actor_node)
	return {"cell": cell, "offset": 0.0, "direction": Vector2.ZERO, "node": actor_node}


func _process(delta: float) -> void:
	if phase != "playing":
		return
	respawn_grace = max(0.0, respawn_grace - delta)
	player = _advance_actor(player, PLAYER_SPEED_TILES_PER_SECOND, delta, true)
	for index in range(hackers.size()):
		hackers[index] = _advance_actor(hackers[index], HACKER_SPEED_TILES_PER_SECOND, delta, false)
	if respawn_grace <= 0.0:
		_check_hacker_collisions()


func _advance_actor(actor: Dictionary, speed_tiles_per_second: float, delta: float, is_player: bool) -> Dictionary:
	var distance_left: float = speed_tiles_per_second * min(delta, 0.1) * tile_size
	if is_player:
		actor = _apply_buffered_player_turn(actor)
	var iterations: int = 0
	while distance_left > 0.0 and iterations < 3:
		iterations += 1
		var cell: Vector2 = actor["cell"]
		var offset: float = actor["offset"]
		if offset <= 0.01:
			if is_player:
				if _can_move(cell, desired_direction):
					actor["direction"] = desired_direction
				elif not _can_move(cell, actor["direction"]):
					actor["direction"] = Vector2.ZERO
			else:
				actor["direction"] = _choose_hacker_direction(cell, actor["direction"])
		var direction: Vector2 = actor["direction"]
		if direction == Vector2.ZERO or not _can_move(cell, direction):
			break
		var distance_to_next_cell: float = tile_size - offset
		var step: float = min(distance_left, distance_to_next_cell)
		offset += step
		distance_left -= step
		if offset >= tile_size - 0.01:
			cell += direction
			offset = 0.0
		actor["cell"] = cell
		actor["offset"] = offset
		_set_actor_position(actor)
		if is_player and offset == 0.0:
			_collect_data(cell)
	return actor


func _apply_buffered_player_turn(actor: Dictionary) -> Dictionary:
	var direction: Vector2 = actor["direction"]
	var desired: Vector2 = desired_direction
	var offset: float = actor["offset"]
	if direction == Vector2.ZERO or offset <= 0.01 or desired == direction:
		return actor
	if desired == -direction:
		actor["cell"] = actor["cell"] + direction
		actor["offset"] = tile_size - offset
		actor["direction"] = desired
		_set_actor_position(actor)
		return actor
	if abs(direction.dot(desired)) > 0.01:
		return actor
	var next_cell: Vector2 = actor["cell"] + direction
	var turn_window: float = tile_size * TURN_EARLY_WINDOW_RATIO
	if tile_size - offset <= turn_window and _can_move(next_cell, desired):
		actor["cell"] = next_cell
		actor["offset"] = 0.0
		actor["direction"] = desired
		_set_actor_position(actor)
		_collect_data(next_cell)
	return actor


func _choose_hacker_direction(cell: Vector2, current_direction: Vector2) -> Vector2:
	var legal: Array = maze.get_legal_directions(cell)
	if legal.empty():
		return Vector2.ZERO
	var options: Array = []
	for direction in legal:
		if direction != -current_direction:
			options.append(direction)
	if options.empty():
		options = legal
	return options[randi() % options.size()]


func _can_move(cell: Vector2, direction: Vector2) -> bool:
	return direction != Vector2.ZERO and maze.is_open(cell + direction)


func _collect_data(cell: Vector2) -> void:
	var key: String = _cell_key(cell)
	if not data_items.has(key):
		return
	data_items.erase(key)
	collected_count += 1
	var progression = get_node_or_null("/root/Progression")
	if progression != null:
		if progression.call("record_protected_data"):
			round_xp_from_data += 5
		else:
			push_error("Não foi possível salvar o XP e o progresso dos dados coletados.")
	_update_hud()
	ui["board"].update()
	if data_items.empty():
		_finish_round(true)


func _check_hacker_collisions() -> void:
	var player_position: Vector2 = _actor_local_position(player)
	for hacker in hackers:
		if player_position.distance_to(_actor_local_position(hacker)) <= tile_size * 0.58:
			lives -= 1
			_update_hud()
			if lives <= 0:
				_finish_round(false)
				return
			_respawn_actors()
			return


func _respawn_actors() -> void:
	player["cell"] = player_spawn
	player["offset"] = 0.0
	player["direction"] = Vector2.ZERO
	desired_direction = Vector2.ZERO
	var hacker_spawns: Array = _hacker_spawns()
	for index in range(hackers.size()):
		hackers[index]["cell"] = hacker_spawns[index]
		hackers[index]["offset"] = 0.0
		hackers[index]["direction"] = Vector2.ZERO
	respawn_grace = RESPAWN_GRACE_SECONDS
	_apply_actor_positions()


func _finish_round(won: bool) -> void:
	if phase == "finished":
		return
	phase = "finished"
	var progression = get_node_or_null("/root/Progression")
	if progression != null:
		if not progression.call("complete_data_protection_round", round_id, won):
			push_error("Não foi possível salvar a recompensa da rodada de Defesa dos Dados.")
		elif won:
			round_xp_completion_bonus = 200
	var total_round_xp: int = round_xp_from_data + round_xp_completion_bonus
	var result_message: String = "Todos os %d dados estão protegidos! Proteger suas informações ajuda a manter sua privacidade." % total_data_count if won else "A Gabivara protegeu %d de %d dados. Proteger informações pessoais, como nome, endereço e senhas, ajuda a evitar golpes e o uso sem permissão." % [collected_count, total_data_count]
	ui["end_title"].text = "Parabéns, Gabivara!" if won else "A Gabivara ficou sem vidas"
	ui["end_message"].text = "%s\n\nXP pelos dados: +%d\nBônus de vitória: +%d" % [result_message, round_xp_from_data, round_xp_completion_bonus]
	ui["end_xp_total"].text = "Total de XP ganho: +%d" % total_round_xp
	ui["modal_backdrop"].visible = true
	ui["end_panel"].visible = true
	for key in ["end_title", "end_message", "end_xp_total", "restart", "map"]:
		ui[key].visible = true
	_layout_screen(current_viewport_size)
	_show_next_pending_badge_notification()


func _show_next_pending_badge_notification() -> void:
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


func _update_hud() -> void:
	if not ui.has("score"):
		return
	ui["score"].text = "DADOS %d / %d" % [collected_count, total_data_count]
	ui["lives"].text = "VIDAS %d" % lives
	ui["lives"].add_color_override("font_color", GREEN if lives > 1 else RED)


func _draw_board() -> void:
	if tile_size <= 0.0:
		return
	var size := Vector2(maze.width * tile_size, maze.height * tile_size)
	ui["board"].draw_rect(Rect2(Vector2.ZERO, size), BACKGROUND_COLOR, true)
	for y in range(maze.height):
		for x in range(maze.width):
			var cell := Vector2(x, y)
			var rect := Rect2(x * tile_size, y * tile_size, tile_size, tile_size)
			if not maze.is_open(cell):
				ui["board"].draw_rect(rect, WALL_COLOR, true)
				continue
			for direction in MAZE_MODEL.DIRECTIONS:
				if maze.is_open(cell + direction):
					continue
				var edge_start: Vector2 = _wall_edge_start(cell, direction)
				var edge_end: Vector2 = _wall_edge_end(cell, direction)
				var glow := WALL_NEON
				glow.a = 0.22
				ui["board"].draw_line(edge_start, edge_end, glow, max(4.0, tile_size * 0.20), true)
				ui["board"].draw_line(edge_start, edge_end, WALL_NEON, max(2.0, tile_size * 0.055), true)
	for key in data_items:
		var cell: Vector2 = data_items[key]
		var data_size: float = tile_size * 0.55
		var data_rect := Rect2(Vector2(cell.x * tile_size, cell.y * tile_size) + Vector2.ONE * (tile_size - data_size) * 0.5, Vector2.ONE * data_size)
		ui["board"].draw_texture_rect(DATA_TEXTURE, data_rect, false, DATA_COLOR)


func _wall_edge_start(cell: Vector2, direction: Vector2) -> Vector2:
	var center: Vector2 = _cell_local_position(cell)
	if direction == Vector2.UP:
		return center + Vector2(-tile_size * 0.5, -tile_size * 0.5)
	if direction == Vector2.RIGHT:
		return center + Vector2(tile_size * 0.5, -tile_size * 0.5)
	if direction == Vector2.DOWN:
		return center + Vector2(-tile_size * 0.5, tile_size * 0.5)
	return center + Vector2(-tile_size * 0.5, -tile_size * 0.5)


func _wall_edge_end(cell: Vector2, direction: Vector2) -> Vector2:
	var center: Vector2 = _cell_local_position(cell)
	if direction == Vector2.UP:
		return center + Vector2(tile_size * 0.5, -tile_size * 0.5)
	if direction == Vector2.RIGHT:
		return center + Vector2(tile_size * 0.5, tile_size * 0.5)
	if direction == Vector2.DOWN:
		return center + Vector2(tile_size * 0.5, tile_size * 0.5)
	return center + Vector2(-tile_size * 0.5, tile_size * 0.5)


func _layout_screen(viewport_size: Vector2) -> void:
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		return
	current_viewport_size = viewport_size
	var width: float = viewport_size.x
	var height: float = viewport_size.y
	var landscape: bool = width > height
	var short_side: float = min(width, height)
	_place(ui["background"], 0.0, 0.0, width, height)
	_place(ui["back"], width * 0.035, height * 0.035, width * (0.20 if not landscape else 0.13), height * 0.055, short_side)
	_place(ui["title"], width * 0.21, height * 0.025, width * 0.74, height * 0.06, short_side)
	_place(ui["subtitle"], width * 0.08, height * 0.09, width * 0.84, height * 0.04, short_side)
	_place(ui["score"], width * 0.08, height * 0.145, width * 0.50, height * 0.045, short_side)
	_place(ui["lives"], width * 0.60, height * 0.145, width * 0.32, height * 0.045, short_side)
	var board_area := Rect2(width * 0.05, height * 0.20, width * 0.90, height * 0.76)
	var landscape_view: bool = width > height
	var desired_maze_dimensions: Vector2 = _maze_dimensions_for_viewport(viewport_size)
	if landscape_view != current_landscape or desired_maze_dimensions != current_maze_dimensions:
		var keep_intro_popup: bool = intro_popup
		current_landscape = landscape_view
		_reset_round(keep_intro_popup)
	tile_size = min(board_area.size.x / float(maze.width), board_area.size.y / float(maze.height))
	var board_size := Vector2(maze.width * tile_size, maze.height * tile_size)
	board_position = board_area.position + (board_area.size - board_size) * 0.5
	_place(ui["board"], board_position.x, board_position.y, board_size.x, board_size.y)
	_layout_end_panel(width, height, short_side, landscape)
	_apply_actor_positions()
	ui["board"].update()


func _layout_end_panel(width: float, height: float, short_side: float, landscape: bool) -> void:
	var panel_width: float = width * (0.60 if landscape else 0.86)
	var panel_height: float = height * (0.66 if landscape else 0.50)
	var panel_x: float = (width - panel_width) * 0.5
	var panel_y: float = (height - panel_height) * 0.5
	_place(ui["end_panel"], panel_x, panel_y, panel_width, panel_height)
	_place(ui["end_title"], panel_x + panel_width * 0.07, panel_y + panel_height * 0.06, panel_width * 0.86, panel_height * 0.17, short_side)
	_place(ui["end_message"], panel_x + panel_width * 0.08, panel_y + panel_height * 0.25, panel_width * 0.84, panel_height * 0.43, short_side)
	var xp_y_ratio: float = 0.60 if not landscape else 0.62
	var xp_height_ratio: float = 0.08 if not landscape else 0.07
	var xp_y: float = panel_y + panel_height * xp_y_ratio
	var xp_height: float = panel_height * xp_height_ratio
	_place(ui["end_xp_total"], panel_x + panel_width * 0.08, xp_y, panel_width * 0.84, xp_height, short_side)
	var actions_y: float = xp_y + xp_height + height * 0.05
	_place(ui["intro_close"], panel_x + panel_width * 0.08, panel_y + panel_height * 0.79, panel_width * 0.84, panel_height * 0.12, short_side)
	_place(ui["restart"], panel_x + panel_width * 0.08, actions_y, panel_width * 0.84, panel_height * 0.10, short_side)
	_place(ui["map"], panel_x + panel_width * 0.08, actions_y + panel_height * 0.11, panel_width * 0.84, panel_height * 0.10, short_side)


func _apply_actor_positions() -> void:
	if tile_size <= 0.0:
		return
	_set_actor_position(player)
	for hacker in hackers:
		_set_actor_position(hacker)


func _set_actor_position(actor: Dictionary) -> void:
	if actor.empty() or not actor.has("node") or not is_instance_valid(actor["node"]):
		return
	var actor_size: float = tile_size * 0.88
	var center: Vector2 = _actor_local_position(actor)
	actor["node"].rect_position = center - Vector2.ONE * actor_size * 0.5
	actor["node"].rect_size = Vector2.ONE * actor_size


func _actor_local_position(actor: Dictionary) -> Vector2:
	return _cell_local_position(actor["cell"]) + actor["direction"] * actor["offset"]


func _cell_local_position(cell: Vector2) -> Vector2:
	return (cell + Vector2.ONE * 0.5) * tile_size


func _place(control: Control, x: float, y: float, width: float, height: float, font_basis: float = 720.0) -> void:
	if control.has_meta("font_role"):
		var font: Font = typography.get_base_font(control)
		var role: String = control.get_meta("font_role")
		if font != null and typography.has_role(role):
			var scale: float = typography.get_target_height(role, font_basis) / font.get_height()
			if control is Label or control is Button:
				scale = min(scale, _fit_font_to_control(control, font, width, height, scale))
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


func _fit_font_to_control(control: Control, font: Font, width: float, height: float, maximum_scale: float) -> float:
	var text: String = control.text
	var scale: float = maximum_scale
	if control is Button:
		var text_width: float = font.get_string_size(text).x
		if text_width > 0.0:
			scale = min(scale, width / text_width)
	else:
		for _iteration in range(3):
			var text_size: Vector2 = font.get_wordwrap_string_size(text, max(1.0, width / scale))
			if text_size.y * scale <= height or text_size.y <= 0.0:
				break
			scale *= height / (text_size.y * scale)
	return max(0.01, scale)


func _cell_key(cell: Vector2) -> String:
	return "%d,%d" % [int(cell.x), int(cell.y)]


func _set_direction(direction: Vector2) -> void:
	if direction == Vector2.UP or direction == Vector2.RIGHT or direction == Vector2.DOWN or direction == Vector2.LEFT:
		desired_direction = direction
		if phase == "ready" and _can_move(player["cell"], direction):
			phase = "playing"
			intro_popup = false
			ui["modal_backdrop"].visible = false
			ui["end_panel"].visible = false
			ui["end_title"].visible = false
			ui["end_message"].visible = false
			ui["end_xp_total"].visible = false
			ui["intro_close"].visible = false
			ui["subtitle"].text = "Fuja dos hackers e recupere todos os dados"


func _apply_swipe_delta(delta: Vector2) -> void:
	if delta.length() < min(current_viewport_size.x, current_viewport_size.y) * 0.035:
		return
	if abs(delta.x) > abs(delta.y):
		_set_direction(Vector2.RIGHT if delta.x > 0.0 else Vector2.LEFT)
	else:
		_set_direction(Vector2.DOWN if delta.y > 0.0 else Vector2.UP)


func _input(event: InputEvent) -> void:
	if phase != "playing" and phase != "ready":
		return
	if event is InputEventKey and event.pressed and not event.echo:
		var key: int = event.scancode
		if key == KEY_W:
			_set_direction(Vector2.UP)
		elif key == KEY_A:
			_set_direction(Vector2.LEFT)
		elif key == KEY_S:
			_set_direction(Vector2.DOWN)
		elif key == KEY_D:
			_set_direction(Vector2.RIGHT)
	elif event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed:
			touch_started_on_board = _is_board_position(touch.position)
			if touch_started_on_board:
				touch_start = touch.position
		else:
			if touch_started_on_board and _is_board_position(touch.position):
				_apply_swipe_delta(touch.position - touch_start)
			touch_started_on_board = false
	elif event is InputEventMouseButton and event.button_index == BUTTON_LEFT:
		var mouse := event as InputEventMouseButton
		if mouse.pressed:
			mouse_started_on_board = _is_board_position(mouse.position)
			if mouse_started_on_board:
				mouse_start = mouse.position
		else:
			if mouse_started_on_board and _is_board_position(mouse.position):
				_apply_swipe_delta(mouse.position - mouse_start)
			mouse_started_on_board = false


func _is_board_position(position: Vector2) -> bool:
	return ui.has("board") and ui["board"].get_global_rect().has_point(position)


func _on_restart_pressed() -> void:
	_reset_round()
	_layout_screen(current_viewport_size)


func _on_intro_close_pressed() -> void:
	if phase != "ready" or not intro_popup:
		return
	intro_popup = false
	ui["modal_backdrop"].visible = false
	ui["end_panel"].visible = false
	ui["end_title"].visible = false
	ui["end_message"].visible = false
	ui["end_xp_total"].visible = false
	ui["intro_close"].visible = false
	ui["subtitle"].text = "Mova para começar"


func _on_map_pressed() -> void:
	_reset_before_leaving()
	get_node("/root/NavigationHistory").call("navigate_to", MAP_SCENE_PATH)


func _reset_before_leaving() -> void:
	_reset_round()
	_layout_screen(current_viewport_size)


func handle_back_request() -> bool:
	_reset_before_leaving()
	return false


func _on_viewport_size_changed() -> void:
	_layout_screen(get_viewport_rect().size)

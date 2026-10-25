extends Control

const BOTTOM_NAVIGATION = preload("res://shared/ui/bottom_navigation.tscn")
const TYPOGRAPHY = preload("res://shared/ui/typography.gd")
const BADGE_CATALOG = preload("res://shared/progress/badge_catalog.gd")
const BADGE_GRAYSCALE_SHADER = preload("res://shared/ui/assets/shaders/badge_grayscale.shader")
const QUESTION_REPOSITORY = preload("res://games/quiz/scripts/quiz_question_repository.gd")
const DAILY_PROGRESS = preload("res://games/quiz/scripts/quiz_daily_progress.gd")
const BACKGROUND_TEXTURE = preload("res://shared/ui/assets/backgrounds/fundo.png")
const NON_HOME_TITLE_SCALE: float = 1.10
const SHIELD_ICON = preload("res://shared/ui/assets/icons/shield_icon.svg")
const NAVY = Color("#071126")
const PANEL = Color("#0b1735")
const PANEL_LIGHT = Color("#14254a")
const WHITE = Color("#f3f7ff")
const MUTED = Color("#a8b5d2")
const CYAN = Color("#28e3dc")
const BADGE_ICON_SCALE: float = 1.20
const BADGES = BADGE_CATALOG.BADGES
const LOCKED_BADGE_COLOR = Color("#778196")
var ui: Dictionary = {}
var badge_controls: Array = []
var current_viewport_size := Vector2.ZERO
var selected_tab: String = "DISTINTIVOS"
var typography = TYPOGRAPHY.new()
var progression_service: Node
var daily_progress = DAILY_PROGRESS.new()
var daily_progress_storage_path: String = DAILY_PROGRESS.SAVE_PATH


func _ready() -> void:
	progression_service = get_node_or_null("/root/Progression")
	_build_screen()
	if progression_service != null:
		progression_service.connect("progress_changed", self, "_on_progress_changed")
	_refresh_progress_ui()
	_refresh_daily_quiz_ui()
	get_viewport().connect("size_changed", self, "_on_viewport_size_changed")
	_layout_screen(get_viewport_rect().size)


func _build_screen() -> void:
	var background := TextureRect.new()
	background.name = "ProfileBackground"
	background.texture = BACKGROUND_TEXTURE
	background.expand = true
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.anchor_right = 1.0
	background.anchor_bottom = 1.0
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)
	ui["background"] = background

	ui["header"] = _new_label("RECOMPENSAS", WHITE, "title", Label.ALIGN_CENTER)
	ui["hero_panel"] = _new_panel("GuardianPointsPanel", PANEL, Color("#12375c"), 20)
	var hero_shield := TextureRect.new()
	hero_shield.name = "GuardianShield"
	hero_shield.texture = SHIELD_ICON
	hero_shield.expand = true
	hero_shield.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	hero_shield.modulate = CYAN
	hero_shield.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(hero_shield)
	ui["hero_shield"] = hero_shield
	ui["points_label"] = _new_label("EXPERIÊNCIA TOTAL", MUTED, "points_label")
	ui["points"] = _new_label("0", WHITE, "points")
	ui["support"] = _new_label("Itens desbloqueados: 0", Color("#a6e85d"), "support")

	ui["level_panel"] = _new_panel("LevelProgressPanel", PANEL, Color("#315076"), 16)
	ui["level_caption"] = _new_label("NÍVEL 1", WHITE, "level")
	ui["xp_value"] = _new_label("0 / 2.000 XP", WHITE, "level", Label.ALIGN_RIGHT)
	ui["xp_track"] = _new_panel("XPTrack", Color("#18284a"), Color("#18284a"), 12)
	ui["xp_fill"] = _new_panel("XPFill", Color("#48dfae"), Color("#48dfae"), 12)

	ui["tabs_panel"] = _new_panel("BadgeTabs", PANEL, Color("#202e54"), 14)
	ui["tabs"] = {}
	for tab_name in ["DISTINTIVOS", "COLEÇÃO"]:
		var tab := Button.new()
		tab.name = "Tab_" + tab_name.to_lower()
		tab.text = tab_name
		tab.focus_mode = Control.FOCUS_ALL
		tab.set_meta("font_role", "tab")
		tab.add_stylebox_override("normal", _stylebox(PANEL, PANEL, 10, 0))
		tab.add_stylebox_override("hover", _stylebox(PANEL_LIGHT, CYAN, 10, 1))
		tab.add_stylebox_override("focus", _stylebox(PANEL_LIGHT, CYAN, 10, 1))
		tab.add_color_override("font_color", MUTED)
		tab.add_color_override("font_color_hover", WHITE)
		tab.connect("pressed", self, "_on_tab_pressed", [tab_name])
		add_child(tab)
		ui["tabs"][tab_name] = tab
	_apply_tab_style()

	for badge in BADGES:
		var badge_item := {}
		var icon := TextureRect.new()
		icon.name = "BadgeIcon_" + badge["name"].to_lower()
		icon.texture = badge["texture"]
		icon.expand = true
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		var icon_material := ShaderMaterial.new()
		icon_material.shader = BADGE_GRAYSCALE_SHADER
		icon_material.set_shader_param("grayscale_amount", 1.0)
		icon.material = icon_material
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(icon)
		badge_item["icon"] = icon
		badge_item["material"] = icon_material
		badge_item["name"] = _new_label(badge["name"], LOCKED_BADGE_COLOR, "badge", Label.ALIGN_CENTER)
		badge_item["level"] = _new_label("NÍVEL 0", LOCKED_BADGE_COLOR, "badge_level", Label.ALIGN_CENTER)
		badge_item["id"] = badge["id"]
		badge_item["color"] = badge["color"]
		badge_controls.append(badge_item)

	ui["challenge_panel"] = _new_panel("DailyQuizPanel", Color("#191b4a"), Color("#383474"), 18)
	ui["challenge_title"] = _new_label("★  QUIZ DIÁRIO", Color("#c06bff"), "challenge")
	ui["challenge_text"] = _new_label("Perguntas respondidas hoje", WHITE, "challenge_body")
	ui["challenge_count"] = _new_label("0 / 5", WHITE, "reward_progress", Label.ALIGN_CENTER)
	ui["challenge_track"] = _new_panel("DailyQuizTrack", Color("#30265b"), Color("#30265b"), 10)
	ui["challenge_fill"] = _new_panel("DailyQuizFill", Color("#a951ed"), Color("#a951ed"), 10)

	ui["status"] = _new_label("", CYAN, "support", Label.ALIGN_CENTER)

	var navigation = BOTTOM_NAVIGATION.instance()
	navigation.name = "BottomNavigation"
	navigation.active_item = "profile"
	navigation.connect("item_selected", self, "_on_nav_pressed")
	add_child(navigation)
	ui["navigation"] = navigation
	navigation.buttons["profile"].grab_focus()


func _layout_screen(viewport_size: Vector2) -> void:
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		return
	current_viewport_size = viewport_size
	var width: float = viewport_size.x
	var height: float = viewport_size.y
	var short_side: float = min(width, height)
	var safe: float = short_side * 0.04
	var landscape: bool = width > height
	var nav_top: float = ui["navigation"].get_bar_top(viewport_size)
	var header_y: float = height * (0.055 if landscape else 0.045)
	_place(ui["header"], safe, header_y, width - safe * 2.0, height * 0.055, short_side)
	if landscape:
		_layout_landscape(viewport_size, safe, short_side, nav_top)
	else:
		_layout_portrait(viewport_size, safe, short_side, nav_top)
	ui["navigation"].layout_for_viewport(viewport_size)


func _layout_portrait(viewport_size: Vector2, safe: float, short_side: float, nav_top: float) -> void:
	var width: float = viewport_size.x
	var height: float = viewport_size.y
	var content_x: float = safe
	var content_width: float = width - safe * 2.0
	var hero_y: float = height * 0.105
	var hero_height: float = height * 0.15
	_layout_hero(content_x, hero_y, content_width, hero_height, short_side)

	var level_y: float = hero_y + hero_height + height * 0.012
	var level_height: float = height * 0.07
	_layout_level(content_x, level_y, content_width, level_height, short_side, width)

	var tabs_y: float = level_y + level_height + height * 0.012
	var tabs_height: float = height * 0.05
	_layout_tabs(content_x, tabs_y, content_width, tabs_height, short_side)

	var challenge_height: float = height * 0.105
	var challenge_y: float = nav_top - challenge_height - height * 0.06
	var grid_top: float = tabs_y + tabs_height + height * 0.012
	var grid_bottom: float = challenge_y - height * 0.018
	_layout_badges(viewport_size, content_x, grid_top, content_width, grid_bottom)
	_layout_challenge(content_x, challenge_y, content_width, challenge_height, short_side)
	_place(ui["status"], safe, nav_top - height * 0.043, width - safe * 2.0, height * 0.03, short_side)


func _layout_landscape(viewport_size: Vector2, safe: float, short_side: float, nav_top: float) -> void:
	var width: float = viewport_size.x
	var height: float = viewport_size.y
	var content_x: float = safe
	var content_width: float = width * 0.42
	var badges_x: float = width * 0.46
	var badges_width: float = width - badges_x - safe
	var hero_y: float = height * 0.12
	var hero_height: float = height * 0.20
	_layout_hero(content_x, hero_y, content_width, hero_height, short_side)

	var level_y: float = hero_y + hero_height + height * 0.014
	var level_height: float = height * 0.12
	_layout_level(content_x, level_y, content_width, level_height, short_side, content_width)

	var tabs_y: float = level_y + level_height + height * 0.012
	var tabs_height: float = height * 0.075
	_layout_tabs(content_x, tabs_y, content_width, tabs_height, short_side)

	var challenge_height: float = height * 0.15
	var challenge_y: float = nav_top - challenge_height - height * 0.06
	_layout_challenge(content_x, challenge_y, content_width, challenge_height, short_side)
	var grid_top: float = height * 0.12
	var grid_bottom: float = nav_top - height * 0.02
	_layout_badges(viewport_size, badges_x, grid_top, badges_width, grid_bottom)
	_place(ui["status"], content_x, nav_top - height * 0.043, content_width, height * 0.03, short_side)


func _layout_hero(x: float, y: float, width: float, height: float, short_side: float) -> void:
	_place(ui["hero_panel"], x, y, width, height)
	var icon_size: float = min(height * 0.82, short_side * 0.22)
	_place(ui["hero_shield"], x + width * 0.06, y + (height - icon_size) * 0.5, icon_size, icon_size)
	var points_x: float = x + width * 0.38
	var points_width: float = width * 0.57
	_place(ui["points_label"], points_x, y + height * 0.08, points_width, height * 0.24, short_side)
	_place(ui["points"], points_x, y + height * 0.31, points_width, height * 0.41, short_side)
	_place(ui["support"], points_x, y + height * 0.74, points_width, height * 0.22, short_side)


func _layout_level(x: float, y: float, width: float, height: float, short_side: float, viewport_width: float) -> void:
	_place(ui["level_panel"], x, y, width, height)
	var safe: float = short_side * 0.04
	_place(ui["level_caption"], x + safe * 0.7, y + height * 0.08, width * 0.34, height * 0.34, short_side)
	_place(ui["xp_value"], x + width * 0.52, y + height * 0.08, width * 0.40, height * 0.34, short_side)
	var track_x: float = x + safe * 0.7
	var track_y: float = y + height * 0.55
	var track_width: float = width - safe * 1.4
	var track_height: float = max(short_side * 0.018, height * 0.18)
	_place(ui["xp_track"], track_x, track_y, track_width, track_height)
	_place(ui["xp_fill"], track_x, track_y, track_width * progression_service.get_progress_ratio(), track_height)


func _layout_tabs(x: float, y: float, width: float, height: float, short_side: float) -> void:
	_place(ui["tabs_panel"], x, y, width, height)
	var tab_width: float = (width - short_side * 0.024) / float(ui["tabs"].size())
	for tab_name in ui["tabs"]:
		var tab_index: int = ["DISTINTIVOS", "COLEÇÃO"].find(tab_name)
		_place(ui["tabs"][tab_name], x + short_side * 0.012 + tab_width * tab_index, y + height * 0.08, tab_width, height * 0.84, short_side)


func _layout_badges(viewport_size: Vector2, x: float, top: float, width: float, bottom: float) -> void:
	var short_side: float = min(viewport_size.x, viewport_size.y)
	var cell_width: float = width / 3.0
	var row_height: float = max(1.0, (bottom - top) / 2.0)
	var icon_size: float = _previous_badge_icon_size(viewport_size) * BADGE_ICON_SCALE
	for index in range(badge_controls.size()):
		var row: int = int(index / 3)
		var column: int = index % 3
		var cell_x: float = x + cell_width * column
		var cell_y: float = top + row_height * row
		var cell: Dictionary = badge_controls[index]
		var icon_y: float = cell_y + row_height * 0.015
		cell["icon"].set_meta("size_before_current_increase", icon_size / BADGE_ICON_SCALE)
		_place(cell["icon"], cell_x + (cell_width - icon_size) * 0.5, icon_y, icon_size, icon_size)
		var name_y: float = icon_y + icon_size + row_height * 0.012
		_place(cell["name"], cell_x + cell_width * 0.02, name_y, cell_width * 0.96, row_height * 0.18, short_side)
		_place(cell["level"], cell_x + cell_width * 0.02, name_y + row_height * 0.19, cell_width * 0.96, row_height * 0.15, short_side)


func _previous_badge_icon_size(viewport_size: Vector2) -> float:
	var width: float = viewport_size.x
	var height: float = viewport_size.y
	var short_side: float = min(width, height)
	var safe: float = short_side * 0.04
	var landscape: bool = width > height
	var nav_top: float = ui["navigation"].get_bar_top(viewport_size)
	var hero_y: float = height * (0.105 if landscape else 0.09)
	var hero_height: float = height * (0.19 if landscape else 0.18)
	var level_y: float = hero_y + hero_height + height * 0.018
	var level_height: float = height * (0.12 if landscape else 0.105)
	var tabs_y: float = level_y + level_height + height * 0.018
	var tabs_height: float = height * (0.075 if landscape else 0.065)
	var grid_top: float = tabs_y + tabs_height + height * 0.014
	var challenge_height: float = height * (0.115 if landscape else 0.105)
	var challenge_y: float = nav_top - challenge_height - height * 0.06
	var row_height: float = max(1.0, (challenge_y - height * 0.018 - grid_top) / 2.0)
	var cell_width: float = (width - safe * 2.0) / 3.0
	var previous_base_size: float = min(min(short_side * 0.105, cell_width * 0.38), row_height * 0.49)
	return previous_base_size * 1.15


func _layout_challenge(x: float, y: float, width: float, height: float, short_side: float) -> void:
	_place(ui["challenge_panel"], x, y, width, height)
	var content_x: float = x + short_side * 0.04
	var content_width: float = max(0.0, width - short_side * 0.08)
	_place(ui["challenge_title"], content_x, y + height * 0.10, content_width, height * 0.22, short_side)
	_place(ui["challenge_text"], content_x, y + height * 0.34, content_width, height * 0.25, short_side)
	_place(ui["challenge_count"], content_x, y + height * 0.66, short_side * 0.12, height * 0.22, short_side)
	var track_x: float = content_x + short_side * 0.14
	var track_y: float = y + height * 0.70
	var track_width: float = max(0.0, width - (track_x - x) - short_side * 0.04)
	var track_height: float = max(3.0, height * 0.12)
	_place(ui["challenge_track"], track_x, track_y, track_width, track_height)
	var progress_ratio: float = float(daily_progress.get_answered_count()) / float(DAILY_PROGRESS.DAILY_LIMIT)
	_place(ui["challenge_fill"], track_x, track_y, track_width * progress_ratio, track_height)


func _place(control: Control, x: float, y: float, width: float, height: float, font_basis: float = 720.0) -> void:
	var scale: float = 1.0
	if control.has_meta("font_role"):
		var font: Font = typography.get_base_font(control)
		var role: String = control.get_meta("font_role")
		if font != null and typography.has_role(role):
			scale = typography.get_target_height("body", font_basis) / font.get_height()
			if not typography.is_uniform_body_role(role):
				var title_scale: float = NON_HOME_TITLE_SCALE if typography.is_title_role(role) else 1.0
				var target_scale: float = typography.get_target_height(role, font_basis) * title_scale / font.get_height()
				scale = min(target_scale, _fit_text_scale(control, font, width, height, target_scale))
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
	var scale: float = maximum_scale
	if control is Button:
		var widest_line: float = 0.0
		for line in text.split("\n"):
			widest_line = max(widest_line, font.get_string_size(line).x)
		if widest_line > 0.0:
			scale = min(scale, min(width / widest_line, height / font.get_height()))
	else:
		for _iteration in range(3):
			var wrapped_size: Vector2 = font.get_wordwrap_string_size(text, width / scale)
			var rendered_height: float = wrapped_size.y * scale
			if rendered_height <= height or rendered_height <= 0.0:
				break
			scale *= height / rendered_height
	return max(0.01, scale)


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


func _new_panel(node_name: String, fill: Color, border: Color, radius: int) -> Panel:
	var panel := Panel.new()
	panel.name = node_name
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_stylebox_override("panel", _stylebox(fill, border, radius, 1 if border.a > 0.0 else 0))
	add_child(panel)
	return panel


func _stylebox(fill: Color, border: Color, radius: int, border_width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(radius)
	return style


func _apply_tab_style() -> void:
	for tab_name in ui["tabs"]:
		var tab: Button = ui["tabs"][tab_name]
		var active: bool = tab_name == selected_tab
		tab.add_stylebox_override("normal", _stylebox(CYAN if active else PANEL, CYAN if active else PANEL, 10, 0))
		tab.add_color_override("font_color", NAVY if active else MUTED)


func _on_progress_changed(_state: Dictionary) -> void:
	_refresh_progress_ui()
	_layout_screen(current_viewport_size)


func _refresh_progress_ui() -> void:
	if progression_service != null:
		var progress: Dictionary = progression_service.get_state()
		var level: int = int(progress["level"])
		var current_xp: int = int(progress["experience"])
		var xp_required: int = progression_service.experience_per_level
		var total_xp: int = progression_service.get_total_experience()
		var item_count: int = progress["unlocked_items"].size()
		ui["points"].text = progression_service.format_number(total_xp)
		ui["support"].text = "Itens desbloqueados: %d" % item_count
		ui["level_caption"].text = "NÍVEL %d" % level
		ui["xp_value"].text = "%s / %s XP" % [progression_service.format_number(current_xp), progression_service.format_number(xp_required)]
	_refresh_badges()


func _refresh_daily_quiz_ui() -> void:
	var repository = QUESTION_REPOSITORY.new()
	if not repository.load_questions():
		ui["challenge_text"].text = "Progresso do quiz indisponível."
		ui["challenge_count"].text = "— / %d" % DAILY_PROGRESS.DAILY_LIMIT
		return
	daily_progress.storage_path = daily_progress_storage_path
	daily_progress.load_progress(repository.questions.size())
	if not daily_progress.last_error.empty():
		ui["challenge_text"].text = "Progresso do quiz indisponível."
		ui["challenge_count"].text = "— / %d" % DAILY_PROGRESS.DAILY_LIMIT
		return
	var answered_count: int = daily_progress.get_answered_count()
	ui["challenge_count"].text = "%d / %d" % [answered_count, DAILY_PROGRESS.DAILY_LIMIT]
	ui["challenge_text"].text = "Parabéns! Você completou o quiz de hoje!" if answered_count >= DAILY_PROGRESS.DAILY_LIMIT else "Perguntas respondidas hoje"
	if current_viewport_size.x > 0.0:
		_layout_screen(current_viewport_size)


func _refresh_badges() -> void:
	for badge in badge_controls:
		var level: int = progression_service.get_badge_level(badge["id"]) if progression_service != null else 0
		var unlocked: bool = level > 0
		var color: Color = badge["color"] if unlocked else LOCKED_BADGE_COLOR
		badge["material"].set_shader_param("grayscale_amount", 0.0 if unlocked else 1.0)
		badge["icon"].modulate = Color.white
		badge["name"].add_color_override("font_color", color)
		badge["level"].text = "NÍVEL %d" % level
		badge["level"].add_color_override("font_color", color)


func _on_tab_pressed(tab_name: String) -> void:
	if tab_name != "DISTINTIVOS":
		if tab_name == "COLEÇÃO":
			var item_count: int = progression_service.get_state()["unlocked_items"].size()
			ui["status"].text = "%d item(ns) desbloqueado(s); nomes e artes serão cadastrados depois." % item_count
		return
	selected_tab = tab_name
	ui["status"].text = ""
	_apply_tab_style()


func _on_nav_pressed(item_id: String) -> void:
	if item_id == "home":
		get_node("/root/NavigationHistory").call("navigate_to", "res://app/menus/home_screen.tscn")
	elif item_id == "map":
		get_node("/root/NavigationHistory").call("navigate_to", "res://app/menus/map_screen.tscn")
	elif item_id == "missions":
		get_node("/root/NavigationHistory").call("navigate_to", "res://games/quiz/scenes/quiz_screen.tscn")
	else:
		ui["status"].text = ""


func _on_viewport_size_changed() -> void:
	_layout_screen(get_viewport_rect().size)

extends Control

const BOTTOM_NAVIGATION = preload("res://shared/ui/bottom_navigation.tscn")
const SHIELD_ICON = preload("res://shared/ui/assets/icons/shield_icon.svg")
const NAVY = Color("#071126")
const PANEL = Color("#0b1735")
const PANEL_LIGHT = Color("#14254a")
const WHITE = Color("#f3f7ff")
const MUTED = Color("#a8b5d2")
const CYAN = Color("#28e3dc")
const BADGES = [
	{"name": "PRIVACIDADE", "level": "NÍVEL 2", "color": Color("#28dce4")},
	{"name": "SEGURANÇA", "level": "NÍVEL 3", "color": Color("#83e74c")},
	{"name": "COMUNICAÇÃO", "level": "NÍVEL 2", "color": Color("#328aff")},
	{"name": "CONHECIMENTO", "level": "NÍVEL 1", "color": Color("#ffad39")},
	{"name": "RESPEITO", "level": "NÍVEL 2", "color": Color("#ff6687")},
	{"name": "ATENÇÃO", "level": "NÍVEL 1", "color": Color("#ad4fe8")}
]
const FONT_RATIOS = {
	"title": 0.041,
	"points_label": 0.020,
	"points": 0.063,
	"support": 0.021,
	"level": 0.021,
	"tab": 0.020,
	"badge": 0.017,
	"badge_level": 0.015,
	"challenge": 0.019,
	"body": 0.016,
	"progress": 0.017
}

var ui: Dictionary = {}
var badge_controls: Array = []
var current_viewport_size := Vector2.ZERO
var selected_tab: String = "DISTINTIVOS"


func _ready() -> void:
	_build_screen()
	get_viewport().connect("size_changed", self, "_on_viewport_size_changed")
	_layout_screen(get_viewport_rect().size)


func _build_screen() -> void:
	var background := ColorRect.new()
	background.color = NAVY
	background.anchor_right = 1.0
	background.anchor_bottom = 1.0
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)

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
	ui["points_label"] = _new_label("PONTOS DE GUARDIÃO", MUTED, "points_label")
	ui["points"] = _new_label("2.450", WHITE, "points")
	ui["support"] = _new_label("Continue assim!", Color("#a6e85d"), "support")

	ui["level_panel"] = _new_panel("LevelProgressPanel", PANEL, Color("#315076"), 16)
	ui["level_caption"] = _new_label("NÍVEL 12", WHITE, "level")
	ui["xp_value"] = _new_label("1.250 / 2.000 XP", WHITE, "level", Label.ALIGN_RIGHT)
	ui["xp_track"] = _new_panel("XPTrack", Color("#18284a"), Color("#18284a"), 12)
	ui["xp_fill"] = _new_panel("XPFill", Color("#48dfae"), Color("#48dfae"), 12)

	ui["tabs_panel"] = _new_panel("BadgeTabs", PANEL, Color("#202e54"), 14)
	ui["tabs"] = {}
	for tab_name in ["DISTINTIVOS", "CONQUISTAS", "COLEÇÃO"]:
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
		icon.texture = SHIELD_ICON
		icon.expand = true
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.modulate = badge["color"]
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(icon)
		badge_item["icon"] = icon
		badge_item["name"] = _new_label(badge["name"], badge["color"], "badge", Label.ALIGN_CENTER)
		badge_item["level"] = _new_label(badge["level"], MUTED, "badge_level", Label.ALIGN_CENTER)
		badge_controls.append(badge_item)

	ui["challenge_panel"] = _new_panel("WeeklyChallengePanel", Color("#191b4a"), Color("#383474"), 18)
	ui["challenge_title"] = _new_label("★  DESAFIO SEMANAL", Color("#c06bff"), "challenge")
	ui["challenge_text"] = _new_label("Complete 3 missões desta semana", WHITE, "body")
	ui["challenge_count"] = _new_label("2 / 3", WHITE, "progress", Label.ALIGN_CENTER)
	ui["challenge_track"] = _new_panel("ChallengeTrack", Color("#30265b"), Color("#30265b"), 10)
	ui["challenge_fill"] = _new_panel("ChallengeFill", Color("#a951ed"), Color("#a951ed"), 10)
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
	var header_y: float = height * (0.035 if landscape else 0.025)
	_place(ui["header"], safe, header_y, width - safe * 2.0, height * 0.055, short_side)

	var hero_y: float = height * (0.105 if landscape else 0.09)
	var hero_height: float = height * (0.19 if landscape else 0.18)
	var hero_x: float = safe
	var hero_width: float = width - safe * 2.0
	_place(ui["hero_panel"], hero_x, hero_y, hero_width, hero_height)
	var hero_icon_size: float = min(hero_height * 0.82, short_side * 0.22)
	_place(ui["hero_shield"], hero_x + hero_width * 0.06, hero_y + (hero_height - hero_icon_size) * 0.5, hero_icon_size, hero_icon_size)
	var points_x: float = hero_x + hero_width * 0.38
	var points_width: float = hero_width * 0.57
	_place(ui["points_label"], points_x, hero_y + hero_height * 0.13, points_width, hero_height * 0.18, short_side)
	_place(ui["points"], points_x, hero_y + hero_height * 0.31, points_width, hero_height * 0.48, short_side)
	_place(ui["support"], points_x, hero_y + hero_height * 0.78, points_width, hero_height * 0.16, short_side)

	var level_y: float = hero_y + hero_height + height * 0.018
	var level_height: float = height * (0.12 if landscape else 0.105)
	_place(ui["level_panel"], safe, level_y, width - safe * 2.0, level_height)
	_place(ui["level_caption"], safe * 1.7, level_y + level_height * 0.12, width * 0.34, level_height * 0.30, short_side)
	_place(ui["xp_value"], width * 0.52, level_y + level_height * 0.12, width * 0.40, level_height * 0.30, short_side)
	var track_x: float = safe * 1.7
	var track_y: float = level_y + level_height * 0.57
	var track_width: float = width - safe * 3.4
	var track_height: float = max(short_side * 0.018, level_height * 0.18)
	_place(ui["xp_track"], track_x, track_y, track_width, track_height)
	_place(ui["xp_fill"], track_x, track_y, track_width * 0.625, track_height)

	var tabs_y: float = level_y + level_height + height * 0.018
	var tabs_height: float = height * (0.075 if landscape else 0.065)
	_place(ui["tabs_panel"], safe, tabs_y, width - safe * 2.0, tabs_height)
	var tab_width: float = (width - safe * 2.4) / 3.0
	for tab_name in ui["tabs"]:
		var tab_index: int = ["DISTINTIVOS", "CONQUISTAS", "COLEÇÃO"].find(tab_name)
		_place(ui["tabs"][tab_name], safe * 1.1 + tab_width * tab_index, tabs_y + tabs_height * 0.08, tab_width, tabs_height * 0.84, short_side)

	var grid_top: float = tabs_y + tabs_height + height * 0.014
	var challenge_height: float = height * (0.115 if landscape else 0.105)
	var challenge_y: float = nav_top - challenge_height - height * 0.06
	var grid_bottom: float = challenge_y - height * 0.018
	var grid_height: float = max(0.0, grid_bottom - grid_top)
	var cell_width: float = (width - safe * 2.0) / 3.0
	var row_height: float = grid_height / 2.0
	for index in range(badge_controls.size()):
		var row: int = int(index / 3)
		var column: int = index % 3
		var cell_x: float = safe + cell_width * column
		var cell_y: float = grid_top + row_height * row
		var cell: Dictionary = badge_controls[index]
		var icon_size: float = min(min(short_side * 0.105, cell_width * 0.38), row_height * 0.49)
		var icon_y: float = cell_y + row_height * 0.04
		_place(cell["icon"], cell_x + (cell_width - icon_size) * 0.5, icon_y, icon_size, icon_size)
		_place(cell["name"], cell_x + cell_width * 0.025, icon_y + icon_size + row_height * 0.025, cell_width * 0.95, row_height * 0.19, short_side)
		_place(cell["level"], cell_x + cell_width * 0.025, icon_y + icon_size + row_height * 0.22, cell_width * 0.95, row_height * 0.16, short_side)

	_place(ui["challenge_panel"], safe, challenge_y, width - safe * 2.0, challenge_height)
	var challenge_x: float = safe * 1.7
	var challenge_width: float = width - safe * 3.4
	_place(ui["challenge_title"], challenge_x, challenge_y + challenge_height * 0.12, challenge_width, challenge_height * 0.22, short_side)
	_place(ui["challenge_text"], challenge_x, challenge_y + challenge_height * 0.37, challenge_width * 0.74, challenge_height * 0.24, short_side)
	_place(ui["challenge_count"], challenge_x, challenge_y + challenge_height * 0.66, short_side * 0.12, challenge_height * 0.22, short_side)
	var challenge_track_x: float = challenge_x + short_side * 0.14
	var challenge_track_y: float = challenge_y + challenge_height * 0.70
	var challenge_track_width: float = max(0.0, challenge_width - short_side * 0.16)
	var challenge_track_height: float = max(3.0, challenge_height * 0.12)
	_place(ui["challenge_track"], challenge_track_x, challenge_track_y, challenge_track_width, challenge_track_height)
	_place(ui["challenge_fill"], challenge_track_x, challenge_track_y, challenge_track_width * (2.0 / 3.0), challenge_track_height)

	_place(ui["status"], safe, nav_top - height * 0.043, width - safe * 2.0, height * 0.03, short_side)
	ui["navigation"].layout_for_viewport(viewport_size)


func _place(control: Control, x: float, y: float, width: float, height: float, font_basis: float = 720.0) -> void:
	var scale: float = 1.0
	if control.has_meta("font_role"):
		var font: Font = control.get_font("font")
		var role: String = control.get_meta("font_role")
		if font != null and FONT_RATIOS.has(role):
			scale = min(font_basis * FONT_RATIOS[role] / font.get_height(), _fit_text_scale(control, font, width, height))
	control.anchor_left = 0.0
	control.anchor_top = 0.0
	control.anchor_right = 0.0
	control.anchor_bottom = 0.0
	control.rect_scale = Vector2(scale, scale)
	control.margin_left = x
	control.margin_top = y
	control.margin_right = x + width / scale
	control.margin_bottom = y + height / scale


func _fit_text_scale(control: Control, font: Font, width: float, height: float) -> float:
	var text: String = ""
	if control is Label:
		text = (control as Label).text
	elif control is Button:
		text = (control as Button).text
	var widest_line: float = 0.0
	for line in text.split("\n"):
		widest_line = max(widest_line, font.get_string_size(line).x)
	var line_count: int = max(1, text.split("\n").size())
	return max(0.01, min(width / max(1.0, widest_line), height / max(1.0, font.get_height() * line_count)))


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


func _on_tab_pressed(tab_name: String) -> void:
	if tab_name != "DISTINTIVOS":
		ui["status"].text = "A aba %s estará disponível em breve." % tab_name.to_lower().capitalize()
		return
	selected_tab = tab_name
	ui["status"].text = ""
	_apply_tab_style()


func _on_nav_pressed(item_id: String) -> void:
	if item_id == "home":
		get_tree().change_scene("res://app/menus/home_screen.tscn")
	elif item_id == "map":
		get_tree().change_scene("res://app/menus/map_screen.tscn")
	elif item_id == "missions":
		ui["status"].text = "A tela de Missões estará disponível em breve."
	else:
		ui["status"].text = ""


func _on_viewport_size_changed() -> void:
	_layout_screen(get_viewport_rect().size)

extends Control

const NAVY = Color("#071126")
const PANEL = Color("#101d3c")
const PANEL_LIGHT = Color("#17284c")
const CYAN = Color("#18d6d2")
const WHITE = Color("#f3f7ff")
const MUTED = Color("#a8b5d2")
const BODY_FONT_SCALE = 1.875
const TITLE_FONT_SCALE = 2.5
const ICON_FONT_SCALE = 1.25

var ui: Dictionary = {}
var status_label: Label


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

	ui["menu"] = _new_label("☰", WHITE, 28, Label.ALIGN_CENTER, ICON_FONT_SCALE)
	ui["notification"] = _new_label("♧", WHITE, 28, Label.ALIGN_CENTER, ICON_FONT_SCALE)
	ui["logo_icon"] = _new_label("✦", CYAN, 46, Label.ALIGN_CENTER, ICON_FONT_SCALE)
	ui["brand_top"] = _new_label("GUARDIÕES", WHITE, 28, Label.ALIGN_LEFT, TITLE_FONT_SCALE)
	ui["brand_bottom"] = _new_label("DA CIDADE DIGITAL", CYAN, 22, Label.ALIGN_LEFT, TITLE_FONT_SCALE)

	var mascot := TextureRect.new()
	mascot.name = "MascotSprite"
	mascot.texture = load("res://ideias/mascote.png")
	mascot.expand = true
	mascot.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	mascot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(mascot)
	ui["mascot"] = mascot

	ui["greeting_panel"] = _new_panel("GreetingPanel", PANEL, Color("#20cbd2"), 18)
	ui["greeting_title"] = _new_label("Olá, Guardião!", CYAN, 19)
	ui["greeting_text"] = _new_label("Pronto para proteger\na cidade digital?", WHITE, 18)

	var start_button := _new_button("MissionButton", "▶   COMEÇAR MISSÃO", Color("#ff626f"), WHITE, 21)
	start_button.connect("pressed", self, "_on_action_pressed", ["Selecione um bairro para iniciar sua missão."])
	ui["start"] = start_button

	ui["nav_missions"] = _new_nav_button("NavMissions", "nav_missions", "◇", "MISSÕES", Color("#19c9c9"), NAVY, "Missões")
	ui["nav_games"] = _new_nav_button("NavMiniGames", "nav_games", "♫", "MINI GAMES", Color("#7565f6"), NAVY, "Mini games")
	ui["nav_games"].add_color_override("font_color", Color("#FFFFFF"))
	ui["nav_learn"] = _new_nav_button("NavLearn", "nav_learn", "▤", "APRENDER", Color("#65c88b"), NAVY, "Aprender")
	ui["nav_profile"] = _new_nav_button("NavProfile", "nav_profile", "♧", "PERFIL", Color("#3187ec"), NAVY, "Perfil")

	ui["progress_panel"] = _new_panel("ProgressPanel", PANEL, Color("#26385e"), 18)
	ui["level_badge"] = _new_panel("LevelBadge", Color("#132345"), Color("#16c7d0"), 56)
	ui["level_caption"] = _new_label("NÍVEL", MUTED, 14, Label.ALIGN_CENTER)
	ui["level_number"] = _new_label("12", WHITE, 34, Label.ALIGN_CENTER)
	ui["progress_title"] = _new_label("NÍVEL", MUTED, 15)
	ui["progress_value"] = _new_label("1.250 / 2.000 XP", WHITE, 20)
	ui["progress_track"] = _new_panel("ProgressTrack", Color("#243253"), Color("#243253"), 12)
	ui["progress_fill"] = _new_panel("ProgressFill", CYAN, CYAN, 10)
	ui["progress_hint"] = _new_label("Mais 750 XP para o próximo nível", MUTED, 14)

	status_label = _new_label("", CYAN, 15, Label.ALIGN_CENTER)
	ui["status"] = status_label
	ui["nav_missions"].grab_focus()


func _layout_screen(viewport_size: Vector2) -> void:
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		return

	var width: float = viewport_size.x
	var height: float = viewport_size.y
	var safe_x: float = max(24.0, min(width, height) * 0.035)
	var safe_y: float = max(18.0, min(width, height) * 0.025)
	var ui_scale: float = clamp(min(width, height) / 720.0, 0.85, 1.5)
	var landscape: bool = width > height

	if landscape:
		_layout_landscape(width, height, safe_x, safe_y, ui_scale)
	else:
		_layout_portrait(width, height, safe_x, safe_y, ui_scale)


func _layout_portrait(width: float, height: float, safe_x: float, safe_y: float, ui_scale: float) -> void:
	_place(ui["menu"], safe_x, safe_y, 60, 58, ui_scale)
	_place(ui["notification"], width - safe_x - 60, safe_y, 60, 58, ui_scale)
	_place(ui["logo_icon"], safe_x, height * 0.085, 76, 82, ui_scale)
	_place(ui["brand_top"], safe_x + 82, height * 0.08, width - safe_x * 2 - 82, 76, ui_scale)
	_place(ui["brand_bottom"], safe_x + 84, height * 0.137, width - safe_x * 2 - 84, 62, ui_scale)

	_place_mascot(safe_x * 0.55, height * 0.255, width * 0.43, height * 0.345)
	var greeting_x := width * 0.415
	var greeting_y := height * 0.292
	var greeting_width := width * 0.535
	var greeting_height := height * 0.16
	_place(ui["greeting_panel"], greeting_x, greeting_y, greeting_width, greeting_height)
	_place(ui["greeting_title"], greeting_x + 18, greeting_y + 14, greeting_width - 36, 34, ui_scale)
	_place(ui["greeting_text"], greeting_x + 18, greeting_y + 52, greeting_width - 36, greeting_height - 62, ui_scale)

	_place(ui["start"], width * 0.06, height * 0.595, width * 0.88, height * 0.068, ui_scale)
	var nav_left := width * 0.05
	var nav_gap := width * 0.018
	var nav_width := (width * 0.90 - nav_gap * 3.0) / 4.0
	var nav_y := height * 0.69
	var nav_height := height * 0.112
	_place_nav("nav_missions", nav_left, nav_y, nav_width, nav_height, ui_scale)
	_place_nav("nav_games", nav_left + nav_width + nav_gap, nav_y, nav_width, nav_height, ui_scale)
	_place_nav("nav_learn", nav_left + (nav_width + nav_gap) * 2.0, nav_y, nav_width, nav_height, ui_scale)
	_place_nav("nav_profile", nav_left + (nav_width + nav_gap) * 3.0, nav_y, nav_width, nav_height, ui_scale)

	var progress_x := width * 0.05
	var progress_y := height * 0.81
	var progress_width := width * 0.90
	var progress_height := height * 0.13
	_place_progress(progress_x, progress_y, progress_width, progress_height, ui_scale)
	_place(ui["status"], safe_x, height - safe_y - 36.0, width - safe_x * 2.0, 34, ui_scale)


func _layout_landscape(width: float, height: float, safe_x: float, safe_y: float, ui_scale: float) -> void:
	_place(ui["menu"], safe_x, safe_y, 60, 58, ui_scale)
	_place(ui["notification"], width - safe_x - 60, safe_y, 60, 58, ui_scale)
	_place(ui["logo_icon"], safe_x, height * 0.065, 76, 82, ui_scale)
	_place(ui["brand_top"], safe_x + 82, height * 0.04, width * 0.34, 76, ui_scale)
	_place(ui["brand_bottom"], safe_x + 84, height * 0.145, width * 0.40, 62, ui_scale)

	_place_mascot(width * 0.025, height * 0.26, width * 0.18, height * 0.50)
	var greeting_x := width * 0.215
	var greeting_y := height * 0.325
	var greeting_width := width * 0.17
	var greeting_height := height * 0.32
	_place(ui["greeting_panel"], greeting_x, greeting_y, greeting_width, greeting_height)
	_place(ui["greeting_title"], greeting_x + 18, greeting_y + 18, greeting_width - 36, 42, ui_scale)
	_place(ui["greeting_text"], greeting_x + 18, greeting_y + 66, greeting_width - 36, greeting_height - 82, ui_scale)

	var content_x := width * 0.405
	var content_width := width * 0.555
	_place(ui["start"], content_x, height * 0.20, content_width, height * 0.12, ui_scale)
	var nav_gap := content_width * 0.025
	var nav_width := (content_width - nav_gap * 3.0) / 4.0
	var nav_y := height * 0.385
	var nav_height := height * 0.30
	_place_nav("nav_missions", content_x, nav_y, nav_width, nav_height, ui_scale)
	_place_nav("nav_games", content_x + nav_width + nav_gap, nav_y, nav_width, nav_height, ui_scale)
	_place_nav("nav_learn", content_x + (nav_width + nav_gap) * 2.0, nav_y, nav_width, nav_height, ui_scale)
	_place_nav("nav_profile", content_x + (nav_width + nav_gap) * 3.0, nav_y, nav_width, nav_height, ui_scale)

	_place_progress(content_x, height * 0.735, content_width, height * 0.205, ui_scale)
	_place(ui["status"], content_x, height - safe_y - 36.0, content_width, 34, ui_scale)


func _place_progress(x: float, y: float, width: float, height: float, ui_scale: float) -> void:
	_place(ui["progress_panel"], x, y, width, height)
	var padding: float = min(width, height) * 0.12
	var badge_size: float = min(height * 0.72, width * 0.22)
	_place(ui["level_badge"], x + padding, y + (height - badge_size) * 0.5, badge_size, badge_size)
	_place(ui["level_caption"], x + padding + 5, y + height * 0.5 - badge_size * 0.27, badge_size - 10, badge_size * 0.23, ui_scale)
	_place(ui["level_number"], x + padding + 5, y + height * 0.5 - badge_size * 0.02, badge_size - 10, badge_size * 0.45, ui_scale)

	var text_x := x + padding + badge_size + padding * 0.55
	var text_width := width - (text_x - x) - padding
	var title_y: float = y + height * 0.13
	_place(ui["progress_title"], text_x, title_y, text_width, height * 0.19, ui_scale)
	_place(ui["progress_value"], text_x, title_y + height * 0.20, text_width, height * 0.23, ui_scale)
	var track_y: float = y + height * 0.62
	var track_height: float = max(14.0, height * 0.13)
	_place(ui["progress_track"], text_x, track_y, text_width, track_height)
	_place(ui["progress_fill"], text_x + 2, track_y + 2, max(8.0, (text_width - 4.0) * 0.625), track_height - 4.0)
	_place(ui["progress_hint"], text_x, track_y + track_height + 4.0, text_width, height * 0.19, ui_scale)


func _place_mascot(x: float, y: float, width: float, height: float) -> void:
	_place(ui["mascot"], x, y, width, height)


func _place_nav(key: String, x: float, y: float, width: float, height: float, ui_scale: float) -> void:
	_place(ui[key], x, y, width, height)
	var icon_label: Label = ui[key + "_icon"]
	var title_label: Label = ui[key + "_title"]
	var base_title: String = title_label.get_meta("base_text")
	if width < 112.0 and base_title == "MINI GAMES":
		title_label.text = "MINI\nGAMES"
	else:
		title_label.text = base_title
	var title_scale: float = ui_scale * max(0.75, min(1.0, width / 110.0))
	_place(icon_label, 0.0, height * 0.04, width, height * 0.43, ui_scale)
	_place(title_label, 2.0, height * 0.49, width - 4.0, height * 0.48, title_scale)


func _place(control: Control, x: float, y: float, width: float, height: float, ui_scale: float = 1.0) -> void:
	var font_factor := float(control.get_meta("font_factor", 1.0))
	var scale: float = font_factor * ui_scale
	control.anchor_left = 0.0
	control.anchor_top = 0.0
	control.anchor_right = 0.0
	control.anchor_bottom = 0.0
	control.rect_scale = Vector2(scale, scale)
	control.margin_left = x
	control.margin_top = y
	control.margin_right = x + width / scale
	control.margin_bottom = y + height / scale


func _new_label(text: String, color: Color, font_size: int, alignment: int = Label.ALIGN_LEFT, font_scale: float = BODY_FONT_SCALE) -> Label:
	var label := Label.new()
	label.text = text
	label.align = alignment
	label.valign = Label.VALIGN_CENTER
	label.autowrap = true
	label.focus_mode = Control.FOCUS_NONE
	label.add_color_override("font_color", color)
	label.set_meta("font_factor", font_size * font_scale / 16.0)
	add_child(label)
	return label


func _new_panel(node_name: String, fill: Color, border: Color, radius: int) -> Panel:
	var panel := Panel.new()
	panel.name = node_name
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_stylebox_override("panel", _stylebox(fill, border, radius, 1))
	add_child(panel)
	return panel


func _new_button(node_name: String, text: String, fill: Color, text_color: Color, font_size: int) -> Button:
	var button := Button.new()
	button.name = node_name
	button.text = text
	button.align = Button.ALIGN_CENTER
	button.focus_mode = Control.FOCUS_ALL
	button.add_stylebox_override("normal", _stylebox(fill, fill, 20, 1))
	button.add_stylebox_override("hover", _stylebox(Color("#ff7a84"), Color("#ff7a84"), 20, 1))
	button.add_stylebox_override("focus", _stylebox(Color("#ff7a84"), WHITE, 20, 2))
	button.add_color_override("font_color", text_color)
	button.add_color_override("font_color_hover", text_color)
	button.add_color_override("font_color_focus", text_color)
	button.set_meta("font_factor", font_size * BODY_FONT_SCALE / 16.0)
	add_child(button)
	return button


func _new_nav_button(node_name: String, key: String, icon: String, title: String, color: Color, text_color: Color, action: String) -> Button:
	var button := _new_button(node_name, "", color, text_color, 16)
	# The button is only a background/focus target; scaling it would also scale
	# its child labels and push their centered text outside the visible button.
	button.set_meta("font_factor", 1.0)
	button.add_stylebox_override("normal", _stylebox(color, color, 16, 2))
	button.add_stylebox_override("hover", _stylebox(color, color, 16, 3))
	button.add_stylebox_override("focus", _stylebox(color, WHITE, 16, 4))
	button.add_color_override("font_color", text_color)
	button.add_color_override("font_color_hover", text_color)
	button.add_color_override("font_color_focus", text_color)
	var icon_label := _new_child_label(icon, text_color, 26, Label.ALIGN_CENTER, ICON_FONT_SCALE)
	var title_label := _new_child_label(title, text_color, 14, Label.ALIGN_CENTER)
	title_label.set_meta("base_text", title)
	button.add_child(icon_label)
	button.add_child(title_label)
	ui[key + "_icon"] = icon_label
	ui[key + "_title"] = title_label
	button.connect("pressed", self, "_on_action_pressed", [action + " estará disponível em breve."])
	return button


func _new_child_label(text: String, color: Color, font_size: int, alignment: int, font_scale: float = BODY_FONT_SCALE) -> Label:
	var label := Label.new()
	label.text = text
	label.align = alignment
	label.valign = Label.VALIGN_CENTER
	label.autowrap = true
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_color_override("font_color", color)
	label.set_meta("font_factor", font_size * font_scale / 16.0)
	return label


func _stylebox(fill: Color, border: Color, radius: int, border_width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(radius)
	return style


func _on_viewport_size_changed() -> void:
	_layout_screen(get_viewport_rect().size)


func _on_action_pressed(message: String) -> void:
	status_label.text = message

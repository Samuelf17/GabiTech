extends Control

const NAVY = Color("#071126")
const PANEL = Color("#101d3c")
const PANEL_LIGHT = Color("#17284c")
const CYAN = Color("#18d6d2")
const WHITE = Color("#f3f7ff")
const MUTED = Color("#a8b5d2")
const FONT_ROLE_RATIOS = {
	"icon": 0.0392,
	"brand": 0.0485,
	"brand_title": 0.06305,
	"brand_secondary": 0.0494,
	"heading": 0.038295,
	"body": 0.035995,
	"button": 0.0367,
	"caption": 0.0247,
	"nav_caption": 0.02717,
	"display_number": 0.0593,
	"progress_value": 0.0347,
	"progress_caption": 0.026
}

var ui: Dictionary = {}
var status_label: Label
var current_viewport_size: Vector2


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

	ui["menu"] = _new_label("☰", WHITE, "icon", Label.ALIGN_CENTER)
	ui["notification"] = _new_label("♧", WHITE, "icon", Label.ALIGN_CENTER)
	ui["logo_icon"] = _new_label("✦", CYAN, "brand", Label.ALIGN_CENTER)
	ui["brand_top"] = _new_label("GUARDIÕES", WHITE, "brand_title")
	ui["brand_bottom"] = _new_label("DA CIDADE DIGITAL", CYAN, "brand_secondary")

	var mascot := TextureRect.new()
	mascot.name = "MascotSprite"
	mascot.texture = load("res://shared/mascot/mascote.png")
	mascot.expand = true
	mascot.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	mascot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(mascot)
	ui["mascot"] = mascot

	ui["greeting_panel"] = _new_panel("GreetingPanel", PANEL, Color("#20cbd2"), 18)
	ui["greeting_title"] = _new_label("Olá, Guardião!", CYAN, "heading")
	ui["greeting_text"] = _new_label("Pronto para proteger\na cidade digital?", WHITE, "body")

	var start_button := _new_button("MissionButton", "▶   COMEÇAR MISSÃO", Color("#ff626f"), WHITE, "button")
	start_button.connect("pressed", self, "_on_action_pressed", ["Selecione um bairro para iniciar sua missão."])
	ui["start"] = start_button

	ui["nav_missions"] = _new_nav_button("NavMissions", "nav_missions", "MISSÕES", Color("#19c9c9"), "Missões")
	ui["nav_games"] = _new_nav_button("NavMiniGames", "nav_games", "MINI GAMES", Color("#7565f6"), "Mini games")
	ui["nav_profile"] = _new_nav_button("NavProfile", "nav_profile", "PERFIL", Color("#3187ec"), "Perfil")

	ui["progress_panel"] = _new_panel("ProgressPanel", PANEL, Color("#26385e"), 18)
	ui["level_badge"] = _new_panel("LevelBadge", Color("#132345"), Color("#16c7d0"), 56)
	ui["level_caption"] = _new_label("NÍVEL", MUTED, "caption", Label.ALIGN_CENTER)
	ui["level_number"] = _new_label("12", WHITE, "display_number", Label.ALIGN_CENTER)
	ui["progress_title"] = _new_label("NÍVEL", MUTED, "caption")
	ui["progress_value"] = _new_label("1.250 / 2.000 XP", WHITE, "progress_value")
	ui["progress_track"] = _new_panel("ProgressTrack", Color("#243253"), Color("#243253"), 12)
	ui["progress_fill"] = _new_panel("ProgressFill", CYAN, CYAN, 10)
	ui["progress_hint"] = _new_label("Mais 750 XP para o próximo nível", MUTED, "progress_caption")

	status_label = _new_label("", CYAN, "caption", Label.ALIGN_CENTER)
	ui["status"] = status_label
	ui["nav_missions"].grab_focus()


func _layout_screen(viewport_size: Vector2) -> void:
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		return
	current_viewport_size = viewport_size

	var width: float = viewport_size.x
	var height: float = viewport_size.y
	var safe_x: float = max(24.0, min(width, height) * 0.035)
	var safe_y: float = max(18.0, min(width, height) * 0.025)
	var font_basis: float = min(width, height)
	var landscape: bool = width > height

	if landscape:
		_layout_landscape(width, height, safe_x, safe_y, font_basis)
	else:
		_layout_portrait(width, height, safe_x, safe_y, font_basis)


func _layout_portrait(width: float, height: float, safe_x: float, safe_y: float, font_basis: float) -> void:
	_place(ui["menu"], safe_x, safe_y, 60, 58, font_basis)
	_place(ui["notification"], width - safe_x - 60, safe_y, 60, 58, font_basis)
	_place(ui["logo_icon"], safe_x, height * 0.085, 76, 82, font_basis)
	_place(ui["brand_top"], safe_x + 82, height * 0.08, width - safe_x * 2 - 82, 76, font_basis)
	_place(ui["brand_bottom"], safe_x + 84, height * 0.137, width - safe_x * 2 - 84, 62, font_basis)

	_place_mascot(safe_x * 0.55, height * 0.255, width * 0.43, height * 0.345)
	var greeting_x := width * 0.415
	var greeting_y := height * 0.292
	var greeting_width := width * 0.535
	var greeting_height := height * 0.16
	_place(ui["greeting_panel"], greeting_x, greeting_y, greeting_width, greeting_height)
	_place(ui["greeting_title"], greeting_x + 18, greeting_y + 14, greeting_width - 36, 34, font_basis)
	_place(ui["greeting_text"], greeting_x + 18, greeting_y + 52, greeting_width - 36, greeting_height - 62, font_basis)

	_place(ui["start"], width * 0.06, height * 0.595, width * 0.88, height * 0.068, font_basis)
	var nav_left := width * 0.05
	var nav_gap := width * 0.018
	var nav_width := (width * 0.90 - nav_gap * 2.0) / 3.0
	var nav_y := height * 0.69
	var nav_height := height * 0.112
	_place_nav("nav_missions", nav_left, nav_y, nav_width, nav_height, font_basis)
	_place_nav("nav_games", nav_left + nav_width + nav_gap, nav_y, nav_width, nav_height, font_basis)
	_place_nav("nav_profile", nav_left + (nav_width + nav_gap) * 2.0, nav_y, nav_width, nav_height, font_basis)

	var progress_x := width * 0.05
	var progress_y := height * 0.81
	var progress_width := width * 0.90
	var progress_height := height * 0.13
	_place_progress(progress_x, progress_y, progress_width, progress_height, font_basis)
	_place(ui["status"], safe_x, height - safe_y - 36.0, width - safe_x * 2.0, 34, font_basis)


func _layout_landscape(width: float, height: float, safe_x: float, safe_y: float, font_basis: float) -> void:
	_place(ui["menu"], safe_x, safe_y, 60, 58, font_basis)
	_place(ui["notification"], width - safe_x - 60, safe_y, 60, 58, font_basis)
	_place(ui["logo_icon"], safe_x, height * 0.065, 76, 82, font_basis)
	_place(ui["brand_top"], safe_x + 82, height * 0.04, width * 0.34, 76, font_basis)
	_place(ui["brand_bottom"], safe_x + 84, height * 0.145, width * 0.40, 62, font_basis)

	_place_mascot(width * 0.025, height * 0.26, width * 0.18, height * 0.50)
	var greeting_x := width * 0.215
	var greeting_y := height * 0.325
	var greeting_width := width * 0.18
	var greeting_height := height * 0.36
	_place(ui["greeting_panel"], greeting_x, greeting_y, greeting_width, greeting_height)
	var greeting_text_x: float = greeting_x + 18
	var greeting_text_width: float = greeting_width - 36
	_place(ui["greeting_title"], greeting_text_x, greeting_y + 12, greeting_text_width, 60, font_basis)
	var greeting_title_scale: float = ui["greeting_title"].rect_scale.x
	var greeting_text_y: float = greeting_y + 80
	var greeting_text_height: float = greeting_height - 96
	var greeting_text_scale: float = _adaptive_font_scale(ui["greeting_text"], font_basis, greeting_text_width, greeting_text_height)
	var greeting_text_scale_limit: float = greeting_title_scale * 0.88
	var greeting_text_extra_scale: float = min(1.0, greeting_text_scale_limit / greeting_text_scale)
	_place(ui["greeting_text"], greeting_text_x, greeting_text_y, greeting_text_width, greeting_text_height, font_basis, greeting_text_extra_scale)

	var content_x := width * 0.405
	var content_width := width * 0.555
	_place(ui["start"], content_x, height * 0.20, content_width, height * 0.12, font_basis)
	var nav_gap := content_width * 0.025
	var nav_width := (content_width - nav_gap * 2.0) / 3.0
	var nav_y := height * 0.385
	var nav_height := height * 0.30
	_place_nav("nav_missions", content_x, nav_y, nav_width, nav_height, font_basis)
	_place_nav("nav_games", content_x + nav_width + nav_gap, nav_y, nav_width, nav_height, font_basis)
	_place_nav("nav_profile", content_x + (nav_width + nav_gap) * 2.0, nav_y, nav_width, nav_height, font_basis)

	_place_progress(content_x, height * 0.735, content_width, height * 0.205, font_basis)
	_place(ui["status"], content_x, height - safe_y - 36.0, content_width, 34, font_basis)


func _place_progress(x: float, y: float, width: float, height: float, font_basis: float) -> void:
	_place(ui["progress_panel"], x, y, width, height)
	var padding: float = min(width, height) * 0.12
	var badge_size: float = min(height * 0.72, width * 0.22)
	_place(ui["level_badge"], x + padding, y + (height - badge_size) * 0.5, badge_size, badge_size)
	_place(ui["level_caption"], x + padding + 5, y + height * 0.5 - badge_size * 0.27, badge_size - 10, badge_size * 0.23, font_basis)
	_place(ui["level_number"], x + padding + 5, y + height * 0.5 - badge_size * 0.02, badge_size - 10, badge_size * 0.45, font_basis)

	var text_x := x + padding + badge_size + padding * 0.55
	var text_width := width - (text_x - x) - padding
	var title_y: float = y + height * 0.13
	_place(ui["progress_title"], text_x, title_y, text_width, height * 0.19, font_basis)
	_place(ui["progress_value"], text_x, title_y + height * 0.20, text_width, height * 0.23, font_basis)
	var track_y: float = y + height * 0.62
	var track_height: float = max(14.0, height * 0.13)
	_place(ui["progress_track"], text_x, track_y, text_width, track_height)
	_place(ui["progress_fill"], text_x + 2, track_y + 2, max(8.0, (text_width - 4.0) * 0.625), track_height - 4.0)
	_place(ui["progress_hint"], text_x, track_y + track_height + 4.0, text_width, height * 0.19, font_basis)


func _place_mascot(x: float, y: float, width: float, height: float) -> void:
	_place(ui["mascot"], x, y, width, height)


func _place_nav(key: String, x: float, y: float, width: float, height: float, font_basis: float) -> void:
	var button: Button = ui[key]
	var title_label: Label = ui[key + "_title"]
	var button_height: float = height * 0.70
	var label_y: float = y + height * 0.74
	var label_height: float = height * 0.26
	_place(button, x, y, width, button_height)
	_place(title_label, x, label_y, width, label_height, font_basis)


func _place(control: Control, x: float, y: float, width: float, height: float, font_basis: float = 720.0, extra_scale: float = 1.0) -> void:
	var scale: float = extra_scale
	if control.has_meta("font_role"):
		scale = _adaptive_font_scale(control, font_basis, width, height) * extra_scale
	control.anchor_left = 0.0
	control.anchor_top = 0.0
	control.anchor_right = 0.0
	control.anchor_bottom = 0.0
	control.rect_scale = Vector2(scale, scale)
	control.margin_left = x
	control.margin_top = y
	control.margin_right = x + width / scale
	control.margin_bottom = y + height / scale


func _adaptive_font_scale(control: Control, font_basis: float, width: float, height: float) -> float:
	var role: String = control.get_meta("font_role")
	var font: Font = control.get_font("font")
	if font == null or not FONT_ROLE_RATIOS.has(role):
		return 1.0
	var text: String = ""
	if control is Label:
		text = (control as Label).text
	elif control is Button:
		text = (control as Button).text
	var target_height: float = font_basis * FONT_ROLE_RATIOS[role]
	var scale: float = target_height / font.get_height()
	if control is Button:
		var widest_line: float = 0.0
		for line in text.split("\n"):
			widest_line = max(widest_line, font.get_string_size(line).x)
		if widest_line > 0.0:
			scale = min(scale, width / widest_line)
	else:
		var label: Label = control as Label
		for _iteration in range(3):
			var wrapped_size: Vector2 = font.get_wordwrap_string_size(text, width / scale)
			var rendered_height: float = wrapped_size.y * scale
			if rendered_height <= height or rendered_height <= 0.0:
				break
			scale *= height / rendered_height
	return max(0.01, scale)


func _new_label(text: String, color: Color, font_role: String, alignment: int = Label.ALIGN_LEFT) -> Label:
	var label := Label.new()
	label.text = text
	label.align = alignment
	label.valign = Label.VALIGN_CENTER
	label.autowrap = true
	label.focus_mode = Control.FOCUS_NONE
	label.add_color_override("font_color", color)
	label.set_meta("font_role", font_role)
	add_child(label)
	return label


func _new_panel(node_name: String, fill: Color, border: Color, radius: int) -> Panel:
	var panel := Panel.new()
	panel.name = node_name
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_stylebox_override("panel", _stylebox(fill, border, radius, 1))
	add_child(panel)
	return panel


func _new_button(node_name: String, text: String, fill: Color, text_color: Color, font_role: String) -> Button:
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
	button.set_meta("font_role", font_role)
	add_child(button)
	return button


func _new_nav_button(node_name: String, key: String, title: String, color: Color, action: String) -> Button:
	var button := _new_button(node_name, "", color, WHITE, "button")
	# Keep each colored button ready for a centered icon without a text placeholder.
	button.remove_meta("font_role")
	button.icon_align = Button.ALIGN_CENTER
	button.expand_icon = true
	button.add_stylebox_override("normal", _stylebox(color, color, 16, 2))
	button.add_stylebox_override("hover", _stylebox(color, color, 16, 3))
	button.add_stylebox_override("focus", _stylebox(color, WHITE, 16, 4))
	var title_label := _new_label(title, WHITE, "nav_caption", Label.ALIGN_CENTER)
	title_label.name = node_name + "Title"
	ui[key + "_title"] = title_label
	button.connect("pressed", self, "_on_action_pressed", [action + " estará disponível em breve."])
	return button


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
	_layout_screen(current_viewport_size)

extends Control

const BOTTOM_NAVIGATION = preload("res://shared/ui/bottom_navigation.tscn")
const TYPOGRAPHY = preload("res://shared/ui/typography.gd")
const BACKGROUND_TEXTURE = preload("res://shared/ui/assets/backgrounds/fundo.png")
const MASCOT_BOTTOM_MARGIN_RATIO: float = 0.28
const PROGRESS_BOTTOM_GAP_RATIO: float = 0.04
const MASCOT_LEVEL_TEXTURES = [
	preload("res://shared/mascot/levels/1.png"),
	preload("res://shared/mascot/levels/2.png"),
	preload("res://shared/mascot/levels/3.png"),
	preload("res://shared/mascot/levels/4.png"),
	preload("res://shared/mascot/levels/5.png"),
	preload("res://shared/mascot/levels/6.png"),
	preload("res://shared/mascot/levels/7.png"),
	preload("res://shared/mascot/levels/8.png"),
	preload("res://shared/mascot/levels/9.png"),
	preload("res://shared/mascot/levels/10.png")
]
const NAVY = Color("#071126")
const PANEL = Color("#101d3c")
const PANEL_LIGHT = Color("#17284c")
const CYAN = Color("#18d6d2")
const WHITE = Color("#f3f7ff")
const MUTED = Color("#a8b5d2")
var ui: Dictionary = {}
var typography = TYPOGRAPHY.new()
var progression_service: Node
var status_label: Label
var current_viewport_size: Vector2
var current_mascot_level: int = 0


func _ready() -> void:
	progression_service = get_node_or_null("/root/Progression")
	_build_screen()
	if progression_service != null:
		progression_service.connect("progress_changed", self, "_on_progress_changed")
	_refresh_progress_ui()
	get_viewport().connect("size_changed", self, "_on_viewport_size_changed")
	_layout_screen(get_viewport_rect().size)


func _build_screen() -> void:
	var background := TextureRect.new()
	background.name = "HomeBackground"
	background.texture = BACKGROUND_TEXTURE
	background.expand = true
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.anchor_right = 1.0
	background.anchor_bottom = 1.0
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)
	ui["background"] = background

	ui["menu"] = _new_label("☰", WHITE, "icon", Label.ALIGN_CENTER)
	ui["notification"] = _new_label("♧", WHITE, "icon", Label.ALIGN_CENTER)
	ui["logo_icon"] = _new_label("✦", CYAN, "brand", Label.ALIGN_CENTER)
	ui["brand_top"] = _new_label("GUARDIÕES", WHITE, "brand_title")
	ui["brand_bottom"] = _new_label("DA CIDADE DIGITAL", CYAN, "brand_secondary")

	var mascot := TextureRect.new()
	mascot.name = "MascotSprite"
	mascot.texture = MASCOT_LEVEL_TEXTURES[0]
	mascot.expand = true
	mascot.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	mascot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(mascot)
	ui["mascot"] = mascot

	ui["greeting_panel"] = _new_panel("GreetingPanel", PANEL, Color("#20cbd2"), 18)
	ui["greeting_title"] = _new_label("Olá, Guardião!", CYAN, "heading")
	ui["greeting_text"] = _new_label("Pronto para proteger\na cidade digital?", WHITE, "body")

	ui["progress_panel"] = _new_panel("ProgressPanel", PANEL, Color("#26385e"), 18)
	ui["level_caption"] = _new_label("NÍVEL", MUTED, "caption", Label.ALIGN_CENTER)
	ui["level_number"] = _new_label("1", WHITE, "level_display", Label.ALIGN_CENTER)
	ui["progress_title"] = _new_label("EXPERIÊNCIA", MUTED, "caption")
	ui["progress_value"] = _new_label("0 / 2.000 XP", WHITE, "progress_value")
	ui["progress_track"] = _new_panel("ProgressTrack", Color("#243253"), Color("#243253"), 12)
	ui["progress_fill"] = _new_panel("ProgressFill", CYAN, CYAN, 10)
	ui["progress_hint"] = _new_label("Faltam 2.000 XP para o próximo nível", MUTED, "progress_caption")

	status_label = _new_label("", CYAN, "caption", Label.ALIGN_CENTER)
	ui["status"] = status_label
	var navigation = BOTTOM_NAVIGATION.instance()
	navigation.name = "BottomNavigation"
	navigation.active_item = "home"
	navigation.connect("item_selected", self, "_on_home_nav_pressed")
	add_child(navigation)
	ui["navigation"] = navigation
	navigation.buttons["home"].grab_focus()


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

	var progress_x := width * 0.05
	var progress_width := width * 0.90
	var progress_height := height * 0.18
	var navigation_top: float = ui["navigation"].get_bar_top(Vector2(width, height))
	var progress_y: float = navigation_top - height * PROGRESS_BOTTOM_GAP_RATIO - progress_height
	_place_progress(progress_x, progress_y, progress_width, progress_height, font_basis)
	_place_status_above_navigation(safe_x, width - safe_x * 2.0, width, height, font_basis)


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
	var greeting_text_y: float = greeting_y + 80
	var greeting_text_height: float = greeting_height - 96
	_place(ui["greeting_text"], greeting_text_x, greeting_text_y, greeting_text_width, greeting_text_height, font_basis)

	var content_x := width * 0.405
	var content_width := width * 0.555
	var progress_height: float = height * 0.23
	var speech_center_y: float = greeting_text_y + greeting_text_height * 0.5
	var progress_y: float = speech_center_y - progress_height * 0.5
	_place_progress(content_x, progress_y, content_width, progress_height, font_basis)
	_place_status_above_navigation(content_x, content_width, width, height, font_basis)


func _place_progress(x: float, y: float, width: float, height: float, font_basis: float) -> void:
	_place(ui["progress_panel"], x, y, width, height)
	var padding: float = min(width, height) * 0.12
	var level_width: float = width * 0.24
	var level_x: float = x + padding
	var level_caption_height: float = height * 0.20
	var level_group_y: float = y + height * 0.20
	var level_number_height: float = height * 0.55
	var level_area_right: float = x + padding + level_width + padding * 0.55
	if current_viewport_size.x > current_viewport_size.y:
		level_x = x + (level_area_right - x - level_width) * 0.5
		ui["level_caption"].align = Label.ALIGN_CENTER
		ui["level_number"].align = Label.ALIGN_CENTER
	_place(ui["level_caption"], level_x, level_group_y, level_width, level_caption_height, font_basis)
	_place(ui["level_number"], level_x, level_group_y + level_caption_height, level_width, level_number_height, font_basis)

	var text_x: float = level_area_right
	var text_width := width - (text_x - x) - padding
	var title_y: float = y + height * 0.20
	_place(ui["progress_title"], text_x, title_y, text_width, height * 0.14, font_basis)
	_place(ui["progress_value"], text_x, title_y + height * 0.15, text_width, height * 0.17, font_basis)
	var track_y: float = y + height * 0.54
	var track_height: float = max(14.0, height * 0.11)
	_place(ui["progress_track"], text_x, track_y, text_width, track_height)
	var progress_width: float = max(0.0, (text_width - 4.0) * progression_service.get_progress_ratio())
	_place(ui["progress_fill"], text_x + 2, track_y + 2, progress_width, track_height - 4.0)
	_place(ui["progress_hint"], text_x, track_y + track_height + 4.0, text_width, height * 0.24, font_basis)


func _place_mascot(x: float, y: float, width: float, height: float) -> void:
	var bottom_margin: float = height * MASCOT_BOTTOM_MARGIN_RATIO
	_place(ui["mascot"], x, y, width, height - bottom_margin)


func _place_status_above_navigation(x: float, width: float, viewport_width: float, height: float, font_basis: float) -> void:
	var viewport_size := Vector2(viewport_width, height)
	var navigation_top: float = ui["navigation"].get_bar_top(viewport_size)
	_place(ui["status"], x, navigation_top - height * 0.04, width, height * 0.03, font_basis)


func _place(control: Control, x: float, y: float, width: float, height: float, font_basis: float = 720.0) -> void:
	var scale: float = 1.0
	if control.has_meta("font_role"):
		var role: String = control.get_meta("font_role")
		var font: Font = typography.get_base_font(control)
		if typography.is_uniform_body_role(role):
			if font != null:
				scale = typography.get_target_height("body", font_basis) / font.get_height()
		else:
			scale = _adaptive_font_scale(control, font_basis, width, height)
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


func _adaptive_font_scale(control: Control, font_basis: float, width: float, height: float) -> float:
	var role: String = control.get_meta("font_role")
	var font: Font = typography.get_base_font(control)
	if font == null or not typography.has_role(role):
		return 1.0
	var text: String = ""
	if control is Label:
		text = (control as Label).text
	elif control is Button:
		text = (control as Button).text
	var target_height: float = typography.get_target_height(role, font_basis)
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


func _stylebox(fill: Color, border: Color, radius: int, border_width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(radius)
	return style


func _on_viewport_size_changed() -> void:
	_layout_screen(get_viewport_rect().size)


func _on_progress_changed(_state: Dictionary) -> void:
	_refresh_progress_ui()
	_layout_screen(current_viewport_size)


func _refresh_progress_ui() -> void:
	if progression_service == null:
		return
	var progress: Dictionary = progression_service.get_state()
	var current_level: int = int(progress["level"])
	var current_xp: int = int(progress["experience"])
	var xp_required: int = progression_service.experience_per_level
	ui["level_number"].text = str(current_level)
	ui["progress_value"].text = "%s / %s XP" % [progression_service.format_number(current_xp), progression_service.format_number(xp_required)]
	ui["progress_hint"].text = "Faltam %s XP para o próximo nível" % progression_service.format_number(xp_required - current_xp)
	_refresh_mascot_for_level(current_level)


func _refresh_mascot_for_level(level: int) -> void:
	var mascot_level: int = clamp(level, 1, MASCOT_LEVEL_TEXTURES.size())
	if mascot_level == current_mascot_level:
		return
	var mascot_texture: Texture = MASCOT_LEVEL_TEXTURES[mascot_level - 1]
	if mascot_texture == null:
		push_error("Não foi possível carregar a capivara do nível %d." % mascot_level)
		return
	ui["mascot"].texture = mascot_texture
	current_mascot_level = mascot_level


func _on_action_pressed(message: String) -> void:
	status_label.text = message
	_layout_screen(current_viewport_size)


func _open_map_screen() -> void:
	get_node("/root/NavigationHistory").call("navigate_to", "res://app/menus/map_screen.tscn")


func _on_home_nav_pressed(item_id: String) -> void:
	if item_id == "map":
		_open_map_screen()
	elif item_id == "missions":
		get_node("/root/NavigationHistory").call("navigate_to", "res://games/quiz/scenes/quiz_screen.tscn")
	elif item_id == "profile":
		get_node("/root/NavigationHistory").call("navigate_to", "res://app/menus/profile_screen.tscn")
	else:
		status_label.text = ""

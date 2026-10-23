extends Control

const NAVY = Color("#071126")
const PANEL = Color("#0b1735")
const WHITE = Color("#f3f7ff")
const MUTED = Color("#bac8e8")
const CYAN = Color("#55f4e9")
const DISTRICTS = [
	{"id": "privacy", "name": "BAIRRO DA\nPRIVACIDADE", "progress": "3/5 MISSÕES", "color": Color("#a95aff"), "center": Vector2(0.25, 0.325), "size": Vector2(0.26, 0.12), "points": [Vector2(0.04, 0.265), Vector2(0.25, 0.215), Vector2(0.48, 0.285), Vector2(0.43, 0.405), Vector2(0.25, 0.455), Vector2(0.055, 0.39)]},
	{"id": "communication", "name": "BAIRRO DA\nCOMUNICAÇÃO", "progress": "3/5 MISSÕES", "color": Color("#23e2e7"), "center": Vector2(0.75, 0.385), "size": Vector2(0.26, 0.12), "points": [Vector2(0.53, 0.315), Vector2(0.76, 0.265), Vector2(0.97, 0.34), Vector2(0.95, 0.455), Vector2(0.75, 0.505), Vector2(0.54, 0.445)]},
	{"id": "security", "name": "BAIRRO DA\nSEGURANÇA", "progress": "3/5 MISSÕES", "color": Color("#81ea48"), "center": Vector2(0.49, 0.555), "size": Vector2(0.30, 0.115), "points": [Vector2(0.27, 0.475), Vector2(0.50, 0.425), Vector2(0.73, 0.495), Vector2(0.69, 0.625), Vector2(0.50, 0.685), Vector2(0.30, 0.625), Vector2(0.19, 0.535)]},
	{"id": "knowledge", "name": "BAIRRO DO\nCONHECIMENTO", "progress": "1/3 MISSÕES", "color": Color("#ffc34f"), "center": Vector2(0.245, 0.715), "size": Vector2(0.27, 0.12), "points": [Vector2(0.035, 0.625), Vector2(0.24, 0.565), Vector2(0.48, 0.665), Vector2(0.43, 0.785), Vector2(0.24, 0.835), Vector2(0.045, 0.775)]},
	{"id": "respect", "name": "BAIRRO DO\nRESPEITO", "progress": "3/5 MISSÕES", "color": Color("#ff6687"), "center": Vector2(0.765, 0.745), "size": Vector2(0.27, 0.12), "points": [Vector2(0.56, 0.665), Vector2(0.77, 0.605), Vector2(0.97, 0.675), Vector2(0.96, 0.805), Vector2(0.77, 0.855), Vector2(0.57, 0.795)]}
]

var ui: Dictionary = {}
var selected_district: int = -1
var current_viewport_size := Vector2.ZERO


func _ready() -> void:
	_build_screen()
	get_viewport().connect("size_changed", self, "_on_viewport_size_changed")
	_layout_screen(get_viewport_rect().size)


func _build_screen() -> void:
	var background := TextureRect.new()
	background.name = "CityMapBackground"
	background.texture = load("res://shared/map/assets/mapa.png")
	background.expand = true
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background.anchor_right = 1.0
	background.anchor_bottom = 1.0
	add_child(background)
	ui["background"] = background

	var tint := ColorRect.new()
	tint.color = Color(0.015, 0.045, 0.13, 0.38)
	tint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tint.anchor_right = 1.0
	tint.anchor_bottom = 1.0
	add_child(tint)

	var area_layer := Control.new()
	area_layer.name = "InteractiveDistricts"
	area_layer.anchor_right = 1.0
	area_layer.anchor_bottom = 1.0
	area_layer.focus_mode = Control.FOCUS_ALL
	area_layer.mouse_filter = Control.MOUSE_FILTER_STOP
	area_layer.connect("draw", self, "_draw_districts")
	area_layer.connect("gui_input", self, "_on_area_input")
	add_child(area_layer)
	ui["areas"] = area_layer

	ui["header_panel"] = _new_panel("HeaderPanel", PANEL, Color("#526aa1"), 24)
	ui["screen_title"] = _new_label("MAPA DA CIDADE DIGITAL", WHITE, "title", Label.ALIGN_CENTER)
	ui["prompt_panel"] = _new_panel("MissionPrompt", PANEL, Color("#7886bd"), 22)
	ui["prompt"] = _new_label("Escolha um bairro para aceitar a missão!", WHITE, "prompt", Label.ALIGN_CENTER)
	ui["status"] = _new_label("", CYAN, "status", Label.ALIGN_CENTER)

	for district in DISTRICTS:
		var title := _new_label(district["name"], WHITE, "district", Label.ALIGN_CENTER)
		var progress := _new_label(district["progress"], WHITE, "progress", Label.ALIGN_CENTER)
		ui[district["id"] + "_title"] = title
		ui[district["id"] + "_progress"] = progress

	var nav_background := _new_panel("BottomNavigationBackground", NAVY, Color("#33466e"), 16)
	ui["nav_background"] = nav_background
	_add_nav_item("Inicio", "⌂", 0, "res://app/menus/home_screen.tscn")
	_add_nav_item("Mapa", "●", 1, "")
	_add_nav_item("Missões", "⚑", 2, "")
	_add_nav_item("Perfil", "♟", 3, "")
	ui["areas"].grab_focus()


func _draw_districts() -> void:
	var layer: Control = ui["areas"]
	var font: Font = layer.get_font("font")
	if font == null:
		return
	var landscape: bool = current_viewport_size.x > current_viewport_size.y
	var regions: Array = _district_layout(current_viewport_size, landscape)
	for index in range(regions.size()):
		var region: Dictionary = regions[index]
		var color: Color = DISTRICTS[index]["color"]
		var points := PoolVector2Array()
		for point in region["points"]:
			points.append(Vector2(point.x * layer.rect_size.x, point.y * layer.rect_size.y))
		var fill: Color = color
		fill.a = 0.30 if index != selected_district else 0.48
		layer.draw_colored_polygon(points, fill)
		var outline := PoolVector2Array(points)
		outline.append(points[0])
		layer.draw_polyline(outline, color.lightened(0.2), 3.0 if index == selected_district else 2.0, true)
		var center: Vector2 = region["center"] * layer.rect_size
		layer.draw_circle(center + Vector2(0, -font.get_height() * 0.95), min(layer.rect_size.x, layer.rect_size.y) * (0.027 if landscape else 0.038), color)
		layer.draw_arc(center + Vector2(0, -font.get_height() * 0.95), min(layer.rect_size.x, layer.rect_size.y) * (0.027 if landscape else 0.038), 0, TAU, 24, WHITE, 2.0, true)


func _district_layout(viewport_size: Vector2, landscape: bool) -> Array:
	var layouts: Array = []
	if landscape:
		var centers := [Vector2(0.18, 0.40), Vector2(0.50, 0.40), Vector2(0.82, 0.40), Vector2(0.34, 0.73), Vector2(0.67, 0.73)]
		var dimensions := Vector2(0.28, 0.25)
		for index in range(DISTRICTS.size()):
			layouts.append(_hex_region(centers[index], dimensions))
	else:
		for district in DISTRICTS:
			layouts.append({"points": district["points"], "center": district["center"]})
	return layouts


func _hex_region(center: Vector2, size: Vector2) -> Dictionary:
	var half_width: float = size.x * 0.5
	var half_height: float = size.y * 0.5
	var points := [
		Vector2(center.x - half_width * 0.62, center.y - half_height),
		Vector2(center.x + half_width * 0.62, center.y - half_height),
		Vector2(center.x + half_width, center.y),
		Vector2(center.x + half_width * 0.62, center.y + half_height),
		Vector2(center.x - half_width * 0.62, center.y + half_height),
		Vector2(center.x - half_width, center.y)
	]
	return {"points": points, "center": center}


func _add_nav_item(title: String, icon_text: String, index: int, scene_path: String) -> void:
	var button := Button.new()
	button.name = "Nav" + title.replace("ó", "o")
	button.text = icon_text + "\n" + title
	button.align = Button.ALIGN_CENTER
	button.focus_mode = Control.FOCUS_ALL
	button.add_stylebox_override("normal", _stylebox(NAVY, NAVY, 12, 1))
	button.add_stylebox_override("hover", _stylebox(Color("#132345"), CYAN, 12, 2))
	button.add_stylebox_override("focus", _stylebox(Color("#132345"), CYAN, 12, 2))
	button.add_color_override("font_color", CYAN if title == "Mapa" else MUTED)
	button.add_color_override("font_color_hover", WHITE)
	button.add_color_override("font_color_focus", WHITE)
	button.set_meta("nav_index", index)
	button.set_meta("font_role", "nav")
	button.connect("pressed", self, "_on_nav_pressed", [title, scene_path])
	add_child(button)
	ui["nav_" + str(index)] = button


func _layout_screen(viewport_size: Vector2) -> void:
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		return
	current_viewport_size = viewport_size
	var width: float = viewport_size.x
	var height: float = viewport_size.y
	var landscape: bool = width > height
	var safe: float = min(width, height) * 0.035
	var font_basis: float = min(width, height)
	_place(ui["header_panel"], safe * 0.6, safe * 0.55, width - safe * 1.2, height * 0.075)
	_place(ui["screen_title"], safe * 1.4, safe * 0.65, width - safe * 2.8, height * 0.055, font_basis)
	_place(ui["prompt_panel"], safe, height * 0.105, width - safe * 2.0, height * 0.078)
	_place(ui["prompt"], safe * 1.6, height * 0.115, width - safe * 3.2, height * 0.055, font_basis)
	var nav_height: float = height * (0.105 if landscape else 0.11)
	var nav_y: float = height - nav_height - safe * 0.5
	_place(ui["nav_background"], safe * 0.5, nav_y, width - safe, nav_height)
	var nav_width: float = (width - safe * 2.0) / 4.0
	for index in range(4):
		_place(ui["nav_" + str(index)], safe + nav_width * index, nav_y + nav_height * 0.06, nav_width, nav_height * 0.88, font_basis)
	_place(ui["status"], safe, nav_y - height * 0.038, width - safe * 2.0, height * 0.035, font_basis)
	var regions: Array = _district_layout(viewport_size, landscape)
	for index in range(DISTRICTS.size()):
		var region: Dictionary = regions[index]
		var center: Vector2 = region["center"]
		var size: Vector2 = region.get("size", Vector2(width * (0.20 if landscape else 0.28), height * (0.105 if landscape else 0.095)))
		if landscape:
			size = Vector2(width * 0.22, height * 0.10)
		var name_key: String = DISTRICTS[index]["id"] + "_title"
		var progress_key: String = DISTRICTS[index]["id"] + "_progress"
		_place(ui[name_key], center.x * width - size.x * 0.5, center.y * height - size.y * 0.28, size.x, size.y * 0.55, font_basis)
		_place(ui[progress_key], center.x * width - size.x * 0.5, center.y * height + size.y * 0.24, size.x, size.y * 0.30, font_basis)
	ui["areas"].rect_size = viewport_size
	ui["areas"].update()


func _place(control: Control, x: float, y: float, width: float, height: float, font_basis: float = 720.0) -> void:
	var scale: float = 1.0
	if control.has_meta("font_role"):
		var font: Font = control.get_font("font")
		var ratio: float = {"title": 0.038, "prompt": 0.031, "district": 0.021, "progress": 0.016, "status": 0.018, "nav": 0.020}[control.get_meta("font_role")]
		if font != null:
			scale = min(font_basis * ratio / font.get_height(), _fit_text_scale(control, font, width, height))
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
	var width_scale: float = width / max(1.0, widest_line)
	var height_scale: float = height / max(1.0, font.get_height() * line_count)
	return max(0.01, min(width_scale, height_scale))


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


func _new_panel(node_name: String, fill: Color, border: Color, radius: int) -> Panel:
	var panel := Panel.new()
	panel.name = node_name
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_stylebox_override("panel", _stylebox(fill, border, radius, 2))
	add_child(panel)
	return panel


func _stylebox(fill: Color, border: Color, radius: int, border_width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(radius)
	return style


func _district_at_point(point: Vector2) -> int:
	var regions: Array = _district_layout(current_viewport_size, current_viewport_size.x > current_viewport_size.y)
	for index in range(regions.size() - 1, -1, -1):
		var polygon: PoolVector2Array = PoolVector2Array()
		for normalized_point in regions[index]["points"]:
			polygon.append(Vector2(normalized_point.x * current_viewport_size.x, normalized_point.y * current_viewport_size.y))
		if Geometry.is_point_in_polygon(point, polygon):
			return index
	return -1


func _on_area_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == BUTTON_LEFT:
		_select_district(_district_at_point((event as InputEventMouseButton).position))
		ui["areas"].accept_event()
	elif event is InputEventScreenTouch and event.pressed:
		_select_district(_district_at_point((event as InputEventScreenTouch).position))
		ui["areas"].accept_event()
	elif event is InputEventKey and event.pressed:
		var key: int = (event as InputEventKey).scancode
		if key == KEY_LEFT or key == KEY_UP:
			selected_district = posmod(selected_district - 1, DISTRICTS.size())
			ui["areas"].update()
		elif key == KEY_RIGHT or key == KEY_DOWN:
			selected_district = posmod(selected_district + 1, DISTRICTS.size())
			ui["areas"].update()
		elif (key == KEY_ENTER or key == KEY_KP_ENTER or key == KEY_SPACE) and selected_district >= 0:
			_select_district(selected_district)
		ui["areas"].accept_event()


func _select_district(index: int) -> void:
	if index < 0 or index >= DISTRICTS.size():
		return
	selected_district = index
	ui["areas"].update()
	ui["status"].text = DISTRICTS[index]["name"].replace("\n", " ") + " selecionado."


func _on_nav_pressed(title: String, scene_path: String) -> void:
	if not scene_path.empty():
		get_tree().change_scene(scene_path)
	elif title == "Missões":
		ui["status"].text = "Escolha um bairro para aceitar a missão!"
	else:
		ui["status"].text = "A tela de Perfil estará disponível em breve."


func _on_viewport_size_changed() -> void:
	_layout_screen(get_viewport_rect().size)

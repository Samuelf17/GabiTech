extends Control

const BOTTOM_NAVIGATION = preload("res://shared/ui/bottom_navigation.tscn")
const TYPOGRAPHY = preload("res://shared/ui/typography.gd")
const NON_HOME_TITLE_SCALE: float = 1.10
const PORTRAIT_MAP_BACKGROUND_PATH = "res://shared/map/assets/mapa.png"
const LANDSCAPE_MAP_BACKGROUND_PATH = "res://shared/map/assets/mapa_horizontal.png"
const NAVY = Color("#071126")
const PANEL = Color("#0b1735")
const WHITE = Color("#f3f7ff")
const CYAN = Color("#55f4e9")
const DISTRICT_ICON_PATHS = {
	"privacy": "res://shared/ui/assets/icons/lock_icon.svg",
	"communication": "res://shared/ui/assets/icons/chat_icon.svg",
	"security": "res://shared/ui/assets/icons/shield_icon.svg",
	"respect": "res://shared/ui/assets/icons/groups_icon.svg"
}
const DISTRICTS = [
	{"id": "privacy", "name": "BAIRRO DA\nPRIVACIDADE", "color": Color("#a95aff")},
	{"id": "communication", "name": "BAIRRO DA\nCOMUNICAÇÃO", "color": Color("#23e2e7")},
	{"id": "security", "name": "BAIRRO DA\nSEGURANÇA", "color": Color("#81ea48")},
	{"id": "knowledge", "name": "BAIRRO DO\nCONHECIMENTO", "color": Color("#ffc34f")},
	{"id": "respect", "name": "BAIRRO DO\nRESPEITO", "color": Color("#ff6687")}
]

var ui: Dictionary = {}
var selected_district: int = -1
var current_viewport_size := Vector2.ZERO
var active_background_path: String = ""
var typography = TYPOGRAPHY.new()


func _ready() -> void:
	_build_screen()
	get_viewport().connect("size_changed", self, "_on_viewport_size_changed")
	_layout_screen(get_viewport_rect().size)


func _build_screen() -> void:
	var background := TextureRect.new()
	background.name = "CityMapBackground"
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
		ui[district["id"] + "_title"] = title
		if DISTRICT_ICON_PATHS.has(district["id"]):
			var district_icon := TextureRect.new()
			district_icon.name = "DistrictIcon_" + district["id"]
			district_icon.texture = load(DISTRICT_ICON_PATHS[district["id"]])
			district_icon.expand = true
			district_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			district_icon.modulate = district["color"]
			district_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
			add_child(district_icon)
			ui[district["id"] + "_icon"] = district_icon

	var navigation = BOTTOM_NAVIGATION.instance()
	navigation.name = "BottomNavigation"
	navigation.active_item = "map"
	navigation.connect("item_selected", self, "_on_nav_pressed")
	add_child(navigation)
	ui["navigation"] = navigation
	ui["areas"].grab_focus()


func _draw_districts() -> void:
	var layer: Control = ui["areas"]
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


func _district_layout(viewport_size: Vector2, landscape: bool) -> Array:
	var layouts: Array = []
	var width: float = viewport_size.x
	var height: float = viewport_size.y
	var short_side: float = min(width, height)
	var centers: Array = []
	var district_size: Vector2
	if landscape:
		centers = [Vector2(0.18, 0.37), Vector2(0.50, 0.37), Vector2(0.82, 0.37), Vector2(0.20, 0.72), Vector2(0.80, 0.72)]
		district_size = Vector2(min(width * 0.28, short_side * 0.50), min(height * 0.27 * 1.10, short_side * 0.36 * 1.10))
	else:
		centers = [Vector2(0.25, 0.34), Vector2(0.75, 0.34), Vector2(0.50, 0.54), Vector2(0.25, 0.74), Vector2(0.75, 0.74)]
		district_size = Vector2(min(width * 0.46, short_side * 0.50), min(height * 0.19 * 1.10, short_side * 0.42 * 1.10))
	for center in centers:
		layouts.append(_octagon_region(center, district_size, viewport_size))
	return layouts


func _octagon_region(center: Vector2, size: Vector2, viewport_size: Vector2) -> Dictionary:
	var half_width: float = size.x / viewport_size.x * 0.5
	var half_height: float = size.y / viewport_size.y * 0.5
	var chamfer_x: float = half_width * 0.34
	var chamfer_y: float = half_height * 0.34
	var points := [
		Vector2(center.x - chamfer_x, center.y - half_height),
		Vector2(center.x + chamfer_x, center.y - half_height),
		Vector2(center.x + half_width, center.y - chamfer_y),
		Vector2(center.x + half_width, center.y + chamfer_y),
		Vector2(center.x + chamfer_x, center.y + half_height),
		Vector2(center.x - chamfer_x, center.y + half_height),
		Vector2(center.x - half_width, center.y + chamfer_y),
		Vector2(center.x - half_width, center.y - chamfer_y)
	]
	return {"points": points, "center": center, "size": size}


func _layout_screen(viewport_size: Vector2) -> void:
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		return
	current_viewport_size = viewport_size
	var width: float = viewport_size.x
	var height: float = viewport_size.y
	var landscape: bool = width > height
	_load_background_for_orientation(landscape)
	var safe: float = min(width, height) * 0.035
	var font_basis: float = min(width, height)
	var header_y: float = height * 0.05
	var header_height: float = height * 0.075
	var prompt_y: float = header_y + header_height + height * 0.018
	_place(ui["header_panel"], safe * 0.6, header_y, width - safe * 1.2, header_height)
	_place(ui["screen_title"], safe * 1.4, header_y + safe * 0.1, width - safe * 2.8, height * 0.055, font_basis)
	_place(ui["prompt_panel"], safe, prompt_y, width - safe * 2.0, height * 0.078)
	_place(ui["prompt"], safe * 1.6, prompt_y + height * 0.01, width - safe * 3.2, height * 0.055, font_basis)
	var navigation_top: float = ui["navigation"].get_bar_top(viewport_size)
	_place(ui["status"], safe, navigation_top - height * 0.043, width - safe * 2.0, height * 0.035, font_basis)
	var regions: Array = _district_layout(viewport_size, landscape)
	for index in range(DISTRICTS.size()):
		var region: Dictionary = regions[index]
		var center: Vector2 = region["center"]
		var size: Vector2 = region["size"]
		var name_key: String = DISTRICTS[index]["id"] + "_title"
		var title_y: float = center.y * height - size.y * 0.12
		_place(ui[name_key], center.x * width - size.x * 0.5, title_y, size.x, size.y * 0.32, font_basis)
		var icon_key: String = DISTRICTS[index]["id"] + "_icon"
		if ui.has(icon_key):
			var icon_size: float = min(min(width, height) * 0.07, size.y * 0.20)
			_place(ui[icon_key], center.x * width - icon_size * 0.5, center.y * height - size.y * 0.35, icon_size, icon_size)
	ui["areas"].rect_size = viewport_size
	ui["areas"].update()


func _load_background_for_orientation(landscape: bool) -> void:
	var texture_path: String = LANDSCAPE_MAP_BACKGROUND_PATH if landscape else PORTRAIT_MAP_BACKGROUND_PATH
	if active_background_path == texture_path:
		return

	var background: TextureRect = ui["background"]
	background.texture = null
	active_background_path = ""
	var loaded_texture: Texture = ResourceLoader.load(texture_path, "Texture", true)
	if loaded_texture == null:
		push_error("Não foi possível carregar a arte do mapa: " + texture_path)
		return
	background.texture = loaded_texture
	active_background_path = texture_path


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



func _on_nav_pressed(item_id: String) -> void:
	if item_id == "home":
		get_node("/root/NavigationHistory").call("navigate_to", "res://app/menus/home_screen.tscn")
	elif item_id == "missions":
		get_node("/root/NavigationHistory").call("navigate_to", "res://games/quiz/scenes/quiz_screen.tscn")
	elif item_id == "profile":
		get_node("/root/NavigationHistory").call("navigate_to", "res://app/menus/profile_screen.tscn")
	else:
		ui["status"].text = ""


func _on_viewport_size_changed() -> void:
	_layout_screen(get_viewport_rect().size)

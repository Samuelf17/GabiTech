extends Control

signal item_selected(item_id)

const NAVY = Color("#071126")
const PANEL_LIGHT = Color("#17284c")
const CYAN = Color("#18d6d2")
const MUTED = Color("#a8b5d2")
const WHITE = Color("#f3f7ff")
const TYPOGRAPHY = preload("res://shared/ui/typography.gd")
const ITEM_IDS = ["home", "map", "missions", "profile"]
const ITEM_LABELS = ["Inicio", "Mapa", "Missões", "Perfil"]
const ITEM_ICON_PATHS = {
	"home": "res://shared/ui/assets/icons/home_icon.svg",
	"map": "res://shared/ui/assets/icons/map_icon.svg",
	"missions": "res://shared/ui/assets/icons/mission_icon.svg",
	"profile": "res://shared/ui/assets/icons/profile_icon.svg"
}

export(String, "home", "map", "missions", "profile") var active_item = "home"

var buttons: Dictionary = {}
var labels: Dictionary = {}
var icons: Dictionary = {}
var background: Panel
var typography = TYPOGRAPHY.new()


func _ready() -> void:
	_build_menu()
	connect("resized", self, "_on_resized")
	get_viewport().connect("size_changed", self, "_on_viewport_size_changed")
	call_deferred("layout_for_viewport", rect_size)


func _build_menu() -> void:
	background = Panel.new()
	background.name = "Background"
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background.add_stylebox_override("panel", _stylebox(NAVY, Color("#33466e"), 16, 1))
	add_child(background)

	for index in range(ITEM_IDS.size()):
		var item_id: String = ITEM_IDS[index]
		var button := Button.new()
		button.name = "NavItem_" + item_id
		button.text = ""
		button.focus_mode = Control.FOCUS_ALL
		button.add_stylebox_override("normal", _stylebox(NAVY, NAVY, 12, 1))
		button.add_stylebox_override("hover", _stylebox(PANEL_LIGHT, CYAN, 12, 2))
		button.add_stylebox_override("focus", _stylebox(PANEL_LIGHT, CYAN, 12, 2))
		button.add_color_override("font_color", CYAN if item_id == active_item else MUTED)
		button.add_color_override("font_color_hover", WHITE)
		button.add_color_override("font_color_focus", WHITE)
		button.set_meta("font_role", "navigation")
		button.connect("pressed", self, "_on_item_pressed", [item_id])
		add_child(button)

		var icon := TextureRect.new()
		icon.name = "Icon_" + item_id
		icon.texture = load(ITEM_ICON_PATHS[item_id])
		icon.expand = true
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.modulate = CYAN if item_id == active_item else MUTED
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.add_child(icon)

		var label := Label.new()
		label.name = "Label_" + item_id
		label.text = ITEM_LABELS[index]
		label.clip_text = true
		label.align = Label.ALIGN_CENTER
		label.valign = Label.VALIGN_CENTER
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		label.add_color_override("font_color", CYAN if item_id == active_item else MUTED)
		label.set_meta("font_role", "navigation")
		button.add_child(label)

		buttons[item_id] = button
		icons[item_id] = icon
		labels[item_id] = label


func layout_for_viewport(viewport_size: Vector2) -> void:
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		return
	var width: float = viewport_size.x
	var height: float = viewport_size.y
	var short_side: float = min(width, height)
	var safe_x: float = short_side * 0.035
	var bar_height: float = height * 0.11
	var bar_top: float = get_bar_top(viewport_size)
	_place(background, safe_x * 0.5, bar_top, width - safe_x, bar_height, 1.0)
	var item_width: float = (width - safe_x * 2.0) / float(ITEM_IDS.size())
	for index in range(ITEM_IDS.size()):
		var item_id: String = ITEM_IDS[index]
		var button: Button = buttons[item_id]
		var label: Label = labels[item_id]
		var x: float = safe_x + item_width * index
		var button_y: float = bar_top + bar_height * 0.06
		var button_height: float = bar_height * 0.88
		var scale: float = _font_scale(label, short_side)
		_place(button, x, button_y, item_width, button_height, scale)
		_layout_item_content(item_id, short_side, item_width, button_height, scale)


func get_bar_top(viewport_size: Vector2) -> float:
	var short_side: float = min(viewport_size.x, viewport_size.y)
	var safe_bottom: float = max(9.0, short_side * 0.0125)
	return viewport_size.y - viewport_size.y * 0.11 - safe_bottom


func _layout_item_content(item_id: String, short_side: float, width: float, height: float, scale: float) -> void:
	var local_width: float = width / scale
	var local_height: float = height / scale
	var icon_size: float = min(short_side * 0.08, height * 0.45) / scale
	var icon: TextureRect = icons[item_id]
	icon.rect_position = Vector2((local_width - icon_size) * 0.5, local_height * 0.08)
	icon.rect_size = Vector2(icon_size, icon_size)
	var label: Label = labels[item_id]
	var label_top: float = icon.rect_position.y + icon_size + (short_side * 0.008 / scale)
	label.rect_position = Vector2(local_width * 0.04, label_top)
	label.rect_size = Vector2(local_width * 0.92, max(0.0, local_height - label_top - local_height * 0.04))


func _font_scale(label: Label, short_side: float) -> float:
	var font: Font = label.get_font("font")
	if font == null:
		return 1.0
	return typography.get_target_height("body", short_side) / font.get_height()


func _place(control: Control, x: float, y: float, width: float, height: float, scale: float) -> void:
	control.anchor_left = 0.0
	control.anchor_top = 0.0
	control.anchor_right = 0.0
	control.anchor_bottom = 0.0
	control.rect_scale = Vector2(scale, scale)
	control.margin_left = x
	control.margin_top = y
	control.margin_right = x + width / scale
	control.margin_bottom = y + height / scale


func _stylebox(fill: Color, border: Color, radius: int, border_width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(radius)
	return style


func _on_item_pressed(item_id: String) -> void:
	emit_signal("item_selected", item_id)


func _on_resized() -> void:
	layout_for_viewport(rect_size)


func _on_viewport_size_changed() -> void:
	layout_for_viewport(get_viewport_rect().size)

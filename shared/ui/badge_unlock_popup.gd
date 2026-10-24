extends CanvasLayer

signal dismissed(event_id)

const TYPOGRAPHY = preload("res://shared/ui/typography.gd")
const BADGE_CATALOG = preload("res://shared/progress/badge_catalog.gd")
const SHIELD_ICON = preload("res://shared/ui/assets/icons/shield_icon.svg")
const CYAN = Color("#28e3dc")
const WHITE = Color("#f3f7ff")
const LOCKED_COLOR = Color("#778196")
const DISPLAY_SECONDS: float = 5.0
const TITLE_SCALE: float = 1.10
const LEVEL_UP_ROTATIONS: int = 3
const LEVEL_UP_HALF_TURN_DURATION: float = 0.32

var typography = TYPOGRAPHY.new()
var event_id: String = ""
var badge_color: Color = WHITE
var overlay: Control
var title_label: Label
var badge_icon: TextureRect
var badge_name_label: Label
var timer: Timer
var tween: Tween
var displayed: bool = false


func _ready() -> void:
	layer = 20
	set_process_input(true)
	_build_popup()
	get_viewport().connect("size_changed", self, "_on_viewport_size_changed")


func present(notification: Dictionary) -> bool:
	var badge: Dictionary = BADGE_CATALOG.get_badge(String(notification.get("badge_id", "")))
	if badge.empty() or not notification.has("event_id") or not notification.has("level"):
		return false
	event_id = String(notification["event_id"])
	badge_color = badge["color"]
	var is_first_unlock: bool = notification.get("kind", "") == "unlocked"
	title_label.text = (
		"Distintivo %s desbloqueado!" % badge["display_name"]
		if is_first_unlock
		else "Nivel %d alcançado!!!" % int(notification["level"])
	)
	badge_name_label.text = badge["name"]
	badge_name_label.visible = not is_first_unlock
	badge_icon.modulate = LOCKED_COLOR if is_first_unlock else badge_color
	badge_icon.rect_scale = Vector2.ONE if not is_first_unlock else Vector2(0.72, 0.72)
	badge_icon.rect_rotation = 0.0
	visible = true
	displayed = true
	_layout_popup(get_viewport().get_visible_rect().size)
	_start_badge_animation(is_first_unlock)
	timer.start(DISPLAY_SECONDS)
	return true


func _build_popup() -> void:
	overlay = Control.new()
	overlay.name = "BadgeUnlockOverlay"
	overlay.anchor_right = 1.0
	overlay.anchor_bottom = 1.0
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(overlay)

	var dim := ColorRect.new()
	dim.name = "DimBackground"
	dim.color = Color(0.0, 0.0, 0.0, 0.84)
	dim.anchor_right = 1.0
	dim.anchor_bottom = 1.0
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(dim)

	title_label = Label.new()
	title_label.name = "NotificationTitle"
	title_label.align = Label.ALIGN_CENTER
	title_label.valign = Label.VALIGN_CENTER
	title_label.autowrap = true
	title_label.add_color_override("font_color", CYAN)
	title_label.set_meta("font_role", "heading")
	overlay.add_child(title_label)

	badge_icon = TextureRect.new()
	badge_icon.name = "BadgeIcon"
	badge_icon.texture = SHIELD_ICON
	badge_icon.expand = true
	badge_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	badge_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(badge_icon)

	badge_name_label = Label.new()
	badge_name_label.name = "BadgeName"
	badge_name_label.align = Label.ALIGN_CENTER
	badge_name_label.valign = Label.VALIGN_CENTER
	badge_name_label.autowrap = true
	badge_name_label.add_color_override("font_color", WHITE)
	badge_name_label.set_meta("font_role", "body")
	overlay.add_child(badge_name_label)

	timer = Timer.new()
	timer.name = "DismissTimer"
	timer.one_shot = true
	timer.wait_time = DISPLAY_SECONDS
	timer.connect("timeout", self, "_on_timer_timeout")
	add_child(timer)
	visible = false


func _layout_popup(viewport_size: Vector2) -> void:
	if badge_name_label.visible:
		_layout_level_up_popup(viewport_size)
	else:
		_layout_unlock_popup(viewport_size)


func _layout_unlock_popup(viewport_size: Vector2) -> void:
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		return
	title_label.valign = Label.VALIGN_CENTER
	overlay.rect_size = viewport_size
	var width: float = viewport_size.x
	var height: float = viewport_size.y
	var short_side: float = min(width, height)
	var title_height: float = min(height * 0.20, short_side * 0.24)
	_layout_title(width, height, short_side, max(short_side * 0.05, height * 0.04), title_height)
	var icon_size: float = min(short_side * 0.36, height * 0.42)
	var icon_left: float = (width - icon_size) * 0.5
	var icon_top: float = (height - icon_size) * 0.5
	badge_icon.rect_size = Vector2(icon_size, icon_size)
	badge_icon.rect_position = Vector2(icon_left, icon_top)
	badge_icon.rect_pivot_offset = Vector2(icon_size, icon_size) * 0.5
	_layout_badge_name(width, height, short_side, icon_top, icon_size, short_side * 0.025)


func _layout_level_up_popup(viewport_size: Vector2) -> void:
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		return
	title_label.valign = Label.VALIGN_TOP
	overlay.rect_size = viewport_size
	var width: float = viewport_size.x
	var height: float = viewport_size.y
	var short_side: float = min(width, height)
	var title_height: float = min(height * 0.10, short_side * 0.14)
	_layout_title(width, height, short_side, height * 0.20, title_height)
	var icon_size: float = min(short_side * 0.33, height * 0.42)
	var icon_left: float = (width - icon_size) * 0.5
	var icon_top: float = (height - icon_size) * 0.5
	badge_icon.rect_size = Vector2(icon_size, icon_size)
	badge_icon.rect_position = Vector2(icon_left, icon_top)
	badge_icon.rect_pivot_offset = Vector2(icon_size, icon_size) * 0.5
	_layout_badge_name(width, height, short_side, icon_top, icon_size, 0.0)


func _layout_title(width: float, height: float, short_side: float, title_margin: float, title_height: float) -> void:
	title_label.rect_position = Vector2(short_side * 0.05, title_margin)
	title_label.rect_size = Vector2(width - short_side * 0.10, title_height)
	_place_label(title_label, short_side, "heading", true)


func _layout_badge_name(width: float, height: float, short_side: float, icon_top: float, icon_size: float, content_gap: float) -> void:
	var name_width: float = width * 0.84
	var name_top: float = icon_top + icon_size + content_gap
	var base_font: Font = typography.get_base_font(badge_name_label)
	var font_scale: float = typography.get_target_height("body", short_side) / base_font.get_height()
	var font: Font = typography.apply_font_scale(badge_name_label, font_scale)
	var text_size: Vector2 = font.get_wordwrap_string_size(badge_name_label.text, name_width)
	var name_height: float = max(text_size.y, 1.0)
	badge_name_label.valign = Label.VALIGN_TOP
	badge_name_label.rect_position = Vector2((width - name_width) * 0.5, name_top)
	badge_name_label.rect_size = Vector2(name_width, name_height)


func _place_label(label: Label, font_basis: float, role: String, is_title: bool) -> void:
	var font: Font = typography.get_base_font(label)
	if font == null:
		return
	var scale: float = typography.get_target_height(role, font_basis) / font.get_height()
	if is_title:
		scale *= TITLE_SCALE
	typography.apply_font_scale(label, scale)


func _start_badge_animation(is_first_unlock: bool) -> void:
	if tween != null and tween.is_active():
		tween.stop_all()
		tween.remove_all()
	if tween == null:
		tween = Tween.new()
		add_child(tween)
	tween.repeat = false
	if is_first_unlock:
		tween.interpolate_property(
			badge_icon,
			"rect_scale",
			Vector2(0.72, 0.72),
			Vector2(1.18, 1.18),
			0.45,
			Tween.TRANS_BACK,
			Tween.EASE_OUT
		)
		tween.interpolate_property(
			badge_icon,
			"rect_scale",
			Vector2(1.18, 1.18),
			Vector2.ONE,
			0.35,
			Tween.TRANS_SINE,
			Tween.EASE_IN_OUT,
			0.45
		)
		tween.interpolate_property(
			badge_icon,
			"modulate",
			LOCKED_COLOR,
			badge_color,
			0.80,
			Tween.TRANS_SINE,
			Tween.EASE_IN_OUT
		)
	else:
		for rotation_index in range(LEVEL_UP_ROTATIONS):
			var rotation_delay: float = float(rotation_index) * LEVEL_UP_HALF_TURN_DURATION * 2.0
			tween.interpolate_property(
				badge_icon,
				"rect_scale:x",
				1.0,
				0.04,
				LEVEL_UP_HALF_TURN_DURATION,
				Tween.TRANS_SINE,
				Tween.EASE_IN_OUT,
				rotation_delay
			)
			tween.interpolate_property(
				badge_icon,
				"rect_scale:x",
				0.04,
				1.0,
				LEVEL_UP_HALF_TURN_DURATION,
				Tween.TRANS_SINE,
				Tween.EASE_IN_OUT,
				rotation_delay + LEVEL_UP_HALF_TURN_DURATION
			)
	tween.start()


func _on_timer_timeout() -> void:
	if not displayed:
		return
	displayed = false
	visible = false
	if tween != null and tween.is_active():
		tween.stop_all()
		badge_icon.rect_scale = Vector2.ONE
	emit_signal("dismissed", event_id)


func _on_viewport_size_changed() -> void:
	if displayed:
		_layout_popup(get_viewport().get_visible_rect().size)


func _input(event: InputEvent) -> void:
	if displayed and event is InputEventKey:
		get_tree().set_input_as_handled()



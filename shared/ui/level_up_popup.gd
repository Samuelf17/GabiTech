extends CanvasLayer

signal dismissed

const TYPOGRAPHY = preload("res://shared/ui/typography.gd")
const MASCOT_TEXTURES = [
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
const DISPLAY_SECONDS: float = 5.0
const SPIN_COUNT: int = 8
const QUARTER_TURN_SECONDS: float = 0.05
const BURST_SECONDS: float = 0.35
const BURST_RADIUS_RATIO: float = 0.28
const BURST_COLORS = [Color("#20bfff"), Color("#1685ff"), Color("#75eaff"), Color("#4b5dff")]
const WHITE = Color("#f3f7ff")
const CYAN = Color("#55e8e2")

var typography = TYPOGRAPHY.new()
var overlay: Control
var title_label: Label
var previous_mascot: TextureRect
var reached_mascot: TextureRect
var blue_flash: ColorRect
var burst_sparks: Array = []
var tween: Tween
var dismiss_timer: Timer
var displayed: bool = false
var animation_phase: String = "hidden"
var previous_level: int = 0
var reached_level: int = 0
var viewport_size: Vector2 = Vector2.ZERO


func _ready() -> void:
	layer = 30
	_build_popup()
	get_viewport().connect("size_changed", self, "_on_viewport_size_changed")


func present(old_level: int, new_level: int) -> bool:
	if new_level <= old_level or old_level < 1:
		return false
	previous_level = old_level
	reached_level = new_level
	title_label.text = "Nivel %d alcançado!" % reached_level
	previous_mascot.texture = _mascot_for_level(previous_level)
	reached_mascot.texture = _mascot_for_level(reached_level)
	previous_mascot.rect_scale = Vector2.ONE
	previous_mascot.flip_h = false
	previous_mascot.modulate = WHITE
	previous_mascot.visible = true
	reached_mascot.rect_scale = Vector2(0.76, 0.76)
	reached_mascot.modulate = Color(1.0, 1.0, 1.0, 0.0)
	reached_mascot.visible = true
	blue_flash.color.a = 0.0
	for spark in burst_sparks:
		spark.modulate.a = 0.0
	visible = true
	displayed = true
	animation_phase = "spinning"
	_layout_popup(get_viewport().get_visible_rect().size)
	_start_animation()
	dismiss_timer.start(DISPLAY_SECONDS)
	return true


func _build_popup() -> void:
	overlay = Control.new()
	overlay.name = "LevelUpOverlay"
	overlay.anchor_right = 1.0
	overlay.anchor_bottom = 1.0
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(overlay)

	var dim_background := ColorRect.new()
	dim_background.name = "DimBackground"
	dim_background.color = Color(0.0, 0.0, 0.0, 0.86)
	dim_background.anchor_right = 1.0
	dim_background.anchor_bottom = 1.0
	dim_background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(dim_background)

	blue_flash = ColorRect.new()
	blue_flash.name = "BlueExplosionFlash"
	blue_flash.color = Color(0.04, 0.40, 1.0, 0.0)
	blue_flash.anchor_right = 1.0
	blue_flash.anchor_bottom = 1.0
	blue_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(blue_flash)

	previous_mascot = _new_mascot("PreviousLevelCapybara")
	overlay.add_child(previous_mascot)
	reached_mascot = _new_mascot("ReachedLevelCapybara")
	overlay.add_child(reached_mascot)

	for spark_index in range(12):
		var spark := ColorRect.new()
		spark.name = "BlueBurstSpark%d" % spark_index
		spark.color = BURST_COLORS[spark_index % BURST_COLORS.size()]
		spark.mouse_filter = Control.MOUSE_FILTER_IGNORE
		spark.modulate.a = 0.0
		overlay.add_child(spark)
		burst_sparks.append(spark)

	title_label = Label.new()
	title_label.name = "LevelUpTitle"
	title_label.align = Label.ALIGN_CENTER
	title_label.valign = Label.VALIGN_TOP
	title_label.autowrap = true
	title_label.add_color_override("font_color", CYAN)
	title_label.set_meta("font_role", "heading")
	title_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(title_label)

	dismiss_timer = Timer.new()
	dismiss_timer.name = "LevelUpDismissTimer"
	dismiss_timer.one_shot = true
	dismiss_timer.wait_time = DISPLAY_SECONDS
	dismiss_timer.connect("timeout", self, "_on_dismiss_timer_timeout")
	add_child(dismiss_timer)
	visible = false


func _new_mascot(node_name: String) -> TextureRect:
	var mascot := TextureRect.new()
	mascot.name = node_name
	mascot.expand = true
	mascot.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	mascot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return mascot


func _mascot_for_level(level: int) -> Texture:
	var texture_index: int = clamp(level, 1, MASCOT_TEXTURES.size()) - 1
	return MASCOT_TEXTURES[texture_index]


func burst_radius_for_viewport() -> float:
	return min(viewport_size.x, viewport_size.y) * BURST_RADIUS_RATIO


func _layout_popup(size: Vector2) -> void:
	if size.x <= 0.0 or size.y <= 0.0:
		return
	viewport_size = size
	var width: float = size.x
	var height: float = size.y
	var short_side: float = min(width, height)
	var title_width: float = width - short_side * 0.10
	var title_height: float = min(height * 0.12, short_side * 0.16)
	title_label.rect_position = Vector2(short_side * 0.05, height * 0.055)
	title_label.rect_size = Vector2(title_width, title_height)
	var base_font: Font = typography.get_base_font(title_label)
	if base_font != null:
		var title_scale: float = typography.get_target_height("heading", short_side) / base_font.get_height()
		typography.apply_font_scale(title_label, title_scale)

	var mascot_size: float = min(short_side * 0.50, height * 0.43)
	var mascot_position := Vector2((width - mascot_size) * 0.5, height * 0.53 - mascot_size * 0.5)
	for mascot in [previous_mascot, reached_mascot]:
		mascot.rect_position = mascot_position
		mascot.rect_size = Vector2(mascot_size, mascot_size)
		mascot.rect_pivot_offset = Vector2(mascot_size, mascot_size) * 0.5

	var spark_length: float = max(10.0, short_side * 0.055)
	var spark_width: float = max(4.0, short_side * 0.018)
	var center: Vector2 = mascot_position + Vector2.ONE * mascot_size * 0.5
	for spark_index in range(burst_sparks.size()):
		var angle: float = TAU * float(spark_index) / float(burst_sparks.size())
		var spark: ColorRect = burst_sparks[spark_index]
		spark.rect_size = Vector2(spark_width, spark_length)
		spark.rect_pivot_offset = spark.rect_size * 0.5
		spark.rect_position = center - spark.rect_pivot_offset
		spark.rect_rotation = rad2deg(angle)


func _start_animation() -> void:
	if tween != null:
		tween.stop_all()
		tween.queue_free()
	tween = Tween.new()
	tween.name = "LevelUpAnimation"
	add_child(tween)
	var quarter_index: int = 0
	for _spin_index in range(SPIN_COUNT):
		for target_scale in [0.04, -1.0, -0.04, 1.0]:
			var delay: float = float(quarter_index) * QUARTER_TURN_SECONDS
			tween.interpolate_property(
				previous_mascot,
				"rect_scale:x",
				null,
				target_scale,
				QUARTER_TURN_SECONDS,
				Tween.TRANS_LINEAR,
				Tween.EASE_IN_OUT,
				delay
			)
			quarter_index += 1
	var spin_duration: float = float(SPIN_COUNT * 4) * QUARTER_TURN_SECONDS
	tween.interpolate_property(previous_mascot, "modulate:a", 1.0, 0.0, 0.08, Tween.TRANS_SINE, Tween.EASE_IN_OUT, spin_duration)
	tween.interpolate_property(blue_flash, "color:a", 0.0, 0.42, 0.08, Tween.TRANS_SINE, Tween.EASE_OUT, spin_duration)
	tween.interpolate_property(blue_flash, "color:a", 0.42, 0.0, BURST_SECONDS, Tween.TRANS_SINE, Tween.EASE_IN_OUT, spin_duration + 0.08)
	tween.interpolate_callback(self, spin_duration, "_on_explosion_started")
	tween.interpolate_callback(self, spin_duration + BURST_SECONDS, "_on_mascot_revealed")
	var radius: float = burst_radius_for_viewport()
	for spark_index in range(burst_sparks.size()):
		var angle: float = TAU * float(spark_index) / float(burst_sparks.size())
		var direction := Vector2(cos(angle), sin(angle))
		var spark: ColorRect = burst_sparks[spark_index]
		var start_position: Vector2 = spark.rect_position
		var end_position: Vector2 = start_position + direction * radius
		tween.interpolate_property(spark, "rect_position", start_position, end_position, BURST_SECONDS, Tween.TRANS_CUBIC, Tween.EASE_OUT, spin_duration)
		tween.interpolate_property(spark, "modulate:a", 1.0, 0.0, BURST_SECONDS, Tween.TRANS_SINE, Tween.EASE_IN, spin_duration)
	tween.interpolate_property(reached_mascot, "modulate:a", 0.0, 1.0, 0.20, Tween.TRANS_BACK, Tween.EASE_OUT, spin_duration + BURST_SECONDS)
	tween.interpolate_property(reached_mascot, "rect_scale", Vector2(0.76, 0.76), Vector2.ONE, 0.24, Tween.TRANS_BACK, Tween.EASE_OUT, spin_duration + BURST_SECONDS)
	tween.start()


func _on_explosion_started() -> void:
	animation_phase = "explosion"


func _on_mascot_revealed() -> void:
	animation_phase = "revealed"
	previous_mascot.visible = false


func _on_dismiss_timer_timeout() -> void:
	if not displayed:
		return
	displayed = false
	animation_phase = "hidden"
	visible = false
	if tween != null and tween.is_active():
		tween.stop_all()
	emit_signal("dismissed")


func _on_viewport_size_changed() -> void:
	if displayed:
		_layout_popup(get_viewport().get_visible_rect().size)


func _input(_event: InputEvent) -> void:
	if displayed:
		get_tree().set_input_as_handled()

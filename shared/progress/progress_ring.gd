extends Control

const TRACK_COLOR = Color("#243253")
const PROGRESS_COLOR = Color("#18d6d2")
const SEGMENT_COUNT = 48

var progress_ratio: float = 0.0


func _ready() -> void:
	connect("resized", self, "_on_resized")
	update()


func set_progress_ratio(value: float) -> void:
	var normalized_ratio: float = clamp(value, 0.0, 1.0)
	if abs(progress_ratio - normalized_ratio) < 0.0001:
		return
	progress_ratio = normalized_ratio
	update()


func _draw() -> void:
	var diameter: float = min(rect_size.x, rect_size.y)
	if diameter <= 0.0:
		return

	var stroke_width: float = max(2.0, diameter * 0.045)
	var radius: float = max(0.0, (diameter - stroke_width) * 0.5)
	var center: Vector2 = rect_size * 0.5
	draw_arc(center, radius, 0.0, PI * 2.0, SEGMENT_COUNT, TRACK_COLOR, stroke_width, false)
	if progress_ratio <= 0.0:
		return

	var progress_segments: int = max(2, int(ceil(SEGMENT_COUNT * progress_ratio)))
	var end_angle: float = -PI * 0.5 + PI * 2.0 * progress_ratio
	draw_arc(center, radius, -PI * 0.5, end_angle, progress_segments, PROGRESS_COLOR, stroke_width, false)


func _on_resized() -> void:
	update()

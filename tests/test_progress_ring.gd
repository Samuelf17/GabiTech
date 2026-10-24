extends SceneTree

const RING_SCRIPT = preload("res://shared/progress/progress_ring.gd")

var failures: Array = []

func _initialize() -> void:
	call_deferred("_run_tests")

func _run_tests() -> void:
	var ring := Control.new()
	ring.set_script(RING_SCRIPT)
	get_root().add_child(ring)
	yield(self, "idle_frame")
	_check(is_equal_approx(ring.progress_ratio, 0.0), "ring starts empty")
	ring.set_progress_ratio(0.5)
	_check(is_equal_approx(ring.progress_ratio, 0.5), "ring accepts progress in range")
	ring.set_progress_ratio(-0.5)
	_check(is_equal_approx(ring.progress_ratio, 0.0), "ring clamps progress below zero")
	ring.set_progress_ratio(1.5)
	_check(is_equal_approx(ring.progress_ratio, 1.0), "ring clamps progress above one")
	ring.set_progress_ratio(0.75)
	ring.set_progress_ratio(0.75001)
	_check(is_equal_approx(ring.progress_ratio, 0.75), "tiny duplicate update does not alter stored ratio")
	_check(ring.get("SEGMENT_COUNT") == 48, "ring uses a bounded 48 segment drawing")
	ring.rect_size = Vector2(0, 0)
	ring.update()
	_check(ring.rect_size == Vector2.ZERO, "ring accepts zero-sized viewport geometry")
	if failures.empty():
		print("Progress ring tests passed")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)

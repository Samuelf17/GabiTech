extends SceneTree

const TEST_STORAGE_PATH = "user://level_up_notification_test.json"

var failures: Array = []


func _initialize() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	var progression = get_root().get_node("Progression")
	var notifier = get_root().get_node("LevelUpNotifications")
	var previous_storage_path: String = progression.storage_path
	_remove_test_file()
	progression.storage_path = TEST_STORAGE_PATH
	progression.load_progress()
	notifier.pending_level_changes.clear()
	notifier.last_seen_level = int(progression.state["level"])

	var xp_to_next_level: int = progression.experience_per_level - int(progression.state["experience"])
	_check(progression.add_experience(xp_to_next_level), "earning enough XP saves the new level")
	yield(self, "idle_frame")
	yield(self, "idle_frame")
	_check(progression.state["level"] == 2, "the progression service reaches level 2")
	_check(notifier.active_popup != null, "a level increase opens the shared popup")
	if notifier.active_popup != null:
		yield(_test_popup(notifier.active_popup), "completed")
		notifier.active_popup._on_dismiss_timer_timeout()
		progression.state["pending_badge_notifications"].append({
			"event_id": "test:badge",
			"badge_id": "knowledge",
			"level": 1,
			"kind": "unlocked"
		})
		notifier._on_progress_changed({"level": 3})
		yield(self, "idle_frame")
		yield(self, "idle_frame")
		_check(notifier.active_popup == null and notifier.pending_level_changes.size() == 1, "level-up popup waits while badge notifications are pending")
		progression.state["pending_badge_notifications"].clear()
		notifier._show_next_level_change()
		_check(notifier.active_popup != null and notifier.active_popup.title_label.text == "Nivel 3 alcançado!", "queued level popup appears after badge notifications clear")
		if notifier.active_popup != null:
			notifier.active_popup._on_dismiss_timer_timeout()

	progression.storage_path = previous_storage_path
	_remove_test_file()
	if failures.empty():
		print("Level-up notification tests passed")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func _test_popup(popup) -> void:
	_check(popup.title_label.text == "Nivel 2 alcançado!", "level-up popup titles the reached level")
	_check(popup.previous_mascot.texture.resource_path == "res://shared/mascot/levels/1.png", "popup starts with the previous level's capybara")
	_check(popup.reached_mascot.texture.resource_path == "res://shared/mascot/levels/2.png", "popup prepares the newly unlocked capybara")
	_check(popup.SPIN_COUNT == 8, "previous capybara is set to rotate eight times")
	_check(popup.burst_sparks.size() == 12, "blue explosion uses twelve lightweight rays")
	_check(is_equal_approx(popup.dismiss_timer.wait_time, 5.0), "level-up popup closes after five seconds")
	_check(popup.overlay.mouse_filter == Control.MOUSE_FILTER_STOP, "popup blocks interaction with the underlying screen")
	for viewport_size in [Vector2(720, 1280), Vector2(1280, 720), Vector2(320, 568)]:
		popup._layout_popup(viewport_size)
		_check(_fits_viewport(popup.title_label, viewport_size), "level title fits at %s" % viewport_size)
		_check(_fits_viewport(popup.previous_mascot, viewport_size), "old capybara fits at %s" % viewport_size)
		_check(_fits_viewport(popup.reached_mascot, viewport_size), "new capybara fits at %s" % viewport_size)
		_check(popup.previous_mascot.rect_position.distance_to(popup.reached_mascot.rect_position) < 0.01, "both capybaras stay centered at %s" % viewport_size)
		_check(is_equal_approx(popup.burst_radius_for_viewport(), min(viewport_size.x, viewport_size.y) * 0.28), "blue explosion has medium radius at %s" % viewport_size)
	_check(popup.animation_phase == "spinning", "popup begins with the old capybara spinning")
	yield(create_timer(2.1), "timeout")
	_check(popup.animation_phase == "revealed", "new capybara appears after the blue explosion")
	_check(not popup.previous_mascot.visible and popup.reached_mascot.visible, "the old capybara is replaced after the animation")


func _fits_viewport(control: Control, viewport_size: Vector2) -> bool:
	var position: Vector2 = control.rect_position
	var size := Vector2(control.rect_size.x * abs(control.rect_scale.x), control.rect_size.y * abs(control.rect_scale.y))
	return position.x >= -1.0 and position.y >= -1.0 and position.x + size.x <= viewport_size.x + 1.0 and position.y + size.y <= viewport_size.y + 1.0


func _remove_test_file() -> void:
	var file := File.new()
	if file.file_exists(TEST_STORAGE_PATH):
		Directory.new().remove(TEST_STORAGE_PATH)


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error(message)

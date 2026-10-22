extends SceneTree

const HOME_SCREEN = preload("res://app/menus/home_screen.tscn")

var failures: Array = []


func _initialize() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	var screen = HOME_SCREEN.instance()
	get_root().add_child(screen)
	yield(self, "idle_frame")

	_test_layout(screen, Vector2(720, 1280), "portrait")
	_test_layout(screen, Vector2(1280, 720), "landscape")
	_test_layout(screen, Vector2(360, 800), "narrow portrait")
	_test_action_feedback(screen)

	if failures.empty():
		print("Home screen tests passed")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func _test_layout(screen, viewport_size: Vector2, layout_name: String) -> void:
	screen._layout_screen(viewport_size)

	for key in ["start", "greeting_panel", "progress_panel"]:
		var control: Control = screen.ui[key]
		_check(control.visible, "%s: %s is visible" % [layout_name, key])
		_check(control.rect_size.x > 0.0 and control.rect_size.y > 0.0, "%s: %s has positive size" % [layout_name, key])

	var start_button: Button = screen.ui["start"]
	_check(not start_button.text.empty(), "%s: mission button text is present" % layout_name)
	_check(start_button.align == Button.ALIGN_CENTER, "%s: mission button text is centered" % layout_name)

	for key in ["nav_missions", "nav_games", "nav_learn", "nav_profile"]:
		var button: Button = screen.ui[key]
		var icon_label: Label = screen.ui[key + "_icon"]
		var title_label: Label = screen.ui[key + "_title"]
		_check(button.visible, "%s: %s is visible" % [layout_name, key])
		_check(not icon_label.text.empty(), "%s: %s icon text is present" % [layout_name, key])
		_check(not title_label.text.empty(), "%s: %s title text is present" % [layout_name, key])
		_check(title_label.align == Label.ALIGN_CENTER, "%s: %s title is centered" % [layout_name, key])
		_check(button.rect_scale == Vector2.ONE, "%s: %s container does not rescale its child labels" % [layout_name, key])
		_check(_fits_inside(title_label, button), "%s: %s title fits in its button" % [layout_name, key])


func _fits_inside(child: Control, parent: Control) -> bool:
	var right: float = child.rect_position.x + child.rect_size.x * child.rect_scale.x
	var bottom: float = child.rect_position.y + child.rect_size.y * child.rect_scale.y
	return child.rect_position.x >= 0.0 and child.rect_position.y >= 0.0 and right <= parent.rect_size.x + 1.0 and bottom <= parent.rect_size.y + 1.0


func _test_action_feedback(screen) -> void:
	screen._on_action_pressed("Teste de feedback")
	_check(screen.status_label.text == "Teste de feedback", "action feedback updates status label")


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)

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
	_test_layout(screen, Vector2(960, 540), "compact landscape")
	_test_layout(screen, Vector2(360, 800), "narrow portrait")
	_test_layout(screen, Vector2(320, 568), "compact portrait")
	_test_adaptive_font_sizes(screen)
	_test_landscape_greeting_hierarchy(screen)
	_test_text_fits_controls(screen)
	_test_action_feedback(screen)

	if failures.empty():
		print("Home screen tests passed")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func _test_layout(screen, viewport_size: Vector2, layout_name: String) -> void:
	screen.anchor_right = 0.0
	screen.anchor_bottom = 0.0
	screen.rect_size = viewport_size
	screen._layout_screen(viewport_size)

	for key in ["start", "greeting_panel", "progress_panel", "mascot"]:
		var control: Control = screen.ui[key]
		_check(control.visible, "%s: %s is visible" % [layout_name, key])
		_check(control.rect_size.x > 0.0 and control.rect_size.y > 0.0, "%s: %s has positive size" % [layout_name, key])
		_check(_fits_viewport(control, viewport_size), "%s: %s stays inside the viewport" % [layout_name, key])

	var mascot: TextureRect = screen.ui["mascot"]
	_check(mascot.texture != null, "%s: mascot sprite texture is loaded" % layout_name)
	_check(mascot.stretch_mode == TextureRect.STRETCH_KEEP_ASPECT_CENTERED, "%s: mascot sprite preserves its aspect ratio" % layout_name)

	var start_button: Button = screen.ui["start"]
	_check(not start_button.text.empty(), "%s: mission button text is present" % layout_name)
	_check(start_button.align == Button.ALIGN_CENTER, "%s: mission button text is centered" % layout_name)
	_check(start_button.has_meta("font_role"), "%s: mission button uses an adaptive font role" % layout_name)

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
		_check(icon_label.has_meta("font_role") and title_label.has_meta("font_role"), "%s: %s uses adaptive font roles" % [layout_name, key])
		_check(_fits_viewport(button, viewport_size), "%s: %s stays inside the viewport" % [layout_name, key])


func _test_adaptive_font_sizes(screen) -> void:
	screen._layout_screen(Vector2(720, 1280))
	var large_portrait_scale: float = screen.ui["brand_top"].rect_scale.x
	screen._layout_screen(Vector2(360, 800))
	var narrow_portrait_scale: float = screen.ui["brand_top"].rect_scale.x
	screen._layout_screen(Vector2(1280, 720))
	var tv_landscape_scale: float = screen.ui["brand_top"].rect_scale.x
	screen._layout_screen(Vector2(960, 540))
	var compact_landscape_scale: float = screen.ui["brand_top"].rect_scale.x
	_check(narrow_portrait_scale < large_portrait_scale, "font size decreases with a smaller portrait viewport")
	_check(compact_landscape_scale < tv_landscape_scale, "font size decreases with a smaller landscape viewport")
	_check(narrow_portrait_scale > 0.0 and compact_landscape_scale > 0.0, "adaptive font sizes remain positive in portrait and landscape")


func _test_landscape_greeting_hierarchy(screen) -> void:
	for viewport_size in [Vector2(1280, 720), Vector2(960, 540)]:
		screen._layout_screen(viewport_size)
		var title: Control = screen.ui["greeting_title"]
		var message: Control = screen.ui["greeting_text"]
		_check(title.rect_scale.x > message.rect_scale.x, "landscape greeting title is larger than its message at %s" % viewport_size)
		_check(_text_fits_control(title), "landscape greeting title fits at %s" % viewport_size)
		_check(_text_fits_control(message), "landscape greeting message fits at %s" % viewport_size)


func _test_text_fits_controls(screen) -> void:
	for viewport_size in [Vector2(720, 1280), Vector2(1280, 720), Vector2(960, 540), Vector2(360, 800), Vector2(320, 568)]:
		screen._layout_screen(viewport_size)
		for key in ["menu", "notification", "logo_icon", "brand_top", "brand_bottom", "greeting_title", "greeting_text", "start", "level_caption", "level_number", "progress_title", "progress_value", "progress_hint", "status"]:
			var control: Control = screen.ui[key]
			_check(control.has_meta("font_role"), "%s uses an adaptive font role at %s" % [key, viewport_size])
			_check(_text_fits_control(control), "%s text fits its allocated area at %s" % [key, viewport_size])


func _fits_inside(child: Control, parent: Control) -> bool:
	var right: float = child.rect_position.x + child.rect_size.x * child.rect_scale.x
	var bottom: float = child.rect_position.y + child.rect_size.y * child.rect_scale.y
	return child.rect_position.x >= 0.0 and child.rect_position.y >= 0.0 and right <= parent.rect_size.x + 1.0 and bottom <= parent.rect_size.y + 1.0


func _fits_viewport(control: Control, viewport_size: Vector2) -> bool:
	var rect: Rect2 = control.get_global_rect()
	return rect.position.x >= -1.0 and rect.position.y >= -1.0 and rect.end.x <= viewport_size.x + 1.0 and rect.end.y <= viewport_size.y + 1.0


func _text_fits_control(control: Control) -> bool:
	var text: String = ""
	if control is Label:
		text = (control as Label).text
	elif control is Button:
		text = (control as Button).text
	if text.empty():
		return true
	var font: Font = control.get_font("font")
	var scale: float = control.rect_scale.x
	if control is Button:
		var max_line_width: float = 0.0
		for line in text.split("\n"):
			max_line_width = max(max_line_width, font.get_string_size(line).x)
		return max_line_width * scale <= control.rect_size.x * scale + 1.0
	var wrapped_size: Vector2 = font.get_wordwrap_string_size(text, control.rect_size.x)
	return wrapped_size.x * scale <= control.rect_size.x * scale + 1.0 and wrapped_size.y * scale <= control.rect_size.y * scale + 1.0


func _test_action_feedback(screen) -> void:
	screen._on_action_pressed("Teste de feedback")
	_check(screen.status_label.text == "Teste de feedback", "action feedback updates status label")
	_check(_text_fits_control(screen.status_label), "action feedback text adapts to the available status area")


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)

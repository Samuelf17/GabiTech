extends SceneTree

const NAVIGATION_SCENE = preload("res://shared/ui/bottom_navigation.tscn")
const NAVIGATION_SCRIPT = preload("res://shared/ui/bottom_navigation.gd")

var failures: Array = []
var selected_item: String = ""


func _initialize() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	var home_navigation = NAVIGATION_SCENE.instance()
	home_navigation.active_item = "home"
	get_root().add_child(home_navigation)
	var map_navigation = NAVIGATION_SCENE.instance()
	map_navigation.active_item = "map"
	get_root().add_child(map_navigation)
	home_navigation.connect("item_selected", self, "_on_item_selected")
	yield(self, "idle_frame")

	_check(home_navigation.active_item == "home", "home menu accepts a current item")
	_check(map_navigation.active_item == "map", "map menu accepts a current item")
	_check(NAVIGATION_SCRIPT.ITEM_IDS.size() == 4, "shared menu defines four navigation items")
	for viewport_size in [Vector2(720, 1280), Vector2(1280, 720), Vector2(960, 540), Vector2(360, 800), Vector2(320, 568)]:
		home_navigation.layout_for_viewport(viewport_size)
		map_navigation.layout_for_viewport(viewport_size)
		for item_id in NAVIGATION_SCRIPT.ITEM_IDS:
			var home_button: Button = home_navigation.buttons[item_id]
			var map_button: Button = map_navigation.buttons[item_id]
			_check(home_navigation.labels[item_id].text == map_navigation.labels[item_id].text, "%s label is shared at %s" % [item_id, viewport_size])
			_check(home_button.text.empty() and map_button.text.empty(), "%s button displays its label below the icon using the shared layout" % item_id)
			_check(home_navigation.icons[item_id].texture != null and map_navigation.icons[item_id].texture != null, "%s icon loads in both screens" % item_id)
			_check(is_equal_approx(home_button.rect_scale.x, map_button.rect_scale.x), "%s font scale matches across screens at %s" % [item_id, viewport_size])
			_check(home_button.focus_mode == Control.FOCUS_ALL and map_button.focus_mode == Control.FOCUS_ALL, "%s can be focused at %s" % [item_id, viewport_size])
			_check(_fits_viewport(home_button, viewport_size), "home %s item fits at %s" % [item_id, viewport_size])
			_check(_fits_viewport(map_button, viewport_size), "map %s item fits at %s" % [item_id, viewport_size])
			_check(home_button.get_color("font_color") == (Color("#18d6d2") if item_id == "home" else Color("#a8b5d2")), "home %s uses the standard active state" % item_id)
			_check(map_button.get_color("font_color") == (Color("#18d6d2") if item_id == "map" else Color("#a8b5d2")), "map %s uses the standard active state" % item_id)

	home_navigation.buttons["profile"].emit_signal("pressed")
	_check(selected_item == "profile", "shared menu emits the selected item id")
	if failures.empty():
		print("Bottom navigation tests passed")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func _fits_viewport(control: Control, viewport_size: Vector2) -> bool:
	var rect: Rect2 = control.get_global_rect()
	return rect.position.x >= -1.0 and rect.position.y >= -1.0 and rect.end.x <= viewport_size.x + 1.0 and rect.end.y <= viewport_size.y + 1.0


func _on_item_selected(item_id: String) -> void:
	selected_item = item_id


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)

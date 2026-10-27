extends Node

signal transition_started(transition_type)
signal transition_finished(transition_type)

const TRANSITION_FADE: String = "fade"
const TRANSITION_ZOOM: String = "zoom"
const FADE_DURATION: float = 0.18
const ZOOM_OUT_DURATION: float = 0.22
const ZOOM_IN_DURATION: float = 0.28
const ZOOM_OUT_SCALE: float = 1.12
const ZOOM_IN_SCALE: float = 0.86
const ZOOM_OUT_ALPHA: float = 0.35

var previous_scene_paths: Array = []
var transition_in_progress: bool = false
var last_transition_type: String = ""
var transition_layer: CanvasLayer
var transition_overlay: ColorRect
var transition_tween: Tween
var queued_navigation: Dictionary = {}


func _ready() -> void:
	get_tree().quit_on_go_back = false
	_setup_transition_layer()


func _setup_transition_layer() -> void:
	transition_layer = CanvasLayer.new()
	transition_layer.name = "SceneTransitionLayer"
	transition_layer.layer = 100
	add_child(transition_layer)
	transition_overlay = ColorRect.new()
	transition_overlay.name = "TransitionInputBlocker"
	transition_overlay.color = Color(0.0, 0.0, 0.0, 0.0)
	transition_overlay.anchor_right = 1.0
	transition_overlay.anchor_bottom = 1.0
	transition_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	transition_overlay.visible = false
	transition_layer.add_child(transition_overlay)
	transition_tween = Tween.new()
	transition_tween.name = "SceneTransitionTween"
	add_child(transition_tween)


func _notification(what: int) -> void:
	if what == MainLoop.NOTIFICATION_WM_GO_BACK_REQUEST:
		go_back()


func navigate_to(scene_path: String, transition_type: String = TRANSITION_FADE, delay_seconds: float = 0.0) -> void:
	if scene_path.empty():
		push_error("Não é possível navegar para uma cena com caminho vazio.")
		return
	if transition_in_progress:
		queued_navigation = {"action": "navigate", "scene_path": scene_path, "transition_type": transition_type, "delay_seconds": delay_seconds}
		return
	var current_scene: Node = get_tree().current_scene
	var previous_path: String = current_scene.filename if current_scene != null else ""
	var history_size: int = previous_scene_paths.size()
	if not previous_path.empty() and previous_path != scene_path:
		remember_previous_scene(previous_path)
	var chosen_transition: String = _validated_transition_type(transition_type)
	call_deferred("_run_scene_transition", scene_path, chosen_transition, previous_path, history_size, false, max(0.0, delay_seconds))


func return_to(scene_path: String) -> void:
	if scene_path.empty():
		push_error("Não é possível retornar para uma cena com caminho vazio.")
		return
	if transition_in_progress:
		queued_navigation = {"action": "return", "scene_path": scene_path}
		return
	if not previous_scene_paths.empty() and previous_scene_paths.back() == scene_path:
		take_previous_scene()
	var current_scene: Node = get_tree().current_scene
	var previous_path: String = current_scene.filename if current_scene != null else ""
	call_deferred("_run_scene_transition", scene_path, TRANSITION_FADE, previous_path, previous_scene_paths.size(), true, 0.0)


func go_back() -> void:
	if transition_in_progress:
		queued_navigation = {"action": "back"}
		return
	var current_scene: Node = get_tree().current_scene
	if current_scene != null and current_scene.has_method("handle_back_request") and current_scene.handle_back_request():
		return
	if previous_scene_paths.empty():
		get_tree().quit()
		return
	var scene_path: String = take_previous_scene()
	call_deferred("_run_scene_transition", scene_path, TRANSITION_FADE, "", previous_scene_paths.size(), true, 0.0)


func _run_scene_transition(scene_path: String, transition_type: String, previous_path: String, history_size: int, is_back: bool, delay_seconds: float = 0.0) -> void:
	if transition_in_progress:
		return
	transition_in_progress = true
	last_transition_type = transition_type
	if delay_seconds > 0.0:
		yield(get_tree().create_timer(delay_seconds), "timeout")
	transition_overlay.visible = true
	transition_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	emit_signal("transition_started", transition_type)
	var tree := get_tree()
	var outgoing_scene: Node = tree.current_scene
	if transition_type == TRANSITION_ZOOM:
		if outgoing_scene is Control:
			var outgoing_control: Control = outgoing_scene as Control
			_prepare_scene_control(outgoing_control)
			yield(_animate_scene_control(outgoing_control, Vector2.ONE, Vector2.ONE * ZOOM_OUT_SCALE, 1.0, ZOOM_OUT_ALPHA, ZOOM_OUT_DURATION), "completed")
		else:
			transition_overlay.color.a = 0.0
	else:
		transition_overlay.color.a = 0.0
		yield(_animate_overlay_alpha(0.0, 1.0, FADE_DURATION), "completed")

	var change_error: int = tree.change_scene(scene_path)
	if change_error != OK:
		if is_back:
			remember_previous_scene(scene_path)
		elif previous_scene_paths.size() > history_size and previous_scene_paths.back() == previous_path:
			take_previous_scene()
		if transition_type == TRANSITION_ZOOM:
			if outgoing_scene is Control:
				var failed_control: Control = outgoing_scene as Control
				yield(_animate_scene_control(failed_control, failed_control.rect_scale, Vector2.ONE, failed_control.modulate.a, 1.0, ZOOM_IN_DURATION), "completed")
		else:
			yield(_animate_overlay_alpha(1.0, 0.0, FADE_DURATION), "completed")
		push_error("Não foi possível abrir a cena: %s" % scene_path)
		_finish_transition(transition_type)
		return

	if transition_type == TRANSITION_ZOOM and tree.current_scene is Control:
		var incoming_control: Control = tree.current_scene as Control
		_prepare_scene_control(incoming_control)
		incoming_control.rect_scale = Vector2.ONE * ZOOM_IN_SCALE
		incoming_control.modulate.a = ZOOM_OUT_ALPHA
		yield(_animate_scene_control(incoming_control, Vector2.ONE * ZOOM_IN_SCALE, Vector2.ONE, ZOOM_OUT_ALPHA, 1.0, ZOOM_IN_DURATION), "completed")
	else:
		transition_overlay.color.a = 1.0
		yield(_animate_overlay_alpha(1.0, 0.0, FADE_DURATION), "completed")
	_finish_transition(transition_type)


func _prepare_scene_control(scene_control: Control) -> void:
	scene_control.rect_pivot_offset = get_viewport().get_visible_rect().size * 0.5
	scene_control.rect_scale = Vector2.ONE
	scene_control.modulate.a = 1.0


func _animate_scene_control(scene_control: Control, from_scale: Vector2, to_scale: Vector2, from_alpha: float, to_alpha: float, duration: float) -> void:
	transition_tween.stop_all()
	transition_tween.remove_all()
	transition_tween.interpolate_property(scene_control, "rect_scale", from_scale, to_scale, duration, Tween.TRANS_CUBIC, Tween.EASE_IN_OUT)
	transition_tween.interpolate_property(scene_control, "modulate:a", from_alpha, to_alpha, duration, Tween.TRANS_CUBIC, Tween.EASE_IN_OUT)
	transition_tween.start()
	yield(get_tree().create_timer(duration), "timeout")
	transition_tween.stop_all()
	if is_instance_valid(scene_control):
		scene_control.rect_scale = to_scale
		scene_control.modulate.a = to_alpha


func _animate_overlay_alpha(from_alpha: float, to_alpha: float, duration: float) -> void:
	transition_tween.stop_all()
	transition_tween.remove_all()
	transition_tween.interpolate_property(transition_overlay, "color:a", from_alpha, to_alpha, duration, Tween.TRANS_SINE, Tween.EASE_IN_OUT)
	transition_tween.start()
	yield(get_tree().create_timer(duration), "timeout")
	transition_tween.stop_all()
	transition_overlay.color.a = to_alpha


func _finish_transition(transition_type: String) -> void:
	transition_overlay.color.a = 0.0
	transition_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	transition_overlay.visible = false
	transition_in_progress = false
	emit_signal("transition_finished", transition_type)
	if not queued_navigation.empty():
		call_deferred("_process_queued_navigation")


func _process_queued_navigation() -> void:
	if transition_in_progress or queued_navigation.empty():
		return
	var request: Dictionary = queued_navigation.duplicate(true)
	queued_navigation.clear()
	match request.get("action", ""):
		"navigate":
			navigate_to(str(request.get("scene_path", "")), str(request.get("transition_type", TRANSITION_FADE)), float(request.get("delay_seconds", 0.0)))
		"return":
			return_to(str(request.get("scene_path", "")))
		"back":
			go_back()


func _validated_transition_type(transition_type: String) -> String:
	return TRANSITION_ZOOM if transition_type == TRANSITION_ZOOM else TRANSITION_FADE


func remember_previous_scene(scene_path: String) -> void:
	if scene_path.empty():
		return
	if not previous_scene_paths.empty() and previous_scene_paths.back() == scene_path:
		return
	previous_scene_paths.append(scene_path)


func take_previous_scene() -> String:
	if previous_scene_paths.empty():
		return ""
	return previous_scene_paths.pop_back()

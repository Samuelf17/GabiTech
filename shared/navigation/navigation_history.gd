extends Node

var previous_scene_paths: Array = []


func _ready() -> void:
	get_tree().quit_on_go_back = false


func _notification(what: int) -> void:
	if what == MainLoop.NOTIFICATION_WM_GO_BACK_REQUEST:
		go_back()


func navigate_to(scene_path: String) -> void:
	if scene_path.empty():
		push_error("Não é possível navegar para uma cena com caminho vazio.")
		return
	var tree := get_tree()
	var current_scene: Node = tree.current_scene
	var previous_path: String = current_scene.filename if current_scene != null else ""
	var history_size: int = previous_scene_paths.size()
	if not previous_path.empty() and previous_path != scene_path:
		remember_previous_scene(previous_path)
	var result: int = tree.change_scene(scene_path)
	if result != OK:
		if previous_scene_paths.size() > history_size:
			take_previous_scene()
		push_error("Não foi possível abrir a cena: %s" % scene_path)


func go_back() -> void:
	var current_scene: Node = get_tree().current_scene
	if current_scene != null and current_scene.has_method("handle_back_request") and current_scene.handle_back_request():
		return
	if previous_scene_paths.empty():
		get_tree().quit()
		return
	var scene_path: String = take_previous_scene()
	var result: int = get_tree().change_scene(scene_path)
	if result != OK:
		remember_previous_scene(scene_path)
		push_error("Não foi possível retornar à cena anterior: %s" % scene_path)


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

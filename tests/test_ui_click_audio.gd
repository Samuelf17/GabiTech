extends SceneTree

var failures: Array = []


func _initialize() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	var click_audio: Node = get_root().get_node("UIClickAudio")
	yield(self, "idle_frame")
	_check(click_audio.click_player.stream.resource_path == "res://shared/audio/assets/click_3.mp3", "global UI click audio uses Clique 3 copied to shared assets")
	_check(not click_audio.click_player.stream.loop, "global click audio plays once without looping")
	var button := Button.new()
	get_root().add_child(button)
	yield(self, "idle_frame")
	_check(button.is_connected("pressed", click_audio, "_on_button_pressed"), "newly added buttons are connected to the global click sound")
	button.emit_signal("pressed")
	_check(click_audio.click_player.is_playing(), "pressing a UI button plays the click sound")
	button.queue_free()
	if failures.empty():
		print("UI click audio tests passed")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)

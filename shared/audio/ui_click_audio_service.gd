extends Node

const CLICK_STREAM = preload("res://shared/audio/assets/click_3.mp3")

var click_player: AudioStreamPlayer


func _ready() -> void:
	click_player = AudioStreamPlayer.new()
	click_player.name = "UIClickAudioPlayer"
	CLICK_STREAM.loop = false
	click_player.stream = CLICK_STREAM
	add_child(click_player)
	get_tree().connect("node_added", self, "_on_node_added")
	_connect_buttons_recursively(get_tree().root)


func _on_node_added(node: Node) -> void:
	if node is BaseButton:
		_connect_button(node as BaseButton)


func _connect_buttons_recursively(node: Node) -> void:
	if node is BaseButton:
		_connect_button(node as BaseButton)
	for child in node.get_children():
		_connect_buttons_recursively(child)


func _connect_button(button: BaseButton) -> void:
	if not button.is_connected("pressed", self, "_on_button_pressed"):
		button.connect("pressed", self, "_on_button_pressed")


func _on_button_pressed() -> void:
	if click_player != null:
		click_player.play()

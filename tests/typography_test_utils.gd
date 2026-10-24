extends Reference


static func get_uniform_body_size_failures(root: Node, typography, viewport_basis: float) -> Array:
	var failures: Array = []
	_check_node(root, typography, viewport_basis, 1.0, failures)
	return failures


static func _check_node(
	node: Node,
	typography,
	viewport_basis: float,
	parent_scale: float,
	failures: Array
) -> void:
	var control_scale: float = parent_scale
	if node is Control:
		control_scale *= (node as Control).rect_scale.x
	if node is Label or node is Button:
		var text_control: Control = node as Control
		if not is_equal_approx(text_control.rect_scale.x, 1.0) or not is_equal_approx(text_control.rect_scale.y, 1.0):
			failures.append("%s has a scaled text control" % node.name)
		if not is_equal_approx(parent_scale, 1.0):
			failures.append("%s inherits scale from a parent control" % node.name)
		var text: String = (node as Label).text if node is Label else (node as Button).text
		if not text.empty() and node.has_meta("font_role"):
			var role: String = node.get_meta("font_role")
			if typography.is_uniform_body_role(role) and not node.has_meta("title_text"):
				var font: Font = text_control.get_font("font")
				var actual_height: float = font.get_height() * control_scale
				var expected_height: float = typography.get_target_height("body", viewport_basis)
				if abs(actual_height - expected_height) > 1.0:
					failures.append("%s renders at %.3f instead of body size %.3f" % [node.name, actual_height, expected_height])
	for child in node.get_children():
		_check_node(child, typography, viewport_basis, control_scale, failures)

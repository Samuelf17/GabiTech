extends SceneTree

const TYPOGRAPHY_SCRIPT = preload("res://shared/ui/typography.gd")

var failures: Array = []

func _initialize() -> void:
	call_deferred("_run_tests")

func _run_tests() -> void:
	var typography = TYPOGRAPHY_SCRIPT.new()
	_check(is_equal_approx(TYPOGRAPHY_SCRIPT.BASE_BODY_RATIO, 0.04), "shared body typography uses the mobile readability baseline")
	_check(typography.has_role("body"), "body role exists")
	_check(typography.has_role("navigation"), "navigation role exists")
	_check(not typography.has_role("unknown"), "unknown role is reported absent")
	_check(is_equal_approx(typography.get_role_ratio("body"), TYPOGRAPHY_SCRIPT.BASE_BODY_RATIO), "body uses base ratio")
	_check(is_equal_approx(typography.get_role_ratio("unknown"), TYPOGRAPHY_SCRIPT.BASE_BODY_RATIO), "unknown role falls back to base ratio")
	for role in TYPOGRAPHY_SCRIPT.ROLE_MULTIPLIERS:
		_check(typography.has_role(role), "%s is a supported typography role" % role)
		_check(typography.get_role_ratio(role) > 0.0, "%s has positive scale" % role)
		if typography.is_uniform_body_role(role):
			_check(is_equal_approx(typography.get_role_ratio(role), typography.get_role_ratio("body")), "%s matches capivara body size" % role)
	_check(typography.is_title_role("heading"), "heading is excluded from uniform body typography")
	_check(typography.is_title_role("title"), "screen title is excluded from uniform body typography")
	for basis in [320.0, 540.0, 720.0, 1280.0]:
		_check(is_equal_approx(typography.get_target_height("body", basis), basis * TYPOGRAPHY_SCRIPT.BASE_BODY_RATIO), "body scales with viewport basis %s" % basis)
		_check(is_equal_approx(typography.get_target_height("title", basis), basis * TYPOGRAPHY_SCRIPT.BASE_BODY_RATIO * TYPOGRAPHY_SCRIPT.ROLE_MULTIPLIERS["title"]), "title scales with viewport basis %s" % basis)
	_finish()

func _finish() -> void:
	if failures.empty():
		print("Typography tests passed")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)

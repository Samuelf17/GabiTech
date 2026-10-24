extends SceneTree

const TYPOGRAPHY_SCRIPT = preload("res://shared/ui/typography.gd")
const EXPECTED_INTER_FONT_PATH = "res://shared/ui/inter_regular.tres"
const EXPECTED_INTER_DATA_PATH = "res://shared/ui/assets/fonts/Inter_18pt-Regular.ttf"

var failures: Array = []

func _initialize() -> void:
	call_deferred("_run_tests")

func _run_tests() -> void:
	var typography = TYPOGRAPHY_SCRIPT.new()
	_check(ProjectSettings.get_setting("gui/theme/custom_font") == EXPECTED_INTER_FONT_PATH, "project default GUI font points to the shared Inter resource")
	var inter_font = load(EXPECTED_INTER_FONT_PATH)
	_check(inter_font is DynamicFont, "shared Inter resource is a dynamic font")
	if inter_font is DynamicFont:
		_check(inter_font.font_data.font_path == EXPECTED_INTER_DATA_PATH, "shared dynamic font loads the Inter regular face")
	var sample_label: Label = Label.new()
	get_root().add_child(sample_label)
	var label_font: Font = sample_label.get_font("font")
	_check(label_font is DynamicFont, "default labels use the project Inter font")
	var sample_button: Button = Button.new()
	get_root().add_child(sample_button)
	_check(sample_button.get_font("font") is DynamicFont, "default buttons use the project Inter font")
	var shared_font: DynamicFont = label_font as DynamicFont
	var original_font_size: int = shared_font.size
	sample_label.set_meta("font_role", "body")
	sample_button.set_meta("font_role", "body")
	var resized_label_font: Font = typography.apply_font_scale(sample_label, 1.5)
	var resized_button_font: Font = typography.apply_font_scale(sample_button, 1.5)
	_check(resized_label_font is DynamicFont and resized_label_font.get_height() > shared_font.get_height(), "responsive sizing increases DynamicFont raster size")
	_check(resized_button_font == resized_label_font, "same font size reuses its cached DynamicFont resource")
	_check(sample_label.rect_scale == Vector2.ONE and sample_button.rect_scale == Vector2.ONE, "text controls stay at unit scale")
	_check(shared_font.size == original_font_size, "resizing a label does not mutate the shared Inter resource")
	_check(is_equal_approx(TYPOGRAPHY_SCRIPT.BASE_BODY_RATIO, 0.04), "shared body typography uses the mobile readability baseline")
	_check(typography.has_role("body"), "body role exists")
	_check(typography.has_role("navigation"), "navigation role exists")
	_check(not typography.has_role("unknown"), "unknown role is reported absent")
	_check(is_equal_approx(typography.get_role_ratio("body"), TYPOGRAPHY_SCRIPT.BASE_BODY_RATIO * TYPOGRAPHY_SCRIPT.BODY_SCALE_ADJUSTMENT), "body is reduced by three percent")
	_check(is_equal_approx(typography.get_role_ratio("unknown"), typography.get_role_ratio("body")), "unknown role falls back to adjusted body size")
	for role in TYPOGRAPHY_SCRIPT.ROLE_MULTIPLIERS:
		_check(typography.has_role(role), "%s is a supported typography role" % role)
		_check(typography.get_role_ratio(role) > 0.0, "%s has positive scale" % role)
		if typography.is_uniform_body_role(role):
			_check(is_equal_approx(typography.get_role_ratio(role), typography.get_role_ratio("body")), "%s matches capivara body size" % role)
	_check(typography.is_title_role("heading"), "heading is excluded from uniform body typography")
	_check(typography.is_title_role("title"), "screen title is excluded from uniform body typography")
	for basis in [320.0, 540.0, 720.0, 1280.0]:
		_check(is_equal_approx(typography.get_target_height("body", basis), basis * TYPOGRAPHY_SCRIPT.BASE_BODY_RATIO * TYPOGRAPHY_SCRIPT.BODY_SCALE_ADJUSTMENT), "body scales with viewport basis after the three percent reduction %s" % basis)
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

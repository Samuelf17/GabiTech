extends Reference

# Base taken from the adaptive body text "Pronto para proteger a cidade digital?".
const BASE_BODY_RATIO: float = 0.04
const BODY_SCALE_ADJUSTMENT: float = 0.97
const APP_FONT_PATH: String = "res://shared/ui/jersey_10.tres"
const ROLE_MULTIPLIERS = {
	"icon": 1.089040,
	"brand": 1.347409,
	"brand_title": 1.751632,
	"brand_secondary": 1.372413,
	"heading": 1.063898,
	"level_display": 2.325,
	"body": 1.0,
	"button": 1.0,
	"caption": 1.0,
	"display_number": 1.0,
	"progress_value": 1.0,
	"progress_caption": 1.0,
	"navigation": 1.0,
	"title": 1.139047,
	"prompt": 1.0,
	"district": 1.0,
	"district_progress": 1.0,
	"status": 1.0,
	"points_label": 1.0,
	"points": 1.0,
	"support": 1.0,
	"level": 1.0,
	"tab": 1.0,
	"badge": 1.0,
	"badge_level": 1.0,
	"challenge": 0.527851,
	"challenge_body": 1.0,
	"reward_progress": 1.0
}
const TITLE_ROLES = ["brand_title", "brand_secondary", "heading", "title", "challenge", "level_display"]
const DECORATIVE_ROLES = ["icon", "brand"]

var resized_font_cache: Dictionary = {}


func has_role(role: String) -> bool:
	return ROLE_MULTIPLIERS.has(role)


func get_role_ratio(role: String) -> float:
	if not has_role(role):
		return BASE_BODY_RATIO * BODY_SCALE_ADJUSTMENT
	var ratio: float = BASE_BODY_RATIO * ROLE_MULTIPLIERS[role]
	if is_uniform_body_role(role):
		ratio *= BODY_SCALE_ADJUSTMENT
	return ratio


func get_target_height(role: String, viewport_basis: float) -> float:
	return viewport_basis * get_role_ratio(role)


func is_title_role(role: String) -> bool:
	return TITLE_ROLES.has(role)


func is_decorative_role(role: String) -> bool:
	return DECORATIVE_ROLES.has(role)


func is_uniform_body_role(role: String) -> bool:
	return not is_title_role(role) and not is_decorative_role(role)


func is_title_control(control: Control) -> bool:
	if control.has_meta("title_text") and bool(control.get_meta("title_text")):
		return true
	return control.has_meta("font_role") and is_title_role(str(control.get_meta("font_role")))


func get_base_font(control: Control) -> Font:
	var font: DynamicFont = load(APP_FONT_PATH) as DynamicFont
	if font != null:
		control.set_meta("typography_base_font", font)
		return font
	if control.has_meta("typography_base_font"):
		return control.get_meta("typography_base_font")
	var font_from_theme: Font = control.get_font("font")
	if font_from_theme != null:
		control.set_meta("typography_base_font", font_from_theme)
	return font_from_theme


func apply_font_scale(control: Control, font_scale: float) -> Font:
	control.rect_scale = Vector2.ONE
	var base_font: Font = get_base_font(control)
	if not base_font is DynamicFont:
		return base_font
	var dynamic_base: DynamicFont = base_font as DynamicFont
	var safe_scale: float = max(font_scale, 0.01)
	var target_height: float = dynamic_base.get_height() * safe_scale
	var exact_size: float = float(dynamic_base.size) * safe_scale
	var lower_size: int = max(1, int(floor(exact_size)))
	var upper_size: int = max(lower_size, int(ceil(exact_size)))
	var lower_font: DynamicFont = _get_dynamic_font_at_size(dynamic_base, lower_size)
	var upper_font: DynamicFont = _get_dynamic_font_at_size(dynamic_base, upper_size)
	var resized_font: DynamicFont = lower_font if abs(lower_font.get_height() - target_height) <= abs(upper_font.get_height() - target_height) else upper_font
	control.add_font_override("font", resized_font)
	control.rect_scale = Vector2.ONE
	return resized_font


func _get_dynamic_font_at_size(base_font: DynamicFont, font_size: int) -> DynamicFont:
	if font_size == base_font.size:
		return base_font
	var cache_key: String = "%d:%d" % [base_font.get_instance_id(), font_size]
	if resized_font_cache.has(cache_key):
		return resized_font_cache[cache_key]
	var resized_font: DynamicFont = base_font.duplicate() as DynamicFont
	resized_font.size = font_size
	resized_font_cache[cache_key] = resized_font
	return resized_font

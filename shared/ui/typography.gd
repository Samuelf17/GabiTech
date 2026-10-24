extends Reference

# Base taken from the adaptive body text "Pronto para proteger a cidade digital?".
const BASE_BODY_RATIO: float = 0.035995
const ROLE_MULTIPLIERS = {
	"icon": 1.089040,
	"brand": 1.347409,
	"brand_title": 1.751632,
	"brand_secondary": 1.372413,
	"heading": 1.063898,
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


func has_role(role: String) -> bool:
	return ROLE_MULTIPLIERS.has(role)


func get_role_ratio(role: String) -> float:
	if not has_role(role):
		return BASE_BODY_RATIO
	return BASE_BODY_RATIO * ROLE_MULTIPLIERS[role]


func get_target_height(role: String, viewport_basis: float) -> float:
	return viewport_basis * get_role_ratio(role)

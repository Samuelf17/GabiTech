extends Reference

const BADGES = [
	{"id": "privacy", "name": "PRIVACIDADE", "display_name": "Privacidade", "color": Color("#28dce4"), "texture": preload("res://shared/progress/assets/badges/privacy.png")},
	{"id": "security", "name": "SEGURANÇA", "display_name": "Segurança", "color": Color("#83e74c"), "texture": preload("res://shared/progress/assets/badges/security.png")},
	{"id": "communication", "name": "COMUNICAÇÃO", "display_name": "Comunicação", "color": Color("#328aff"), "texture": preload("res://shared/progress/assets/badges/communication.png")},
	{"id": "knowledge", "name": "CONHECIMENTO", "display_name": "Conhecimento", "color": Color("#ffad39"), "texture": preload("res://shared/progress/assets/badges/knowledge.png")},
	{"id": "respect", "name": "RESPEITO", "display_name": "Respeito", "color": Color("#ff6687"), "texture": preload("res://shared/progress/assets/badges/respect.png")},
	{"id": "attention", "name": "ATENÇÃO", "display_name": "Atenção", "color": Color("#ad4fe8"), "texture": preload("res://shared/progress/assets/badges/attention.png")}
]


static func get_badge(badge_id: String) -> Dictionary:
	for badge in BADGES:
		if badge["id"] == badge_id:
			return badge.duplicate(true)
	return {}

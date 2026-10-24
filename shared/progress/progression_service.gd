extends Node

signal progress_changed(state)

const RULES_PATH = "res://data/progression/progression_rules.json"
const DEFAULT_PROGRESS_PATH = "res://data/progression/default_progress.json"
const DEFAULT_EXPERIENCE_PER_LEVEL = 2000
const DEFAULT_REWARD_ID_PREFIX = "level_reward_"
const QUIZ_XP_PER_CORRECT_ANSWER: int = 100
const KNOWLEDGE_BADGE_ID: String = "knowledge"
const CORRECT_ANSWERS_PER_KNOWLEDGE_LEVEL: int = 3
const BADGE_IDS = ["privacy", "security", "communication", "knowledge", "respect", "attention"]
const DEFAULT_STATE = {
	"schema_version": 1,
	"level": 1,
	"experience": 0,
	"unlocked_items": [],
	"badge_levels": {
		"privacy": 0,
		"security": 0,
		"communication": 0,
		"knowledge": 0,
		"respect": 0,
		"attention": 0
	},
	"quiz_correct_answers": 0,
	"processed_quiz_answer_ids": [],
	"processed_quiz_sessions": [],
	"pending_badge_notifications": []
}

var storage_path: String = "user://progress.json"
var experience_per_level: int = DEFAULT_EXPERIENCE_PER_LEVEL
var reward_id_prefix: String = DEFAULT_REWARD_ID_PREFIX
var state: Dictionary = {}


func _ready() -> void:
	_load_rules()
	load_progress()


func get_state() -> Dictionary:
	return state.duplicate(true)


func get_total_experience() -> int:
	if state.empty():
		return 0
	return (int(state["level"]) - 1) * experience_per_level + int(state["experience"])


func get_progress_ratio() -> float:
	if state.empty() or experience_per_level <= 0:
		return 0.0
	return float(state["experience"]) / float(experience_per_level)


func format_number(value: int) -> String:
	var digits: String = str(max(0, value))
	var formatted: String = ""
	for index in range(digits.length()):
		if index > 0 and (digits.length() - index) % 3 == 0:
			formatted += "."
		formatted += digits.substr(index, 1)
	return formatted


func get_badge_level(badge_id: String) -> int:
	if state.empty():
		return 0
	var badge_levels: Dictionary = state.get("badge_levels", {})
	if not badge_levels.has(badge_id):
		return 0
	return int(badge_levels[badge_id])


func get_pending_badge_notifications() -> Array:
	if state.empty():
		return []
	return state["pending_badge_notifications"].duplicate(true)


func record_quiz_correct_answer(answer_id: String) -> bool:
	if answer_id.empty() or state.empty():
		return false
	if state["processed_quiz_answer_ids"].has(answer_id):
		return true
	var updated: Dictionary = state.duplicate(true)
	updated["processed_quiz_answer_ids"].append(answer_id)
	updated["quiz_correct_answers"] = int(updated["quiz_correct_answers"]) + 1
	var old_level: int = int(updated["badge_levels"][KNOWLEDGE_BADGE_ID])
	var new_level: int = _get_knowledge_level_for_correct_answers(int(updated["quiz_correct_answers"]))
	if new_level > old_level:
		for level in range(old_level + 1, new_level + 1):
			updated["pending_badge_notifications"].append({
				"event_id": "%s:%d" % [KNOWLEDGE_BADGE_ID, level],
				"badge_id": KNOWLEDGE_BADGE_ID,
				"level": level,
				"kind": "unlocked" if level == 1 else "level_up"
			})
		updated["badge_levels"][KNOWLEDGE_BADGE_ID] = new_level
	if not _save_state(updated):
		return false
	state = updated
	emit_signal("progress_changed", get_state())
	return true


func _get_knowledge_level_for_correct_answers(correct_answer_count: int) -> int:
	var level: int = 0
	var remaining_answers: int = correct_answer_count
	while remaining_answers >= (level + 1) * CORRECT_ANSWERS_PER_KNOWLEDGE_LEVEL:
		remaining_answers -= (level + 1) * CORRECT_ANSWERS_PER_KNOWLEDGE_LEVEL
		level += 1
	return level


func complete_quiz_session(session_id: String, correct_answer_count: int) -> bool:
	if session_id.empty() or correct_answer_count < 0 or state.empty():
		return false
	if state["processed_quiz_sessions"].has(session_id):
		return true
	var updated: Dictionary = state.duplicate(true)
	if correct_answer_count > 0:
		updated = _advance_state(updated, correct_answer_count * QUIZ_XP_PER_CORRECT_ANSWER)
	updated["processed_quiz_sessions"].append(session_id)
	if not _save_state(updated):
		return false
	state = updated
	emit_signal("progress_changed", get_state())
	return true


func acknowledge_badge_notification(event_id: String) -> bool:
	if state.empty() or state["pending_badge_notifications"].empty():
		return false
	if state["pending_badge_notifications"][0]["event_id"] != event_id:
		return false
	var updated: Dictionary = state.duplicate(true)
	updated["pending_badge_notifications"].pop_front()
	if not _save_state(updated):
		return false
	state = updated
	emit_signal("progress_changed", get_state())
	return true


func load_progress() -> bool:
	var file := File.new()
	if not file.file_exists(storage_path):
		state = _load_default_state()
		if not _save_state(state):
			return false
		emit_signal("progress_changed", get_state())
		return true

	var open_error: int = file.open(storage_path, File.READ)
	if open_error != OK:
		push_error("Não foi possível abrir o progresso do usuário: %s" % storage_path)
		state = _load_default_state()
		return false
	var content: String = file.get_as_text()
	file.close()
	var parsed: JSONParseResult = JSON.parse(content)
	if parsed.error != OK or not parsed.result is Dictionary:
		push_error("O JSON de progresso é inválido na linha %d: %s" % [parsed.error_line, parsed.error_string])
		state = _load_default_state()
		return false

	var normalized: Dictionary = _normalize_state(parsed.result)
	if normalized.empty():
		push_error("O JSON de progresso contém dados inválidos; os dados do usuário foram preservados.")
		state = _load_default_state()
		return false
	state = normalized
	emit_signal("progress_changed", get_state())
	return true


func add_experience(amount: int) -> bool:
	if amount <= 0 or state.empty():
		return false
	var updated: Dictionary = _advance_state(state, amount)
	if not _save_state(updated):
		return false
	state = updated
	emit_signal("progress_changed", get_state())
	return true


func _advance_state(current_state: Dictionary, amount: int) -> Dictionary:
	var updated: Dictionary = current_state.duplicate(true)
	var current_level: int = int(updated["level"])
	var remaining_experience: int = int(updated["experience"]) + amount
	var unlocked_items: Array = updated["unlocked_items"]
	while remaining_experience >= experience_per_level:
		remaining_experience -= experience_per_level
		current_level += 1
		var reward_id: String = "%s%d" % [reward_id_prefix, current_level]
		if not unlocked_items.has(reward_id):
			unlocked_items.append(reward_id)
	updated["level"] = current_level
	updated["experience"] = remaining_experience
	updated["unlocked_items"] = unlocked_items
	return updated


func _normalize_state(data: Dictionary) -> Dictionary:
	var level_value = data.get("level", null)
	var experience_value = data.get("experience", null)
	var item_values = data.get("unlocked_items", [])
	var badge_level_values = data.get("badge_levels", {})
	var quiz_correct_answers_value = data.get("quiz_correct_answers", 0)
	var processed_answer_values = data.get("processed_quiz_answer_ids", [])
	var processed_session_values = data.get("processed_quiz_sessions", [])
	var pending_notification_values = data.get("pending_badge_notifications", [])
	var schema_version = data.get("schema_version", 1)
	if not _is_number(level_value) or not _is_number(experience_value) or not _is_number(schema_version) or not _is_number(quiz_correct_answers_value):
		return {}
	var level: int = int(level_value)
	var experience: int = int(experience_value)
	if int(schema_version) != 1 or level < 1 or experience < 0 or experience >= experience_per_level:
		return {}
	if not item_values is Array:
		return {}
	if int(quiz_correct_answers_value) < 0 or not badge_level_values is Dictionary:
		return {}
	if not processed_answer_values is Array or not processed_session_values is Array or not pending_notification_values is Array:
		return {}
	if not _is_valid_string_array(processed_answer_values) or not _is_valid_string_array(processed_session_values):
		return {}
	var clean_items: Array = []
	for item_id in item_values:
		if not item_id is String or item_id.empty():
			return {}
		if not clean_items.has(item_id):
			clean_items.append(item_id)
	var clean_answer_ids: Array = _normalize_string_array(processed_answer_values)
	var clean_session_ids: Array = _normalize_string_array(processed_session_values)
	var clean_badge_levels: Dictionary = {}
	for badge_id in BADGE_IDS:
		var badge_level_value = badge_level_values.get(badge_id, 0)
		if not _is_number(badge_level_value) or int(badge_level_value) < 0:
			return {}
		clean_badge_levels[badge_id] = int(badge_level_value)
	clean_badge_levels[KNOWLEDGE_BADGE_ID] = _get_knowledge_level_for_correct_answers(int(quiz_correct_answers_value))
	var clean_notifications: Array = []
	for notification in pending_notification_values:
		if not notification is Dictionary:
			return {}
		var event_id = notification.get("event_id", null)
		var badge_id = notification.get("badge_id", null)
		var notification_level = notification.get("level", null)
		var notification_kind = notification.get("kind", null)
		if not event_id is String or event_id.empty() or not BADGE_IDS.has(badge_id):
			return {}
		if not _is_number(notification_level) or int(notification_level) < 1:
			return {}
		if notification_kind != "unlocked" and notification_kind != "level_up":
			return {}
		if badge_id == KNOWLEDGE_BADGE_ID and int(notification_level) > int(clean_badge_levels[KNOWLEDGE_BADGE_ID]):
			continue
		clean_notifications.append({
			"event_id": event_id,
			"badge_id": badge_id,
			"level": int(notification_level),
			"kind": notification_kind
		})
	return {
		"schema_version": 1,
		"level": level,
		"experience": experience,
		"unlocked_items": clean_items,
		"badge_levels": clean_badge_levels,
		"quiz_correct_answers": int(quiz_correct_answers_value),
		"processed_quiz_answer_ids": clean_answer_ids,
		"processed_quiz_sessions": clean_session_ids,
		"pending_badge_notifications": clean_notifications
	}


func _is_valid_string_array(values: Array) -> bool:
	for value in values:
		if not value is String or value.empty():
			return false
	return true


func _normalize_string_array(values: Array) -> Array:
	var normalized: Array = []
	for value in values:
		if not normalized.has(value):
			normalized.append(value)
	return normalized


func _load_default_state() -> Dictionary:
	var file := File.new()
	var open_error: int = file.open(DEFAULT_PROGRESS_PATH, File.READ)
	if open_error != OK:
		push_error("Não foi possível ler o estado inicial; usando nível 1 com 0 XP.")
		return DEFAULT_STATE.duplicate(true)
	var parsed: JSONParseResult = JSON.parse(file.get_as_text())
	file.close()
	if parsed.error == OK and parsed.result is Dictionary:
		var normalized: Dictionary = _normalize_state(parsed.result)
		if not normalized.empty():
			return normalized
	push_error("O estado inicial do progresso é inválido; usando nível 1 com 0 XP.")
	return DEFAULT_STATE.duplicate(true)


func _is_number(value) -> bool:
	return typeof(value) == TYPE_INT or typeof(value) == TYPE_REAL


func _save_state(value: Dictionary) -> bool:
	var file := File.new()
	var open_error: int = file.open(storage_path, File.WRITE)
	if open_error != OK:
		push_error("Não foi possível salvar o progresso do usuário: %s" % storage_path)
		return false
	file.store_string(JSON.print(value, "\t"))
	var write_error: int = file.get_error()
	file.close()
	if write_error != OK:
		push_error("Falha ao gravar o JSON de progresso: %s" % storage_path)
		return false
	return true


func _load_rules() -> void:
	var file := File.new()
	var open_error: int = file.open(RULES_PATH, File.READ)
	if open_error != OK:
		push_error("Não foi possível abrir as regras de progressão; usando os valores padrão.")
		return
	var parsed: JSONParseResult = JSON.parse(file.get_as_text())
	file.close()
	if parsed.error != OK or not parsed.result is Dictionary:
		push_error("As regras de progressão são inválidas; usando os valores padrão.")
		return
	var xp_value = parsed.result.get("experience_per_level", DEFAULT_EXPERIENCE_PER_LEVEL)
	var prefix_value = parsed.result.get("reward_id_prefix", DEFAULT_REWARD_ID_PREFIX)
	if _is_number(xp_value) and int(xp_value) > 0:
		experience_per_level = int(xp_value)
	else:
		push_error("XP por nível inválido; usando %d." % DEFAULT_EXPERIENCE_PER_LEVEL)
	if prefix_value is String and not prefix_value.empty():
		reward_id_prefix = prefix_value
	else:
		push_error("Prefixo de recompensas inválido; usando o padrão.")

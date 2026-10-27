extends Node

signal progress_changed(state)

const RULES_PATH = "res://data/progression/progression_rules.json"
const DEFAULT_PROGRESS_PATH = "res://data/progression/default_progress.json"
const DEFAULT_EXPERIENCE_PER_LEVEL = 2000
const CURRENT_SCHEMA_VERSION: int = 3
const DEFAULT_EXPERIENCE_THRESHOLDS: Dictionary = {
	"1": 2000,
	"2": 500,
	"3": 500,
	"4": 2000,
	"5": 2000,
	"6": 2000,
	"7": 2000,
	"8": 5000,
	"9": 5000,
	"10": 5000
}
const DEFAULT_REWARD_ID_PREFIX = "level_reward_"
const QUIZ_XP_PER_CORRECT_ANSWER: int = 60
const KNOWLEDGE_BADGE_ID: String = "knowledge"
const CORRECT_ANSWERS_PER_KNOWLEDGE_LEVEL: int = 3
const RESPECT_BADGE_ID: String = "respect"
const RESPECT_CORRECT_ANSWERS_FOR_FIRST_LEVEL: int = 4
const SECURITY_BADGE_ID: String = "security"
const SECURITY_DATA_FOR_FIRST_LEVEL: int = 300
const PROTECTED_DATA_SAVE_BATCH: int = 10
const PROCESSED_ID_RETENTION_SECONDS: int = 31536000
const PROGRESS_BACKUP_SUFFIX: String = ".bak"
const PROGRESS_TEMP_SUFFIX: String = ".tmp"
const BADGE_IDS = ["privacy", "security", "communication", "knowledge", "respect", "attention"]
const DEFAULT_STATE = {
	"schema_version": CURRENT_SCHEMA_VERSION,
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
	"anti_bullying_correct_answers": 0,
	"protected_data_count": 0,
	"processed_quiz_answer_ids": {},
	"processed_quiz_sessions": {},
	"processed_anti_bullying_sessions": {},
	"processed_data_protection_sessions": {},
	"pending_badge_notifications": []
}

var storage_path: String = "user://progress.json"
var experience_per_level: int = DEFAULT_EXPERIENCE_PER_LEVEL
var experience_thresholds: Dictionary = DEFAULT_EXPERIENCE_THRESHOLDS.duplicate(true)
var reward_id_prefix: String = DEFAULT_REWARD_ID_PREFIX
var state: Dictionary = {}
var pending_protected_data_count: int = 0


func _ready() -> void:
	_load_rules()
	load_progress()


func get_state() -> Dictionary:
	return state.duplicate(true)


func get_total_experience() -> int:
	if state.empty():
		return 0
	var total_experience: int = int(state["experience"])
	var current_level: int = int(state["level"])
	for level in range(1, min(current_level, 11)):
		total_experience += _get_experience_threshold(level)
	if current_level > 11:
		total_experience += (current_level - 11) * _get_experience_threshold(10)
	return total_experience


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
	_mark_processed_id(updated["processed_quiz_answer_ids"], answer_id)
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
	_mark_processed_id(updated["processed_quiz_sessions"], session_id)
	if not _save_state(updated):
		return false
	state = updated
	emit_signal("progress_changed", get_state())
	return true


func complete_anti_bullying_round(round_id: String, correct_answer_count: int, total_situations: int) -> bool:
	if round_id.empty() or state.empty() or total_situations < 1 or correct_answer_count < 0 or correct_answer_count > total_situations:
		return false
	if state["processed_anti_bullying_sessions"].has(round_id):
		return true
	var updated: Dictionary = state.duplicate(true)
	var correct_total: int = int(updated["anti_bullying_correct_answers"])
	var old_level: int = int(updated["badge_levels"][RESPECT_BADGE_ID])
	correct_total += correct_answer_count
	updated["anti_bullying_correct_answers"] = correct_total
	var new_level: int = _get_progressive_badge_level(correct_total, RESPECT_CORRECT_ANSWERS_FOR_FIRST_LEVEL, 2)
	_queue_badge_level_notifications(updated, RESPECT_BADGE_ID, old_level, new_level)
	var xp_delta: int = correct_answer_count * 100 - (total_situations - correct_answer_count) * 20
	if xp_delta > 0:
		updated = _advance_state(updated, xp_delta)
	_mark_processed_id(updated["processed_anti_bullying_sessions"], round_id)
	if not _save_state(updated):
		return false
	state = updated
	emit_signal("progress_changed", get_state())
	return true


func record_protected_data() -> bool:
	if state.empty():
		return false
	pending_protected_data_count += 1
	if pending_protected_data_count >= PROTECTED_DATA_SAVE_BATCH:
		flush_pending_protected_data()
	return true


func flush_pending_protected_data() -> bool:
	if pending_protected_data_count <= 0:
		return true
	if state.empty():
		return false
	var updated: Dictionary = state.duplicate(true)
	updated = _apply_protected_data_to_state(updated, pending_protected_data_count)
	if not _save_state(updated):
		return false
	pending_protected_data_count = 0
	state = updated
	emit_signal("progress_changed", get_state())
	return true


func _apply_protected_data_to_state(updated: Dictionary, amount: int) -> Dictionary:
	if amount <= 0:
		return updated
	var old_level: int = int(updated["badge_levels"][SECURITY_BADGE_ID])
	var protected_data_count: int = int(updated["protected_data_count"]) + amount
	updated["protected_data_count"] = protected_data_count
	var new_level: int = _get_progressive_badge_level(protected_data_count, SECURITY_DATA_FOR_FIRST_LEVEL, 200)
	_queue_badge_level_notifications(updated, SECURITY_BADGE_ID, old_level, new_level)
	return _advance_state(updated, amount * 5)


func complete_data_protection_round(round_id: String, won: bool) -> bool:
	if round_id.empty() or state.empty():
		return false
	if state["processed_data_protection_sessions"].has(round_id):
		return true
	var updated: Dictionary = state.duplicate(true)
	updated = _apply_protected_data_to_state(updated, pending_protected_data_count)
	if won:
		updated = _advance_state(updated, 200)
	_mark_processed_id(updated["processed_data_protection_sessions"], round_id)
	if not _save_state(updated):
		return false
	pending_protected_data_count = 0
	state = updated
	emit_signal("progress_changed", get_state())
	return true


func _get_progressive_badge_level(progress_count: int, first_level_requirement: int, requirement_step: int) -> int:
	var level: int = 0
	var remaining_progress: int = progress_count
	while remaining_progress >= first_level_requirement + level * requirement_step:
		remaining_progress -= first_level_requirement + level * requirement_step
		level += 1
	return level


func _queue_badge_level_notifications(updated: Dictionary, badge_id: String, old_level: int, new_level: int) -> void:
	if new_level <= old_level:
		return
	for level in range(old_level + 1, new_level + 1):
		updated["pending_badge_notifications"].append({
			"event_id": "%s:%d" % [badge_id, level],
			"badge_id": badge_id,
			"level": level,
			"kind": "unlocked" if level == 1 else "level_up"
		})
	updated["badge_levels"][badge_id] = new_level


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


func _notification(what: int) -> void:
	if what == MainLoop.NOTIFICATION_APP_PAUSED or what == MainLoop.NOTIFICATION_WM_QUIT_REQUEST:
		if not flush_pending_protected_data():
			push_error("Não foi possível salvar os dados coletados antes de pausar ou fechar o aplicativo.")


func load_progress() -> bool:
	_recover_progress_backup()
	pending_protected_data_count = 0
	var file := File.new()
	if not file.file_exists(storage_path):
		state = _load_default_state()
		_update_experience_per_level()
		if not _save_state(state):
			return false
		emit_signal("progress_changed", get_state())
		return true

	var open_error: int = file.open(storage_path, File.READ)
	if open_error != OK:
		push_error("Não foi possível abrir o progresso do usuário: %s" % storage_path)
		state = _load_default_state()
		_update_experience_per_level()
		return false
	var content: String = file.get_as_text()
	file.close()
	var parsed: JSONParseResult = JSON.parse(content)
	if parsed.error != OK or not parsed.result is Dictionary:
		push_error("O JSON de progresso é inválido na linha %d: %s" % [parsed.error_line, parsed.error_string])
		state = _load_default_state()
		_update_experience_per_level()
		return false

	var normalized: Dictionary = _normalize_state(parsed.result)
	if normalized.empty():
		push_error("O JSON de progresso contém dados inválidos; os dados do usuário foram preservados.")
		state = _load_default_state()
		_update_experience_per_level()
		return false
	state = normalized
	_update_experience_per_level()
	if int(parsed.result.get("schema_version", 1)) < CURRENT_SCHEMA_VERSION and not _save_state(state):
		push_error("Não foi possível atualizar o formato do progresso salvo; os dados continuam carregados.")
	emit_signal("progress_changed", get_state())
	return true


func add_experience(amount: int) -> bool:
	if amount <= 0 or state.empty():
		return false
	var updated: Dictionary = _advance_state(state, amount)
	if not _save_state(updated):
		return false
	state = updated
	_update_experience_per_level()
	emit_signal("progress_changed", get_state())
	return true


func _advance_state(current_state: Dictionary, amount: int) -> Dictionary:
	var updated: Dictionary = current_state.duplicate(true)
	var current_level: int = int(updated["level"])
	var remaining_experience: int = int(updated["experience"]) + amount
	var unlocked_items: Array = updated["unlocked_items"]
	while remaining_experience >= _get_experience_threshold(current_level):
		remaining_experience -= _get_experience_threshold(current_level)
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
	var anti_bullying_correct_answers_value = data.get("anti_bullying_correct_answers", 0)
	var protected_data_count_value = data.get("protected_data_count", 0)
	var processed_answer_values = data.get("processed_quiz_answer_ids", [])
	var processed_session_values = data.get("processed_quiz_sessions", [])
	var processed_anti_bullying_values = data.get("processed_anti_bullying_sessions", [])
	var processed_data_protection_values = data.get("processed_data_protection_sessions", [])
	var pending_notification_values = data.get("pending_badge_notifications", [])
	var schema_version = data.get("schema_version", 1)
	if not _is_number(level_value) or not _is_number(experience_value) or not _is_number(schema_version) or not _is_number(quiz_correct_answers_value) or not _is_number(anti_bullying_correct_answers_value) or not _is_number(protected_data_count_value):
		return {}
	var level: int = int(level_value)
	var experience: int = int(experience_value)
	if int(schema_version) < 1 or int(schema_version) > CURRENT_SCHEMA_VERSION or level < 1 or experience < 0:
		return {}
	var migration_experience_limit: int = experience_per_level if int(schema_version) < CURRENT_SCHEMA_VERSION else _get_experience_threshold(level)
	if experience >= migration_experience_limit:
		return {}
	if int(schema_version) < CURRENT_SCHEMA_VERSION:
		var legacy_total_experience: int = (level - 1) * experience_per_level + experience
		level = 1
		experience = legacy_total_experience
		while experience >= _get_experience_threshold(level):
			experience -= _get_experience_threshold(level)
			level += 1
	if not item_values is Array:
		return {}
	if int(quiz_correct_answers_value) < 0 or int(anti_bullying_correct_answers_value) < 0 or int(protected_data_count_value) < 0 or not badge_level_values is Dictionary:
		return {}
	if (not processed_answer_values is Array and not processed_answer_values is Dictionary) or (not processed_session_values is Array and not processed_session_values is Dictionary) or (not processed_anti_bullying_values is Array and not processed_anti_bullying_values is Dictionary) or (not processed_data_protection_values is Array and not processed_data_protection_values is Dictionary) or not pending_notification_values is Array:
		return {}
	var clean_answer_ids: Dictionary = _normalize_processed_ids(processed_answer_values)
	var clean_session_ids: Dictionary = _normalize_processed_ids(processed_session_values)
	var clean_anti_bullying_ids: Dictionary = _normalize_processed_ids(processed_anti_bullying_values)
	var clean_data_protection_ids: Dictionary = _normalize_processed_ids(processed_data_protection_values)
	if (clean_answer_ids.empty() and not processed_answer_values.empty()) or (clean_session_ids.empty() and not processed_session_values.empty()) or (clean_anti_bullying_ids.empty() and not processed_anti_bullying_values.empty()) or (clean_data_protection_ids.empty() and not processed_data_protection_values.empty()):
		return {}
	var clean_items: Array = []
	for item_id in item_values:
		if not item_id is String or item_id.empty():
			return {}
		if not clean_items.has(item_id):
			clean_items.append(item_id)
	for reached_level in range(2, level + 1):
		var reward_id: String = "%s%d" % [reward_id_prefix, reached_level]
		if not clean_items.has(reward_id):
			clean_items.append(reward_id)
	var clean_badge_levels: Dictionary = {}
	for badge_id in BADGE_IDS:
		var badge_level_value = badge_level_values.get(badge_id, 0)
		if not _is_number(badge_level_value) or int(badge_level_value) < 0:
			return {}
		clean_badge_levels[badge_id] = int(badge_level_value)
	clean_badge_levels[KNOWLEDGE_BADGE_ID] = _get_knowledge_level_for_correct_answers(int(quiz_correct_answers_value))
	clean_badge_levels[RESPECT_BADGE_ID] = _get_progressive_badge_level(int(anti_bullying_correct_answers_value), RESPECT_CORRECT_ANSWERS_FOR_FIRST_LEVEL, 2)
	clean_badge_levels[SECURITY_BADGE_ID] = _get_progressive_badge_level(int(protected_data_count_value), SECURITY_DATA_FOR_FIRST_LEVEL, 200)
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
		if int(notification_level) > int(clean_badge_levels[badge_id]):
			continue
		clean_notifications.append({
			"event_id": event_id,
			"badge_id": badge_id,
			"level": int(notification_level),
			"kind": notification_kind
		})
	return {
		"schema_version": CURRENT_SCHEMA_VERSION,
		"level": level,
		"experience": experience,
		"unlocked_items": clean_items,
		"badge_levels": clean_badge_levels,
		"quiz_correct_answers": int(quiz_correct_answers_value),
		"anti_bullying_correct_answers": int(anti_bullying_correct_answers_value),
		"protected_data_count": int(protected_data_count_value),
		"processed_quiz_answer_ids": clean_answer_ids,
		"processed_quiz_sessions": clean_session_ids,
		"processed_anti_bullying_sessions": clean_anti_bullying_ids,
		"processed_data_protection_sessions": clean_data_protection_ids,
		"pending_badge_notifications": clean_notifications
	}


func _normalize_processed_ids(values) -> Dictionary:
	var indexed: Dictionary = {}
	var now: int = OS.get_unix_time()
	if values is Array:
		for value in values:
			if not value is String or value.empty():
				return {}
			indexed[value] = _processed_id_timestamp(value, now)
	elif values is Dictionary:
		for key in values:
			var timestamp = values[key]
			if not key is String or key.empty() or not _is_number(timestamp) or int(timestamp) < 0:
				return {}
			indexed[key] = int(timestamp)
	else:
		return {}
	_prune_processed_ids(indexed, now)
	return indexed


func _mark_processed_id(indexed: Dictionary, identifier: String) -> void:
	var now: int = OS.get_unix_time()
	indexed[identifier] = _processed_id_timestamp(identifier, now)
	if indexed.size() % 64 == 0:
		_prune_processed_ids(indexed, now)


func _prune_processed_ids(indexed: Dictionary, now: int) -> void:
	for key in indexed.keys():
		var timestamp: int = int(indexed[key])
		if timestamp <= now and now - timestamp > PROCESSED_ID_RETENTION_SECONDS:
			indexed.erase(key)


func _processed_id_timestamp(identifier: String, fallback: int) -> int:
	var parts: PoolStringArray = identifier.split(":")
	var date_id: String = parts[0] if parts.size() >= 2 else identifier
	if date_id.begins_with("20"):
		var date_parts: PoolStringArray = date_id.split("-")
		if date_parts.size() == 3 and date_parts[0].is_valid_integer() and date_parts[1].is_valid_integer() and date_parts[2].is_valid_integer():
			return OS.get_unix_time_from_datetime({
				"year": int(date_parts[0]), "month": int(date_parts[1]), "day": int(date_parts[2]),
				"hour": 0, "minute": 0, "second": 0
			})
	if parts.size() >= 3 and parts[1].is_valid_integer():
		return int(parts[1])
	return fallback


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
	var temporary_path: String = storage_path + PROGRESS_TEMP_SUFFIX
	var backup_path: String = storage_path + PROGRESS_BACKUP_SUFFIX
	var file := File.new()
	var open_error: int = file.open(temporary_path, File.WRITE)
	if open_error != OK:
		push_error("Não foi possível abrir o arquivo temporário de progresso: %s" % temporary_path)
		return false
	file.store_string(JSON.print(value, "\t"))
	file.flush()
	var write_error: int = file.get_error()
	file.close()
	if write_error != OK:
		push_error("Falha ao gravar o JSON temporário de progresso: %s" % temporary_path)
		_remove_file_if_exists(temporary_path)
		return false
	var directory := Directory.new()
	if directory.file_exists(storage_path):
		_remove_file_if_exists(backup_path)
		var backup_error: int = directory.rename(storage_path, backup_path)
		if backup_error != OK:
			push_error("Não foi possível preservar o progresso anterior antes da substituição.")
			_remove_file_if_exists(temporary_path)
			return false
	var replace_error: int = directory.rename(temporary_path, storage_path)
	if replace_error != OK:
		if directory.file_exists(backup_path):
			directory.rename(backup_path, storage_path)
		push_error("Não foi possível substituir o arquivo de progresso salvo.")
		_remove_file_if_exists(temporary_path)
		return false
	_remove_file_if_exists(backup_path)
	return true


func _recover_progress_backup() -> void:
	var directory := Directory.new()
	var backup_path: String = storage_path + PROGRESS_BACKUP_SUFFIX
	if directory.file_exists(storage_path) or not directory.file_exists(backup_path):
		return
	if directory.rename(backup_path, storage_path) != OK:
		push_error("Não foi possível restaurar o backup do progresso do usuário.")


func _remove_file_if_exists(path: String) -> void:
	var directory := Directory.new()
	if directory.file_exists(path):
		directory.remove(path)


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
	var thresholds_value = parsed.result.get("experience_per_level_by_current_level", DEFAULT_EXPERIENCE_THRESHOLDS)
	var prefix_value = parsed.result.get("reward_id_prefix", DEFAULT_REWARD_ID_PREFIX)
	if _is_number(xp_value) and int(xp_value) > 0:
		experience_per_level = int(xp_value)
		if thresholds_value is Dictionary and _is_valid_experience_thresholds(thresholds_value):
			experience_thresholds = thresholds_value.duplicate(true)
		else:
			push_error("Limiares de XP inválidos; usando os valores padrão por nível.")
			experience_thresholds = DEFAULT_EXPERIENCE_THRESHOLDS.duplicate(true)
	else:
		push_error("XP por nível inválido; usando %d." % DEFAULT_EXPERIENCE_PER_LEVEL)
	if prefix_value is String and not prefix_value.empty():
		reward_id_prefix = prefix_value
	else:
		push_error("Prefixo de recompensas inválido; usando o padrão.")


func _get_experience_threshold(level: int) -> int:
	var level_key: String = str(max(1, level))
	if experience_thresholds.has(level_key):
		return int(experience_thresholds[level_key])
	return int(experience_thresholds.get("10", experience_per_level))


func _update_experience_per_level() -> void:
	if not state.empty():
		experience_per_level = _get_experience_threshold(int(state["level"]))


func _is_valid_experience_thresholds(values: Dictionary) -> bool:
	for level in range(1, 11):
		var level_key: String = str(level)
		if not values.has(level_key) or not _is_number(values[level_key]) or int(values[level_key]) <= 0:
			return false
	return true

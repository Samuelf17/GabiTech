extends Node

signal progress_changed(state)

const RULES_PATH = "res://data/progression/progression_rules.json"
const DEFAULT_PROGRESS_PATH = "res://data/progression/default_progress.json"
const DEFAULT_EXPERIENCE_PER_LEVEL = 2000
const DEFAULT_REWARD_ID_PREFIX = "level_reward_"
const DEFAULT_STATE = {
	"schema_version": 1,
	"level": 1,
	"experience": 0,
	"unlocked_items": []
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
	var schema_version = data.get("schema_version", 1)
	if not _is_number(level_value) or not _is_number(experience_value) or not _is_number(schema_version):
		return {}
	var level: int = int(level_value)
	var experience: int = int(experience_value)
	if int(schema_version) != 1 or level < 1 or experience < 0 or experience >= experience_per_level:
		return {}
	if not item_values is Array:
		return {}
	var clean_items: Array = []
	for item_id in item_values:
		if not item_id is String or item_id.empty():
			return {}
		if not clean_items.has(item_id):
			clean_items.append(item_id)
	return {
		"schema_version": 1,
		"level": level,
		"experience": experience,
		"unlocked_items": clean_items
	}


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

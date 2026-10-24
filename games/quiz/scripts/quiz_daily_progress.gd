extends Reference

const SAVE_PATH: String = "user://quiz_daily_progress.json"
const DAILY_LIMIT: int = 5

var date_key: String = ""
var answered_question_indices: Array = []
var correct_question_indices: Array = []
var last_error: String = ""
var storage_path: String = SAVE_PATH
var follows_system_date: bool = true


func load_progress(question_count: int, date_override: String = "") -> void:
	follows_system_date = date_override.empty()
	date_key = date_override if not date_override.empty() else _today_key()
	answered_question_indices.clear()
	correct_question_indices.clear()
	last_error = ""
	var file := File.new()
	if not file.file_exists(storage_path):
		return
	var open_error: int = file.open(storage_path, File.READ)
	if open_error != OK:
		last_error = "Não foi possível ler o progresso diário."
		return
	var parsed: JSONParseResult = JSON.parse(file.get_as_text())
	file.close()
	if parsed.error != OK or not (parsed.result is Dictionary):
		last_error = "O progresso diário salvo está inválido e não pôde ser verificado."
		return
	if not parsed.result.has("date") or typeof(parsed.result["date"]) != TYPE_STRING:
		last_error = "A data do progresso diário está inválida."
		return
	if parsed.result.get("date", "") != date_key:
		return
	if not parsed.result.has("answered_question_indices"):
		last_error = "O progresso salvo não contém a lista de respostas do dia."
		return
	var stored_indices = parsed.result["answered_question_indices"]
	if not (stored_indices is Array):
		last_error = "A lista de perguntas respondidas está inválida e não pôde ser verificada."
		return
	for value in stored_indices:
		if typeof(value) != TYPE_REAL and typeof(value) != TYPE_INT:
			last_error = "A lista diária salva contém um identificador inválido."
			answered_question_indices.clear()
			return
		var question_index: int = int(value)
		if question_index < 0 or question_index >= question_count:
			last_error = "A lista diária salva contém uma pergunta inexistente."
			answered_question_indices.clear()
			return
		if not answered_question_indices.has(question_index):
			answered_question_indices.append(question_index)
		if answered_question_indices.size() >= DAILY_LIMIT:
			break
	var stored_correct_indices = parsed.result.get("correct_question_indices", [])
	if not stored_correct_indices is Array:
		last_error = "A lista diária de acertos está inválida e não pôde ser verificada."
		answered_question_indices.clear()
		return
	for value in stored_correct_indices:
		if (typeof(value) != TYPE_REAL and typeof(value) != TYPE_INT):
			last_error = "A lista diária salva contém um acerto inválido."
			answered_question_indices.clear()
			correct_question_indices.clear()
			return
		var question_index: int = int(value)
		if not answered_question_indices.has(question_index) or question_index < 0 or question_index >= question_count:
			last_error = "A lista diária de acertos contém uma pergunta inexistente ou não respondida."
			answered_question_indices.clear()
			correct_question_indices.clear()
			return
		if not correct_question_indices.has(question_index):
			correct_question_indices.append(question_index)


func get_answered_count() -> int:
	_sync_current_date()
	return answered_question_indices.size()


func can_answer() -> bool:
	return get_answered_count() < DAILY_LIMIT


func get_correct_count() -> int:
	_sync_current_date()
	return correct_question_indices.size()


func record_answer(question_index: int, question_count: int, was_correct: bool = false) -> bool:
	if not can_answer() or question_index < 0 or question_index >= question_count:
		return false
	if answered_question_indices.has(question_index):
		return false
	answered_question_indices.append(question_index)
	if was_correct:
		correct_question_indices.append(question_index)
	if not _save_progress():
		answered_question_indices.pop_back()
		if was_correct:
			correct_question_indices.pop_back()
		return false
	return true


func _save_progress() -> bool:
	var file := File.new()
	var open_error: int = file.open(storage_path, File.WRITE)
	if open_error != OK:
		last_error = "Não foi possível salvar o progresso diário."
		return false
	var content: String = JSON.print({
		"date": date_key,
		"answered_question_indices": answered_question_indices,
		"correct_question_indices": correct_question_indices
	})
	file.store_string(content)
	file.flush()
	var write_error: int = file.get_error()
	file.close()
	if write_error != OK:
		last_error = "O progresso diário não foi gravado corretamente."
		return false
	return true


func _today_key() -> String:
	var today: Dictionary = OS.get_date()
	return "%04d-%02d-%02d" % [today["year"], today["month"], today["day"]]


func _sync_current_date() -> void:
	if not follows_system_date:
		return
	var current_date: String = _today_key()
	if not date_key.empty() and current_date != date_key:
		date_key = current_date
		answered_question_indices.clear()
		correct_question_indices.clear()
		last_error = ""

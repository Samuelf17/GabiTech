extends Reference

const DATA_PATH: String = "res://games/anti_bullying/data/situations.json"
const OPTIONS_PER_SITUATION: int = 4

var situations: Array = []
var load_error: String = ""


func load_situations(path: String = DATA_PATH) -> bool:
	situations.clear()
	load_error = ""
	var file := File.new()
	if not file.file_exists(path):
		load_error = "O arquivo de situações não foi encontrado."
		return false
	var error: int = file.open(path, File.READ)
	if error != OK:
		load_error = "Não foi possível abrir as situações (%d)." % error
		return false
	var parsed = JSON.parse(file.get_as_text())
	file.close()
	if parsed.error != OK or not parsed.result is Dictionary:
		load_error = "O arquivo de situações contém JSON inválido."
		return false
	var entries = parsed.result.get("situations", null)
	if not entries is Array or entries.empty():
		load_error = "O arquivo não contém situações."
		return false
	for entry in entries:
		if not _is_valid_situation(entry):
			situations.clear()
			load_error = "Uma situação está incompleta ou inválida."
			return false
		situations.append(entry)
	return true


func _is_valid_situation(entry) -> bool:
	if not entry is Dictionary or str(entry.get("id", "")).empty():
		return false
	if not entry.get("conversation", null) is Array or entry["conversation"].empty():
		return false
	if not entry.get("options", null) is Array or entry["options"].size() != OPTIONS_PER_SITUATION:
		return false
	if str(entry.get("explanation", "")).empty():
		return false
	var correct_count: int = 0
	for message in entry["conversation"]:
		if not message is Dictionary or str(message.get("speaker", "")).empty() or str(message.get("text", "")).empty():
			return false
	for option in entry["options"]:
		if not option is Dictionary or str(option.get("text", "")).empty() or str(option.get("consequence", "")).empty():
			return false
		if not option.get("correct", null) is bool:
			return false
		if option["correct"]:
			correct_count += 1
	return correct_count > 0

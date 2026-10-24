extends Reference

const QUESTIONS_PATH: String = "res://games/quiz/data/perguntas_e_respostas.json"

var questions: Array = []
var load_error: String = ""
var random_generator := RandomNumberGenerator.new()


func _init() -> void:
	random_generator.randomize()


func load_questions() -> bool:
	questions.clear()
	load_error = ""
	var file := File.new()
	var open_error: int = file.open(QUESTIONS_PATH, File.READ)
	if open_error != OK:
		load_error = "Não foi possível abrir o arquivo de perguntas."
		return false
	var parsed: JSONParseResult = JSON.parse(file.get_as_text())
	file.close()
	if parsed.error != OK or not (parsed.result is Array):
		load_error = "O arquivo de perguntas está inválido."
		return false
	for entry in parsed.result:
		if _is_valid_question(entry):
			questions.append(entry)
	if questions.empty():
		load_error = "O arquivo não contém perguntas válidas."
		return false
	return true


func get_random_question_index(excluded_indices: Array) -> int:
	var candidates: Array = []
	for index in range(questions.size()):
		if not excluded_indices.has(index):
			candidates.append(index)
	if candidates.empty():
		return -1
	var chosen_position: int = random_generator.randi_range(0, candidates.size() - 1)
	return int(candidates[chosen_position])


func _is_valid_question(entry) -> bool:
	if not (entry is Dictionary):
		return false
	for required_key in ["tema", "pergunta", "opcoes", "respostaCorreta", "explicacao"]:
		if not entry.has(required_key):
			return false
		if required_key != "opcoes" and required_key != "respostaCorreta" and typeof(entry[required_key]) != TYPE_STRING:
			return false
	if not (entry["opcoes"] is Array) or entry["opcoes"].size() != 4:
		return false
	if typeof(entry["respostaCorreta"]) != TYPE_REAL and typeof(entry["respostaCorreta"]) != TYPE_INT:
		return false
	var answer_index: int = int(entry["respostaCorreta"])
	if answer_index < 0 or answer_index >= entry["opcoes"].size():
		return false
	for option in entry["opcoes"]:
		if typeof(option) != TYPE_STRING or String(option).empty():
			return false
	return true

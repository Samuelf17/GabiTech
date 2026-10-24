extends SceneTree

const PROGRESSION_SCRIPT = preload("res://shared/progress/progression_service.gd")
const TEST_STORAGE_PATH = "user://progression_test.json"

var failures: Array = []
var emitted_states: Array = []


func _initialize() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	_remove_test_file()
	var progression = Node.new()
	progression.set_script(PROGRESSION_SCRIPT)
	progression.set("storage_path", TEST_STORAGE_PATH)
	progression.connect("progress_changed", self, "_on_progress_changed")
	get_root().add_child(progression)
	yield(self, "idle_frame")

	_check(progression.experience_per_level == 2000, "progression rules use 2000 XP per level")
	_check(progression.state["level"] == 1 and progression.state["experience"] == 0, "missing save starts at level 1 with 0 XP")
	_check(not progression.add_experience(0), "zero XP is rejected")
	_check(not progression.add_experience(-10), "negative XP is rejected")
	_check(progression.add_experience(750), "positive XP can be applied by the progression API")
	_check(progression.state["level"] == 1 and progression.state["experience"] == 750, "partial XP does not advance the level")
	_check(progression.state["unlocked_items"].empty(), "partial XP does not grant a level item")
	_check(progression.add_experience(1250), "XP reaches the next level")
	_check(progression.state["level"] == 2 and progression.state["experience"] == 0, "exact threshold advances the level without losing XP")
	_check(progression.state["unlocked_items"] == ["level_reward_2"], "level 2 grants its future-configurable reward ID")
	_check(progression.add_experience(4500), "multiple level advances can be processed")
	_check(progression.state["level"] == 4 and progression.state["experience"] == 500, "overflow XP carries across multiple levels")
	_check(progression.state["unlocked_items"] == ["level_reward_2", "level_reward_3", "level_reward_4"], "each crossed level grants one item ID")
	_check(progression.get_total_experience() == 6500, "total XP is derived from level and current XP")
	_check(abs(progression.get_progress_ratio() - 0.25) < 0.0001, "XP progress ratio reflects current level progress")
	_check(progression.format_number(2000) == "2.000", "XP values use localized thousands separators")
	_check(emitted_states.size() == 4, "each persisted XP update emits a progress change")
	var copied_state: Dictionary = progression.get_state()
	copied_state["level"] = 99
	_check(progression.state["level"] == 4, "get_state returns a defensive copy")

	var reloaded = Node.new()
	reloaded.set_script(PROGRESSION_SCRIPT)
	reloaded.set("storage_path", TEST_STORAGE_PATH)
	get_root().add_child(reloaded)
	yield(self, "idle_frame")
	_check(reloaded.state["level"] == 4 and reloaded.state["experience"] == 500, "saved level and XP load from JSON")
	_check(reloaded.state["unlocked_items"].size() == 3, "unlocked item IDs load from JSON")
	_check(_saved_json_is_valid(), "runtime save is valid JSON")
	_test_quiz_rewards(progression, reloaded)
	_test_invalid_saved_data(progression)
	_test_failed_save(progression)

	_remove_test_file()
	if failures.empty():
		print("Progression tests passed")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func _test_quiz_rewards(progression: Node, reloaded: Node) -> void:
	_check(progression.get_badge_level("knowledge") == 0, "knowledge badge starts locked at level zero")
	_check(progression.get_badge_level("privacy") == 0, "badges without unlock rules stay at level zero")
	for index in range(3):
		_check(progression.record_quiz_correct_answer("2026-02-01:%d" % index), "correct quiz answer %d is persisted" % (index + 1))
	_check(progression.state["quiz_correct_answers"] == 3, "correct quiz answers accumulate across sessions")
	_check(progression.get_badge_level("knowledge") == 1, "three correct quiz answers unlock knowledge level one")
	var notifications: Array = progression.get_pending_badge_notifications()
	_check(notifications.size() == 1 and notifications[0]["kind"] == "unlocked", "first knowledge level queues an unlock notification")
	_check(progression.record_quiz_correct_answer("2026-02-01:2"), "replayed answer event is accepted idempotently")
	_check(progression.state["quiz_correct_answers"] == 3, "replayed correct answer is not counted twice")
	_check(progression.complete_quiz_session("2026-02-01", 3), "finished quiz session grants its XP")
	_check(progression.get_total_experience() == 6800, "each correct answer grants 100 XP after session completion")
	_check(progression.complete_quiz_session("2026-02-01", 3), "finished quiz session can be retried safely")
	_check(progression.get_total_experience() == 6800, "retrying a finished session does not grant duplicate XP")
	for index in range(3, 6):
		_check(progression.record_quiz_correct_answer("2026-02-02:%d" % index), "additional correct answer is persisted")
	_check(progression.get_badge_level("knowledge") == 1, "three more answers bring the total to six without raising knowledge to level two")
	for index in range(6, 9):
		_check(progression.record_quiz_correct_answer("2026-02-03:%d" % index), "correct answer toward the nine-answer threshold is persisted")
	_check(progression.get_badge_level("knowledge") == 2, "nine total correct answers raise knowledge to level two")
	notifications = progression.get_pending_badge_notifications()
	_check(notifications.size() == 2 and notifications[1]["kind"] == "level_up", "higher badge level queues a level-up notification")
	_check(progression.acknowledge_badge_notification("knowledge:1"), "unlock popup can be acknowledged")
	_check(progression.get_pending_badge_notifications()[0]["level"] == 2, "level-up popup stays queued after the unlock popup")
	reloaded.load_progress()
	_check(reloaded.get_badge_level("knowledge") == 2, "badge level persists after reloading progression")
	_check(reloaded.get_pending_badge_notifications().size() == 1, "unseen badge notification persists after reloading progression")
	for index in range(9, 17):
		_check(progression.record_quiz_correct_answer("2026-02-04:%d" % index), "correct answer before the level-three threshold is persisted")
	_check(progression.get_badge_level("knowledge") == 2, "17 total correct answers do not reach knowledge level three")
	_check(progression.record_quiz_correct_answer("2026-02-04:17"), "18th correct answer is persisted")
	_check(progression.get_badge_level("knowledge") == 3, "18 total correct answers raise knowledge to level three")
	var legacy_state: Dictionary = {
		"schema_version": 1,
		"level": 1,
		"experience": 0,
		"unlocked_items": [],
		"quiz_correct_answers": 6,
		"badge_levels": {"knowledge": 2},
		"pending_badge_notifications": [{
			"event_id": "knowledge:2",
			"badge_id": "knowledge",
			"level": 2,
			"kind": "level_up"
		}]
	}
	var normalized_legacy: Dictionary = progression._normalize_state(legacy_state)
	_check(normalized_legacy["badge_levels"]["knowledge"] == 1, "legacy progress is normalized to the new cumulative level threshold")
	_check(normalized_legacy["pending_badge_notifications"].empty(), "legacy notifications above the normalized badge level are discarded")


func _saved_json_is_valid() -> bool:
	var file := File.new()
	if file.open(TEST_STORAGE_PATH, File.READ) != OK:
		return false
	var parsed: JSONParseResult = JSON.parse(file.get_as_text())
	file.close()
	return parsed.error == OK and parsed.result is Dictionary


func _remove_test_file() -> void:
	var file := File.new()
	if file.file_exists(TEST_STORAGE_PATH):
		var directory := Directory.new()
		directory.remove(TEST_STORAGE_PATH)


func _test_invalid_saved_data(progression: Node) -> void:
	var file := File.new()
	_check(file.open(TEST_STORAGE_PATH, File.WRITE) == OK, "test can create malformed save")
	file.store_string("{invalid json")
	file.close()
	progression.load_progress()
	_check(progression.state["level"] == 1 and progression.state["experience"] == 0, "malformed save falls back to default state")
	_check(_file_text(TEST_STORAGE_PATH) == "{invalid json", "malformed save is preserved for diagnosis")
	file.open(TEST_STORAGE_PATH, File.WRITE)
	file.store_string(JSON.print({"level": "bad", "experience": -1, "unlocked_items": "bad"}))
	file.close()
	progression.load_progress()
	_check(progression.state["level"] == 1 and progression.state["experience"] == 0, "invalid schema falls back to default state")


func _test_failed_save(progression: Node) -> void:
	var previous_path: String = progression.get("storage_path")
	var previous_total: int = progression.get_total_experience()
	progression.set("storage_path", "user://missing_progress_test_directory/progress.json")
	_check(not progression.add_experience(100), "failed storage write rejects XP update")
	_check(progression.get_total_experience() == previous_total, "failed write does not mutate in-memory progress")
	progression.set("storage_path", previous_path)


func _file_text(path: String) -> String:
	var file := File.new()
	if file.open(path, File.READ) != OK:
		return ""
	var content: String = file.get_as_text()
	file.close()
	return content


func _on_progress_changed(state: Dictionary) -> void:
	emitted_states.append(state.duplicate(true))


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)

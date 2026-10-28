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

	_check(progression.experience_per_level == 500 and progression._get_experience_threshold(1) == 500, "level one requires 500 XP to advance")
	_check(progression._get_experience_threshold(2) == 500 and progression._get_experience_threshold(3) == 500, "levels two and three require 500 XP to advance")
	_check(progression._get_experience_threshold(4) == 2000 and progression._get_experience_threshold(7) == 2000, "levels four through seven require 2000 XP to advance")
	_check(progression._get_experience_threshold(8) == 5000 and progression._get_experience_threshold(10) == 5000, "levels eight through ten require 5000 XP to advance")
	_check(progression.state["level"] == 1 and progression.state["experience"] == 0, "missing save starts at level 1 with 0 XP")
	_check(not progression.add_experience(0), "zero XP is rejected")
	_check(not progression.add_experience(-10), "negative XP is rejected")
	_check(progression.add_experience(250), "positive XP can be applied by the progression API")
	_check(progression.state["level"] == 1 and progression.state["experience"] == 250, "partial XP does not advance the level")
	_check(progression.state["unlocked_items"].empty(), "partial XP does not grant a level item")
	_check(progression.add_experience(250), "XP reaches the next level")
	_check(progression.state["level"] == 2 and progression.state["experience"] == 0, "exact threshold advances the level without losing XP")
	_check(progression.state["unlocked_items"] == ["level_reward_2"], "level 2 grants its future-configurable reward ID")
	_check(progression.add_experience(4500), "multiple level advances can be processed")
	_check(progression.state["level"] == 5 and progression.state["experience"] == 1500, "overflow XP carries across levels with different XP costs")
	_check(progression.state["unlocked_items"] == ["level_reward_2", "level_reward_3", "level_reward_4", "level_reward_5"], "each crossed level grants one item ID")
	_check(progression.get_total_experience() == 5000, "total XP is derived from level and current XP")
	_check(abs(progression.get_progress_ratio() - 0.75) < 0.0001, "XP progress ratio reflects the current level's XP threshold")
	_check(progression.format_number(2000) == "2.000", "XP values use localized thousands separators")
	_check(emitted_states.size() == 4, "each persisted XP update emits a progress change")
	var copied_state: Dictionary = progression.get_state()
	copied_state["level"] = 99
	_check(progression.state["level"] == 5, "get_state returns a defensive copy")

	var reloaded = Node.new()
	reloaded.set_script(PROGRESSION_SCRIPT)
	reloaded.set("storage_path", TEST_STORAGE_PATH)
	get_root().add_child(reloaded)
	yield(self, "idle_frame")
	_check(reloaded.state["level"] == 5 and reloaded.state["experience"] == 1500, "saved level and XP load from JSON")
	_check(reloaded.state["unlocked_items"].size() == 4, "unlocked item IDs load from JSON")
	_check(_saved_json_is_valid(), "runtime save is valid JSON")
	_test_quiz_rewards(progression, reloaded)
	_test_other_game_rewards(progression)
	_test_invalid_saved_data(progression)
	_test_atomic_backup_recovery(progression)
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
	_check(progression.get_total_experience() == 5180, "each correct answer grants 60 XP after session completion")
	_check(progression.complete_quiz_session("2026-02-01", 3), "finished quiz session can be retried safely")
	_check(progression.get_total_experience() == 5180, "retrying a finished session does not grant duplicate XP")
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
	var old_xp_state: Dictionary = {
		"schema_version": 2,
		"level": 4,
		"experience": 500,
		"unlocked_items": ["level_reward_2", "level_reward_3", "level_reward_4"]
	}
	var migrated_xp_state: Dictionary = progression._normalize_state(old_xp_state)
	_check(migrated_xp_state["schema_version"] == 4, "old XP progress upgrades to the current save schema")
	_check(migrated_xp_state["level"] == 6 and migrated_xp_state["experience"] == 1000, "migration preserves earned XP while applying new level thresholds")
	_check(migrated_xp_state["unlocked_items"].has("level_reward_6"), "XP migration includes level rewards reached by the preserved balance")
	var schema_three_state: Dictionary = {
		"schema_version": 3,
		"level": 1,
		"experience": 750,
		"unlocked_items": []
	}
	var migrated_schema_three: Dictionary = progression._normalize_state(schema_three_state)
	_check(migrated_schema_three["schema_version"] == 4, "schema three saves upgrade to schema four")
	_check(migrated_schema_three["level"] == 2 and migrated_schema_three["experience"] == 250, "schema three XP is preserved when the level-one threshold drops to 500")
	_check(migrated_schema_three["unlocked_items"].has("level_reward_2"), "schema three XP migration unlocks the crossed level reward")


func _test_other_game_rewards(progression: Node) -> void:
	var initial_total: int = progression.get_total_experience()
	_check(progression.complete_anti_bullying_round("anti:test:one", 3, 5), "Anti-Bullying round progress can be recorded")
	_check(progression.get_total_experience() == initial_total + 260, "Anti-Bullying grants 100 XP per correct situation and subtracts 20 per wrong one")
	_check(progression.state["anti_bullying_correct_answers"] == 3, "Anti-Bullying badge progress counts only correct choices")
	_check(progression.get_badge_level("respect") == 0, "Respect remains locked before four correct answers")
	_check(progression.complete_anti_bullying_round("anti:test:two", 1, 5), "second Anti-Bullying round records")
	_check(progression.get_total_experience() == initial_total + 280, "one correct and four wrong answers produce a net gain of 20 XP")
	_check(progression.get_badge_level("respect") == 1, "four total correct Anti-Bullying answers unlock Respect level one")
	_check(progression.get_pending_badge_notifications().back()["badge_id"] == "respect", "Respect unlock queues a shared badge notification")
	_check(progression.complete_anti_bullying_round("anti:test:respect-level-two", 6, 6), "six additional correct choices can complete the next Respect level")
	_check(progression.get_badge_level("respect") == 2, "six correct answers after Respect level one reach level two")
	_check(progression.get_pending_badge_notifications().back()["kind"] == "level_up", "Respect level-up queues the shared level notification")
	var after_respect: int = progression.get_total_experience()
	_check(progression.complete_anti_bullying_round("anti:test:negative", 0, 5), "an all-wrong Anti-Bullying round is recorded")
	_check(progression.get_total_experience() == after_respect, "negative Anti-Bullying net XP does not change user XP")
	_check(progression.complete_anti_bullying_round("anti:test:negative", 5, 5), "duplicate Anti-Bullying completion is idempotent")
	_check(progression.get_total_experience() == after_respect, "duplicate Anti-Bullying completion cannot grant more XP")
	_check(progression._get_progressive_badge_level(9, 4, 2) == 1, "Respect level two requires six more correct answers after level one")
	_check(progression._get_progressive_badge_level(10, 4, 2) == 2, "ten total correct answers reach Respect level two")
	_check(progression._get_progressive_badge_level(299, 300, 200) == 0, "Security stays locked before 300 collected data")
	_check(progression._get_progressive_badge_level(300, 300, 200) == 1, "300 collected data unlock Security level one")
	_check(progression._get_progressive_badge_level(799, 300, 200) == 1, "Security level two requires 500 additional data")
	_check(progression._get_progressive_badge_level(800, 300, 200) == 2, "800 total collected data reach Security level two")
	var before_data: int = progression.get_total_experience()
	progression.state["protected_data_count"] = 299
	_check(progression.record_protected_data(), "collecting data records persistent progress")
	_check(progression.get_total_experience() == before_data, "data XP waits until a checkpoint")
	_check(progression.pending_protected_data_count == 1, "one data item stays in the in-memory save batch")
	_check(progression.complete_data_protection_round("data:test:loss", false), "data-protection loss is recorded")
	_check(progression.get_total_experience() == before_data + 5, "round completion flushes data XP without a loss bonus")
	_check(progression.get_badge_level("security") == 1, "the 300th collected data unlocks Security level one")
	_check(progression.get_pending_badge_notifications().back()["badge_id"] == "security", "Security unlock queues the shared badge notification")
	_check(progression.complete_data_protection_round("data:test:win", true), "data-protection win is recorded")
	_check(progression.get_total_experience() == before_data + 205, "winning data-protection grants a 200 XP bonus")
	_check(progression.complete_data_protection_round("data:test:win", true), "data-protection completion can be retried safely")
	_check(progression.get_total_experience() == before_data + 205, "replaying completion does not duplicate its bonus")
	var saved_data_count: int = progression.state["protected_data_count"]
	var xp_before_batch: int = progression.get_total_experience()
	for _index in range(progression.PROTECTED_DATA_SAVE_BATCH - 1):
		_check(progression.record_protected_data(), "collectible joins the pending data batch")
	_check(progression.state["protected_data_count"] == saved_data_count, "incomplete save batches do not rewrite the protected-data total")
	_check(progression.flush_pending_protected_data(), "pending data flushes explicitly at lifecycle boundaries")
	_check(progression.state["protected_data_count"] == saved_data_count + progression.PROTECTED_DATA_SAVE_BATCH - 1, "one checkpoint commits every item in the batch")
	_check(progression.get_total_experience() == xp_before_batch + (progression.PROTECTED_DATA_SAVE_BATCH - 1) * 5, "batch checkpoint applies five XP for each collected item")
	saved_data_count = progression.state["protected_data_count"]
	xp_before_batch = progression.get_total_experience()
	for _index in range(progression.PROTECTED_DATA_SAVE_BATCH):
		_check(progression.record_protected_data(), "data collection can fill the automatic checkpoint")
	_check(progression.pending_protected_data_count == 0, "the configured batch size triggers a checkpoint automatically")
	_check(progression.state["protected_data_count"] == saved_data_count + progression.PROTECTED_DATA_SAVE_BATCH, "automatic checkpoint commits every collected data item")
	_check(progression.get_total_experience() == xp_before_batch + progression.PROTECTED_DATA_SAVE_BATCH * 5, "automatic checkpoint grants five XP per item")
	_check(progression.record_protected_data(), "one more item waits after the automatic checkpoint")
	progression._notification(MainLoop.NOTIFICATION_APP_PAUSED)
	_check(progression.pending_protected_data_count == 0, "application pause flushes pending collected data")
	_check(progression.state["protected_data_count"] == saved_data_count + progression.PROTECTED_DATA_SAVE_BATCH + 1, "application pause preserves the last buffered data item")
	var now: int = OS.get_unix_time()
	var retained_ids: Dictionary = progression._normalize_processed_ids({"recent": now, "expired": now - progression.PROCESSED_ID_RETENTION_SECONDS - 1})
	_check(retained_ids.has("recent") and not retained_ids.has("expired"), "processed-ID compaction removes records older than one year")
	var migrated_ids: Dictionary = progression._normalize_processed_ids(["2026-02-01:2", "anti:test:one"])
	_check(migrated_ids.has("2026-02-01:2") and migrated_ids.has("anti:test:one"), "legacy arrays migrate to indexed processed-ID maps")


func _saved_json_is_valid() -> bool:
	var file := File.new()
	if file.open(TEST_STORAGE_PATH, File.READ) != OK:
		return false
	var parsed: JSONParseResult = JSON.parse(file.get_as_text())
	file.close()
	return parsed.error == OK and parsed.result is Dictionary


func _remove_test_file() -> void:
	for suffix in ["", ".tmp", ".bak"]:
		var path: String = TEST_STORAGE_PATH + suffix
		var directory := Directory.new()
		if directory.file_exists(path):
			directory.remove(path)


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


func _test_atomic_backup_recovery(progression: Node) -> void:
	_check(progression._save_state(progression.state), "progress is saved via the temporary-file replacement path")
	var backup_path: String = TEST_STORAGE_PATH + ".bak"
	var file := File.new()
	_check(file.open(TEST_STORAGE_PATH, File.READ) == OK, "saved progress opens before backup recovery test")
	var saved_contents: String = file.get_as_text()
	file.close()
	_check(file.open(backup_path, File.WRITE) == OK, "test creates a backup copy of progress")
	file.store_string(saved_contents)
	file.close()
	Directory.new().remove(TEST_STORAGE_PATH)
	progression._recover_progress_backup()
	_check(file.file_exists(TEST_STORAGE_PATH), "missing primary save is recovered from its backup")
	_check(_saved_json_is_valid(), "recovered progress backup remains valid JSON")


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

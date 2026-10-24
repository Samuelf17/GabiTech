#!/usr/bin/env bash
set -u

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GODOT_BIN="${GODOT_BIN:-godot}"
if [[ "$GODOT_BIN" == */* ]]; then
	if [[ ! -x "$GODOT_BIN" ]]; then
		echo "Godot executable not found or not executable: $GODOT_BIN" >&2
		exit 2
	fi
else
	GODOT_BIN="$(command -v "$GODOT_BIN" || true)"
	if [[ -z "$GODOT_BIN" ]]; then
		echo "Godot executable not found. Set GODOT_BIN to its path." >&2
		exit 2
	fi
fi

TEST_DATA_DIR="${TMPDIR:-/tmp}/app-jogos-godot-tests-${UID:-0}"
mkdir -p "$TEST_DATA_DIR"
failed_tests=()
test_count=0

while IFS= read -r test_file; do
	[[ -n "$test_file" ]] || continue
	test_count=$((test_count + 1))
	test_name="$(basename "$test_file")"
	echo "==> $test_name"
	if ! XDG_DATA_HOME="$TEST_DATA_DIR" "$GODOT_BIN" --no-window --path "$PROJECT_ROOT" -s "res://tests/$test_name"; then
		failed_tests+=("$test_name")
	fi
done < <(find "$PROJECT_ROOT/tests" -maxdepth 1 -type f -name 'test_*.gd' -print | sort)

echo "Executed $test_count test scripts."
if (( ${#failed_tests[@]} > 0 )); then
	printf 'Failed: %s\n' "${failed_tests[@]}" >&2
	exit 1
fi
echo "All automated tests passed."

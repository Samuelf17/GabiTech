extends Reference

const DIRECTIONS = [Vector2.UP, Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT]

var width: int = 21
var height: int = 15
var cells: PoolByteArray = PoolByteArray()
var _working_cells: Array = []
var rng := RandomNumberGenerator.new()


func _init(seed_value: int = 197903, maze_width: int = 21, maze_height: int = 15) -> void:
	rng.seed = seed_value
	width = maze_width
	height = maze_height
	_generate()


func _generate() -> void:
	_working_cells.resize(width * height)
	_working_cells.fill(0)

	var start := Vector2(1, 1)
	_set_open(start)
	var stack: Array = [start]
	while not stack.empty():
		var current: Vector2 = stack.back()
		var candidates: Array = []
		for direction in DIRECTIONS:
			var destination: Vector2 = current + direction * 2.0
			if _is_inside(destination) and not is_open(destination):
				candidates.append(direction)
		if candidates.empty():
			stack.pop_back()
			continue
		var direction: Vector2 = candidates[rng.randi_range(0, candidates.size() - 1)]
		_set_open(current + direction)
		var next_cell: Vector2 = current + direction * 2.0
		_set_open(next_cell)
		stack.append(next_cell)

	# A few extra openings make random hacker routes less predictable while
	# keeping every floor connected to the starting cell.
	for y in range(1, height - 1):
		for x in range(1, width - 1):
			var cell := Vector2(x, y)
			if is_open(cell) or rng.randf() > 0.12:
				continue
			var horizontal_pair: bool = is_open(cell + Vector2.LEFT) and is_open(cell + Vector2.RIGHT)
			var vertical_pair: bool = is_open(cell + Vector2.UP) and is_open(cell + Vector2.DOWN)
			if horizontal_pair or vertical_pair:
				_set_open(cell)
	cells = PoolByteArray(_working_cells)
	_working_cells.clear()


func is_open(cell: Vector2) -> bool:
	var x: int = int(cell.x)
	var y: int = int(cell.y)
	if x < 0 or x >= width or y < 0 or y >= height:
		return false
	var index: int = y * width + x
	if not _working_cells.empty():
		return int(_working_cells[index]) != 0
	return int(cells[index]) != 0


func get_open_cells() -> Array:
	var result: Array = []
	for y in range(height):
		for x in range(width):
			if is_open(Vector2(x, y)):
				result.append(Vector2(x, y))
	return result


func get_legal_directions(cell: Vector2) -> Array:
	var result: Array = []
	for direction in DIRECTIONS:
		if is_open(cell + direction):
			result.append(direction)
	return result


func _set_open(cell: Vector2) -> void:
	if _is_inside(cell):
		_working_cells[int(cell.y) * width + int(cell.x)] = 1


func _is_inside(cell: Vector2) -> bool:
	return cell.x > 0 and cell.x < width - 1 and cell.y > 0 and cell.y < height - 1


func _cell_key(cell: Vector2) -> String:
	return "%d,%d" % [int(cell.x), int(cell.y)]

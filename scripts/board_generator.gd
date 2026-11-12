extends RefCounted
## Builds the 36 numbers for a board.

const TILE_COUNT := 36
const MIN_MULTIPLES := 15
const MAX_MULTIPLES := 20
const GUIDED_MAX_FACTOR := 10


static func generate(table: int) -> Array[int]:
	var out: Array[int] = []
	# Every entry of the times table appears at least once...
	for m in range(1, 13):
		out.append(table * m)
	# ...then random repeats up to the chosen count.
	var count := randi_range(MIN_MULTIPLES, MAX_MULTIPLES)
	while out.size() < count:
		out.append(table * randi_range(1, 12))
	while out.size() < TILE_COUNT:
		out.append(_distractor(table))
	out.shuffle()
	return out


static func _distractor(table: int, max_factor: int = 12) -> int:
	for attempt in 200:
		var n: int
		if randf() < 0.6:
			# Near miss: just beside a real multiple.
			n = table * randi_range(1, max_factor) + [-2, -1, 1, 2].pick_random()
		else:
			n = randi_range(1, table * max_factor + 2)
		if n >= 1 and n % table != 0:
			return n
	return 1


## Start centrally and span every row, column and quadrant. Classic uses a few
## more multiples so the route can reach the edges without becoming cramped.
static func generate_classic(table: int, beginner: bool = false) -> Dictionary:
	var count := randi_range(MIN_MULTIPLES if beginner else 18, MAX_MULTIPLES)
	var route := _beginner_route(count) if beginner else _spread_route(count)
	var turns := randi_range(0, 3)
	var mirror := randf() < 0.5
	for i in route.size():
		var cell := route[i]
		for turn in turns:
			cell = Vector2i(5 - cell.y, cell.x)
		if mirror:
			cell.x = 5 - cell.x
		route[i] = cell
	var numbers: Array[int] = []
	for m in range(1, GUIDED_MAX_FACTOR + 1):
		numbers.append(table * m)
	while numbers.size() < count:
		numbers.append(table * randi_range(1, GUIDED_MAX_FACTOR))
	numbers.shuffle()
	var values: Array[int] = []
	for i in TILE_COUNT:
		values.append(_distractor(table, GUIDED_MAX_FACTOR))
	for i in count:
		var cell := route[i]
		values[cell.y * 6 + cell.x] = numbers[i]
	return {"values": values, "start": route[0], "route": route}


static func _spread_route(count: int) -> Array[Vector2i]:
	# Bounded randomized walks keep generation fast; the fallback guarantees the
	# same coverage even when every sampled walk gets trapped or stays too local.
	for attempt in 256:
		var path: Array[Vector2i] = [Vector2i(2, 2)]
		while path.size() < count:
			var choices: Array[Vector2i] = []
			for dir in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
				var cell: Vector2i = path[-1] + dir
				if cell.x >= 0 and cell.x < 6 and cell.y >= 0 and cell.y < 6 and not path.has(cell):
					choices.append(cell)
			if choices.is_empty():
				break
			path.append(choices.pick_random())
		if path.size() == count and _covers_grid(path):
			return path
	var fallback: Array[Vector2i] = [
		Vector2i(2, 2), Vector2i(2, 1), Vector2i(2, 0), Vector2i(3, 0),
		Vector2i(3, 1), Vector2i(3, 2), Vector2i(3, 3), Vector2i(4, 3),
		Vector2i(5, 3), Vector2i(5, 4), Vector2i(4, 4), Vector2i(3, 4),
		Vector2i(2, 4), Vector2i(2, 5), Vector2i(1, 5), Vector2i(0, 5),
		Vector2i(0, 4), Vector2i(0, 3), Vector2i(1, 3), Vector2i(1, 4)]
	fallback.resize(count)
	return fallback


static func _covers_grid(path: Array[Vector2i]) -> bool:
	var rows := {}
	var columns := {}
	var quadrants := {}
	for cell in path:
		rows[cell.y] = true
		columns[cell.x] = true
		quadrants[Vector2i(cell.x / 3, cell.y / 3)] = true
	return rows.size() == 6 and columns.size() == 6 and quadrants.size() == 4


static func generate_beginner(table: int) -> Dictionary:
	return generate_classic(table, true)


## An induced path has no shortcuts: only the previous and next multiples
## touch each cell. Blocking cleared cells leaves exactly one correct choice.
static func _beginner_route(count: int) -> Array[Vector2i]:
	for attempt in 128:
		var path: Array[Vector2i] = [Vector2i(2, 2)]
		while path.size() < count:
			var choices: Array[Vector2i] = []
			for dir in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
				var cell: Vector2i = path[-1] + dir
				if cell.x < 0 or cell.x > 5 or cell.y < 0 or cell.y > 5 or path.has(cell):
					continue
				var shortcut := false
				for i in path.size() - 1:
					var delta := cell - path[i]
					if absi(delta.x) + absi(delta.y) == 1:
						shortcut = true
						break
				if not shortcut:
					choices.append(cell)
			if choices.is_empty():
				break
			path.append(choices.pick_random())
		if path.size() == count:
			return path
	var fallback: Array[Vector2i] = [
		Vector2i(2, 2), Vector2i(2, 3), Vector2i(3, 3), Vector2i(4, 3),
		Vector2i(5, 3), Vector2i(5, 4), Vector2i(5, 5), Vector2i(4, 5),
		Vector2i(3, 5), Vector2i(2, 5), Vector2i(1, 5), Vector2i(0, 5),
		Vector2i(0, 4), Vector2i(0, 3), Vector2i(0, 2), Vector2i(0, 1),
		Vector2i(1, 1), Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0)]
	fallback.resize(count)
	return fallback

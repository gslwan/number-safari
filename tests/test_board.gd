extends SceneTree
## Run: godot --headless -s tests/test_board.gd

const BoardGenerator := preload("res://scripts/board_generator.gd")


func _init() -> void:
	var failures := 0
	for table in range(2, 13):
		var counts := {}
		for run in 1000:
			var board := BoardGenerator.generate(table)
			var multiples := 0
			var seen := {}
			for v in board:
				if v % table == 0:
					multiples += 1
					seen[v / table] = true
					if v < table or v > table * 12:
						failures += 1
						print("FAIL table %d: multiple %d outside the table" % [table, v])
				elif v < 1:
					failures += 1
					print("FAIL table %d: bad distractor %d" % [table, v])
			counts[multiples] = true
			if board.size() != 36 or multiples < 15 or multiples > 20 or seen.size() != 12:
				failures += 1
				print("FAIL table %d: size=%d multiples=%d distinct=%d"
						% [table, board.size(), multiples, seen.size()])
		var keys := counts.keys()
		keys.sort()
		print("table %2d ok, multiple counts seen: %s" % [table, keys])
	print("FAILURES: %d" % failures)
	quit(1 if failures > 0 else 0)

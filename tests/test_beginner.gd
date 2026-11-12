extends SceneTree
const Generator := preload("res://scripts/board_generator.gd")
var failures := 0

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		printerr(message)

func _initialize() -> void:
	call_deferred("run")

func settle(game: Node) -> void:
	for i in 1000:
		if not game.busy:
			return
		await process_frame
	check(false, "Movement timed out")

func run() -> void:
	for table in range(2, 13):
		for trial in 200:
			var board := Generator.generate_beginner(table)
			var seen := {}
			var factors := {}
			check(board.route.size() >= 15 and board.route.size() <= 20, "Multiple count")
			for i in board.route.size():
				var cell: Vector2i = board.route[i]
				check(not seen.has(cell), "No revisits")
				seen[cell] = true
				var value: int = board.values[cell.y * 6 + cell.x]
				check(value % table == 0, "Route contains multiples")
				check(value >= table and value <= table * 10, "Multiples limited to x1 through x10")
				factors[value / table] = true
				var forward := 0
				for j in range(i + 1, board.route.size()):
					var delta: Vector2i = board.route[j] - cell
					if absi(delta.x) + absi(delta.y) == 1:
						forward += 1
						check(j == i + 1, "No shortcut to later multiples")
				check(forward == (0 if i == board.route.size() - 1 else 1), "Exactly one next adjacent multiple")
			check(factors.size() == 10, "All times-table factors represented")
			for i in 36:
				check((board.values[i] % table == 0) == seen.has(Vector2i(i % 6, i / 6)), "Every multiple reachable")
	Engine.time_scale = 10.0
	change_scene_to_file("res://scenes/main.tscn")
	await process_frame
	await process_frame
	var main = root.get_node("Main")
	seed(218)
	var board := Generator.generate_beginner(7)
	seed(218)
	main.start_game(7, "Beginner")
	var game = main.current
	# Avoid writing a completed test round to the player's history.
	var history = root.get_node("GameHistory")
	var saved_records: Array = history.records.duplicate(true)
	var path := "user://history.json"
	var existed := FileAccess.file_exists(path)
	var saved_bytes := FileAccess.get_file_as_bytes(path) if existed else PackedByteArray()
	check(game.eaten == 1, "Start automatically collected")
	var start: Vector2i = game.cub_cell
	game._move(Vector2i(2, 0))
	check(game.cub_cell == start, "Only adjacent movement")
	game._eat()
	check(game.eaten == 1, "Manual eating disabled")
	for dir in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
		var cell: Vector2i = start + dir
		if game.values[cell.y * 6 + cell.x] % 7 != 0:
			game._move(dir)
			await settle(game)
			check(game.cub_cell == start and game.mistakes == 1, "Wrong step rejected")
			check(game.tiles[cell.y * 6 + cell.x].alive, "Wrong tile remains")
			break
	for i in range(1, board.route.size()):
		game._move(board.route[i] - game.cub_cell)
		await settle(game)
		check(game.eaten == i + 1, "Forward step collected once")
		check(game._growth_level == game.eaten - game.mistakes, "Forward step grows from penalized level")
		var current: Vector2i = game.cub_cell
		game._move(board.route[i - 1] - current)
		check(game.cub_cell == current and not game.busy, "Backtracking blocked")
	check(game.finished and game.remaining == 0, "Completes without backtracking")
	await create_timer(3.0).timeout
	var expected_growth: float = float(game.total - game.mistakes) / game.total
	check(is_equal_approx(game.cub.growth_progress, expected_growth), "Mistake penalties persist at completion")
	check(is_equal_approx(game.cub._mane.scale.x, lerpf(0.45, 1.0, expected_growth)), "Mane retains growth penalties")
	game.replay_requested.emit()
	check(main.current.mode == "Beginner", "Replay keeps Beginner")
	history.records = saved_records
	if existed:
		var file := FileAccess.open(path, FileAccess.WRITE)
		if file:
			file.store_buffer(saved_bytes)
	elif FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)
	print("BEGINNER TEST failures=", failures)
	quit(0 if failures == 0 else 1)

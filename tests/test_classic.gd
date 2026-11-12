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
	var starts := {}
	for table in range(2, 13):
		for trial in 200:
			var board := Generator.generate_classic(table)
			var seen := {}
			var factors := {}
			starts[board.start] = true
			check(board.start.x in [2, 3] and board.start.y in [2, 3], "Starts in middle")
			check(Generator._covers_grid(board.route), "Route spans all rows, columns and quadrants")
			check(board.route.size() >= 18 and board.route.size() <= 20, "Multiple count")
			for i in board.route.size():
				var cell: Vector2i = board.route[i]
				check(cell.x >= 0 and cell.x < 6 and cell.y >= 0 and cell.y < 6, "Inside grid")
				check(not seen.has(cell), "Route has no duplicate cells")
				seen[cell] = true
				var value: int = board.values[cell.y * 6 + cell.x]
				check(value % table == 0, "Route contains only multiples")
				check(value >= table and value <= table * 10, "Multiples limited to x1 through x10")
				factors[value / table] = true
				if i > 0:
					var delta: Vector2i = cell - board.route[i - 1]
					check(absi(delta.x) + absi(delta.y) == 1, "Route uses adjacent cells")
			check(factors.size() == 10, "Every times-table factor appears")
			for i in 36:
				check((board.values[i] % table == 0) == seen.has(Vector2i(i % 6, i / 6)), "All multiples on route")
	check(starts.size() == 4, "All four center cells can be a start")
	var history_path := "user://history.json"
	var had_history := FileAccess.file_exists(history_path)
	var history_bytes := FileAccess.get_file_as_bytes(history_path) if had_history else PackedByteArray()
	Engine.time_scale = 10.0
	change_scene_to_file("res://scenes/main.tscn")
	await process_frame
	await process_frame
	var main = root.get_node("Main")
	check(main.current.mode == "Beginner", "Beginner selected by default")
	main.start_game(7)
	check(main.current.mode == "Beginner", "Default game is Beginner")
	seed(428)
	var board := Generator.generate_classic(7)
	seed(428)
	main.start_game(7, "Classic")
	var game = main.current
	check(game.cub_cell == board.start, "Uses generated start")
	check(game.eaten == 1, "Starting tile collected")
	game._eat()
	check(game.eaten == 1, "Manual eating disabled")
	var tested_wrong := false
	for i in board.route.size():
		if i > 0:
			game._move(board.route[i] - game.cub_cell)
			await settle(game)
		check(game.eaten == i + 1, "Exactly one collection per new tile")
		check(game._growth_level == game.eaten - game.mistakes, "Correct answer adds only one growth step after penalties")
		if i == 1:
			game._move(board.route[0] - game.cub_cell)
			await settle(game)
			game._move(board.route[1] - game.cub_cell)
			await settle(game)
			check(game.eaten == 2 and game.mistakes == (2 if tested_wrong else 0), "Cleared tiles safe and counted once")
		if i >= 3 and not tested_wrong and not game.finished:
			for dir in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
				var cell: Vector2i = game.cub_cell + dir
				if cell.x < 0 or cell.x > 5 or cell.y < 0 or cell.y > 5:
					continue
				var tile = game.tiles[cell.y * 6 + cell.x]
				if tile.value % 7 == 0:
					continue
				var origin: Vector2i = game.cub_cell
				for attempt in 2:
					game._move(dir)
					check(game.busy, "Input blocked during rejected move")
					game._move(-dir)
					await settle(game)
					check(game.cub_cell == origin, "Wrong step returns to previous cell")
					check(game.cub.position.is_equal_approx(game._cell_pos(origin)), "Visual position returns")
					check(tile.alive, "Wrong number preserved")
					check(is_equal_approx(game.cub.growth_progress, float(maxi(0, i - attempt)) / game.total), "Each mistake rolls back one growth step")
					check(game.mistakes == attempt + 1, "Repeated wrong step counts")
				tested_wrong = true
				break
	check(tested_wrong, "Exercised wrong steps")
	check(game.finished and game.remaining == 0, "Classic completes using only movement")
	await create_timer(3.0).timeout
	var expected_growth: float = float(game.total - game.mistakes) / game.total
	check(is_equal_approx(game.cub.growth_progress, expected_growth), "Mistake penalties persist at completion")
	check(is_equal_approx(game.cub._mane.scale.x, lerpf(0.45, 1.0, expected_growth)), "Mane retains growth penalties")
	game.replay_requested.emit()
	check(main.current.mode == "Classic", "Replay preserves mode")
	main.show_menu()
	check(main.current.mode == "Classic", "Menu preserves mode")
	main.start_game(7, "Freestyle")
	game = main.current
	check(game.eaten == 0, "Freestyle does not eat starting tile")
	var target := 0
	while game.values[target] % 7 != 0:
		target += 1
	game.cub_cell = Vector2i(target % 6, target / 6)
	game.cub.position = game._cell_pos(game.cub_cell)
	game._eat()
	check(game.eaten == 1, "Freestyle manual eating retained")
	if had_history:
		var saved := FileAccess.open(history_path, FileAccess.WRITE)
		if saved:
			saved.store_buffer(history_bytes)
	elif FileAccess.file_exists(history_path):
		DirAccess.remove_absolute(history_path)
	print("CLASSIC TEST failures=", failures)
	quit(0 if failures == 0 else 1)

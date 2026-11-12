extends SceneTree
## Scripted playthrough that saves screenshots.
## Run: godot -s tests/demo.gd -- --out=/some/folder

var out_dir := "."


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out_dir = a.substr(6)
	_run()


func _run() -> void:
	change_scene_to_file("res://scenes/main.tscn")
	await _wait(0.6)
	await _shot("1_menu")
	var main = root.get_node("Main")
	main.start_game(7, "Freestyle")
	await _wait(0.4)
	var game = main.current
	await _shot("2_start")

	var wrong := -1
	var right: Array[int] = []
	for i in 36:
		if game.values[i] % 7 == 0:
			right.append(i)
		elif wrong < 0:
			wrong = i
	await _goto(game, wrong)
	game._eat()
	game._eat()  # second bite must do nothing
	await _wait(0.6)
	await _shot("3_stomach_ache")
	await _wait(2.0)
	assert(game.mistakes == 1)

	for n in right.size():
		await _goto(game, right[n])
		game._eat()
		game._eat()
		await _wait(0.12)
		if n == 8:
			await _wait(0.4)
			await _shot("4_midgame")
	assert(game.finished and game.remaining == 0)
	await _wait(0.9)
	await _shot("5_confetti")
	await _wait(2.2)
	await _shot("6_clear")
	print("DEMO OK mistakes=%d eaten=%d total=%d" % [game.mistakes, game.eaten, game.total])
	main.show_history()
	await _wait(0.4)
	await _shot("7_history")
	quit()


func _goto(game, idx: int) -> void:
	var target := Vector2i(idx % 6, idx / 6)
	while game.cub_cell != target:
		var d: Vector2i = target - game.cub_cell
		game._move(Vector2i(signi(d.x), 0) if d.x != 0 else Vector2i(0, signi(d.y)))
		await _wait(0.03)
	await _wait(0.2)


func _wait(s: float) -> void:
	await create_timer(s).timeout


func _shot(name: String) -> void:
	await process_frame
	root.get_texture().get_image().save_png(out_dir.path_join(name + ".png"))

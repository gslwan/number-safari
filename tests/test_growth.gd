extends SceneTree
const Lion := preload("res://scripts/lion_cub.gd")
var failures := 0
func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		printerr(message)
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var cub := Lion.new()
	root.add_child(cub)
	check(not cub._mane.visible, "New cub has no mane")
	var start_size := cub._rig.scale.x
	cub.eat_good(0.25)
	await create_timer(0.6).timeout
	check(is_equal_approx(cub.growth_progress, 0.25), "Quarter growth")
	check(cub._rig.scale.x > start_size, "Body grows")
	var small_mane := cub._mane.scale.x
	cub.eat_good(0.5)
	await create_timer(0.1).timeout
	cub.move_to(Vector2(100, 100), Vector2i.RIGHT)
	await create_timer(0.6).timeout
	check(is_equal_approx(cub.growth_progress, 0.5), "Movement preserves growth")
	check(cub._mane.scale.x > small_mane, "Mane grows gradually")
	var grown_body := cub._rig.scale.x
	var grown_mane := cub._mane.scale.x
	cub.animate_growth(0.25)
	await cub.stomach_ache()
	check(is_equal_approx(cub.growth_progress, 0.25), "Mistake rolls growth back")
	check(cub._rig.scale.x < grown_body and cub._mane.scale.x < grown_mane, "Both body and mane shrink")
	cub.animate_growth(-0.25)
	await create_timer(0.6).timeout
	check(cub.growth_progress == 0.0 and not cub._mane.visible, "Shrink stops at original cub size")
	cub.eat_good(0.75)
	await create_timer(0.05).timeout
	cub.eat_good(1.0)
	cub.celebrate()
	await create_timer(0.6).timeout
	check(is_equal_approx(cub.growth_progress, 1.0), "Rapid eating and victory finish growth")
	check(cub._mane.scale.is_equal_approx(Vector2.ONE) and cub._mane.modulate.a == 1.0, "Full mane")
	check(is_equal_approx(cub._rig.scale.x, Lion.BASE_SCALE * Lion.FULL_GROW), "Full body size")
	await create_timer(1.6).timeout
	cub.queue_free()
	await process_frame
	print("GROWTH TEST failures=", failures)
	quit(0 if failures == 0 else 1)

extends Control
## One round: the board, the cub, the HUD and the stage-clear celebration.

signal menu_requested
signal replay_requested

const BoardGenerator := preload("res://scripts/board_generator.gd")
const Tile := preload("res://scripts/tile.gd")
const LionCub := preload("res://scripts/lion_cub.gd")

const GRID := 6
const STEP := 106.0                     # tile size + gap
const BOARD_PX := STEP * GRID - 6.0
const BOARD_POS := Vector2(600, 45)
const INK := Color("4a2c0a")
const CREAM := Color("fff6dc")

var table := 2
var mode := "Beginner"
var values: Array[int] = []
var tiles: Array = []
var cub_cell := Vector2i.ZERO
var total := 0
var eaten := 0
var _growth_level := 0
var remaining := 0
var mistakes := 0
var busy := false       # true during the stomach ache
var finished := false

var cub: LionCub
var _board: Node2D
var _badge: Label
var _hud: VBoxContainer
var _left_label: Label
var _mistake_label: Label
var _move_tween: Tween
var _start_ms := 0
var _stars: Control
var _stars_earned := 0
var _stars_shown := 0


func _ready() -> void:
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	if mode != "Freestyle":
		var board := BoardGenerator.generate_beginner(table) if mode == "Beginner" else BoardGenerator.generate_classic(table)
		values = board.values
		cub_cell = board.start
	else:
		values = BoardGenerator.generate(table)
		cub_cell = Vector2i(randi_range(0, GRID - 1), randi_range(0, GRID - 1))
	for v in values:
		if v % table == 0:
			total += 1
	remaining = total
	_build_board()
	_build_hud()
	_update_hud()
	_update_badge()
	_start_ms = Time.get_ticks_msec()
	if mode != "Freestyle":
		_collect(tiles[cub_cell.y * GRID + cub_cell.x])


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		menu_requested.emit()
	elif event.is_action_pressed("move_up", true):
		_move(Vector2i.UP)
	elif event.is_action_pressed("move_down", true):
		_move(Vector2i.DOWN)
	elif event.is_action_pressed("move_left", true):
		_move(Vector2i.LEFT)
	elif event.is_action_pressed("move_right", true):
		_move(Vector2i.RIGHT)
	elif mode == "Freestyle" and event.is_action_pressed("eat"):
		_eat()


func _move(dir: Vector2i) -> void:
	if busy or finished or absi(dir.x) + absi(dir.y) != 1:
		return
	var target := (cub_cell + dir).clamp(Vector2i.ZERO, Vector2i(GRID - 1, GRID - 1))
	if target == cub_cell:
		return
	if mode == "Beginner" and not tiles[target.y * GRID + target.x].alive:
		return
	if mode != "Freestyle":
		_move_classic(target, dir)
		return
	cub_cell = target
	if _move_tween:
		_move_tween.kill()
	_move_tween = cub.move_to(_cell_pos(target), dir)
	Sfx.play("step", randf_range(0.95, 1.1), -6.0)
	_update_badge()


func _eat() -> void:
	if busy or finished or mode != "Freestyle":
		return
	var tile: Tile = tiles[cub_cell.y * GRID + cub_cell.x]
	if not tile.alive:
		return
	if tile.value % table == 0:
		_collect(tile)
	else:
		mistakes += 1
		_rollback_growth()
		tile.eat_bad()  # the number is gone, so it cannot be eaten twice
		Sfx.play("bad")
		_update_hud()
		_update_badge()
		var t := create_tween()
		t.tween_property(_mistake_label, "modulate", Color("ff8a7a"), 0.1)
		t.tween_property(_mistake_label, "modulate", Color.WHITE, 0.6)
		busy = true
		await cub.stomach_ache()
		busy = false


func _stage_clear() -> void:
	finished = true
	var seconds := (Time.get_ticks_msec() - _start_ms) / 1000.0
	GameHistory.add(table, mistakes, seconds, mode)
	Sfx.play("win")
	cub.celebrate()
	for i in tiles.size():
		tiles[i].celebrate((i % GRID + i / GRID) * 0.05)
	_confetti(Vector2(640, -20), 260, false)
	_confetti(BOARD_POS + cub.position, 60, true)
	await get_tree().create_timer(1.3).timeout
	_show_clear_panel(seconds)


# ---------- building ----------

func _cell_pos(cell: Vector2i) -> Vector2:
	return Vector2(cell.x * STEP + 50.0, cell.y * STEP + 50.0)


func _build_board() -> void:
	var back := Panel.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("2c5d40")
	sb.set_corner_radius_all(26)
	back.add_theme_stylebox_override("panel", sb)
	back.position = BOARD_POS - Vector2(16, 16)
	back.size = Vector2(BOARD_PX + 32, BOARD_PX + 32)
	add_child(back)

	_board = Node2D.new()
	_board.position = BOARD_POS
	add_child(_board)
	for i in values.size():
		var cell := Vector2i(i % GRID, i / GRID)
		var tile := Tile.new()
		tile.setup(values[i], (cell.x + cell.y) % 2 == 1)
		tile.position = _cell_pos(cell)
		_board.add_child(tile)
		tiles.append(tile)

	cub = LionCub.new()
	cub.position = _cell_pos(cub_cell)
	_board.add_child(cub)

	# The cub covers the number it is standing on, so show it in a tag above.
	_badge = Label.new()
	var tag := StyleBoxFlat.new()
	tag.bg_color = Color.WHITE
	tag.set_corner_radius_all(10)
	tag.set_border_width_all(3)
	tag.border_color = INK
	_badge.add_theme_stylebox_override("normal", tag)
	_badge.add_theme_color_override("font_color", INK)
	_badge.add_theme_font_override("font", ThemeDB.fallback_font)  # Node2D parent breaks theme inheritance
	_badge.add_theme_font_size_override("font_size", 24)
	_badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_badge.size = Vector2(64, 36)
	_badge.position = Vector2(-32, -70)
	cub.add_child(_badge)


func _build_hud() -> void:
	_hud = VBoxContainer.new()
	_hud.position = Vector2(40, 40)
	_hud.size = Vector2(500, 640)
	_hud.add_theme_constant_override("separation", 6)
	add_child(_hud)
	_hud.add_child(_label(mode, 26, Color("ffd166")))
	_hud.add_child(_label("Eat the multiples of", 34, CREAM))
	_hud.add_child(_label(str(table), 150, Color("ffd166")))
	_left_label = _label("", 32, CREAM)
	_hud.add_child(_left_label)
	_mistake_label = _label("", 32, CREAM)
	_hud.add_child(_mistake_label)
	var gap := Control.new()
	gap.size_flags_vertical = SIZE_EXPAND_FILL
	_hud.add_child(gap)
	var help := "Arrow keys or WASD: move\nSpace or Enter: eat"
	if mode != "Freestyle":
		help = "Arrow keys or WASD: move & eat\nWrong number? Back you go!\nCleared tiles are safe to cross."
	if mode == "Beginner":
		help = "Arrow keys or WASD: move & eat\nChoose an adjacent multiple.\nNo going back to cleared tiles!"
	_hud.add_child(_label(help, 22, Color("cfe6d3")))
	var btn := Button.new()
	btn.text = "Menu (Esc)"
	btn.focus_mode = FOCUS_NONE  # keep Space/Enter/arrows for the game
	btn.size_flags_horizontal = SIZE_SHRINK_CENTER
	btn.pressed.connect(func(): menu_requested.emit())
	_hud.add_child(btn)


func _update_hud() -> void:
	_left_label.text = "Left to eat: %d" % remaining
	_mistake_label.text = "Mistakes: %d" % mistakes


func _update_badge() -> void:
	var tile: Tile = tiles[cub_cell.y * GRID + cub_cell.x]
	_badge.visible = tile.alive and not finished
	_badge.text = str(tile.value)


func _label(text: String, font_size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	return l


# ---------- stage clear ----------

func _confetti(at: Vector2, amount: int, burst: bool) -> void:
	var p := CPUParticles2D.new()
	p.position = at
	p.z_index = 10
	p.amount = amount
	p.lifetime = 4.5
	p.gravity = Vector2(0, 260)
	p.angular_velocity_min = -360.0
	p.angular_velocity_max = 360.0
	p.scale_amount_min = 7.0
	p.scale_amount_max = 14.0
	var ramp := Gradient.new()
	ramp.offsets = PackedFloat32Array([0.0, 0.2, 0.4, 0.6, 0.8, 1.0])
	ramp.colors = PackedColorArray([
		Color("ff595e"), Color("ffca3a"), Color("8ac926"),
		Color("1982c4"), Color("c77dff"), Color("ffffff")])
	p.color_initial_ramp = ramp
	if burst:
		p.one_shot = true
		p.explosiveness = 1.0
		p.direction = Vector2(0, -1)
		p.spread = 70.0
		p.initial_velocity_min = 180.0
		p.initial_velocity_max = 420.0
	else:
		p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
		p.emission_rect_extents = Vector2(640, 10)
		p.direction = Vector2(0, 1)
		p.spread = 25.0
		p.initial_velocity_min = 40.0
		p.initial_velocity_max = 160.0
	add_child(p)
	p.emitting = true


func _show_clear_panel(seconds: float) -> void:
	_hud.hide()
	# Sits on the left so the dancing cub stays in view.
	var holder := CenterContainer.new()
	holder.position = Vector2(20, 0)
	holder.size = Vector2(540, 720)
	holder.pivot_offset = holder.size / 2
	add_child(holder)
	var panel := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = CREAM
	sb.set_corner_radius_all(30)
	sb.set_border_width_all(6)
	sb.border_color = Color("ffd166")
	sb.set_content_margin_all(34)
	panel.add_theme_stylebox_override("panel", sb)
	holder.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	panel.add_child(box)

	box.add_child(_label("Stage Clear!", 62, Color("e07a1f")))
	_stars_earned = 3 if mistakes == 0 else (2 if mistakes <= 2 else 1)
	_stars = Control.new()
	_stars.custom_minimum_size = Vector2(330, 110)
	_stars.draw.connect(_draw_stars)
	box.add_child(_stars)
	var verdict := "Perfect! Impressive!" if mistakes == 0 else "Mistakes: %d" % mistakes
	box.add_child(_label(verdict, 30, INK))
	var secs := int(seconds)
	box.add_child(_label("You ate all %d multiples of %d\nTime: %d:%02d"
			% [total, table, secs / 60, secs % 60], 24, INK))
	var again := Button.new()
	again.text = "Play Again"
	again.custom_minimum_size = Vector2(0, 76)
	again.add_theme_font_size_override("font_size", 32)
	again.pressed.connect(func(): replay_requested.emit())
	box.add_child(again)
	var menu := Button.new()
	menu.text = "Change Table"
	menu.pressed.connect(func(): menu_requested.emit())
	box.add_child(menu)

	holder.scale = Vector2(0.2, 0.2)
	var t := create_tween()
	t.tween_property(holder, "scale", Vector2.ONE, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	for i in _stars_earned:
		t.tween_interval(0.22)
		t.tween_callback(_pop_star.bind(i))
	t.tween_callback(again.grab_focus)


func _pop_star(i: int) -> void:
	_stars_shown = i + 1
	_stars.queue_redraw()
	Sfx.play("star", 1.0 + 0.15 * i)


func _draw_stars() -> void:
	for i in 3:
		var c := Vector2(55 + 110 * i, 55)
		var pts := PackedVector2Array()
		for k in 10:
			var a := -PI / 2 + k * PI / 5
			pts.append(c + Vector2(cos(a), sin(a)) * (48.0 if k % 2 == 0 else 21.0))
		var lit := i < _stars_shown
		_stars.draw_colored_polygon(pts, Color("ffc300") if lit else Color("e3d9c3"))
		pts.append(pts[0])
		_stars.draw_polyline(pts, Color("d98f2b") if lit else Color("cdbfa3"), 3.0, true)


func _collect(tile: Tile) -> void:
	if not tile.alive:
		return
	eaten += 1
	remaining -= 1
	tile.eat_good()
	_growth_level += 1
	cub.eat_good(float(_growth_level) / total)
	Sfx.play("good", 0.9 + 0.5 * eaten / total)
	_update_hud()
	_update_badge()
	_update_beginner_choices()
	if remaining == 0:
		_stage_clear()


func _move_classic(target: Vector2i, dir: Vector2i) -> void:
	busy = true
	var previous := cub_cell
	cub_cell = target
	_move_tween = cub.move_to(_cell_pos(target), dir)
	Sfx.play("step", randf_range(0.95, 1.1), -6.0)
	_update_badge()
	await _move_tween.finished
	var tile: Tile = tiles[target.y * GRID + target.x]
	if tile.value % table == 0:
		_collect(tile)
	else:
		mistakes += 1
		_rollback_growth()
		tile.reject_step()
		Sfx.play("bad")
		_update_hud()
		await cub.stomach_ache()
		cub_cell = previous
		_move_tween = cub.move_to(_cell_pos(previous), -dir)
		_update_badge()
		await _move_tween.finished
	busy = false


func _update_beginner_choices() -> void:
	if mode != "Beginner":
		return
	for i in tiles.size():
		var delta := Vector2i(i % GRID, i / GRID) - cub_cell
		var adjacent := absi(delta.x) + absi(delta.y) == 1
		tiles[i].modulate.a = 1.0 if adjacent and tiles[i].alive else 0.45


## Roll back one collected-number size; repeated mistakes can return to cub size.
## Each successful bite adds one step from this penalized level.
func _rollback_growth() -> void:
	_growth_level = maxi(0, _growth_level - 1)
	cub.animate_growth(float(_growth_level) / total)

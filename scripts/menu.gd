extends Control
## Title screen: choose a times table, then play.

signal play(table: int, mode: String)
signal history

const LionCub := preload("res://scripts/lion_cub.gd")

var table := 2
var mode := "Beginner"


func _ready() -> void:
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)

	var cub := LionCub.new()
	cub.position = Vector2(170, 300)
	cub.scale = Vector2(3.2, 3.2)
	add_child(cub)
	cub._set_eyes("happy")

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	add_child(center)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	center.add_child(box)

	box.add_child(_label("Number Safari", 84, Color("ffd166")))
	box.add_child(_label("Help the lion cub eat every multiple!", 28))
	var modes := HBoxContainer.new()
	modes.alignment = BoxContainer.ALIGNMENT_CENTER
	modes.add_theme_constant_override("separation", 16)
	box.add_child(modes)
	var mode_group := ButtonGroup.new()
	for choice in ["Beginner", "Classic", "Freestyle"]:
		var button := Button.new()
		button.text = choice
		button.toggle_mode = true
		button.button_group = mode_group
		button.button_pressed = mode == choice
		button.pressed.connect(func(): mode = choice)
		modes.add_child(button)
	box.add_child(_label("Pick a times table", 30))

	var grid := GridContainer.new()
	grid.columns = 6
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	grid.size_flags_horizontal = SIZE_SHRINK_CENTER
	box.add_child(grid)
	var group := ButtonGroup.new()
	for n in range(2, 13):
		var b := Button.new()
		b.text = str(n)
		b.toggle_mode = true
		b.button_group = group
		b.custom_minimum_size = Vector2(92, 74)
		b.add_theme_font_size_override("font_size", 34)
		b.button_pressed = n == table
		b.pressed.connect(_pick.bind(n))
		grid.add_child(b)

	box.add_child(_spacer(10))
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 24)
	box.add_child(row)
	var play_btn := Button.new()
	play_btn.text = "Play!"
	play_btn.custom_minimum_size = Vector2(260, 86)
	play_btn.add_theme_font_size_override("font_size", 40)
	play_btn.pressed.connect(func(): play.emit(table, mode))
	row.add_child(play_btn)
	var hist_btn := Button.new()
	hist_btn.text = "History"
	hist_btn.custom_minimum_size = Vector2(180, 86)
	hist_btn.pressed.connect(func(): history.emit())
	row.add_child(hist_btn)
	play_btn.grab_focus.call_deferred()


func _pick(n: int) -> void:
	table = n
	Sfx.play("click")


func _label(text: String, font_size: int, color := Color("fff6dc")) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	return l


func _spacer(h: float) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(0, h)
	return c

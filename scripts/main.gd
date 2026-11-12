extends Control
## Root of the game: sets up input, look and feel, and swaps between screens.

const MenuScreen := preload("res://scripts/menu.gd")
const GameScreen := preload("res://scripts/game.gd")
const HistoryScreen := preload("res://scripts/history_screen.gd")

const INK := Color("4a2c0a")
const CREAM := Color("fff6dc")
const GOLD := Color("ffd166")

var table := 2
var mode := "Beginner"
var current: Control


func _ready() -> void:
	_setup_input()
	var font := SystemFont.new()
	font.font_names = PackedStringArray(["Arial Rounded MT Bold", "Segoe UI", "Verdana", "Arial"])
	font.font_weight = 700
	ThemeDB.fallback_font = font
	theme = _make_theme(font)
	show_menu()


func show_menu() -> void:
	var menu := MenuScreen.new()
	menu.table = table
	menu.mode = mode
	menu.play.connect(start_game)
	menu.history.connect(show_history)
	_swap(menu)


func start_game(for_table: int, for_mode: String = "Beginner") -> void:
	table = for_table
	mode = for_mode
	var game := GameScreen.new()
	game.table = table
	game.mode = mode
	game.menu_requested.connect(show_menu)
	game.replay_requested.connect(start_game.bind(table, mode))
	_swap(game)


func show_history() -> void:
	var screen := HistoryScreen.new()
	screen.back.connect(show_menu)
	_swap(screen)


func _swap(screen: Control) -> void:
	if current:
		current.queue_free()
	current = screen
	add_child(screen)


func _setup_input() -> void:
	_add_action("move_up", [KEY_UP, KEY_W])
	_add_action("move_down", [KEY_DOWN, KEY_S])
	_add_action("move_left", [KEY_LEFT, KEY_A])
	_add_action("move_right", [KEY_RIGHT, KEY_D])
	_add_action("eat", [KEY_SPACE, KEY_ENTER, KEY_KP_ENTER])


func _add_action(action: String, keys: Array) -> void:
	if InputMap.has_action(action):
		return
	InputMap.add_action(action)
	for key in keys:
		var ev := InputEventKey.new()
		ev.physical_keycode = key
		InputMap.action_add_event(action, ev)


func _make_theme(font: Font) -> Theme:
	var th := Theme.new()
	th.default_font = font
	th.default_font_size = 26
	th.set_color("font_color", "Label", CREAM)
	var fills := {
		"normal": GOLD,
		"hover": Color("ffe08f"),
		"pressed": Color("ff9f1c"),
		"hover_pressed": Color("ffab3d"),
		"disabled": Color("cfc7b0"),
	}
	for state in fills:
		var sb := StyleBoxFlat.new()
		sb.bg_color = fills[state]
		sb.set_corner_radius_all(16)
		sb.border_color = (fills[state] as Color).darkened(0.25)
		sb.border_width_bottom = 5
		sb.content_margin_left = 26
		sb.content_margin_right = 26
		sb.content_margin_top = 12
		sb.content_margin_bottom = 14
		th.set_stylebox(state, "Button", sb)
	var focus := StyleBoxFlat.new()
	focus.bg_color = Color(0, 0, 0, 0)
	focus.set_corner_radius_all(16)
	focus.set_border_width_all(4)
	focus.border_color = Color.WHITE
	focus.set_expand_margin_all(3)
	th.set_stylebox("focus", "Button", focus)
	for c in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color",
			"font_hover_pressed_color"]:
		th.set_color(c, "Button", INK)
	return th

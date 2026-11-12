extends Node2D
## One square of the board. Origin is the tile centre.

const SIZE := 100.0
const INK := Color("4a2c0a")
const GOOD_BG := Color("c9ecae")
const BAD_BG := Color("f4c3b8")

var value := 0
var alive := true  # still has a number that can be eaten

var bg := Color.WHITE:
	set(v):
		bg = v
		queue_redraw()
var num_scale := 1.0:
	set(v):
		num_scale = v
		queue_redraw()
var num_color := INK:
	set(v):
		num_color = v
		queue_redraw()


func setup(number: int, dark: bool) -> void:
	value = number
	bg = Color("f3dba6") if dark else Color("fff1cf")


func _draw() -> void:
	var box := StyleBoxFlat.new()
	box.bg_color = bg
	box.set_corner_radius_all(14)
	box.border_color = bg.darkened(0.14)
	box.border_width_bottom = 5
	draw_style_box(box, Rect2(-SIZE / 2, -SIZE / 2, SIZE, SIZE))
	if num_scale > 0.01:
		var font := ThemeDB.fallback_font
		var fs := 42
		var y := (font.get_ascent(fs) - font.get_descent(fs)) / 2.0
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(num_scale, num_scale))
		draw_string(font, Vector2(-SIZE / 2, y), str(value), HORIZONTAL_ALIGNMENT_CENTER, SIZE, fs, num_color)


func eat_good() -> void:
	alive = false
	var t := create_tween()
	t.tween_property(self, "num_scale", 1.5, 0.08)
	t.tween_property(self, "num_scale", 0.0, 0.16)
	t.parallel().tween_property(self, "bg", GOOD_BG, 0.16)


func eat_bad() -> void:
	alive = false
	num_color = Color("c0392b")
	var x := position.x
	var t := create_tween()
	for dx in [7.0, -7.0, 5.0, -5.0, 0.0]:
		t.tween_property(self, "position:x", x + dx, 0.04)
	t.tween_property(self, "num_scale", 0.0, 0.25)
	t.parallel().tween_property(self, "bg", BAD_BG, 0.25)


func celebrate(delay: float) -> void:
	var t := create_tween()
	t.tween_interval(delay)
	t.tween_property(self, "scale", Vector2(1.14, 1.14), 0.12)
	t.tween_property(self, "scale", Vector2.ONE, 0.18)
	if alive:
		t.parallel().tween_property(self, "num_color:a", 0.25, 0.3)


## Classic mistakes leave the number in place, so it never becomes a shortcut.
func reject_step() -> void:
	var original := bg
	var t := create_tween()
	t.tween_property(self, "bg", BAD_BG, 0.1)
	t.tween_property(self, "bg", original, 0.4)

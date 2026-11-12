extends Node2D
## The lion cub: a rig of body-part sprites animated with tweens.
##
## Node layout:  Player (tile centre) > _rig (growth scale, origin at the feet)
##               > _pose (hop / squash / wobble / facing) > parts.

const CELL := 100.0
const ART := "res://assets/characters/lion_cub/"
const FEET_Y := 42.0       # Match the base game’s feet position within a tile.
const BASE_SCALE := 0.36
const BASE_GROW := 1.0
const FULL_GROW := 1.5
const MOVE_TIME := 0.18
const HEAD_POS := Vector2(-40, -90)   # neck joint
const TAIL_JOINT := Vector2(54, -76)
const SWEAT_POS := Vector2(-18, -168)
const SICK_TINT := Color(0.74, 1.0, 0.6)

var _rig: Node2D
var _pose: Node2D
var _tail: Sprite2D
var _leg_nf: Sprite2D   # near front
var _leg_ff: Sprite2D   # far front
var _leg_nh: Sprite2D   # near hind
var _leg_fh: Sprite2D   # far hind
var _head: Node2D
var _mane: Sprite2D
var _eyes: Sprite2D
var _mouth: Sprite2D
var _sweat: Sprite2D

## Fraction of the board collected, animated independently of movement/poses.
var growth_progress := 0.0:
	set(value):
		growth_progress = clampf(value, 0.0, 1.0)
		_apply_growth()

var _tex := {}
var _factor := 1.0
var _facing := 1.0          # 1 = facing left (as drawn), -1 = facing right
var _sick := false
var _ring: StyleBoxFlat
var _action: Tween
var _grow_tween: Tween
var _idle: Tween


func _ready() -> void:
	setup(false)


func setup(show_ring: bool = true) -> void:
	z_index = 10
	for n in ["body", "leg", "tail", "head", "mane", "sweat",
			"eyes_open", "eyes_closed", "eyes_happy", "eyes_sick",
			"mouth_smile", "mouth_open", "mouth_chew", "mouth_sick"]:
		_tex[n] = load(ART + n + ".svg")

	if show_ring:
		_ring = StyleBoxFlat.new()
		_ring.bg_color = Color(1, 1, 1, 0.0)
		_ring.border_color = Color("ff9f1c")
		_ring.set_border_width_all(7)
		_ring.set_corner_radius_all(22)

	_rig = Node2D.new()
	_rig.position = Vector2(0, FEET_Y)
	_rig.scale = Vector2.ONE * BASE_SCALE
	add_child(_rig)
	_pose = Node2D.new()
	_rig.add_child(_pose)

	# Back to front. Coordinates match tools/generate_characters.py:
	# (texture, top-left of its bounds, pivot), all in design space.
	var far := Color(0.84, 0.8, 0.76)
	var leg_tl := Vector2(-24, -10)
	_tail = _part("tail", TAIL_JOINT + Vector2(-8, -28), TAIL_JOINT, _pose)
	_leg_ff = _part("leg", Vector2(-34, -57) + leg_tl, Vector2(-34, -57), _pose)
	_leg_fh = _part("leg", Vector2(28, -57) + leg_tl, Vector2(28, -57), _pose)
	_leg_ff.modulate = far
	_leg_fh.modulate = far
	_part("body", Vector2(-64, -114), Vector2(8, -72), _pose)
	_leg_nf = _part("leg", Vector2(-22, -57) + leg_tl, Vector2(-22, -57), _pose)
	_leg_nh = _part("leg", Vector2(40, -57) + leg_tl, Vector2(40, -57), _pose)
	_head = Node2D.new()
	_head.position = HEAD_POS
	_pose.add_child(_head)
	_mane = _part("mane", Vector2(-128, -192), Vector2(-56, -118), _head, HEAD_POS)
	_part("head", Vector2(-100, -178), HEAD_POS, _head, HEAD_POS)
	_apply_growth()
	_eyes = _part("eyes_open", Vector2(-92, -156), Vector2(-59, -127), _head, HEAD_POS)
	_mouth = _part("mouth_smile", Vector2(-98, -104), Vector2(-80, -98), _head, HEAD_POS)
	_sweat = _part("sweat", SWEAT_POS + Vector2(-8, -2), SWEAT_POS, _pose)
	_sweat.visible = false

	_start_idle()
	var blink := Timer.new()
	blink.wait_time = 2.5
	blink.autostart = true
	blink.timeout.connect(_blink.bind(blink))
	add_child(blink)
	queue_redraw()


## `top_left` and `pivot` are in design space; `parent_origin` is where the parent node sits.
func _part(tex_name: String, top_left: Vector2, pivot: Vector2, parent: Node, parent_origin: Vector2 = Vector2.ZERO) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = _tex[tex_name]
	s.centered = false
	s.offset = top_left - pivot
	s.position = pivot - parent_origin
	parent.add_child(s)
	return s


func _draw() -> void:
	if _ring:
		draw_style_box(_ring, Rect2(-CELL / 2.0 + 3, -CELL / 2.0 + 3, CELL - 6, CELL - 6))
	# Soft shadow under the feet.
	draw_set_transform(Vector2(0, FEET_Y), 0.0, Vector2(1.0, 0.3))
	draw_circle(Vector2.ZERO, 46.0 * _factor, Color(0, 0, 0, 0.18))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _set_eyes(n: String) -> void:
	_eyes.texture = _tex["eyes_" + n]


func _set_mouth(n: String) -> void:
	_mouth.texture = _tex["mouth_" + n]


# ---------- idle ----------

func _start_idle() -> void:
	_idle = create_tween().set_loops()
	_idle.tween_property(_head, "position:y", HEAD_POS.y + 3.0, 0.7).set_trans(Tween.TRANS_SINE)
	_idle.parallel().tween_property(_tail, "rotation", 0.25, 0.7).set_trans(Tween.TRANS_SINE)
	_idle.tween_property(_head, "position:y", HEAD_POS.y, 0.7).set_trans(Tween.TRANS_SINE)
	_idle.parallel().tween_property(_tail, "rotation", -0.15, 0.7).set_trans(Tween.TRANS_SINE)


func _blink(timer: Timer) -> void:
	timer.wait_time = randf_range(1.8, 4.0)
	if _sick or _eyes.texture != _tex["eyes_open"]:
		return
	_set_eyes("closed")
	await get_tree().create_timer(0.12).timeout
	if _eyes.texture == _tex["eyes_closed"]:
		_set_eyes("open")


# ---------- action plumbing ----------

func _reset_pose() -> void:
	_sick = false
	_pose.position = Vector2.ZERO
	_pose.rotation = 0.0
	_pose.scale = Vector2(_facing, 1.0)
	_pose.modulate = Color.WHITE
	_head.position = HEAD_POS
	_head.rotation = 0.0
	_head.scale = Vector2.ONE
	for leg in [_leg_nf, _leg_ff, _leg_nh, _leg_fh]:
		leg.rotation = 0.0
	_tail.rotation = 0.0
	_sweat.visible = false
	_set_eyes("open")
	_set_mouth("smile")


## Cancels whatever animation is running and returns a fresh tween for the next one.
func _begin_action() -> Tween:
	if _action and _action.is_valid():
		_action.kill()
	_reset_pose()
	_idle.pause()
	_action = create_tween()
	return _action


func _finish_action() -> void:
	_reset_pose()
	_idle.play()


# ---------- animations ----------
# Rotation sign: positive swings a leg forward (towards the nose) and lifts the head;
# negative lowers the head. Whole-body tilt must be multiplied by _facing.

func place_at(pos: Vector2) -> void:
	position = pos


func _legs(a: Tween, nf: float, ff: float, nh: float, fh: float, t: float) -> void:
	a.tween_property(_leg_nf, "rotation", nf, t)
	a.tween_property(_leg_ff, "rotation", ff, t)
	a.tween_property(_leg_nh, "rotation", nh, t)
	a.tween_property(_leg_fh, "rotation", fh, t)


## Bounds to `pos`. Returns the tween that moves the character (await its `finished`).
func move_to(pos: Vector2, dir: Vector2i = Vector2i.ZERO) -> Tween:
	if dir.x != 0:
		_facing = -1.0 if dir.x > 0 else 1.0
	var half := MOVE_TIME * 0.5
	var f := Vector2(_facing, 1.0)
	var a := _begin_action()
	_pose.scale = f * Vector2(1.08, 0.92)  # stretch out on take-off
	a.set_parallel(true)
	# Up: front legs reach forward, hind legs kick back, tail streams behind.
	a.tween_property(_pose, "position:y", -24.0, half).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_legs(a, 0.8, 0.55, -0.8, -0.55, half)
	a.tween_property(_tail, "rotation", -0.5, half)
	a.tween_property(_head, "rotation", 0.12, half)
	# Down: legs gather under the body.
	a.chain().tween_property(_pose, "position:y", 0.0, half).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_legs(a, -0.25, -0.1, 0.3, 0.15, half)
	a.tween_property(_tail, "rotation", 0.4, half)
	a.tween_property(_head, "rotation", -0.08, half)
	a.tween_property(_pose, "scale", f, half)
	# Landing squash and settle.
	a.chain().tween_property(_pose, "scale", f * Vector2(1.1, 0.86), 0.06)
	_legs(a, 0.0, 0.0, 0.0, 0.0, 0.06)
	a.chain().tween_property(_pose, "scale", f, 0.14).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	a.tween_property(_head, "rotation", 0.0, 0.14)
	a.chain().tween_callback(_finish_action)

	var mv := create_tween()
	mv.tween_property(self, "position", pos, MOVE_TIME).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	return mv


## Chomp, chew, and grow towards the fraction of multiples collected.
func eat_good(progress: float) -> void:
	var f := Vector2(_facing, 1.0)
	var a := _begin_action()
	# Chomp: mouth wide, head dips to the number.
	_set_mouth("open")
	a.tween_property(_head, "rotation", -0.55, 0.09).set_ease(Tween.EASE_OUT)
	a.parallel().tween_property(_head, "position:y", HEAD_POS.y + 12.0, 0.09)
	a.parallel().tween_property(_leg_nf, "rotation", 0.25, 0.09)
	a.tween_callback(_set_mouth.bind("chew"))
	a.tween_property(_head, "rotation", -0.1, 0.07)
	a.parallel().tween_property(_head, "position:y", HEAD_POS.y, 0.07)
	a.parallel().tween_property(_leg_nf, "rotation", 0.0, 0.07)
	# Chew.
	for _i in range(3):
		a.tween_callback(_set_mouth.bind("smile"))
		a.tween_property(_head, "scale", Vector2(1.08, 0.93), 0.06)
		a.tween_callback(_set_mouth.bind("chew"))
		a.tween_property(_head, "scale", Vector2.ONE, 0.06)
	# Yum: rear up on the hind legs with the front paws in the air.
	a.tween_callback(_set_eyes.bind("happy"))
	a.tween_callback(_set_mouth.bind("open"))
	a.tween_property(_pose, "position:y", -30.0, 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	a.parallel().tween_property(_pose, "rotation", 0.32 * _facing, 0.16)
	a.parallel().tween_property(_head, "rotation", 0.2, 0.16)
	a.parallel().tween_property(_leg_nf, "rotation", 1.2, 0.16)
	a.parallel().tween_property(_leg_ff, "rotation", 0.8, 0.16)
	a.parallel().tween_property(_tail, "rotation", -0.7, 0.16)
	a.tween_property(_pose, "position:y", 0.0, 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	a.parallel().tween_property(_pose, "rotation", 0.0, 0.16)
	a.parallel().tween_property(_leg_nf, "rotation", 0.0, 0.16)
	a.parallel().tween_property(_leg_ff, "rotation", 0.0, 0.16)
	a.tween_property(_pose, "scale", f * Vector2(1.1, 0.86), 0.06)
	a.tween_property(_pose, "scale", f, 0.14).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	a.parallel().tween_property(_head, "rotation", 0.0, 0.14)
	a.tween_interval(0.15)
	a.tween_callback(_finish_action)

	animate_growth(progress)


func animate_growth(progress: float) -> void:
	# No delay: quick consecutive bites still visibly grow the lion. Movement,
	# sickness and celebration can replace the pose without cancelling growth.
	if _grow_tween and _grow_tween.is_valid():
		_grow_tween.kill()
	_grow_tween = create_tween()
	_grow_tween.tween_property(self, "growth_progress", clampf(progress, 0.0, 1.0), 0.45).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


func _apply_growth() -> void:
	_factor = lerpf(BASE_GROW, FULL_GROW, growth_progress)
	if not is_instance_valid(_rig) or not is_instance_valid(_mane):
		return
	_rig.scale = Vector2.ONE * BASE_SCALE * _factor
	# A small ruff emerges from behind the face, gradually filling out.
	_mane.scale = Vector2.ONE * lerpf(0.45, 1.0, growth_progress)
	_mane.modulate.a = minf(growth_progress * 5.0, 1.0)
	_mane.visible = growth_progress > 0.0
	queue_redraw()


## Turns green, hangs its head, crouches and wobbles. Await it.
func stomach_ache() -> void:
	var f := Vector2(_facing, 1.0)
	var a := _begin_action()
	_sick = true
	_set_eyes("sick")
	_set_mouth("sick")
	_sweat.visible = true
	_sweat.position = SWEAT_POS
	_sweat.modulate.a = 1.0
	a.set_parallel(true)
	# Crouch with the head hanging and the tail drooping.
	a.tween_property(_pose, "modulate", SICK_TINT, 0.15)
	a.tween_property(_pose, "scale", f * Vector2(1.06, 0.86), 0.15)
	a.tween_property(_head, "rotation", -0.45, 0.15)
	a.tween_property(_head, "position:y", HEAD_POS.y + 10.0, 0.15)
	_legs(a, 0.3, 0.45, -0.3, -0.45, 0.15)
	a.tween_property(_tail, "rotation", 0.9, 0.15)
	a.tween_property(_sweat, "position:y", SWEAT_POS.y + 50.0, 0.9).set_ease(Tween.EASE_IN)
	a.tween_property(_sweat, "modulate:a", 0.0, 0.25).set_delay(0.7)
	# Queasy wobble.
	for _i in range(4):
		a.chain().tween_property(_pose, "rotation", 0.09, 0.11).set_trans(Tween.TRANS_SINE)
		a.tween_property(_head, "rotation", -0.65, 0.11).set_trans(Tween.TRANS_SINE)
		a.chain().tween_property(_pose, "rotation", -0.09, 0.11).set_trans(Tween.TRANS_SINE)
		a.tween_property(_head, "rotation", -0.3, 0.11).set_trans(Tween.TRANS_SINE)
	# Recover.
	a.chain().tween_property(_pose, "rotation", 0.0, 0.15)
	a.tween_property(_head, "rotation", 0.0, 0.15)
	a.tween_property(_head, "position:y", HEAD_POS.y, 0.15)
	a.tween_property(_pose, "modulate", Color.WHITE, 0.15)
	a.tween_property(_pose, "scale", f, 0.15)
	_legs(a, 0.0, 0.0, 0.0, 0.0, 0.15)
	a.chain().tween_callback(_finish_action)
	await a.finished


func _flip() -> void:
	_facing = -_facing
	_pose.scale.x = _facing


## Victory dance: three big leaps with the front paws in the air. Await it.
func celebrate() -> void:
	var a := _begin_action()
	_set_eyes("happy")
	_set_mouth("open")
	for _i in range(3):
		a.tween_property(_pose, "position:y", -60.0, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		a.parallel().tween_property(_leg_nf, "rotation", 1.2, 0.22)
		a.parallel().tween_property(_leg_ff, "rotation", 0.8, 0.22)
		a.parallel().tween_property(_leg_nh, "rotation", -0.6, 0.22)
		a.parallel().tween_property(_leg_fh, "rotation", -0.4, 0.22)
		a.parallel().tween_property(_tail, "rotation", -0.7, 0.22)
		a.tween_callback(_flip)
		a.tween_property(_pose, "position:y", 0.0, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		a.parallel().tween_property(_leg_nf, "rotation", 0.0, 0.22)
		a.parallel().tween_property(_leg_ff, "rotation", 0.0, 0.22)
		a.parallel().tween_property(_leg_nh, "rotation", 0.0, 0.22)
		a.parallel().tween_property(_leg_fh, "rotation", 0.0, 0.22)
		a.parallel().tween_property(_tail, "rotation", 0.5, 0.22)
		a.tween_property(_pose, "scale:y", 0.86, 0.05)
		a.tween_property(_pose, "scale:y", 1.0, 0.08)
	await a.finished
	_idle.play()

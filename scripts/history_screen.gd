extends Control
## List of finished games, newest first.

signal back


func _ready() -> void:
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 40)
	add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 16)
	margin.add_child(box)

	box.add_child(_label("History", 60, Color("ffd166")))

	var records: Array = GameHistory.records
	if records.is_empty():
		var empty := _label("No games yet. Go and play!", 30)
		empty.size_flags_vertical = SIZE_EXPAND_FILL
		empty.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		box.add_child(empty)
	else:
		var total_mistakes := 0
		var perfect := 0
		for r in records:
			total_mistakes += int(r.get("mistakes", 0))
			if int(r.get("mistakes", 0)) == 0:
				perfect += 1
		box.add_child(_label("Games played: %d     Perfect games: %d     Total mistakes: %d"
				% [records.size(), perfect, total_mistakes], 26))

		var scroll := ScrollContainer.new()
		scroll.size_flags_vertical = SIZE_EXPAND_FILL
		box.add_child(scroll)
		var grid := GridContainer.new()
		grid.columns = 5
		grid.add_theme_constant_override("h_separation", 36)
		grid.add_theme_constant_override("v_separation", 8)
		grid.size_flags_horizontal = SIZE_SHRINK_CENTER | SIZE_EXPAND
		scroll.add_child(grid)
		for head in ["When", "Mode", "Table", "Mistakes", "Time"]:
			grid.add_child(_label(head, 26, Color("ffd166")))
		for i in range(records.size() - 1, -1, -1):
			var r: Dictionary = records[i]
			var mistakes := int(r.get("mistakes", 0))
			var secs := int(r.get("seconds", 0))
			grid.add_child(_label(str(r.get("date", "")), 24))
			grid.add_child(_label(str(r.get("mode", "Freestyle")), 24))
			grid.add_child(_label("x %d" % int(r.get("table", 0)), 24))
			grid.add_child(_label("Perfect!" if mistakes == 0 else str(mistakes), 24,
					Color("c9ecae") if mistakes == 0 else Color("fff6dc")))
			grid.add_child(_label("%d:%02d" % [secs / 60, secs % 60], 24))

	var btn := Button.new()
	btn.text = "Back"
	btn.custom_minimum_size = Vector2(220, 70)
	btn.size_flags_horizontal = SIZE_SHRINK_CENTER
	btn.pressed.connect(func(): back.emit())
	box.add_child(btn)
	btn.grab_focus.call_deferred()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		back.emit()


func _label(text: String, font_size: int, color := Color("fff6dc")) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	return l

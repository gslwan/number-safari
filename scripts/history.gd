extends Node
## Autoload: remembers finished games in user://history.json.

const PATH := "user://history.json"

var records: Array = []


func _ready() -> void:
	if not FileAccess.file_exists(PATH):
		return
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	if parsed is Array:
		records = parsed


func add(table: int, mistakes: int, seconds: float, mode: String = "Freestyle") -> void:
	records.append({
		"date": Time.get_datetime_string_from_system(false, true),
		"table": table,
		"mode": mode,
		"mistakes": mistakes,
		"seconds": snappedf(seconds, 0.1),
	})
	var f := FileAccess.open(PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(records, "\t"))

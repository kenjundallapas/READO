extends Node

var has_seen_tutorial: bool = false
var selected_module_id = 1 

const SAVE_PATH = "user://tutorial_save.save"

func _ready() -> void:
	load_tutorial_state()

func save_tutorial_state() -> void:
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_var(has_seen_tutorial)

func load_tutorial_state() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
		if file:
			has_seen_tutorial = file.get_var()

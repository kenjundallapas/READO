extends Control

func _on_level_1_button_pressed():
	Global.selected_module_id = 1
	get_tree().change_scene_to_file("res://main_screen.tscn")

func _on_level_2_button_pressed():
	Global.selected_module_id = 2
	get_tree().change_scene_to_file("res://main_screen.tscn")

func _on_level_3_button_pressed():
	Global.selected_module_id = 3
	get_tree().change_scene_to_file("res://main_screen.tscn")

func _on_back_button_pressed():
	get_tree().change_scene_to_file("res://main_menu.tscn")

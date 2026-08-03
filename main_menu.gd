extends Control

func _on_play_button_pressed():
	get_tree().change_scene_to_file("res://level_select_screen.tscn")

func _on_archive_button_pressed():
	get_tree().change_scene_to_file("res://archive_screen.tscn")

func _on_quit_button_pressed():
	get_tree().quit()

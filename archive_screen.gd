extends Control

# Grab the nodes from inside your existing GridContainer
@onready var novice_badge = $GridContainer/BadgeNoviceReader
@onready var flawless_badge = $GridContainer/BadgeFlawlessVictory
@onready var boss_badge = $GridContainer/BadgeBossSlayer

func _ready():
	update_badges()

func update_badges():
	# --- 1. Novice Reader Badge ---
	if BadgeManager.has_badge("BadgeNoviceReader"):
		novice_badge.modulate = Color(1, 1, 1, 1) # Fully bright and colorful
	else:
		novice_badge.modulate = Color(0.1, 0.1, 0.1, 1) # Very dark/silhouetted

	# --- 2. Flawless Victory Badge ---
	if BadgeManager.has_badge("BadgeFlawlessVictory"):
		flawless_badge.modulate = Color(1, 1, 1, 1) 
	else:
		flawless_badge.modulate = Color(0.1, 0.1, 0.1, 1) 

	# --- 3. Boss Slayer Badge ---
	if BadgeManager.has_badge("BadgeBossSlayer"):
		boss_badge.modulate = Color(1, 1, 1, 1) 
	else:
		boss_badge.modulate = Color(0.1, 0.1, 0.1, 1)

func _on_back_button_pressed():
	get_tree().change_scene_to_file("res://main_menu.tscn")

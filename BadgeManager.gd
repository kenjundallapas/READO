extends Node

signal badge_unlocked(badge_id: String)

var unlocked_badges: Array = []
const SAVE_PATH = "user://unlocked_badges.save"

# Define your badge IDs cleanly
const BADGES = {
	NOVICE_READER = "BadgeNoviceReader",
	FLAWLESS = "BadgeFlawlessVictory",
	BOSS_SLAYER = "BadgeBossSlayer"
}

func _ready() -> void:
	load_badges()

func unlock_badge(badge_id: String) -> void:
	if badge_id not in unlocked_badges:
		unlocked_badges.append(badge_id)
		save_badges()
		badge_unlocked.emit(badge_id)
		print("Achievement Unlocked: " + badge_id)

func has_badge(badge_id: String) -> bool:
	return badge_id in unlocked_badges

func save_badges() -> void:
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_var(unlocked_badges)

func load_badges() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
		if file:
			unlocked_badges = file.get_var()

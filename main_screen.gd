extends Control

signal correct_answer_selected
signal wrong_answer_selected

@onready var button_container = %ButtonContainer
@onready var story_text = %RichTextLabel
@onready var mage_node = $VBoxContainer/SubViewportContainer/SubViewport/GameWorld/Mage

var question_start_time = 0
var ml_engine = preload("res://ml_engine.gd").new()
var database = [] 
var current_level_chunks = [] 
var current_chunk_index = 0 
var current_module_id = 2 
# We store the user's successful reading times to learn their natural pace
var successful_reading_times: Array = []
var dynamic_reading_threshold: float = 4.0 # Starts at a 4.0 default baseline
var text_tween : Tween

# --- NEW HEART SYSTEM ---
var max_hearts = 3
var current_hearts = 3

# This function acts as our Decision Tree Classifier.
# It takes the telemetry data and predicts the student's reading profile.
func classify_learner_behavior(time_seconds: float, is_correct: bool, current_focus: int) -> String:
	
	# Branch 1: The student answered CORRECTLY
	if is_correct:
		if time_seconds < dynamic_reading_threshold:
			# Prediction: They didn't read it, they just clicked a random button and got lucky.
			return "Lucky_Guesser" 
		else:
			# THE MACHINE LEARNING PART: 
			# The student read it properly and got it right. 
			# We record their time to learn their natural reading speed.
			successful_reading_times.append(time_seconds)
			_recalculate_dynamic_threshold()
			
			# Prediction: They took their time, read the text, and understood it.
			return "Mastering" 
			
	# Branch 2: The student answered INCORRECTLY
	else:
		if time_seconds < dynamic_reading_threshold:
			# Prediction: They are spam-clicking through the game without trying.
			return "Rushing" 
		else:
			# They took the time to read, but still got it wrong.
			if current_focus <= 1:
				# Prediction: They are out of focus and getting overwhelmed.
				return "Fatigued"
			else:
				# Prediction: They are genuinely struggling with the reading comprehension.
				return "Struggling"

# This function allows the engine to learn and adjust its own rules
func _recalculate_dynamic_threshold():
	if successful_reading_times.size() > 0:
		var total_time = 0.0
		for t in successful_reading_times:
			total_time += t
			
		var average_time = total_time / successful_reading_times.size()
		
		# Set the new rushing threshold to 60% of their personal average speed
		dynamic_reading_threshold = average_time * 0.6
		
		# Optional: Print to the Godot console to prove it is learning during testing
		print("ML Engine learned a new pattern. Adjusted Rushing Threshold to: ", dynamic_reading_threshold)
		
func _ready():
	print("--- LEVEL LOADED ---")
	print("Global selected_module_id is: ", Global.selected_module_id)
	
	button_container.hide()
	%TryAgainButton.hide()
	%ContinueReadingButton.hide() 
	%PauseOverlay.hide()
	update_hearts_ui()
	
	load_database() 
	current_module_id = Global.selected_module_id 
	start_level(current_module_id)
	
	if current_module_id == 1:
		check_and_show_tutorial()
func update_hearts_ui():
	if not has_node("%HeartsContainer"):
		return
		
	# Grab the 3 MarginContainers (HeartSlots)
	var heart_slots = %HeartsContainer.get_children()
	
	# Loop through each slot and show/hide the bright top layer
	for i in range(heart_slots.size()):
		var bright_heart = heart_slots[i].get_node("FullHeart")
		
		if i < current_hearts:
			bright_heart.show() # Safe! Show the bright heart.
		else:
			bright_heart.hide() # Damage taken! Hide it to reveal the dark heart.

# --- BACKEND LOGIC ---
func load_database():
	var file = FileAccess.open("res://questions.json", FileAccess.READ)
	if file:
		var json_string = file.get_as_text()
		var data = JSON.parse_string(json_string)
		
		if data == null:
			print("CRITICAL ERROR: questions.json syntax error.")
		elif data.has("levels"):
			database = data["levels"]
		else:
			print("ERROR: No 'levels' array found.")
	else:
		print("ERROR: Could not find questions.json!")

# --- LEVEL MANAGEMENT ---
func start_level(mod_id: int):
	current_chunk_index = 0
	current_hearts = max_hearts # Reset hearts at the start of a level
	current_level_chunks = []
	update_hearts_ui()
	
	# BACKGROUND SWITCHING LOGIC
	# Change '$BackgroundTextureRect' to match the actual node path of your background in the scene tree
	var bg_node = %Sprite2D
	if bg_node:
		if mod_id == 2:
			bg_node.texture = load("res://Backgrounds/Nature Landscapes Free Pixel Art/nature_5/orig.png")
			bg_node.scale = Vector2(1.5, 1.5)
		elif mod_id == 3:
			bg_node.texture = load("res://Backgrounds/PNG/1/terrace.png")
	
	for level in database:
		if level["module_id"] == mod_id:
			current_level_chunks = level["chunks"]
			break
			
	if current_level_chunks.is_empty():
		story_text.visible_ratio = 1.0 
		story_text.text = "Error: Level data not found for Module ID " + str(mod_id)
		return
		
	update_story_display()
	
func update_story_display():
	if current_chunk_index < current_level_chunks.size():
		var current_chunk = current_level_chunks[current_chunk_index]
		story_text.text = current_chunk["text"]
		
		# UNLOCK: Novice Reader on the very first chunk/level start
		if current_chunk_index == 0:
			BadgeManager.unlock_badge("BadgeNoviceReader")
		
		%ContinueReadingButton.show() 
		
		story_text.visible_ratio = 0.0
		if text_tween:
			text_tween.kill()
		text_tween = create_tween()
		
		var reading_time = story_text.text.length() * 0.02 
		text_tween.tween_property(story_text, "visible_ratio", 1.0, reading_time)
	else:
		story_text.text = "Level Complete! The Anomaly has been defeated."
		%ContinueReadingButton.hide()
		
		# UNLOCK: Boss Slayer upon defeating the final anomaly
		BadgeManager.unlock_badge("BadgeBossSlayer")
		
		# UNLOCK: Flawless Victory if hearts never dropped from max
		if current_hearts == max_hearts:
			BadgeManager.unlock_badge("BadgeFlawlessVictory")
		
		await get_tree().create_timer(3.0).timeout
		get_tree().change_scene_to_file("res://level_select_screen.tscn")
# --- THE WIPEOUT RESTART LOOP ---
func restart_level_loop():
	current_hearts = max_hearts
	current_chunk_index = 0
	update_hearts_ui()
	
	# Reset the Mage animation
	mage_node.reset_to_walking()
	
	# Start the story from the beginning
	update_story_display()

# --- ENCOUNTER LOGIC ---
func _on_continue_reading_button_pressed():
	if story_text.visible_ratio < 1.0:
		if text_tween:
			text_tween.kill()
		story_text.visible_ratio = 1.0
	else:
		%ContinueReadingButton.hide()
		mage_node.force_encounter()

func _on_mage_encounter_started() -> void:
	if text_tween:
		text_tween.kill()
	story_text.visible_ratio = 1.0 
	show_question_ui()
	
func show_question_ui():
	if current_level_chunks.is_empty():
		return
		
	%TryAgainButton.hide()
	var current_chunk = current_level_chunks[current_chunk_index]
	story_text.text = "ENCOUNTER!\n\n" + current_chunk["question"]
	
	var buttons = button_container.get_children()
	var options = current_chunk["options"]
	
	for i in range(buttons.size()):
		if i < options.size():
			buttons[i].text = options[i]
			buttons[i].show()
			
			if buttons[i].pressed.is_connected(_on_answer_button_pressed):
				buttons[i].pressed.disconnect(_on_answer_button_pressed)
				
			buttons[i].pressed.connect(_on_answer_button_pressed.bind(i))
		else:
			buttons[i].hide() 
			
	button_container.show()
	question_start_time = Time.get_ticks_msec()
	
func _on_answer_button_pressed(button_index: int) -> void:
	button_container.hide()
	var current_chunk = current_level_chunks[current_chunk_index]
	
	var current_time = Time.get_ticks_msec()
	var time_taken_seconds = (current_time - question_start_time) / 1000.0
	var is_correct = (button_index == current_chunk["correct_answer"])
	
	var learner_profile = ml_engine.classify_learner_behavior(time_taken_seconds, is_correct, current_hearts)
	save_local_telemetry(learner_profile, time_taken_seconds, is_correct, current_hearts)
	
	if is_correct:
		correct_answer_selected.emit()
		
		# Optional: Heal 1 heart when they get it right, capped at max_hearts
		current_hearts = min(current_hearts + 1, max_hearts)
		update_hearts_ui()
		
		current_chunk_index += 1
		update_story_display() 
		
	else:
		wrong_answer_selected.emit()
		
		# Take damage!
		current_hearts -= 1
		update_hearts_ui()
		
		# DEATH CHECK FIRST
		if current_hearts <= 0:
			%TryAgainButton.hide()
			story_text.text = "You have lost all your Hearts! The Anomaly overwhelmed you.\n\nRestarting the level..."
			await get_tree().create_timer(3.0).timeout
			restart_level_loop()
			return # Stop running the rest of the code so it cleanly resets!
			
		# Kill any currently running tweens so they don't overlap
		if text_tween:
			text_tween.kill()
		
		# 1. RUSHING INTERVENTION: Time-Out Penalty (Cooldown)
		if learner_profile == "Rushing" or learner_profile == "Lucky_Guesser":
			story_text.text = "You're moving too fast! The Anomaly cast a Time Bind on you. Take a breath and review the text:\n\n" + current_chunk["text"]
			story_text.visible_ratio = 1.0 # Text appears instantly
			
			%TryAgainButton.hide() # Hide the button so they can't spam
			await get_tree().create_timer(5.0).timeout # Force them to wait 5 seconds
			
			# Only show it if they haven't died/reset while waiting
			if current_hearts > 0:
				%TryAgainButton.show()
			
		# 2. STRUGGLING INTERVENTION: Instant Hint Reveal
		elif learner_profile == "Struggling":
			var hint = current_chunk.get("simplified_text", "Look closely at the context clues!")
			story_text.text = "Let's simplify this concept:\n\n" + hint
			story_text.visible_ratio = 1.0 
			%TryAgainButton.show()
			
		# 3. FATIGUED INTERVENTION: Instant Prompt Reveal
		elif learner_profile == "Fatigued":
			story_text.text = "You seem tired, Mage. Take a deep breath and review:\n\n" + current_chunk["text"]
			story_text.visible_ratio = 1.0
			%TryAgainButton.show()
			
		# 4. DEFAULT: Instant Reveal
		else:
			story_text.text = "Focus lost! Review the text:\n\n" + current_chunk["text"]
			story_text.visible_ratio = 1.0
			%TryAgainButton.show()

func _on_try_again_button_pressed():
	show_question_ui()

func save_local_telemetry(learner_profile: String, time_taken: float, is_correct: bool, hearts_remaining: int):
	var file_path = "user://student_telemetry.csv"
	var file
	
	if not FileAccess.file_exists(file_path):
		file = FileAccess.open(file_path, FileAccess.WRITE)
		file.store_line("timestamp,profile,time_seconds,is_correct,hearts_remaining")
	else:
		file = FileAccess.open(file_path, FileAccess.READ_WRITE)
		file.seek_end()
		
	var current_datetime = Time.get_datetime_string_from_system()
	var data_string = "%s,%s,%f,%s,%d" % [current_datetime, learner_profile, time_taken, str(is_correct), hearts_remaining]
	
	file.store_line(data_string)
	file.close()
	


func _on_resume_button_pressed():
	# 1. Unfreeze the game engine
	get_tree().paused = false 
	
	# 2. Hide the dark overlay and menu
	%PauseOverlay.hide()

func _on_back_to_menu_button_pressed():
	# CRITICAL: Unfreeze the game before leaving! 
	get_tree().paused = false 
	
	# Load the Level Select map (Make sure this filename matches your exact scene name)
	get_tree().change_scene_to_file("res://level_select_screen.tscn")


func _on_settings_button_pressed():
	# 1. Freeze the entire game engine (enemies, animations, everything stops)
	get_tree().paused = true 
	
	# 2. Show the dark overlay and your custom settings menu
	%PauseOverlay.show()

# This dictionary stores all the definitions for your interactive words
var glossary_dict = {
	"evaporation": "Evaporation: The process where liquid water turns into an invisible gas (vapor) due to heat.",
	"condensation": "Condensation: When cold air turns invisible water vapor back into tiny drops of liquid water.",
	"mana": "Mana: Magical energy required to cast spells.",
	"oxidation": "Oxidation: A chemical reaction where iron mixes with water and oxygen to create rust."
}

# This triggers exactly when a player clicks a glowing word in the story
func _on_rich_text_label_meta_clicked(meta):
	var clicked_word = str(meta)
	
	# Check if the word exists in our dictionary
	if glossary_dict.has(clicked_word):
		var popup = $GlossaryPopup
		popup.dialog_text = glossary_dict[clicked_word]
		popup.popup_centered() # Shows the popup perfectly in the middle of the screen
		
# We now store the text AND the exact node we want to highlight!
var tutorial_steps = [
	{
		"text": "Welcome, brave Mage! Let's go over the basics.",
		"target_node": null # null means no highlight for this step
	},
	{
		"text": "Keep an eye on your Hearts at the bottom left. Wrong answers will hurt you!",
		"target_node": "%HeartsContainer" # Change this if your hearts are stored in a different container!
	},
	{
		"text": "Click on the glowing, waving yellow words in the story to reveal secret context clues!",
		"target_node": "%RichTextLabel" 
	},
	{
		"text": "Are you ready? Tap the screen one last time to begin your adventure!",
		"target_node": null
	}
]
var current_tutorial_step = 0

func check_and_show_tutorial():
	if not Global.has_seen_tutorial:
		$TutorialOverlay.show()
		get_tree().paused = true
		
		current_tutorial_step = 0
		update_tutorial_visuals() # Call our new function to set up step 1

# Connect this to your new invisible ScreenTapButton!
func _on_screen_tap_button_pressed():
	current_tutorial_step += 1
	
	if current_tutorial_step < tutorial_steps.size():
		update_tutorial_visuals() 
	else:
		$TutorialOverlay.hide()
		Global.has_seen_tutorial = true
		Global.save_tutorial_state() # <--- ADD THIS LINE HERE
		get_tree().paused = false

# --- THE SMART HIGHLIGHT LOGIC ---
func update_tutorial_visuals():
	var step_data = tutorial_steps[current_tutorial_step]
	$TutorialOverlay/RichTextLabel.text = "[center]" + step_data["text"] + "[/center]"
	
	var box = $TutorialOverlay/HighlightBox
	var arrow = $TutorialOverlay/TutorialArrow
	
	if step_data["target_node"] != null:
		# Find the target node in the game
		var target = get_node(step_data["target_node"])
		
		# 1. Snap the glowing box exactly over the target node
		box.global_position = target.global_position
		box.size = target.size
		box.show()
		
		# 2. Snap the arrow just below the target node, pointing up at it
		arrow.global_position = target.global_position + Vector2(target.size.x / 2 - (arrow.size.x / 2), target.size.y + 10)
		arrow.show()
		
	else:
		# Hide the box and arrow for intro/outro screens
		box.hide()
		arrow.hide()

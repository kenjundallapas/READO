extends CharacterBody2D

signal encounter_started 

const SPEED = 100.0
var is_walking = true
var enemy_list = ["Bat", "Fly", "MR"]
var current_enemy_name = ""

func _ready():
	# Hide the anomaly when the game first loads
	$Anomaly.hide()
	$AnimatedSprite2D.play("walk")

func _physics_process(delta):
	if is_walking:
		velocity.x = SPEED
	else:
		velocity.x = 0
		
	move_and_slide()

# This is called manually by the Continue Reading button!
func force_encounter():
	if is_walking:
		is_walking = false
		$AnimatedSprite2D.play("idle") 
		
		# Pick a random enemy from your list (e.g., "MR")
		current_enemy_name = enemy_list.pick_random()
		
		# Add "Idle" to the end (making it "MRIdle") and play it!
		$Anomaly.play(current_enemy_name + "Idle") 
		$Anomaly.show()                
		
		encounter_started.emit()

# This is triggered by your UI Button!
func _on_main_screen_correct_answer_selected():
	$AnimatedSprite2D.play("attack")

func _on_animated_sprite_2d_animation_finished():
	if $AnimatedSprite2D.animation == "attack":
		
		# 1. Start at the invisible Marker2D we just placed!
		$SpellParticle.position = $SpellSpawnPoint.position 
		$SpellParticle.show()
		
		# Tell the sliced spritesheet to start animating!
		$SpellParticle.play("default") 
		
		var tween = create_tween()
		
		# 2. Aim for the center of the monster (adjust the -30 up or down if needed)
		var target_pos = $Anomaly.position + Vector2(0, -30)
		
		tween.tween_property($SpellParticle, "position", target_pos, 0.5)
		tween.finished.connect(_on_spell_hit)
		
	elif $AnimatedSprite2D.animation == "hurt":
		# Return to the idle animation
		$AnimatedSprite2D.play("idle")

# This triggers the exact millisecond the particle finishes traveling
func _on_spell_hit():
	$SpellParticle.hide()
	$SpellParticle.stop() 
	
	# If the enemy was "Bat", this plays "BatDeath"
	$Anomaly.play(current_enemy_name + "Death")

# This triggers exactly when the Anomaly finishes dying
func _on_anomaly_animation_finished():
	# Check if the enemy just finished dying
	if $Anomaly.animation == current_enemy_name + "Death":
		$Anomaly.hide() 
		
		$AnimatedSprite2D.play("walk") 
		is_walking = true              
		# Note: $EncounterTimer.start() was removed from here so it doesn't randomly trigger!
		
	# Check if the enemy just finished attacking
	elif $Anomaly.animation == current_enemy_name + "Attack":
		# Return to the idle animation while they read!
		$Anomaly.play(current_enemy_name + "Idle")
		
func _on_main_screen_wrong_answer_selected():
	# 1. Play the specific enemy's attack animation!
	$Anomaly.play(current_enemy_name + "Attack")
	await get_tree().create_timer(0.4).timeout
	$AnimatedSprite2D.play("hurt")
	$AnimatedSprite2D.modulate = Color(1, 0, 0) 
	
	var color_tween = create_tween()
	color_tween.tween_property($AnimatedSprite2D, "modulate", Color(1, 1, 1), 0.3)
	
# This triggers when the learner dies and the level restarts
func reset_to_walking():
	$Anomaly.hide()
	$AnimatedSprite2D.play("walk")
	is_walking = true

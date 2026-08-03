extends Node

# This function acts as our Decision Tree Classifier.
# It takes the telemetry data and predicts the student's reading profile.
func classify_learner_behavior(time_seconds: float, is_correct: bool, current_focus: int) -> String:
	
	# The threshold for reading speed. A Grade 4 student realistically 
	# cannot read a 50-word paragraph in under 4 seconds.
	var reading_threshold = 4.0 
	
	# Branch 1: The student answered CORRECTLY
	if is_correct:
		if time_seconds < reading_threshold:
			# Prediction: They didn't read it, they just clicked a random button and got lucky.
			return "Lucky_Guesser" 
		else:
			# Prediction: They took their time, read the text, and understood it.
			return "Mastering" 
			
	# Branch 2: The student answered INCORRECTLY
	else:
		if time_seconds < reading_threshold:
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

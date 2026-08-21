extends Node

# The "K" in K-Means. We start with baseline assumptions (Centroids) in seconds.
# The machine will move these numbers on its own as it learns.
var clusters = {
	"Rushing": 1.5,
	"Mastering": 5.0,
	"Struggling": 12.0
}

# The learning rate (alpha). 0.2 means the centroid moves 20% toward every new data point.
var learning_rate: float = 0.2 

func classify_learner_behavior(time_seconds: float, is_correct: bool, current_focus: int) -> String:
	
	# STEP 1: Find the nearest cluster (The K-Means calculation)
	var assigned_cluster = ""
	var shortest_distance = 9999.0
	
	# Loop through our centroids to calculate mathematical distance
	for cluster_name in clusters.keys():
		var distance = abs(clusters[cluster_name] - time_seconds)
		
		if distance < shortest_distance:
			shortest_distance = distance
			assigned_cluster = cluster_name
			
	# STEP 2: Update the centroid (The Machine Learning)
	# Formula: C_new = C_old + alpha * (x - C_old)
	var old_centroid = clusters[assigned_cluster]
	var shift_amount = learning_rate * (time_seconds - old_centroid)
	clusters[assigned_cluster] += shift_amount
	
	print("ML Engine Updated! '", assigned_cluster, "' centroid moved from ", old_centroid, " to ", clusters[assigned_cluster])

	# STEP 3: Contextual Overrides (Game Logic)
	# The ML clustered their reading speed, now we apply the game state.
	if assigned_cluster == "Rushing" and is_correct:
		return "Lucky_Guesser"
		
	if assigned_cluster == "Mastering" and not is_correct:
		if current_focus <= 1:
			return "Fatigued"
		else:
			return "Struggling"
			
	return assigned_cluster

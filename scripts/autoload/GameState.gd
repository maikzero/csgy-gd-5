# GameState.gd
extends Node

var current_score: int = 0
var high_score: int = 0
var total_coins: int = 0
var current_run_seed: int = 0

# Time tracking
var run_time: float = 0.0
var base_time_score: int = 5  # Base points per second

func reset_run():
	current_score = 0
	run_time = 0.0
	current_run_seed = randi()

func _process(delta):
	if get_tree().paused:
		return
	
	run_time += delta

func add_time_score(speed_multiplier: float):
	"""Called by player to add time-based score"""
	var time_points = int(base_time_score * speed_multiplier)
	current_score += time_points

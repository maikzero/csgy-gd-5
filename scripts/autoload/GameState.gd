extends Node

# Global variables - accessible everywhere
var current_score: int = 0
var high_score: int = 0
var total_coins: int = 0
var current_run_seed: int = 0

# Player stats that persist between runs
var permanent_upgrades = {
	"max_speed_boost": 0,
	"starting_health": 10,
	"double_jump_unlocked": false
}

func reset_run():
	current_score = 0
	current_run_seed = randi()

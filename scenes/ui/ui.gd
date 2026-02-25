# UI.gd
extends CanvasLayer

# Node references
@onready var health_bar = $HealthBar
@onready var health_label = $HealthLabel  # Optional: show numeric health
@onready var score_label = $ScoreLabel
@onready var speed_label = $SpeedContainer/SpeedLabel
@onready var multiplier_label = $MultiplierLabel

# For debugging
@onready var debug_label = $DebugLabel  # Optional - add this for testing

func _ready():
	print("UI: _ready() called")
	
	# Connect to GameState changes (if GameState had signals)
	# For now, we'll use _process to update
	
	# Find player and connect to its signals
	call_deferred("find_and_connect_player")

func find_and_connect_player():
	"""Find player and connect to its signals"""
	print("UI: Looking for player...")
	
	# Try multiple ways to find player
	var player = get_tree().get_first_node_in_group("player")
	
	if not player:
		# Try by path
		player = get_node_or_null("/root/Main/Player")
	
	if not player:
		# Try by searching all nodes
		var nodes = get_tree().get_nodes_in_group("player")
		if nodes.size() > 0:
			player = nodes[0]
	
	if player:
		print("UI: Player found! Connecting signals...")
		
		# Connect to player signals
		if player.has_signal("health_changed"):
			player.health_changed.connect(_on_player_health_changed)
			print("UI: Connected to health_changed")
		
		if player.has_signal("speed_changed"):
			player.speed_changed.connect(_on_player_speed_changed)
			print("UI: Connected to speed_changed")
		
		if player.has_signal("score_multiplier_changed"):
			player.score_multiplier_changed.connect(_on_multiplier_changed)
			print("UI: Connected to score_multiplier_changed")
		
		# Initial update
		update_all(player)
	else:
		print("UI: Player not found yet, will try again...")
		# Try again in 1 second
		await get_tree().create_timer(1.0).timeout
		find_and_connect_player()

func update_all(player):
	"""Force update all UI elements"""
	if player:
		if player.has_method("get_health"):
			_on_player_health_changed(player.get_health())
		elif "health" in player:
			_on_player_health_changed(player.health)
		
		if player.has_method("get_current_speed"):
			_on_player_speed_changed(player.get_current_speed())
		elif "current_speed" in player:
			_on_player_speed_changed(player.current_speed)
		
		if player.has_method("get_score_multiplier"):
			_on_multiplier_changed(player.get_score_multiplier())
		elif "score_multiplier" in player:
			_on_multiplier_changed(player.score_multiplier)

func _process(delta):
	# Update score from GameState (polling as fallback)
	if has_node("/root/GameState"):
		score_label.text = "Score: " + str(GameState.current_score)
		
		# Debug - update debug label if it exists
		if debug_label:
			debug_label.text = "Score: " + str(GameState.current_score)

func _on_player_health_changed(new_health: int):
	#print("UI: Health changed to ", new_health)
	if health_bar:
		health_bar.value = new_health
	if health_label:
		health_label.text = "HP: " + str(new_health)

func _on_player_speed_changed(current_speed: float):
	# Only print occasionally to avoid spam
	# print("UI: Speed changed to ", current_speed)
	if speed_label:
		speed_label.text = "Speed: " + str(int(current_speed))

func _on_multiplier_changed(multiplier: float):
	#print("UI: Multiplier changed to ", multiplier)
	if multiplier_label:
		multiplier_label.text = "x" + str(round(multiplier * 10) / 10.0)

# Optional: Debug function to test UI manually
func test_ui():
	print("=== TESTING UI ===")
	_on_player_health_changed(7)
	_on_player_speed_changed(350)
	_on_multiplier_changed(3.5)

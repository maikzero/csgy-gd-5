# UI.gd - Attached to CanvasLayer in UI.tscn
extends CanvasLayer

# Get references to UI elements using @onready
@onready var health_bar = $HealthBar
@onready var score_label = $ScoreLabel
@onready var speed_value = $SpeedContainer/SpeedValue
@onready var multiplier_label = $MultiplierLabel
@onready var death_screen = $DeathScreen  # Optional

# Optional: Animation player for UI effects
@onready var animation_player = $AnimationPlayer

func _ready():
	# Hide death screen at start
	if death_screen:
		death_screen.visible = false
	
	# Find player and connect to its signals
	# Wait one frame to ensure player exists
	await get_tree().process_frame
	
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.health_changed.connect(_on_player_health_changed)
		player.speed_changed.connect(_on_player_speed_changed)
		player.score_multiplier_changed.connect(_on_multiplier_changed)
		
		# Also connect to GameState if you want score updates
		# Note: GameState is an Autoload, always available

func _process(delta):
	# Update score from GameState (or connect a signal)
	score_label.text = "Score: " + str(GameState.current_score)

func _on_player_health_changed(new_health: int):
	health_bar.value = new_health
	
	# Optional: Flash red when health low
	if new_health <= 3:
		animation_player.play("low_health_flash")
	else:
		animation_player.stop()

func _on_player_speed_changed(current_speed: float):
	speed_value.text = str(int(current_speed))

func _on_multiplier_changed(multiplier: float):
	multiplier_label.text = "x%.1f" % multiplier
	
	# Optional: Scale text based on multiplier
	multiplier_label.scale = Vector2(1.0 + multiplier * 0.1, 1.0 + multiplier * 0.1)

func show_death_screen():
	if death_screen:
		death_screen.visible = true
		# Maybe show final score
		var final_score_label = death_screen.get_node("FinalScore")
		if final_score_label:
			final_score_label.text = "Final Score: " + str(GameState.current_score)

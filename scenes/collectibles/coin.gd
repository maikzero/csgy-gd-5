# Coin.gd
extends Area2D
class_name Coin

# Signals
signal collected(coin_value: int)

# Export variables
@export var value: int = 10  # Base point value
@export var health_value: int = 100  # HP restored
@export var collect_sound: AudioStream
#@export var particle_effect: PackedScened

# Node references
@onready var sprite = $Sprite2D
@onready var collision = $CollisionShape2D
@onready var audio_player = $AudioStreamPlayer2D
@onready var particles = $GPUParticles2D

# State
var is_collected: bool = false
var float_tween: Tween


func _ready():
	# Connect the body_entered signal
	body_entered.connect(_on_body_entered)
	
	# Start floating animation
	start_floating_animation()
	
	# Add to group for easy finding
	add_to_group("collectibles")

func start_floating_animation():
	# Create floating animation
	float_tween = create_tween()
	float_tween.set_loops()  # loops indefinitely
	float_tween.set_ease(Tween.EASE_IN_OUT)
	float_tween.set_trans(Tween.TRANS_SINE)
	
	# Store original Y position
	var original_y = sprite.position.y
	
	# Float up and down
	float_tween.tween_property(sprite, "position:y", original_y - 10, 1.0)
	float_tween.tween_property(sprite, "position:y", original_y, 1.0)

func _on_body_entered(body: Node):
	if is_collected:
		return
	
	# Check if it's the player
	if body.is_in_group("player") or body is Player:
		collect(body)

func collect(player: Node):
	is_collected = true
	
	# Stop floating animation
	if float_tween:
		float_tween.kill()
	
	# Calculate score with speed multiplier
	var final_score = value
	if player.has_method("get_score_multiplier"):
		final_score = int(value * player.get_score_multiplier())
	elif "score_multiplier" in player:
		final_score = int(value * player.score_multiplier)
	
	# Add to game score
	if has_node("/root/GameState"):
		GameState.current_score += final_score
		print("Coin collected! +", final_score, " points")
	
	# --- NEW: Give health to player ---
	if player.has_method("collect_hp"):
		player.collect_hp(health_value)
		print("Coin gave +", health_value, " HP")
	elif "health" in player:
		# Direct health manipulation if no method
		player.health = min(player.health + health_value, player.max_health)
		print("Coin gave +", health_value, " HP (direct)")
	
	# Emit signal
	collected.emit(final_score)
	
	# Play effects
	play_collect_effects()
	
	# Disable collision and hide sprite
	collision.set_deferred("disabled", true)
	sprite.visible = false
	
	# Queue free after effects finish
	await get_tree().create_timer(1.0).timeout
	queue_free()

func play_collect_effects():
	# Play sound
	if audio_player and collect_sound:
		audio_player.stream = collect_sound
		audio_player.play()
	
	# Play particles
	if particles:
		particles.emitting = true
	
	# Create score popup
	create_score_popup()

func create_score_popup():
	var label = Label.new()
	label.text = "+" + str(value)
	label.modulate = Color.YELLOW
	label.position = Vector2(-20, -30)
	label.add_theme_color_override("font_color", Color.YELLOW)
	label.add_theme_font_size_override("font_size", 24)
	add_child(label)
	
	# Animate popup
	var popup_tween = create_tween()
	popup_tween.set_parallel(true)
	popup_tween.tween_property(label, "position:y", label.position.y - 50, 1.0)
	popup_tween.tween_property(label, "modulate:a", 0.0, 1.0)
	popup_tween.tween_callback(label.queue_free)

func _process(delta):
	if not is_collected and sprite:
		sprite.rotation += delta * 2.0  # Spin slowly

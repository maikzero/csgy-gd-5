# Coin.gd
extends Area2D
class_name Coin

# Signals
signal collected(coin_value: int)

# Export variables
@export var value: int = 10
@export var collect_sound: AudioStream
@export var particle_effect: PackedScene

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

func start_floating_animation():
	# CORRECT WAY: Create a tween and chain methods properly
	float_tween = create_tween()
	float_tween.set_loops()  # loops indefinitely
	float_tween.set_ease(Tween.EASE_IN_OUT)
	float_tween.set_trans(Tween.TRANS_SINE)
	
	# Add the property animation to the tween
	float_tween.tween_property(sprite, "position:y", sprite.position.y - 10, 1.0)
	float_tween.tween_property(sprite, "position:y", sprite.position.y, 1.0)

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
	var final_value = value
	if player.has_method("get_score_multiplier"):
		final_value = int(value * player.get_score_multiplier())
	elif "score_multiplier" in player:
		final_value = int(value * player.score_multiplier)
	
	# Add to game score
	if has_node("/root/GameState"):
		GameState.current_score += final_value
		print("Coin collected! +", final_value, " points")
	
	# Emit signal
	collected.emit(final_value)
	
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
	elif audio_player:
		# Play default sound if available
		pass
	
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

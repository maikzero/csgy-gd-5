extends CharacterBody2D
class_name Player

# Exported variables (editable in inspector)
@export var base_speed: float = 100.0
@export var max_speed: float = 800.0
@export var acceleration: float = 150.0
@export var deceleration: float = 50.0
@export var jump_velocity: float = -400.0
@export var max_health: int = 1000
@export var health_drain_rate: float = 1.0  # per second

# State variables
var current_speed: float = 100.0
var health: int = 10:
	set(value):
		health = min(value, max_health)
		health_changed.emit(health)  # Auto-update UI

var double_jumps_remaining: int = 1
var was_on_floor: bool = false

# Signals
signal health_changed(new_health: int)
signal died()
signal score_multiplier_changed(multiplier: float)

func _ready():
	health = max_health
	# Connect to game manager
	GameState.reset_run()

func _process(delta: float):
	# Health drain over time
	health -= health_drain_rate * delta
	if health <= 0:
		die()
	
	# Speed = score multiplier
	var multiplier = current_speed / 100.0
	score_multiplier_changed.emit(multiplier)

func _physics_process(delta: float):
	# Speed management
	if Input.is_action_pressed("move_right"):
		current_speed = min(current_speed + acceleration * delta, max_speed)
	else:
		current_speed = max(current_speed - deceleration * delta, base_speed)
	
	# Apply horizontal movement
	velocity.x = current_speed
	
	# Jump handling (with double jump)
	if Input.is_action_just_pressed("jump"):
		if is_on_floor():
			velocity.y = jump_velocity
			double_jumps_remaining = 1
		elif double_jumps_remaining > 0:
			velocity.y = jump_velocity * 0.8  # Weaker double jump
			double_jumps_remaining -= 1
	
	# Gravity
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	move_and_slide()
	
	# Reset double jump when landing
	if is_on_floor() and not was_on_floor:
		double_jumps_remaining = 1
	
	was_on_floor = is_on_floor()

func die():
	died.emit()
	# GameManager will handle restart

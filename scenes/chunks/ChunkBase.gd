# ChunkBase.gd
extends Node2D
class_name ChunkBase

# Signals
signal chunk_entered_view()
signal chunk_exited_view()
signal player_entered_chunk(player: Node)

# Exported variables
@export var chunk_data: ChunkData
@export var chunk_width: float = 2000.0
@export var background_color: Color = Color.WHITE

# Node references
@onready var visuals = $Visuals
@onready var collision = $Collision
@onready var spawn_points = $SpawnPoints
@onready var visibility_notifier = $VisibleOnScreenNotifier2D

# State
var is_active: bool = false
var has_spawned_items: bool = false
var chunk_seed: int = 0

func _ready():
	# Connect visibility signals if notifier exists
	if visibility_notifier:
		visibility_notifier.screen_entered.connect(_on_screen_entered)
		visibility_notifier.screen_exited.connect(_on_screen_exited)
	else:
		print("Warning: No VisibleOnScreenNotifier2D found in chunk")
	
	# Set a random seed for this chunk's variations
	chunk_seed = randi()
	
	# Apply any random variations based on seed
	apply_seed_variations()
	
	# Add to chunk group for easy finding
	add_to_group("chunks")

func _on_screen_entered():
	# Chunk is now visible - activate it
	is_active = true
	chunk_entered_view.emit()
	
	# Spawn items if we haven't yet
	if not has_spawned_items:
		# Use call_deferred to spawn after chunk is fully ready
		call_deferred("spawn_collectibles")
		has_spawned_items = true

func _on_screen_exited():
	# Chunk is no longer visible
	is_active = false
	chunk_exited_view.emit()
	
	# Don't delete here - GameManager handles cleanup

func apply_seed_variations():
	"""Use chunk_seed to add visual variety"""
	seed(chunk_seed)
	
	# Example: Randomly flip decorations
	if visuals:
		for child in visuals.get_children():
			if child.name.begins_with("Decoration") and randi() % 2 == 0:
				child.scale.x *= -1  # Flip horizontally

func spawn_collectibles():
	"""Called by generator or when chunk enters view to populate the chunk"""
	if not spawn_points:
		print("No spawn points found in chunk")
		return
	
	# Set seed for consistent spawning
	seed(chunk_seed)
	
	print("Spawning collectibles in chunk: ", global_position.x)
	
	for spawn in spawn_points.get_children():
		if spawn is Marker2D:
			_spawn_item_at_marker(spawn)

func _spawn_item_at_marker(marker: Marker2D):
	"""Spawn appropriate item based on marker name"""
	var item_scene: PackedScene
	var item_name = marker.name.to_lower()
	
	# Determine what to spawn based on marker name
	if "coin" in item_name:
		item_scene = preload("res://scenes/collectibles/Coin.tscn")
	#elif "hp" in item_name or "health" in item_name:
		#item_scene = preload("res://scenes/collectibles/HealthCrystal.tscn")
	#elif "enemy" in item_name:
		#item_scene = preload("res://scenes/enemies/BasicEnemy.tscn")
	#elif "speed" in item_name:
		#item_scene = preload("res://scenes/collectibles/SpeedBoost.tscn")
	#else:
		## Unknown marker type - maybe it's for something else
		#return
	
	# Make sure the scene exists before instantiating
	if not ResourceLoader.exists(item_scene.resource_path):
		print("Warning: Scene not found for marker: ", marker.name)
		return
	
	# Instantiate and position
	var item = item_scene.instantiate()
	item.position = marker.position
	
	# Add random offset based on seed for variety
	if randi() % 2 == 0:
		item.position.x += randf_range(-20, 20)
	
	# Add to chunk
	add_child(item)
	
	print("Spawned ", marker.name, " at position: ", marker.position)

func get_chunk_start_x() -> float:
	"""Get the left edge of this chunk"""
	return global_position.x

func get_chunk_end_x() -> float:
	"""Get the right edge of this chunk"""
	return global_position.x + chunk_width

func is_player_inside(player_x: float) -> bool:
	"""Check if player is within this chunk's bounds"""
	return player_x >= get_chunk_start_x() and player_x <= get_chunk_end_x()

# Optional: Visual debug in editor
func _draw():
	if Engine.is_editor_hint():
		# Draw chunk boundary in editor
		draw_rect(Rect2(0, -500, chunk_width, 1000), Color.GREEN, false, 2.0)
		
		# Draw chunk name
		if chunk_data and chunk_data.chunk_name:
			var font = ThemeDB.fallback_font
			var font_size = ThemeDB.fallback_font_size
			draw_string(font, Vector2(10, -50), chunk_data.chunk_name,
					   HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color.YELLOW)

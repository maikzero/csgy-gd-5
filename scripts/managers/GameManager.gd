# GameManager.gd
extends Node

# Get references to sibling nodes
@onready var player = $"../Player"
@onready var world = $"../World"
@onready var generator = $"../ChunkGenerator"
@onready var ui = $"../UI"

var chunks_ahead = 3
var chunks_behind = 2
var chunk_width_estimate = 2000

func _ready():
	# Debug: Check if we found everything
	print("=== GameManager Started ===")
	print("Player found: ", player != null)
	print("World found: ", world != null)
	print("Generator found: ", generator != null)
	print("UI found: ", ui != null)
	
	if not player or not world or not generator:
		push_error("Missing required nodes!")
		return
	
	# Connect to player signals
	if player.has_signal("died"):
		player.died.connect(_on_player_died)
	
	# IMPORTANT: Set up generator references
	generator.world_node = world
	
	# Generate initial chunks
	print("Generating initial chunks...")
	for i in chunks_ahead:
		generate_chunk()

func _process(delta):
	if not player or not world or not generator:
		return
	
	# Check if we need more chunks
	var player_x = player.global_position.x
	var farthest_x = get_farthest_chunk_x()
	
	# If player is getting close to the end, generate more
	if player_x > farthest_x - (chunk_width_estimate * 1.5):
		print("Generating new chunk - player at: ", player_x, ", farthest: ", farthest_x)
		generate_chunk()
	
	# Clean up old chunks
	cleanup_behind_player(player_x - (chunk_width_estimate * chunks_behind))
	
func _unhandled_input(event: InputEvent):
	if event.is_action_pressed("restart"):
		get_tree().reload_current_scene()

func generate_chunk():
	if generator and player:
		var new_chunk = generator.generate_chunk(player.current_speed, player.health)
		if new_chunk:
			print("✅ Generated chunk at x: ", new_chunk.global_position.x)
			return new_chunk
		else:
			print("❌ Failed to generate chunk")
	return null

func get_farthest_chunk_x() -> float:
	var max_x = 0.0
	for chunk in world.get_children():
		if chunk is ChunkBase:
			var chunk_end = chunk.get_chunk_end_x()
			max_x = max(max_x, chunk_end)
	
	# If no chunks yet, return player position
	if max_x == 0.0 and player:
		max_x = player.global_position.x
	
	return max_x

func cleanup_behind_player(limit_x: float):
	var removed_count = 0
	for chunk in world.get_children():
		if chunk is ChunkBase and chunk.get_chunk_end_x() < limit_x:
			chunk.queue_free()
			removed_count += 1
	
	if removed_count > 0:
		print("Cleaned up ", removed_count, " chunks behind player")

func _on_player_died():
	print("Player died!")
	if ui and ui.has_method("show_death_screen"):
		ui.show_death_screen()

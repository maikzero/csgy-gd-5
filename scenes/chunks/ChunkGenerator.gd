# ChunkGenerator.gd
extends Node

@export var chunk_pool: Array[ChunkData]
@export var world_node: Node2D

# Make player reference optional - GameManager can set it
var player: Player
var next_spawn_x: float = 0.0
var recent_chunks: Array[ChunkData] = []
const MAX_RECENT_CHUNKS = 3

var is_first_chunk: bool = true

func _ready():
	# Try to load chunks from resources if pool is empty
	if chunk_pool.is_empty():
		load_chunks_from_resources()

func load_chunks_from_resources():
	"""Automatically load chunk resources from the folder"""
	var chunk_dir = "res://resources/chunk_data/"
	if DirAccess.dir_exists_absolute(chunk_dir):
		var dir = DirAccess.open(chunk_dir)
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if file_name.ends_with(".tres") or file_name.ends_with(".res"):
				var chunk = load(chunk_dir + file_name)
				if chunk and chunk is ChunkData:
					chunk_pool.append(chunk)
					print("Loaded chunk: ", chunk.chunk_name)
			file_name = dir.get_next()
			
			

# Enhanced version with weighted selection
func select_weighted_chunk(available_chunks: Array) -> ChunkData:
	"""Select a chunk using weighted probability based on spawn_weight"""
	if available_chunks.is_empty():
		return null
	
	# Calculate total weight
	var total_weight = 0.0
	for chunk in available_chunks:
		total_weight += chunk.spawn_weight
	
	# Pick a random value within total weight
	var random_value = randf() * total_weight
	
	# Find which chunk it lands on
	var current_weight = 0.0
	for chunk in available_chunks:
		current_weight += chunk.spawn_weight
		if current_weight >= random_value:
			return chunk
	
	# Fallback to first chunk
	return available_chunks[0]

# Updated generate_chunk using weighted selection
func generate_chunk(player_speed: float = 100.0, player_health: float = 10.0) -> ChunkBase:
	# SAFETY CHECK: Make sure we have chunks to spawn
	if chunk_pool.is_empty():
		push_error("No chunks in chunk_pool! Cannot generate chunk.")
		return null
	
	# Filter chunks by speed requirements
	var valid_chunks = chunk_pool.filter(func(chunk): 
		return chunk.min_speed <= player_speed and chunk.max_speed >= player_speed
	)
	
	# If no chunks match speed, use all chunks
	if valid_chunks.is_empty():
		valid_chunks = chunk_pool
		print("No chunks match speed ", player_speed, ", using all chunks")
	
	# Avoid recent repeats
	var available = valid_chunks.filter(func(c): return not recent_chunks.has(c))
	
	# If all chunks are recent, use valid_chunks
	if available.is_empty():
		available = valid_chunks
	
	# Use weighted selection
	var selected = select_weighted_chunk(available)
	
	if not selected:
		push_error("Failed to select chunk!")
		return null
	
	# Track recent chunks
	recent_chunks.append(selected)
	if recent_chunks.size() > MAX_RECENT_CHUNKS:
		recent_chunks.pop_front()
	
	# Spawn it
	if not selected.scene:
		push_error("Chunk '", selected.chunk_name, "' has no scene assigned!")
		return null
	
	var chunk = selected.scene.instantiate() as ChunkBase
	if not chunk:
		push_error("Failed to instantiate chunk scene!")
		return null
		
	if is_first_chunk:
		# Position the first chunk so its LEFT edge is at player start
		# Assuming player spawns at (0,0) and chunk width is 2000
		#chunk.position.x = -500  # Adjust this value based on where you want the player
		
		# Or better: Position so player is in the middle of first chunk
		chunk.position.x = -chunk.chunk_width / 2  # Center player in chunk
		
		is_first_chunk = false
	else:
		# Normal positioning for subsequent chunks
		chunk.position.x = next_spawn_x
	
	#chunk.position.x = next_spawn_x
	world_node.add_child(chunk)
	
	# Update spawn position
	next_spawn_x = chunk.position.x + chunk.chunk_width
	
	print("Generated chunk: ", selected.chunk_name, " at x: ", chunk.position.x)
	return chunk
	
func reset_generator():
	"""Call this when starting a new run"""
	next_spawn_x = 0.0
	recent_chunks.clear()

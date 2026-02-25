# ChunkData.gd
extends Resource
class_name ChunkData

# Basic info
@export var chunk_name: String = "New Chunk"
@export var scene: PackedScene  # Reference to the actual chunk scene

# Visual preview in inspector
@export var preview: Texture2D

# Difficulty and speed requirements
@export_range(1, 5) var difficulty: int = 1
@export var min_speed: float = 100.0
@export var max_speed: float = 8000.0

# Chunk type for categorization
@export_enum("Platform", "Gap", "Enemy", "Bonus", "Obstacle", "MultiLevel") 
var chunk_type: String = "Platform"

# Spawn probability weight (higher = more common)
@export var spawn_weight: float = 1.0

# Special properties
@export var requires_double_jump: bool = false
@export var forced_height_offset: float = 0.0

# Optional: Custom generation parameters
@export var min_spawn_count: int = 1
@export var max_spawn_count: int = 3

# Optional: Visual theme info
@export var background_color: Color = Color.WHITE

# Collectible.gd
extends Area2D
class_name Collectible

@export var value: int = 10
@export var collect_sound: AudioStream
@export var particle_effect: PackedScene

signal collected(collector: Node, value: int)

func _ready():
	# Modern connection syntax
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node):
	if body is Player:
		# Emit with value
		collected.emit(body, value)
		
		# Visual feedback
		if particle_effect:
			var particles = particle_effect.instantiate()
			get_parent().add_child(particles)
			particles.global_position = global_position
		
		# Play sound
		if collect_sound and has_node("/root/AudioPlayer"):
			$"/root/AudioPlayer".play_sound(collect_sound)
		
		queue_free()

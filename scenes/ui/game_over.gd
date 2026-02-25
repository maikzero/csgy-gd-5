extends Control

func _unhandled_input(event: InputEvent):
	if event.is_action_pressed("restart"):
		get_tree().change_scene_to_file("res://scenes/main/Main.tscn")

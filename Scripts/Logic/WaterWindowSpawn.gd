# TestScene.gd
extends Node2D

var window_scene := preload("res://Scenes/WindowTest.tscn")  # Adjust path as needed

func _on_pond_pressed():  # Fixed function name formatting
	var new_window := window_scene.instantiate()
	add_child(new_window)
	# Spawn window at random position
	new_window.position = Vector2(
		randf_range(0, get_viewport_rect().size.x - 200),
		randf_range(0, get_viewport_rect().size.y - 150)
	)

	get_tree().call_group("window_buttons", "release_focus")

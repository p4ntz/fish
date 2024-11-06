extends Control

var original_size = Vector2(0, 0)

func _ready():
	original_size = size
	get_tree().get_root().size_changed.connect(_on_screen_resized)
	_on_screen_resized()

func _on_screen_resized():
	# Convert viewport size to Vector2 and calculate scale
	var window_size = Vector2(get_viewport().size)
	var scale_factor = Vector2(
		window_size.x / original_size.x,
		window_size.y / original_size.y
	)
	
	# Update size to match container
	size = window_size
	
	# Scale children
	for child in get_children():
		if child is Control:
			child.scale = scale_factor
			child.size = child.size * scale_factor
			
			# Update anchors if needed
			child.anchor_right = 1
			child.anchor_bottom = 1

extends Control

@onready var window_content = $WindowContent
@onready var title_bar = $TitleBar
@onready var close_button = $TitleBar/CloseButton
@onready var window_title = $TitleBar/Title 
@onready var resize_handle = $ResizeHandle

var dragging = false
var drag_start_pos = Vector2()
var resizing = false
var resize_start_pos = Vector2()
var min_size = Vector2(200, 150)
var default_window_scale = 0.25

func _ready():
	close_button.pressed.connect(_on_close_button_pressed)
	title_bar.gui_input.connect(_on_title_bar_input)
	resize_handle.gui_input.connect(_on_resize_handle_input)
	
	var viewport_size = get_viewport_rect().size
	size = viewport_size * default_window_scale
	
	position = Vector2(
		(viewport_size.x - size.x) * 0.5,
		(viewport_size.y - size.y) * 0.5
	)
	
	top_level = true
	window_content.clip_contents = true

func load_scene(scene_path: String, title: String = "Window"):
	for child in window_content.get_children():
		child.queue_free()
	
	var viewport_container = SubViewportContainer.new()
	viewport_container.stretch = true
	viewport_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	viewport_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	viewport_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	
	var viewport = SubViewport.new()
	viewport.transparent_bg = true
	viewport.handle_input_locally = true
	viewport.size = window_content.size
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	
	viewport_container.add_child(viewport)
	
	var scene_resource = load(scene_path)
	if scene_resource:
		var instance = scene_resource.instantiate()
		viewport.add_child(instance)
		
		if instance is Node2D:
			# Get the original content size
			var content_size = _calculate_node2d_size(instance)
			if content_size != Vector2.ZERO:
				# Store the original aspect ratio
				var original_aspect = content_size.x / content_size.y
				
				# Calculate scale to match window size while maintaining aspect ratio
				var window_aspect = window_content.size.x / window_content.size.y
				var scale_factor: Vector2
				
				if window_aspect > original_aspect:
					# Window is wider than content
					scale_factor = Vector2(
						window_content.size.y / content_size.y,
						window_content.size.y / content_size.y
					)
				else:
					# Window is taller than content
					scale_factor = Vector2(
						window_content.size.x / content_size.x,
						window_content.size.x / content_size.x
					)
				
				instance.scale = scale_factor
				instance.position = viewport.size / 2
	
	window_content.add_child(viewport_container)
	window_title.text = title

func _on_resize_handle_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			resizing = event.pressed
			resize_start_pos = get_global_mouse_position()
	
	elif event is InputEventMouseMotion and resizing:
		var new_size = size + (get_global_mouse_position() - resize_start_pos)
		size.x = max(new_size.x, min_size.x)
		size.y = max(new_size.y, min_size.y)
		resize_start_pos = get_global_mouse_position()
		
		# Update viewport and content size
		if window_content.get_child_count() > 0:
			var viewport_container = window_content.get_child(0)
			if viewport_container is SubViewportContainer:
				var viewport = viewport_container.get_child(0)
				if viewport is SubViewport:
					viewport.size = window_content.size
					
					if viewport.get_child_count() > 0:
						var content = viewport.get_child(0)
						if content is Node2D:
							var content_size = _calculate_node2d_size(content)
							if content_size != Vector2.ZERO:
								var original_aspect = content_size.x / content_size.y
								var window_aspect = window_content.size.x / window_content.size.y
								
								var scale_factor: Vector2
								if window_aspect > original_aspect:
									scale_factor = Vector2(
										window_content.size.y / content_size.y,
										window_content.size.y / content_size.y
									)
								else:
									scale_factor = Vector2(
										window_content.size.x / content_size.x,
										window_content.size.x / content_size.x
									)
								
								content.scale = scale_factor
								content.position = viewport.size / 2

func _calculate_node2d_size(node: Node2D) -> Vector2:
	var size = Vector2.ZERO
	
	if node is Sprite2D:
		size = node.texture.get_size() * node.scale if node.texture else Vector2.ZERO
	elif node is CollisionShape2D and node.shape:
		if node.shape is RectangleShape2D:
			size = node.shape.size * node.scale
		elif node.shape is CircleShape2D:
			var radius = node.shape.radius
			size = Vector2(radius * 2, radius * 2) * node.scale
	
	for child in node.get_children():
		if child is Node2D:
			var child_size = _calculate_node2d_size(child)
			size = size.max(child_size)
	
	return size

func _on_close_button_pressed():
	queue_free()

func _on_title_bar_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			dragging = event.pressed
			drag_start_pos = get_global_mouse_position() - position
	
	elif event is InputEventMouseMotion and dragging:
		position = get_global_mouse_position() - drag_start_pos
		position.x = clamp(position.x, 0, get_viewport_rect().size.x - size.x)
		position.y = clamp(position.y, 0, get_viewport_rect().size.y - size.y)

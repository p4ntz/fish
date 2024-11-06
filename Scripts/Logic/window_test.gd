extends Control

const INITIAL_WINDOW_SIZE = Vector2(200, 150)
const RESIZE_HANDLE_SIZE = 10
var is_resizing = false
var border_offset = Vector2(5, 5)
var handle_size = Vector2(10, 10)
var resize_start_pos = Vector2()
var resize_start_size = Vector2()

@onready var window_content = $WindowContent
@onready var title_bar = $TitleBar
@onready var close_button = $TitleBar/CloseButton
@onready var window_title = $TitleBar/Title 
@onready var resize_handle = $ResizeHandle

var dragging = false
var drag_start_pos = Vector2()
var resizing = false
var min_size = Vector2(300, 200)
var default_window_scale = 0.75

signal window_closed
var handle_opacity = 0.3

# Store reference to viewport
var viewport: Viewport

func _ready():
	self.set_modulate(Color(1, 1, 1, 1))
	viewport = get_viewport()
	if not viewport:
		push_error("Failed to get viewport reference")
		return
	
	# Connect signals
	close_button.pressed.connect(_on_close_button_pressed)
	title_bar.gui_input.connect(_on_title_bar_input)
	resize_handle.gui_input.connect(_on_resize_handle_input)
	
	size = min_size
	custom_minimum_size += Vector2(10, 10)

	position = (viewport.get_visible_rect().size - size) / 2

	# Connect to the fish_game_over signal of the fishing scene
	var fishing_scene = $WindowContent.get_node_or_null("SubViewportContainer/SubViewport/FishingScene")
	if fishing_scene:
		fishing_scene.connect("fish_game_over", Callable(self, "_on_fish_game_over"))

	
	# Connect to viewport size changed signal to handle viewport resizing
	viewport.size_changed.connect(_on_viewport_size_changed)
	
	# Initial setup
	_update_window_size_and_position()
	_update_child_sizes(size)
	
	top_level = true
	window_content.clip_contents = true

	set_process_input(true)

	# Set up anchors and size flags
	if $TitleBar:
		$TitleBar.set_anchors_preset(Control.PRESET_TOP_WIDE)
		$TitleBar.set_h_size_flags(Control.SIZE_FILL)
	
	if window_content:
		window_content.set_anchors_preset(Control.PRESET_FULL_RECT)
		window_content.set_h_size_flags(Control.SIZE_FILL)
		window_content.set_v_size_flags(Control.SIZE_FILL)
		# Account for title bar
		window_content.offset_top = $TitleBar.size.y if $TitleBar else 0

	queue_redraw()
	add_to_group("game_windows")
	Globals.connect("fishing_game_over", Callable(self, "request_close"))

func _update_window_size_and_position():
	# Get current viewport size
	var viewport_size = viewport.get_visible_rect().size
	
	# Set window size based on viewport
	size = viewport_size * default_window_scale
	
	# Center the window in the viewport
	position = (viewport_size - size) / 2
	
	# Ensure window stays within viewport bounds
	_clamp_to_viewport()

func _clamp_to_viewport():
	var viewport_size = viewport.get_visible_rect().size
	position.x = clamp(position.x, 0, viewport_size.x - size.x)
	position.y = clamp(position.y, 0, viewport_size.y - size.y)

func _on_viewport_size_changed():
	_clamp_to_viewport()

func load_scene(scene_path: String, title: String = "Window"):
	for child in window_content.get_children():
		child.queue_free()
	
	var viewport_container = SubViewportContainer.new()
	viewport_container.stretch = true
	viewport_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	viewport_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	viewport_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	
	var sub_viewport = SubViewport.new()
	sub_viewport.transparent_bg = true
	sub_viewport.handle_input_locally = true
	sub_viewport.size = window_content.size
	sub_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	
	viewport_container.add_child(sub_viewport)
	
	var scene_resource = load(scene_path)
	if scene_resource:
		var instance = scene_resource.instantiate()
		sub_viewport.add_child(instance)
		print(scene_path)

		if scene_path.ends_with("fishing.tscn"):
			print("Connecting fish_game_over signal")
			# Try direct connection
			if instance.has_signal("fish_game_over"):
				instance.connect("fish_game_over", Callable(self, "request_close"))
				print("Signal connected successfully")
			
			# Add instance to group for alternative approach
			instance.add_to_group("fishing_game")
		
		if instance is Node2D:
			var content_size = _calculate_node2d_size(instance)
			if content_size != Vector2.ZERO:
				_update_content_scale(sub_viewport)
	
	window_content.add_child(viewport_container)
	window_title.text = title
	
	# Center the window when loading new content
	_update_window_size_and_position()

func _on_resize_handle_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			resizing = event.pressed
			resize_start_pos = get_global_mouse_position()
	
	elif event is InputEventMouseMotion and resizing:
		var new_size = size + (get_global_mouse_position() - resize_start_pos)
		size.x = max(new_size.x, min_size.x)
		size.y = max(new_size.y, min_size.y)
		
		# Clamp size to viewport
		var viewport_size = viewport.get_visible_rect().size
		size.x = min(size.x, viewport_size.x)
		size.y = min(size.y, viewport_size.y)
		
		resize_start_pos = get_global_mouse_position()
		
		# Update viewport and content size
		if window_content.get_child_count() > 0:
			var viewport_container = window_content.get_child(0)
			if viewport_container is SubViewportContainer:
				var sub_viewport = viewport_container.get_child(0)
				if sub_viewport is SubViewport:
					sub_viewport.size = window_content.size
					
					if sub_viewport.get_child_count() > 0:
						var content = sub_viewport.get_child(0)
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
								content.position = sub_viewport.size / 2
		
		# Ensure window stays within viewport after resize
		_clamp_to_viewport()

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

func external_close_request():
	queue_free()

func _on_title_bar_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			dragging = event.pressed
			drag_start_pos = get_global_mouse_position() - position
	
	elif event is InputEventMouseMotion and dragging:
		position = get_global_mouse_position() - drag_start_pos
		_clamp_to_viewport()

func _input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			# Check if the mouse is near any edge of the window
			var mouse_pos = get_local_mouse_position()
			var edge_threshold = 10  # pixels from the edge to start resizing
			
			if mouse_pos.x < edge_threshold or mouse_pos.x > size.x - edge_threshold or \
			   mouse_pos.y < edge_threshold or mouse_pos.y > size.y - edge_threshold:
				is_resizing = true
				resize_start_pos = event.position
				resize_start_size = size
				accept_event()
		else:
			is_resizing = false
	
	elif event is InputEventMouseMotion and is_resizing:
		var new_size = resize_start_size + (event.position - resize_start_pos)
		
		# Enforce minimum size
		new_size.x = max(200, new_size.x)
		new_size.y = max(150, new_size.y)
		
		# Update window size
		custom_minimum_size = new_size
		size = new_size
		
		# Update all child controls
		_update_child_sizes(new_size)
		
		notification(NOTIFICATION_RESIZED)
		_clamp_to_viewport()
		accept_event()
		queue_redraw()

func _update_child_sizes(new_size: Vector2):
	
	if $TitleBar:
		$TitleBar.custom_minimum_size.x = new_size.x
		$TitleBar.size.x = new_size.x
		
		if $TitleBar/Title:
			$TitleBar/Title.position.x = (new_size.x / 2) - $TitleBar/CloseButton.size.x
		
		if $TitleBar/CloseButton:
			$TitleBar/CloseButton.position.x = new_size.x - ($TitleBar/CloseButton.size.x + 5)
	
	if window_content:
		window_content.size = Vector2(new_size.x, new_size.y - ($TitleBar.size.y if $TitleBar else 0))
		
		# Update SubViewport size if it exists
		if window_content.get_child_count() > 0:
			var viewport_container = window_content.get_child(0)
			if viewport_container is SubViewportContainer:
				var sub_viewport = viewport_container.get_child(0)
				if sub_viewport is SubViewport:
					sub_viewport.size = window_content.size
					_update_content_scale(sub_viewport)

func _update_content_scale(sub_viewport: SubViewport):
	if sub_viewport.get_child_count() > 0:
		var content = sub_viewport.get_child(0)
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
				content.position = sub_viewport.size / 2

func _draw():

	draw_rect(Rect2(Vector2(), size), Globals.color_lightest, true)

	var border_thickness = 2.0  # Thicker border for Game Boy style
	var border_offset = Vector2(5, 5)
	var handle_size = Vector2(10, 10)
	
	# Use the darker colors for borders and handles
	var border_color = Globals.color_darkest  # Darkest green for main border
	var handle_color = Color(Globals.color_dark, handle_opacity)  # Dark green with transparency for handles
	
	# Draw main border
	var border_rect = Rect2(
		-border_offset,
		size + (border_offset * 2)
	)
	draw_rect(border_rect, border_color, false, border_thickness)
	
	# Draw handles
	# Corners
	draw_rect(Rect2(-border_offset - handle_size/2, handle_size), handle_color)
	draw_rect(Rect2(Vector2(size.x + border_offset.x - handle_size.x/2, -border_offset.y - handle_size.y/2), handle_size), handle_color)
	draw_rect(Rect2(Vector2(-border_offset.x - handle_size.x/2, size.y + border_offset.y - handle_size.y/2), handle_size), handle_color)
	draw_rect(Rect2(Vector2(size.x + border_offset.x - handle_size.x/2, size.y + border_offset.y - handle_size.y/2), handle_size), handle_color)
	
	# Edges
	# Top
	draw_rect(Rect2(
		Vector2(handle_size.x - border_offset.x/2, -border_offset.y - handle_size.y/2),
		Vector2(size.x - handle_size.x + border_offset.x, handle_size.y)
	), handle_color)
	
	# Left
	draw_rect(Rect2(
		Vector2(-border_offset.x - handle_size.x/2, handle_size.y - border_offset.y/2),
		Vector2(handle_size.x, size.y - handle_size.y + border_offset.y)
	), handle_color)
	
	# Right
	draw_rect(Rect2(
		Vector2(size.x + border_offset.x - handle_size.x/2, handle_size.y - border_offset.y/2),
		Vector2(handle_size.x, size.y - handle_size.y + border_offset.y)
	), handle_color)
	
	# Bottom
	draw_rect(Rect2(
		Vector2(handle_size.x - border_offset.x/2, size.y + border_offset.y - handle_size.y/2),
		Vector2(size.x - handle_size.x + border_offset.x, handle_size.y)
	), handle_color)

# Add this method to allow external closing
func request_close():
	emit_signal("window_closed")
	queue_free()

func _on_fish_game_over():
	request_close()

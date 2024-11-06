extends Control

var dragging := false
var resizing := false
var drag_start_pos := Vector2()
var start_window_pos := Vector2()
var start_window_size := Vector2()
var initial_size := Vector2()
var resize_handle_size := 20

var snap_points: Array[Vector2] = [
	Vector2(50, 650),  # Delete point
	Vector2(570, 500)  # Fishing location point
]
var snap_threshold := 100

var current_z_index := 0
static var top_z_index := 0

@onready var panel: Node = get_node("Panel")
@onready var label: Node = get_node("Panel/Label")

func _ready():
	print("Window started at position: ", position)
	mouse_filter = Control.MOUSE_FILTER_STOP
	initial_size = panel.size
	start_window_size = panel.size
	label.text = "Pond"
	
	current_z_index = top_z_index
	z_index = current_z_index
	top_z_index += 1

func bring_to_top():
	top_z_index += 1
	current_z_index = top_z_index
	z_index = current_z_index

func handle_snap_action(snap_index: int):
	if snap_index == 0:  # First snap point - delete window
		queue_free()
	elif snap_index == 1:  # Second snap point - add fishing location
		Globals.set_current_fishing_location(label.text.to_lower())
		print("Added fishing location: ", label.text, " at ", snap_points[1])

func _input(event) -> void:
	if z_index != top_z_index and (dragging or resizing):
		dragging = false
		resizing = false
		return
		
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		var mouse_pos: Vector2 = event.position - global_position
		if event.pressed:
			if _is_in_resize_handle(mouse_pos - panel.position):
				resizing = true
				dragging = false
				start_window_size = panel.size
				drag_start_pos = event.position
				bring_to_top()
			else:
				var panel_rect := Rect2(panel.position, panel.size)
				if panel_rect.has_point(mouse_pos):
					dragging = true
					resizing = false
					drag_start_pos = event.position
					start_window_pos = panel.position
					bring_to_top()
		else:
			if dragging:
				# Check if we're snapped to any point when releasing
				var global_window_center: Vector2 = global_position + panel.position + (panel.size / 2)
				for i in snap_points.size():
					var distance: float = global_window_center.distance_to(snap_points[i])
					if distance < snap_threshold:
						handle_snap_action(i)
						break
			dragging = false
			resizing = false
	
	elif event is InputEventMouseMotion:
		if dragging:
			var new_pos: Vector2 = start_window_pos + (event.position - drag_start_pos)
			
			var global_window_center: Vector2 = global_position + new_pos + (panel.size / 2)
			
			var closest_snap: Vector2 = Vector2.ZERO
			var closest_distance: float = snap_threshold
			var snap: bool = false
			
			for snap_point in snap_points:
				var distance: float = global_window_center.distance_to(snap_point)
				if distance < closest_distance:
					closest_distance = distance
					closest_snap = snap_point
					snap = true
			
			if snap:
				var local_snap_pos = closest_snap - global_position - (panel.size / 2)
				panel.position = local_snap_pos
			else:
				panel.position = new_pos
		
		elif resizing:
			var new_size: Vector2 = start_window_size + (event.position - drag_start_pos)
			new_size.x = max(100, new_size.x)
			new_size.y = max(100, new_size.y)
			
			panel.size = new_size
			_update_label_position()
			
			var width_height_ratio: float = panel.size.x / panel.size.y
			var height_width_ratio: float = panel.size.y / panel.size.x
			var size_ratio: float = (panel.size.x * panel.size.y) / (initial_size.x * initial_size.y)
			
			if width_height_ratio >= 4.0:
				label.text = "River"
			elif panel.size >= get_viewport().get_visible_rect().size:
				label.text = "Ocean"
			elif height_width_ratio >= 4.0:
				label.text = "Waterfall"
			elif size_ratio >= 2.0:
				label.text = "Lake"
			elif size_ratio <= 0.5:
				label.text = "Puddle"
			else:
				label.text = "Pond"
		
		queue_redraw()

func _draw():
	for point in snap_points:
		var local_point := point - global_position
		draw_circle(local_point, 5, Color.RED)
	
	if panel:
		var handle_pos = panel.position + panel.size - Vector2(resize_handle_size, resize_handle_size)
		draw_rect(Rect2(handle_pos, Vector2(resize_handle_size, resize_handle_size)), Color.GRAY)

func _is_in_resize_handle(mouse_pos: Vector2) -> bool:
	var handle_rect: Rect2 = Rect2(
		Vector2(panel.size.x - resize_handle_size, panel.size.y - resize_handle_size),
		Vector2(resize_handle_size, resize_handle_size)
	)
	return handle_rect.has_point(mouse_pos)
	
func _update_label_position():
	var label_rect = label.get_rect()
	var panel_rect = panel.get_rect()
	var center_x = (panel_rect.size.x / 2)
	var center_y = (panel_rect.size.y / 2)
	label.position = Vector2(center_x - (label_rect.size.x / 2), center_y - (label_rect.size.y / 2))

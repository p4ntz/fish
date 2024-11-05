extends Control

# TODO: Add snapping to certain points
# TODO: Fix resize handle of Label

var dragging := false
var resizing := false
var drag_start_pos := Vector2()
var start_window_pos := Vector2()
var start_window_size := Vector2()
var initial_size := Vector2()
var resize_handle_size := 20

var snap_points: Array[Vector2] = [
	Vector2(0, 600),
	Vector2(500, 500)
]
var snap_threshold := 200  # Increase this value for more powerful snapping

@onready var panel: Node = get_node("Panel")
@onready var label: Node = get_node("Panel/Label")

func _ready():
	print("Window started at position: ", position)
	mouse_filter = Control.MOUSE_FILTER_STOP
	initial_size = panel.size
	start_window_size = panel.size
	label.text = "Pond"

func _input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		var mouse_pos: Vector2 = event.position - position
		if event.pressed:
			print("Mouse pressed at: ", event.position)
			# Check if clicking in resize handle relative to panel position and size
			if _is_in_resize_handle(mouse_pos - panel.position):
				resizing = true
				dragging = false
				start_window_size = panel.size
				drag_start_pos = event.position
			else:
				# Only drag if clicking on the panel
				var panel_rect := Rect2(panel.position, panel.size)
				if panel_rect.has_point(mouse_pos):
					dragging = true
					resizing = false
					drag_start_pos = event.position
					start_window_pos = panel.position
		else:
			dragging = false
			resizing = false
			print("Mouse released at: ", event.position)
	
	elif event is InputEventMouseMotion:
		if dragging:
			print("Mouse Motion while dragging: ", event.position)
			var new_pos: Vector2 = start_window_pos + (event.position - drag_start_pos)
					
			var closest_snap: Vector2 
			var closest_distance: int = snap_threshold
			
			# Calculate the center of the window
			var window_center: Vector2 = new_pos + (panel.size / 2)
			
			for snap_point in snap_points:
				var distance: float = window_center.distance_to(snap_point)
				if distance < closest_distance:
					closest_distance = distance
					closest_snap = snap_point
			
			if closest_snap:
				# Snap the panel to the closest snap point
				print(panel.position)
				panel.position = closest_snap# - (panel.size / 2)
				print("Snapped to: ", closest_snap)
			else:
				# Move the panel to the new position
				panel.position = new_pos
				print("Moved to: ", new_pos)
		
		elif resizing:
			var new_size: Vector2 = start_window_size + (event.position - drag_start_pos)
			# Ensure minimum size
			new_size.x = max(100, new_size.x)
			new_size.y = max(100, new_size.y)
			
			# Update panel size
			panel.size = new_size
			_update_label_position()
			
			# Update label based on panel size ratio
			var size_ratio: float = (panel.size.x * panel.size.y) / (initial_size.x * initial_size.y)
			if size_ratio >= 2.0:
				label.text = "Lake"
			elif size_ratio <= 0.5:
				label.text = "Puddle"
			else:
				label.text = "Pond"
			
			print("New size: ", panel.size, " Ratio: ", size_ratio)
		
		queue_redraw()

func _draw():
	# Draw snap points
	for point in snap_points:
		draw_circle(point - position, 5, Color.RED)
	
	# Draw resize handle on panel
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
	print("panel size:")
	print(panel_rect.size.x)
	print(panel_rect.size.y)
	var center_x = (panel_rect.size.x / 2)
	var center_y = (panel_rect.size.y / 2)
	print(center_x)
	print(center_y)
	label.position = Vector2(center_x - (label_rect.size.x / 2), center_y - (label_rect.size.y / 2))

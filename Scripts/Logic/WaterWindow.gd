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

var current_z_index := -25
static var top_z_index := -25

@onready var panel: Node = get_node("Panel")
@onready var label: Node = get_node("Panel/Label")

var has_cave := false
var pending_cave_creation := false
var window_scene := preload("res://Scenes/WindowTest.tscn")  # Adjust path as needed

var water_bodies := ["Pond", "Lake", "River", "Ocean", "Waterfall", "Puddle"]
var cave_types := ["Cave", "Cavern", "Crevice"]
var deep_water_bodies := ["Deep Pond", "Sea", "Ravine", "Abyss", "Well"]

func _ready():
	print("Window started at position: ", position)
	mouse_filter = Control.MOUSE_FILTER_STOP
	initial_size = panel.size
	start_window_size = panel.size
	if label.text not in deep_water_bodies and label.text not in cave_types:
		label.text = "Pond"

	current_z_index = top_z_index
	z_index = current_z_index
	top_z_index += 1

func _process(delta):
	if pending_cave_creation:
		call_deferred("spawn_cave")
		pending_cave_creation = false

func bring_to_top():
	top_z_index += 1
	current_z_index = top_z_index
	z_index = current_z_index

func handle_snap_action(snap_index: int):
	if snap_index == 0:  # First snap point - delete window
		if label.text in cave_types:
			# Find the parent waterfall and set has_cave to false
			var parent = get_parent()
			for child in parent.get_children():
				if child is Control and child.has_method("get_label_text"):
					var child_label_text = child.get_label_text()
					if child_label_text in water_bodies and child.has_cave:
						child.has_cave = false
						break
		queue_free()
	elif snap_index == 1:  # Second snap point - add fishing location
		Globals.set_current_fishing_location(label.text.to_lower())
		print("Added fishing location: ", label.text, " at ", snap_points[1])

func get_label_text() -> String:
	return label.text if label else ""

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
				var snapped = false
				for i in snap_points.size():
					var distance: float = global_window_center.distance_to(snap_points[i])
					if distance < snap_threshold:
						handle_snap_action(i)
						snapped = true
						break
				
				# If we didn't snap and this is a water body, check for overlaps
				if not snapped and label.text in water_bodies:
					var overlap_count = check_overlaps()
					if overlap_count >= 4:  # 4 other windows + this one = 5 total
						check_overlapping_waters()
			
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
			if Globals.total_fish_dex_entries > 4:
				var new_size: Vector2 = start_window_size + (event.position - drag_start_pos)
				new_size.x = max(100, new_size.x)
				new_size.y = max(100, new_size.y)

				panel.size = new_size
				_update_label_position()

				if label.text in cave_types:
					_handle_cave_resizing(new_size)
				else:
					_handle_water_body_resizing(new_size)

			else:
				resizing = false  # Cancel resize attempt if not enough fish discovered

		queue_redraw()

func _handle_water_body_resizing(new_size: Vector2):
	var width_height_ratio: float = new_size.x / new_size.y
	var height_width_ratio: float = new_size.y / new_size.x
	var size_ratio: float = (new_size.x * new_size.y) / (initial_size.x * initial_size.y)

	var old_label_text = label.text
	if old_label_text in deep_water_bodies:
		if width_height_ratio >= 4.0:
			label.text = "Ravine"
		elif new_size >= get_viewport().get_visible_rect().size:
			label.text = "Abyss"
		elif size_ratio >= 2.0:
			label.text = "Sea"
		elif size_ratio <= 0.5:
			label.text = "Well"
		else:
			label.text = "Deep Pond"
	else:
		# Original water body resizing logic
		if width_height_ratio >= 4.0:
			label.text = "River"
		elif new_size >= get_viewport().get_visible_rect().size:
			label.text = "Ocean"
		elif height_width_ratio >= 4.0:
			label.text = "Waterfall"
		elif size_ratio >= 2.0:
			label.text = "Lake"
		elif size_ratio <= 0.5:
			label.text = "Puddle"
		else:
			label.text = "Pond"
	
	if label.text == "Waterfall" and old_label_text != "Waterfall":
		pending_cave_creation = true

func _handle_cave_resizing(new_size: Vector2):
	var size_ratio: float = (new_size.x * new_size.y) / (initial_size.x * initial_size.y)
	
	if size_ratio >= 2.0:
		label.text = "Cavern"
	elif size_ratio <= 0.5:
		label.text = "Crevice"
	else:
		label.text = "Cave"

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

func spawn_cave():
	if has_cave:
		return  # Prevent spawning multiple caves

	var cave_window := window_scene.instantiate()
	get_parent().add_child(cave_window)
	
	# Position the cave directly behind the waterfall
	cave_window.position = global_position
	
	# Ensure the cave is behind the waterfall
	cave_window.z_index = z_index - 1
	
	# Set the initial size of the cave window
	var cave_width = panel.size.x * 0.9  # 90% of the waterfall's width
	var cave_height = 100  # Fixed height for caves
	cave_window.get_node("Panel").size = Vector2(cave_width, cave_height)
	
	# Center the cave horizontally behind the waterfall
	var x_offset = (panel.size.x - cave_width) / 2
	cave_window.position.x += x_offset
	
	# Set the label text to "Cave"
	cave_window.get_node("Panel/Label").text = "Cave"
	
	# Update the cave window's properties
	cave_window._ready()  # This will initialize the window properly

	cave_window._update_label_position()
	
	has_cave = true

func check_overlapping_waters():
	var parent = get_parent()
	var windows = []
	
	# Collect all regular water body windows
	for child in parent.get_children():
		if child is Control and child.has_method("get_label_text"):
			var label_text = child.get_label_text()
			if label_text in water_bodies:  # Only check regular water bodies
				windows.append({
					"node": child,
					"rect": Rect2(
						child.global_position + child.get_node("Panel").position,
						child.get_node("Panel").size
					)
				})
	
	# Check each window for overlaps
	for i in range(windows.size()):
		var overlapping_windows = []
		var base_window = windows[i]
		
		# Add self to overlapping windows
		overlapping_windows.append(base_window["node"])
		
		# Check against all other windows
		for j in range(windows.size()):
			if i != j:  # Don't check against self
				var other_window = windows[j]
				# Check if windows overlap and share at least 25% of their area
				if do_windows_overlap(base_window["rect"], other_window["rect"]):
					overlapping_windows.append(other_window["node"])
		
		# If we found 5 or more overlapping windows
		if overlapping_windows.size() >= 5:
			print("Found ", overlapping_windows.size(), " overlapping windows")  # Debug print
			transform_to_deep_water(overlapping_windows)
			return

# Add this helper function to check for meaningful overlap
func do_windows_overlap(rect1: Rect2, rect2: Rect2) -> bool:
	# Get the intersection
	var overlap = rect1.intersection(rect2)
	
	# Calculate minimum overlap required (25% of smaller window)
	var min_area = min(rect1.get_area(), rect2.get_area()) * 0.25
	
	# Return true if overlap area is significant enough
	return overlap.get_area() > min_area

# Add this function to handle the transformation
func transform_to_deep_water(windows_to_remove: Array):
	var parent = get_parent()
	
	# Calculate the average center position and combined size of the overlapping windows
	var total_pos = Vector2.ZERO
	var max_size = Vector2.ZERO
	var combined_area = 0.0
	
	for window in windows_to_remove:
		var panel = window.get_node("Panel")
		var global_pos = window.global_position + panel.position
		total_pos += global_pos
		combined_area += panel.size.x * panel.size.y
		max_size.x = max(max_size.x, panel.size.x)
		max_size.y = max(max_size.y, panel.size.y)
	
	var avg_pos = total_pos / windows_to_remove.size()
	
	# Create the new deep water window
	var new_window = window_scene.instantiate()
	parent.add_child(new_window)
	
	# Calculate new size based on combined area
	var new_size = Vector2(
		sqrt(combined_area * 1.25),
		sqrt(combined_area * 1.25)
	)
	
	# Important: Set label text to "Deep Pond" BEFORE calling _ready()
	new_window.get_node("Panel/Label").text = "Deep Pond"
	
	# Set position and size
	new_window.position = avg_pos - new_size/2  # Center the window
	new_window.get_node("Panel").size = new_size
	
	# Initialize the window AFTER setting the label text
	new_window._ready()
	new_window._update_label_position()
	
	# Remove the old windows
	for window in windows_to_remove:
		window.queue_free()

func check_overlaps():
	var parent_node = get_parent()
	var overlapping_count = 0
	var my_rect = Rect2(
		global_position + panel.position,
		panel.size
	)

	for child in parent_node.get_children():
		if child != self and child is Control and child.has_method("get_label_text"):
			var label_text = child.get_label_text()
			if label_text in water_bodies:  # Only check regular water bodies
				var other_rect = Rect2(
					child.global_position + child.get_node("Panel").position,
					child.get_node("Panel").size
				)
				if my_rect.intersects(other_rect):
					overlapping_count += 1

	if overlapping_count > 0:
		print("Window '", label.text, "' is overlapping with ", overlapping_count, " other water bodies")
	return overlapping_count

extends Control

class_name SkillTree

# Signals
signal skill_clicked(skill_data)
signal skill_unlocked(skill_id)

# Constants
const SKILL_SCENE = preload("res://Scenes/skill_node.tscn")
const CONNECTION_COLOR = Color(0.7, 0.7, 0.7) # Edit this to a classic GB color
const LINE_WIDTH = 2.0
const ZOOM_SPEED = 0.1

# Variables
var skills = {}
var connections = []
var drag_start = null
var is_dragging = false
var zoom_level = 1.0
const MIN_ZOOM = 0.5
const MAX_ZOOM = 2.0

@onready var skill_container: Control = $SkillContainer  # Reference to container node

func create_skill_layout():
	# Load skill data and create the skill layout
	load_skill_data()

func _ready():
	# Create skill container if it doesn't exist
	if !skill_container:
		skill_container = Control.new()
		skill_container.name = "SkillContainer"
		add_child(skill_container)
	
	# Load and create skills
	load_skill_data()
	
	# Unlock first skill by default
	if skills.has("1"):
		print("Unlocking initial skill")
		skills["1"].unlock()
		skills["1"].set_availability(true, true)  # Set as available and within reach
	else:
		push_error("Could not find initial skill to unlock")
	
	# Update availability for all skills after unlocking first one
	update_skill_availability()

func _draw():
	# Draw connections between skills, accounting for container position and scale
	for connection in connections:
		var start_node = skills[connection[0]]
		var end_node = skills[connection[1]]
		
		# Calculate positions relative to container and apply container's transform
		var start_pos = skill_container.position + (start_node.position + start_node.size / 2) * skill_container.scale
		var end_pos = skill_container.position + (end_node.position + end_node.size / 2) * skill_container.scale
		
		# Draw the line with proper width scaling
		draw_line(start_pos, end_pos, CONNECTION_COLOR, LINE_WIDTH * zoom_level)

func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			var old_zoom = zoom_level
			zoom_level = clamp(zoom_level + ZOOM_SPEED, MIN_ZOOM, MAX_ZOOM)
			if old_zoom != zoom_level:
				var mouse_pos = get_local_mouse_position()
				_update_zoom(mouse_pos)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			var old_zoom = zoom_level
			zoom_level = clamp(zoom_level - ZOOM_SPEED, MIN_ZOOM, MAX_ZOOM)
			if old_zoom != zoom_level:
				var mouse_pos = get_local_mouse_position()
				_update_zoom(mouse_pos)
		elif event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				drag_start = get_local_mouse_position()
				is_dragging = true
			else:
				is_dragging = false
				drag_start = null
	
	elif event is InputEventMouseMotion and is_dragging and drag_start:
		var current_pos = get_local_mouse_position()
		var delta = current_pos - drag_start
		skill_container.position += delta
		queue_redraw()
		drag_start = current_pos

func _update_zoom(mouse_pos: Vector2):
	# Store the mouse position relative to the skill container before zooming
	var old_mouse_offset = mouse_pos - skill_container.position
	
	# Apply zoom
	skill_container.scale = Vector2(zoom_level, zoom_level)
	
	# Calculate new position to keep mouse point stable
	var new_mouse_offset = old_mouse_offset * (zoom_level / (zoom_level - ZOOM_SPEED))
	skill_container.position = mouse_pos - new_mouse_offset
	
	queue_redraw()

func add_skill(id: String, data: Dictionary):
	if !skill_container:
		push_error("SkillContainer not initialized")
		return
		
	var skill_node = SKILL_SCENE.instantiate()
	skill_container.add_child(skill_node)
	skill_node.setup(id, data)
	skill_node.position = data.position
	skills[id] = skill_node
	skill_node.clicked.connect(_on_skill_clicked)

func add_connection(from_id: String, to_id: String):
	connections.append([from_id, to_id])
	queue_redraw()

func load_skill_data():
	var skill_data = {
		"skill1": {
			"name": "Skill 1",
			"description": "This is the first skill",
			"icon": preload("res://sprites/bubble.png"),
			"position": Vector2(-100, -100),
			"requirements": ["skill2"]
		},
		"skill2": {
			"name": "Skill 2",
			"description": "This is the second skill",
			"icon": preload("res://sprites/bubble.png"),
			"position": Vector2(100, -100),
			"requirements": ["skill3"]
		},
		"skill3": {
			"name": "Skill 3",
			"description": "This is the third skill",
			"icon": preload("res://sprites/bubble.png"),
			"position": Vector2(0, 100),
			"requirements": []
		}
	}
	
	# Add skills
	for id in skill_data:
		add_skill(id, skill_data[id])
	
	# Add connections based on requirements
	for id in skill_data:
		for req in skill_data[id].requirements:
			add_connection(req, id)

func is_skill_available(skill_id: String) -> bool:
	var skill_data = skills[skill_id].skill_data
	if !skill_data.has("requirements") or skill_data.requirements.is_empty():
		return true
		
	for req in skill_data.requirements:
		if !skills[req].is_unlocked:
			return false
	return true

func is_skill_within_reach(skill_id: String) -> bool:
	var skill_data = skills[skill_id].skill_data
	if !skill_data.has("requirements"):
		return true
		
	# Check if any required skill is unlocked or available
	for req in skill_data.requirements:
		if skills[req].is_unlocked or is_skill_available(req):
			return true
	return false

func update_skill_availability():
	for skill_id in skills.keys():
		var available = is_skill_available(skill_id)
		var within_reach = is_skill_within_reach(skill_id)
		skills[skill_id].set_availability(available, within_reach)
		print("Skill ", skill_id, " availability: ", available, " within reach: ", within_reach)

func _on_skill_clicked(skill_data):
	var skill_id = ""
	for id in skills.keys():
		if skills[id].skill_data == skill_data:
			skill_id = id
			break
	
	if skill_id != "":
		if skills[skill_id].is_unlocked:
			print("Cannot lock skills once unlocked")
		elif is_skill_available(skill_id):
			print("Unlocking skill: ", skill_id)
			unlock_skill(skill_id)
		else:
			print("Skill not available - prerequisites not met")
	
	emit_signal("skill_clicked", skill_data)

func unlock_skill(skill_id: String):
	if skills.has(skill_id) and is_skill_available(skill_id):
		skills[skill_id].unlock()
		emit_signal("skill_unlocked", skill_id)
		update_skill_availability()  # Update availability after unlocking

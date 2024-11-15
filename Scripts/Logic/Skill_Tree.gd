extends Control

class_name SkillTree

signal skill_clicked(skill_data)
signal skill_unlocked(skill_id)

const SKILL_SCENE = preload("res://Scenes/skill_node.tscn")
const CONNECTION_COLOR = Color(0.7, 0.7, 0.7)
const LINE_WIDTH = 2.0
const ZOOM_SPEED = 0.1

var skills = {}  # Dictionary to store skill nodes
var connections = []
var drag_start = null
var is_dragging = false
var zoom_level = 1.0
const MIN_ZOOM = 0.5
const MAX_ZOOM = 2.0

@onready var skill_container: Control = $SkillContainer

func _ready():
	if !skill_container:
		skill_container = Control.new()
		skill_container.name = "SkillContainer"
		add_child(skill_container)
	
	load_skill_data()
	
	# Debug print skills
	print("Loaded skills: ", skills.keys())
	
	# Unlock and make available the first skill
	if skills.has("skill1"):
		print("Unlocking skill1")
		var skill = skills["skill1"]
		skill.is_unlocked = true
		skill.is_available = true
		skill.is_within_reach = true
		skill._update_appearance()
	else:
		push_error("Could not find initial skill to unlock")
	
	update_skill_availability()
	queue_redraw() 

func _draw():
	# Draw connections between skills
	for connection in connections:
		if !skills.has(connection[0]) or !skills.has(connection[1]):
			continue
		
		var start_node = skills[connection[0]]
		var end_node = skills[connection[1]]
		
		var start_pos = start_node.global_position + start_node.size / 2
		var end_pos = end_node.global_position + end_node.size / 2
		
		draw_line(start_pos, end_pos, CONNECTION_COLOR, LINE_WIDTH * zoom_level)
		print("Drawing connection from ", connection[0], " to ", connection[1])

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
	queue_redraw()

func add_connection(from_id: String, to_id: String):
	connections.append([from_id, to_id])
	queue_redraw()

func load_skill_data():
	var skill_data = {
		"1": {
			"name": "Basic Fishing",
			"description": "Learn the basics of fishing",
			"icon": preload("res://sprites/bubble.png"),
			"position": Vector2(-100, -100),
			"requirements": {
				"level": 1,
				"fish_caught": 0
			}
		},
		"2": {
			"name": "Advanced Casting",
			"description": "Improve your casting technique",
			"icon": preload("res://Sprites/bubble.png"),
			"position": Vector2(100, -100),
			"requirements": {
				"skills": ["1"],
				"level": 5,
				"fish_caught": 10
			}
		},
		"3": {
			"name": "Master Angler",
			"description": "Become a true master of fishing",
			"icon": preload("res://sprites/bubble.png"),
			"position": Vector2(0, 100),
			"requirements": {
				"skills": ["2"],
				"level": 10,
				"fish_caught": 50
			}
		}
	}
	
	for id in skill_data:
		add_skill(id, skill_data[id])
	
	for id in skill_data:
		if skill_data[id].has("requirements") and skill_data[id].requirements.has("skills"):
			for req in skill_data[id].requirements.skills:
				add_connection(req, id)

func is_skill_available(skill_id: String) -> bool:
	var skill_data = skills[skill_id].skill_data
	if !skill_data.has("requirements"):
		return true
	
	var requirements = skill_data.requirements
	
	# Check skill prerequisites
	if requirements.has("skills"):
		for req in requirements.skills:
			if !skills[req].is_unlocked:
				return false
	
	# Check level requirement
	if requirements.has("level") and Globals.fisher_level < requirements.level:
		return false
	
	# Check fish caught requirement
	if requirements.has("fish_caught") and Globals.total_fish_caught < requirements.fish_caught:
		return false
	
	# Check class level requirement
	for req in requirements.keys():
		if req.begins_with("class_") and req.ends_with("_level"):
			var skill_class = req.trim_prefix("class_").trim_suffix("_level")
			var required_level = requirements[req]
			if Globals.get("class_" + skill_class + "_level") < required_level:
				return false
	
	return true

func is_skill_within_reach(skill_id: String) -> bool:
	var skill_data = skills[skill_id].skill_data
	if !skill_data.has("requirements"):
		return true
	
	if skill_data.requirements.has("skills"):
		for req in skill_data.requirements.skills:
			if skills[req].is_unlocked or is_skill_available(req):
				return true
	
	return false

func update_skill_availability():
	for skill_id in skills.keys():
		var available = is_skill_available(skill_id)
		var within_reach = is_skill_within_reach(skill_id)
		skills[skill_id].set_availability(available, within_reach)
		print("Skill ", skill_id, " availability: ", available, " within reach: ", within_reach)
	
	# Ensure the first skill is always visible
	if skills.has("skill1"):
		skills["skill1"].set_availability(true, true)

func _on_skill_clicked(skill_data):
	var skill_id = ""
	for id in skills.keys():
		if skills[id].skill_data == skill_data:
			skill_id = id
			break
	
	if skill_id != "":
		if skills[skill_id].is_unlocked:
			print("Skill already unlocked")
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
		update_skill_availability()

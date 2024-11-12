extends Control

signal clicked(skill_data)

var skill_id: String
var skill_data: Dictionary
var is_unlocked: bool = false
var is_hovered: bool = false
var is_available: bool = false
var is_within_reach: bool = false

@onready var background: Panel = $Background
@onready var icon: TextureRect = $Icon
@onready var name_label: Label = $Name
@onready var description: Label = $Description

func _ready():
	mouse_entered.connect(_on_mouse_enter)
	mouse_exited.connect(_on_mouse_exit)
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.2, 0.2, 0.2, 1.0)
	style.corner_radius_top_left = 5
	style.corner_radius_top_right = 5
	style.corner_radius_bottom_left = 5
	style.corner_radius_bottom_right = 5
	background.add_theme_stylebox_override("panel", style)

func setup(id: String, data: Dictionary):
	skill_id = id
	skill_data = data
	
	print("Setting up skill: ", id)
	print("Data received: ", data)
	
	# Check and load icon
	if icon and data.has("icon") and data.icon != null:
		icon.texture = load(data.icon)
		print("Loaded icon: ", data.icon)
	else:
		push_warning("No icon found for skill: " + id)
	
	# Check and set name
	if name_label:
		if data.has("name") and data.name != "":
			name_label.text = data.name
			print("Set name: ", data.name)
		else:
			name_label.text = "Skill " + id
			push_warning("No name found for skill: " + id)
	
	# Check and set description
	if description:
		if data.has("description") and data.description != "":
			description.text = data.description
			print("Set description: ", data.description)
		else:
			description.text = "No description available"
			push_warning("No description found for skill: " + id)
	
	_update_appearance()

func set_availability(available: bool, within_reach: bool):
	is_available = available
	is_within_reach = within_reach
	_update_appearance()

func _gui_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			if is_available or is_unlocked:
				emit_signal("clicked", skill_data)

func unlock():
	is_unlocked = true
	_update_appearance()

func _on_mouse_enter():
	is_hovered = true
	_update_appearance()

func _on_mouse_exit():
	is_hovered = false
	_update_appearance()

func _update_appearance():
	if !background:
		return
		
	var style = background.get_theme_stylebox("panel").duplicate()
	
	# Set base color based on status
	if is_unlocked:
		style.bg_color = Color(0.2, 0.4, 0.2, 1.0)  # Green for unlocked
	elif is_available:
		style.bg_color = Color(0.3, 0.3, 0.4, 1.0)  # Blue-ish for available
	else:
		style.bg_color = Color(0.2, 0.2, 0.2, 1.0)  # Dark gray for locked
	
	if is_hovered and (is_available or is_unlocked):
		style.bg_color = style.bg_color.lightened(0.3)
		style.border_color = Color(1, 1, 1, 0.5)
		style.border_width_top = 2
		style.border_width_right = 2
		style.border_width_bottom = 2
		style.border_width_left = 2
	else:
		style.border_width_top = 0
		style.border_width_right = 0
		style.border_width_bottom = 0
		style.border_width_left = 0
	
	background.add_theme_stylebox_override("panel", style)
	
	# Update visibility and opacity based on status
	if !is_within_reach:
		# Hide text for skills that are too far in the chain
		if name_label:
			name_label.visible = false
		if description:
			description.visible = false
	else:
		# Set opacity based on unlock status
		var opacity = 1.0 if (is_unlocked or is_available) else 0.5
		if name_label:
			name_label.modulate.a = opacity
		if description:
			description.modulate.a = opacity
		if icon:  # Add null check for icon
			icon.modulate.a = opacity

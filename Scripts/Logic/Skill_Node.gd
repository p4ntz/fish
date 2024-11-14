extends Control

signal clicked(skill_data)

var skill_id: String
var skill_data: Dictionary
var is_unlocked: bool = false
var is_available: bool = false
var is_within_reach: bool = false

# Game Boy color palette
@onready var color_lightest: Color = Color.html("#9bbc0f")
@onready var color_light: Color = Color.html("#8bac0f")
@onready var color_dark: Color = Color.html("#306230")
@onready var color_darkest: Color = Color.html("#0f380f")

@onready var background: Panel = $Background
@onready var icon: TextureRect = $Background/Icon
@onready var description: Label = $Description
@onready var detail_window: Panel = $DetailWindow
@onready var name_label: Label = $DetailWindow/Name
@onready var detail_description: Label = $DetailWindow/Description
@onready var requirements_label: Label = $DetailWindow/Requirements

func _ready():
	detail_window.visible = false
	_connect_signals()
	_update_appearance()

func _connect_signals():
	if background:
		background.gui_input.connect(_on_background_input)
	background.mouse_entered.connect(_on_mouse_enter)
	background.mouse_exited.connect(_on_mouse_exit)

func setup(id: String, data: Dictionary):
	skill_id = id
	skill_data = data
	if icon and data.has("icon") and data.icon != null:
		icon.texture = data.icon
		print("Skill " + id + " icon set" + str(icon.texture))
	else:
		push_error("Skill " + id + " is missing an icon")
	
	description.text = data.get("name", "Skill " + id)
	name_label.text = data.get("name", "Skill " + id)
	detail_description.text = data.get("description", "No description available")
	
	requirements_label.text = _format_requirements(data.get("requirements", {}))
	
	_update_appearance()

func _format_requirements(requirements: Dictionary) -> String:
	var req_text = "Requirements:\n"
	
	if requirements.has("skills"):
		req_text += "Skills: " + ", ".join(requirements.skills) + "\n"
	
	if requirements.has("level"):
		req_text += "Level: " + str(requirements.level) + "\n"
	
	if requirements.has("fish_caught"):
		req_text += "Fish Caught: " + str(requirements.fish_caught) + "\n"
	
	for req in requirements.keys():
		if req.begins_with("class_") and req.ends_with("_level"):
			var skill_class = req.trim_prefix("class_").trim_suffix("_level")
			req_text += skill_class.capitalize() + " Level: " + str(requirements[req]) + "\n"
	
	return req_text.strip_edges()

func set_availability(available: bool, within_reach: bool):
	is_available = available
	is_within_reach = within_reach
	_update_appearance()

func unlock():
	is_unlocked = true
	_update_appearance()

func _on_background_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			if is_available or is_unlocked:
				emit_signal("clicked", skill_data)

func _on_mouse_enter():
	if is_unlocked or is_available or is_within_reach:
		detail_window.visible = true
		modulate = Color(1.2, 1.2, 1.2)  # Slightly brighten when hovered

func _on_mouse_exit():
	detail_window.visible = false
	modulate = Color(1, 1, 1)  # Reset to normal

func _update_appearance():
	if is_unlocked:
		background.modulate = color_lightest  # Unlocked skills use the lightest color
	elif is_available:
		background.modulate = color_light  # Available skills use the light color
	elif is_within_reach:
		background.modulate = color_dark  # Within reach skills use the dark color
	else:
		background.modulate = color_darkest  # Locked and out of reach skills use the darkest color
	
	# Hide detail window for unavailable and out-of-reach skills
	detail_window.visible = false

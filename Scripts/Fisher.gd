extends Node2D

@onready var indicator_normal = $Indicator1
@onready var indicator_active = $Indicator2

# Timers
var fish_spawn_timer: Timer
var catch_window_timer: Timer

func _ready():
	# Hide the active indicator at start
	indicator_normal.visible = true
	indicator_active.visible = false
	
	# Setup fish spawn timer
	fish_spawn_timer = Timer.new()
	add_child(fish_spawn_timer)
	fish_spawn_timer.one_shot = true  # Timer only runs once
	fish_spawn_timer.timeout.connect(spawn_fish)
	
	# Setup catch window timer
	catch_window_timer = Timer.new()
	add_child(catch_window_timer)
	catch_window_timer.one_shot = true
	catch_window_timer.timeout.connect(miss_fish)
	
	# Start the first fish spawn timer
	start_fish_timer()

func start_fish_timer():
	# Random time between 5-10 seconds
	var random_time = randf_range(5.0, 10.0)
	fish_spawn_timer.start(random_time)

func spawn_fish():
	print("A fish appeared!")
	indicator_normal.visible = false
	indicator_active.visible = true
	
	# Start the catch window timer (5 seconds to catch)
	catch_window_timer.start(5.0)

func miss_fish():
	print("Failed to catch the fish!")
	indicator_normal.visible = true
	indicator_active.visible = false
	
	# Start the next fish spawn timer
	start_fish_timer()

func _input(event):
	# Check for space key press
	if event.is_action_pressed("ui_accept"):  # Space bar by default
		try_catch_fish()
	
	# Check for mouse click
	elif event.is_action_pressed("ui_click"):
		if event is InputEventMouseButton:
			# Check if click is within fisher or indicator area
			if is_click_in_area(event.position):
				try_catch_fish()

func is_click_in_area(click_pos: Vector2) -> bool:
	# Convert click position to local coordinates if needed
	var local_pos = to_local(click_pos)
	
	# Check if click is within fisher or indicator sprites
	# You'll need to adjust these based on your sprite sizes
	var click_rect = Rect2(Vector2(-50, -50), Vector2(100, 100))
	return click_rect.has_point(local_pos)

func try_catch_fish():
	if indicator_active.visible:
		print("fish. start!")
		catch_window_timer.stop()
		get_tree().change_scene_to_file("res://Scenes/fishing.tscn")

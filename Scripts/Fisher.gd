extends Node2D

@onready var indicator_normal: Sprite2D = $Indicator1
@onready var indicator_active: Sprite2D = $Indicator2
@onready var fish_caught: RichTextLabel = $FishCaught
@onready var fisher_stats: Node = $FisherStats
@onready var level_label: Label = $Level
@onready var exp_bar: ProgressBar = $EXPBar

# Timers
var fish_spawn_timer: Timer
var catch_window_timer: Timer
var caught_message_timer: Timer

var overlay_layer: CanvasLayer

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
	
	# Setup caught timer
	caught_message_timer = Timer.new()
	add_child(caught_message_timer)
	caught_message_timer.one_shot = true
	caught_message_timer.timeout.connect(hide_catch_message)
	
	# Start the first fish spawn timer
	start_fish_timer()
	
	# Display a message if we just left the Fishing Game
	if Globals.IsFishing:
		if Globals.FishWasCaught:
			var format_string := "Caught a {name}! It's about {size}{size_unit}!"
			fish_caught.text = format_string.format({"name":Globals.DexInstance.tracked_fish.fish_name, "size": snapped(Globals.DexInstance.tracked_fish.current_size,Globals.SizeDecimalPlaces), "size_unit": Globals.DexInstance.tracked_fish.size_unit})
		else:
			fish_caught.text = "Looks like that one got away!"
		# Clean up state.
		Globals.FishWasCaught = false
		Globals.IsFishing = false
		
		# Free the Fish ref for memeory management
		Globals.DexInstance.free_fish()
		
		# Display notice
		fish_caught.visible = true
		caught_message_timer.start(5.0)

func start_fish_timer():
	# Random time between 5-10 seconds
	var random_time: float = randf_range(5.0, 10.0)
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
	
func hide_catch_message():
	fish_caught.visible = false

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
	var local_pos: Vector2 = to_local(click_pos)
	
	# Check if click is within fisher or indicator sprites
	# You'll need to adjust these based on your sprite sizes
	var click_rect: Rect2 = Rect2(Vector2(-50, -50), Vector2(100, 100))
	return click_rect.has_point(local_pos)

func try_catch_fish():
	if indicator_active.visible:
		print("fish. start!")
		catch_window_timer.stop()
		Globals.IsFishing = true
		get_tree().change_scene_to_file("res://Scenes/fishing.tscn")

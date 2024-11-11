extends Node2D

@onready var indicator_normal: Sprite2D = $Indicator1
@onready var indicator_active: Sprite2D = $Indicator2
@onready var fish_caught: RichTextLabel = $FishCaught
#@onready var fisher_stats: Node = $FisherStats
@onready var level_label: Label = $Level
@onready var exp_bar: ProgressBar = $EXPBar
@onready var time: Label = $Time
@onready var season: Label = $Season
@onready var hooked_stinger : Sprite2D = $HookedSprite
@onready var mode_toggle_button: CheckButton = $ModeToggleButton

# Timers
var fish_spawn_timer: Timer
var catch_window_timer: Timer
var caught_message_timer: Timer
var auto_catch_timer: Timer

var overlay_layer: CanvasLayer

signal fishing_mode_changed(is_idle: bool)

func _ready():
	# Hide the active indicator at start
	indicator_normal.visible = true
	indicator_active.visible = false
	
	# Hide "HOOKED" Stinger on at start
	hooked_stinger.visible = false

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

	# Setup auto catch timer for idle mode
	auto_catch_timer = Timer.new()
	add_child(auto_catch_timer)
	auto_catch_timer.one_shot = true
	auto_catch_timer.timeout.connect(auto_catch_fish)

	mode_toggle_button.toggled.connect(on_mode_toggle_button_toggled)

	# Initialize based on current mode (idle or active)
	update_fishing_mode(Globals.idle_mode)

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
	var random_time: float
	if Globals.idle_mode:
		random_time = randf_range(Globals.idle_min_fish_window, Globals.idle_max_fish_window)
	else:
		random_time = randf_range(Globals.min_fish_catching_window, Globals.max_fish_catching_window)
	fish_spawn_timer.start(random_time)

func spawn_fish():
	print("A fish appeared!")
	indicator_normal.visible = false
	indicator_active.visible = true

	if Globals.idle_mode:
		# In idle mode, start the auto catch timer with a random delay
		var catch_delay = randf_range(Globals.idle_min_catch_delay, Globals.idle_max_catch_delay)
		auto_catch_timer.start(catch_delay)
	else:
		# Normal mode behavior
		catch_window_timer.start(5.0)

func auto_catch_fish():
	if Globals.idle_mode and indicator_active.visible:
		# Calculate success chance
		if randf() <= Globals.idle_catch_chance:
			try_catch_fish()
		else:
			miss_fish()

func miss_fish():
	print("Failed to catch the fish!")
	indicator_normal.visible = true
	indicator_active.visible = false

	# Start the next fish spawn timer
	start_fish_timer()

func hide_catch_message():
	fish_caught.visible = false

func _input(event):
	if event.is_action_pressed("toggle_fishing_mode"):  # You'll need to set this up in your input map
		toggle_fishing_mode()
	elif not Globals.idle_mode:  # Only process fishing input in normal mode
		if event.is_action_pressed("ui_accept"):
			try_catch_fish()
		elif event.is_action_pressed("ui_click"):
			if event is InputEventMouseButton:
				if is_click_in_area(event.position):
					try_catch_fish()

func is_click_in_area(click_pos: Vector2) -> bool:
	# Convert click position to local coordinates if needed
	var local_pos: Vector2 = to_local(click_pos)

	# Check if click is within fisher or indicator sprites
	# You'll need to adjust these based on your sprite sizes
	var click_rect: Rect2 = Rect2(Vector2(-50, -50), Vector2(100, 100))
	return click_rect.has_point(local_pos)

func get_random_fish_for_idle():
	var current_season = Globals.current_season
	var current_time = Globals.current_time
	var current_location = Globals.get_current_fishing_location()
	
	var attempts = 0
	var max_attempts = 10  # Prevent infinite loop
	
	while attempts < max_attempts:
		var fish: Fish = Globals.DexInstance.random_fish()
		
		if fish and is_fish_available(fish, current_time, current_season, current_location):
			return fish
		
		attempts += 1
	
	print("No eligible fish found for current season, time, and location after " + str(max_attempts) + " attempts.")
	return null

func is_fish_available(fish: Fish, current_time: String, current_season: String, current_location: String) -> bool:
	return (current_location in fish.locations
		and current_season in fish.seasons
		and current_time in fish.time_of_day)

func try_catch_fish():
	if indicator_active.visible:
		print("fish. start!")
		catch_window_timer.stop()
		fish_spawn_timer.stop()
		auto_catch_timer.stop()
		
		if not Globals.idle_mode:
			hooked_stinger.visible = true
			hooked_stinger.play_sfx()
			await get_tree().create_timer(1).timeout
		
		if Globals.idle_mode:
			# In idle mode, capture the fish data and print it
			var fish_data = get_random_fish_for_idle()
			if fish_data:
				Globals.DexInstance.tracked_fish = fish_data
				
				# Reset the fishing state
				Globals.FishWasCaught = true
				Globals.IsFishing = false

				var size = randf() * 10  # Random size between 0 and 10 for testing

				# Record the catch
				fish_data.record_catch(size, Globals.get_current_fishing_location())
				
				# Update the UI
				var format_string := "Caught a {name}! It's about {size}{size_unit}!"
				fish_caught.text = format_string.format({
					"name": fish_data.fish_name,
					"size": snapped(size, Globals.SizeDecimalPlaces),
					"size_unit": fish_data.size_unit
				})
				fish_caught.visible = true
				caught_message_timer.start(5.0)
				
				# Calculate and add experience
				var exp_gained = fish_data.calculate_current_EXP(size)
				Globals.gain_experience(exp_gained)
				
				print("Caught a " + fish_data.fish_name + " of size " + str(size) + fish_data.size_unit + ". Gained " + str(exp_gained) + " EXP.")
				
				# Start the next fish spawn timer
				start_fish_timer()
			else:
				print("No fish caught in idle mode.")
		else:
			# Normal mode behavior (unchanged)
			var window_scene = preload("res://Scenes/window.tscn")
			var window = window_scene.instantiate()
			add_child(window)
			window.load_scene("res://Scenes/fishing.tscn", "Fishing")
			window.connect("window_closed", Callable(self, "_on_fishing_window_closed"))
		
		indicator_normal.visible = true
		indicator_active.visible = false
		if not Globals.idle_mode:
			hooked_stinger.visible = false

func _on_fishing_window_closed():
	print("fishing window closed")
	if not fish_spawn_timer.time_left > 0:
		start_fish_timer()

func _process(delta: float) -> void:
	var TimeText: String = "Time of Day: {time}"
	time.text = TimeText.format({"time":Globals.current_time})
	var SeasonText: String = "Current Season: {season}"
	season.text = SeasonText.format({"season": Globals.current_season})

func toggle_fishing_mode():
	update_fishing_mode(not Globals.idle_mode)

func update_fishing_mode(new_idle_state: bool):
	# Update the global state
	Globals.idle_mode = new_idle_state
	
	# Reset all timers
	fish_spawn_timer.stop()
	catch_window_timer.stop()
	auto_catch_timer.stop()
	
	# Reset visual states
	indicator_normal.visible = true
	indicator_active.visible = false
	hooked_stinger.visible = false
	
	# Cancel any ongoing fishing activity
	if Globals.IsFishing:
		Globals.IsFishing = false
		Globals.FishWasCaught = false
		Globals.DexInstance.free_fish()
	
	# Update UI elements for the new mode
	if Globals.idle_mode:
		# Set up idle mode specific UI changes
		indicator_normal.modulate = Color(0.7, 0.7, 1.0)  # Blue tint for idle mode
		fish_caught.text = "Idle Fishing Mode Active"
	else:
		# Reset to normal mode UI
		indicator_normal.modulate = Color(1, 1, 1)  # Normal color
		fish_caught.text = "Active Fishing Mode"
	
	# Show mode change message
	fish_caught.visible = true
	caught_message_timer.start(2.0)
	
	# Start the appropriate fishing timer
	start_fish_timer()
	
	# Emit signal for other systems that might need to know about the mode change
	emit_signal("fishing_mode_changed", Globals.idle_mode)

func on_mode_toggle_button_toggled(button_pressed: bool):
	if button_pressed:
		update_fishing_mode(true)
	else:
		update_fishing_mode(false)

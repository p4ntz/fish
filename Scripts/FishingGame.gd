extends Node2D

# Bar nodes
@onready var rod_health_bar := $RodHealthBar
@onready var fish_stamina_bar := $FishStaminaBar
@onready var catch_progress_bar := $CatchProgressBar

# Sprite nodes for fish direction indicators
@onready var left_sprites := [$LeftFish]
@onready var right_sprites := [$RightFish]
@onready var neutral_sprites := [$NeutralFish]

# Game parameters
var max_rod_health := 100.0
var current_rod_health := 100.0
var max_fish_stamina := 100.0
var current_fish_stamina := 100.0
var catch_progress := 0.0

# Fish state
var fish_direction := "none"  # "left", "right", or "none"
var direction_timer: Timer
var is_fish_tired := false

# Constants for balance tuning
const STAMINA_DRAIN_RATE := 30.0
const ROD_DAMAGE_RATE := 40.0
const BASE_CATCH_RATE := 4
const HELD_CATCH_MULTIPLIER := 5.0

func _ready():
	# get a random fish!
	var fish: Fish = Globals.DexInstance.random_fish()
	
	print("Picked Fish: " + fish.fish_name)
	
	# Setup initial bar values
	rod_health_bar.max_value = max_rod_health
	rod_health_bar.value = current_rod_health
	
	fish_stamina_bar.max_value = max_fish_stamina
	fish_stamina_bar.value = current_fish_stamina
	
	catch_progress_bar.max_value = 100
	catch_progress_bar.value = catch_progress
	
	# Setup direction timer
	direction_timer = Timer.new()
	add_child(direction_timer)
	direction_timer.wait_time = 1.0
	direction_timer.timeout.connect(change_fish_direction)
	direction_timer.start()
	
	# Initialize sprites
	update_direction_sprites("none")

func _process(delta):
	if current_fish_stamina <= 0:
		is_fish_tired = true
	elif is_fish_tired && current_fish_stamina <= 100:
		is_fish_tired = true
	elif is_fish_tired && current_fish_stamina >= 100:
		is_fish_tired = false

	if is_fish_tired:
		handle_tired_state(delta)
	else:
		handle_active_state(delta)
		
	# Always increase catch progress
	var catch_rate := BASE_CATCH_RATE
	if Input.is_action_pressed("ui_down"):
		catch_rate *= HELD_CATCH_MULTIPLIER
	catch_progress += catch_rate * delta
	
	# Update all bars
	rod_health_bar.value = current_rod_health
	fish_stamina_bar.value = current_fish_stamina
	catch_progress_bar.value = catch_progress
	
	if catch_progress >= 100:
		print("Fish caught!")
		Globals.FishWasCaught = true
		Globals.DexInstance.tracked_fish.record_catch(randf() *10, "testing")
		get_tree().change_scene_to_file("res://Scenes/game_background.tscn")

func handle_tired_state(delta):
	is_fish_tired = true
	direction_timer.stop()  # Stop changing directions while tired
	fish_direction = "none"  # No direction when tired
	update_direction_sprites("none")  # Update sprites to "neutral"
	
	# Restore stamina at the same rate it was drained
	current_fish_stamina += abs(STAMINA_DRAIN_RATE * delta)
	#print("Restoring stamina: ", current_fish_stamina)
	
	# Cap stamina at the maximum value
	if current_fish_stamina >= max_fish_stamina:
		current_fish_stamina = max_fish_stamina
		is_fish_tired = false  # Switch back to active once stamina is full
		print("Fish is no longer tired.")
		direction_timer.start()  # Resume changing directions


func handle_active_state(delta):
	var player_direction := get_player_direction()
	
	if player_direction != "none":
		if player_direction == fish_direction:
			# Correct direction held - drain fish stamina
			current_fish_stamina -= STAMINA_DRAIN_RATE * delta
			#print("Good pull!")
		else:
			# Wrong direction held - damage fishing rod
			current_rod_health -= ROD_DAMAGE_RATE * delta
			#print("Wrong direction - damaging rod!")
	
	# Damage rod if pulling down during active fishing
	if Input.is_action_pressed("ui_down") and not is_fish_tired:
		current_rod_health -= ROD_DAMAGE_RATE * delta
		#print("Down pressed - damaging rod!")
	
	# Check for rod break
	if current_rod_health <= 0:
		#print("Rod broke!")
		get_tree().change_scene_to_file("res://Scenes/game_background.tscn")

func get_player_direction() -> String:
	if Input.is_action_pressed("ui_left"):
		return "right"
	elif Input.is_action_pressed("ui_right"):
		return "left"
	return "none"

func change_fish_direction():
	if not is_fish_tired:
		# Randomly choose left or right
		fish_direction = "left" if randf() < 0.5 else "right"
		update_direction_sprites(fish_direction)
		#print("Fish moved " + fish_direction)

func update_direction_sprites(direction: String):
	# Hide all sprites first
	for sprite in left_sprites + right_sprites + neutral_sprites:
		sprite.hide()
	
	# Show the appropriate sprites based on direction
	var sprites_to_show := []
	match direction:
		"left":
			sprites_to_show = left_sprites
		"right":
			sprites_to_show = right_sprites
		"none":
			sprites_to_show = neutral_sprites
	
	for sprite in sprites_to_show:
		sprite.show()

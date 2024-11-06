extends Node2D

# Bar nodes
@onready var rod_health_bar := $RodHealthBar
@onready var fish_stamina_bar := $FishStaminaBar
@onready var catch_progress_bar := $CatchProgressBar
@onready var fish_stamina_bar_label := $FishTextLabel
@onready var rod_health_bar_label := $RodTextLabel

# Sprite nodes for fish direction indicators
@onready var left_sprites := [$LeftFish]
@onready var right_sprites := [$RightFish]
@onready var neutral_sprites := [$NeutralFish]

# Sprite nodes for fishing rod direction indicators
@onready var left_rod_sprites := [$LeftRodBend]
@onready var right_rod_sprites := [$RightRodBend]
@onready var idle_rod_sprites := [$IdleRod]
@onready var middle_rod_sprites := [$MiddleRodBend]

#background sprites
@onready var danger_background := $LosingHealthBackground
@onready var fish_tired_background := $FishTiredBackground
@onready var yanking_background := $YankingFishBackground

var current_background: Sprite2D = null
const FADE_DURATION := 0.3

# Game parameters
var max_rod_health: float = Globals.maximum_rod_health
var current_rod_health: float = Globals.maximum_rod_health
var max_fish_stamina: float = Globals.base_fish_stamina
var current_fish_stamina: float = Globals.base_fish_stamina
var fish_turn_speed: float = Globals.base_fish_turn_speed
var fish_recovery_speed: float = Globals.base_fish_recovery_speed
var rod_damage_rate: float = Globals.rod_damage_rate
var fish_catch_rate: float = Globals.fish_catch_rate
var fish_held_catch_rate: float = Globals.fish_held_catch_rate
var catch_progress: float = 0.0

enum Difficulty { EASY, MEDIUM, HARD, EXTREME }
var catching_difficulty: int

# Fish state
var fish_direction: String = "none"  # "left", "right", or "none"
var direction_timer: Timer
var is_fish_tired: bool = false

# Difficulty multipliers
const STAMINA_MULTIPLIERS: Dictionary = {
	Difficulty.EASY: 0.6,
	Difficulty.MEDIUM: 0.45,
	Difficulty.HARD: 0.3,
	Difficulty.EXTREME: 0.15
}

const ROD_DAMAGE_MULTIPLIERS: Dictionary = {
	Difficulty.EASY: 0.2,
	Difficulty.MEDIUM: 0.4,
	Difficulty.HARD: 0.6,
	Difficulty.EXTREME: 0.8
}

const CATCH_RATE_MULTIPLIERS: Dictionary = {
	Difficulty.EASY: 8.0,
	Difficulty.MEDIUM: 4.0,
	Difficulty.HARD: 2.0,
	Difficulty.EXTREME: 1.0
}

const HELD_CATCH_MULTIPLIERS: Dictionary = {
	Difficulty.EASY: 8.0,
	Difficulty.MEDIUM: 5.0,
	Difficulty.HARD: 3.0,
	Difficulty.EXTREME: 2.0
}

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
	
	# Setup direction timer with difficulty-based timing
	direction_timer = Timer.new()
	add_child(direction_timer)
	var tracked_fish: Fish = Globals.DexInstance.tracked_fish
	match tracked_fish.catching_difficulty:
		Fish.Difficulty.EASY:
			direction_timer.wait_time = 1.5
		Fish.Difficulty.MEDIUM:
			direction_timer.wait_time = 1.0
		Fish.Difficulty.HARD:
			direction_timer.wait_time = 0.5
		Fish.Difficulty.EXTREME:
			direction_timer.wait_time = 0.25
	direction_timer.timeout.connect(change_fish_direction)
	direction_timer.start()
	
	# Initialize sprites
	update_direction_sprites("none")
	update_rod_direction_sprites()
	
	# Set initial visibility based on Fisher Level
	update_bars_visibility()
	
	# Hide all backgrounds initially
	danger_background.modulate.a = 0
	fish_tired_background.modulate.a = 0
	yanking_background.modulate.a = 0

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
	var catch_rate: float = fish_catch_rate
	if Input.is_action_pressed("ui_down"):
		catch_rate *= HELD_CATCH_MULTIPLIERS[Globals.DexInstance.tracked_fish.catching_difficulty]
	catch_progress += catch_rate * delta
	
	# Update all bars
	rod_health_bar.value = current_rod_health
	fish_stamina_bar.value = current_fish_stamina
	catch_progress_bar.value = catch_progress
	
	if catch_progress >= 100:
		print("Fish caught!")
		Globals.FishWasCaught = true
		Globals.DexInstance.tracked_fish.record_catch(randf() *10, "testing")
		Globals.gain_experience(calculate_current_EXP(randf() * 1000))
		get_tree().change_scene_to_file("res://Scenes/game_background.tscn")
		
	#Update the rod sprite	
	update_rod_direction_sprites()
	
	# Update bars visibility if level changes
	update_bars_visibility()
	
	# Update all bars values
	if fish_stamina_bar and fish_stamina_bar.visible:
		fish_stamina_bar.value = current_fish_stamina
	if rod_health_bar and rod_health_bar.visible:
		rod_health_bar.value = current_rod_health
	
	update_background_state()

func handle_tired_state(delta):
	is_fish_tired = true
	direction_timer.stop()  # Stop changing directions while tired
	fish_direction = "none"  # No direction when tired
	update_direction_sprites("none")  # Update sprites to "neutral"
	
	# Restore stamina at different rates based on difficulty
	var restore_rate := 0.0
	match Globals.DexInstance.tracked_fish.catching_difficulty:
		Fish.Difficulty.EASY:
			restore_rate = fish_recovery_speed * 0.5
		Fish.Difficulty.MEDIUM:
			restore_rate = fish_recovery_speed * 1.0
		Fish.Difficulty.HARD:
			restore_rate = fish_recovery_speed * 1.5
		Fish.Difficulty.EXTREME:
			restore_rate = fish_recovery_speed * 2.0
	
	current_fish_stamina += restore_rate * delta
	
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
			# Use base fish stamina drain rate multiplied by difficulty modifier
			current_fish_stamina -= (Globals.base_fish_stamina_drain * STAMINA_MULTIPLIERS[Globals.DexInstance.tracked_fish.catching_difficulty]) * delta
			#print("Good pull!")
		else:
			# Wrong direction held - damage fishing rod
			# Use base rod damage rate multiplied by difficulty modifier
			current_rod_health -= (rod_damage_rate * ROD_DAMAGE_MULTIPLIERS[Globals.DexInstance.tracked_fish.catching_difficulty]) * delta
			#print("Wrong direction - damaging rod!")

	if player_direction == "none":
		# Slowly damage the rod if no direction is pressed (25% of normal damage)
		current_rod_health -= (rod_damage_rate * ROD_DAMAGE_MULTIPLIERS[Globals.DexInstance.tracked_fish.catching_difficulty] * 0.25) * delta
		#print("No direction pressed - slowly damaging rod!")
	
	# Damage rod if pulling down during active fishing
	if Input.is_action_pressed("ui_down") and not is_fish_tired:
		current_rod_health -= (rod_damage_rate * ROD_DAMAGE_MULTIPLIERS[Globals.DexInstance.tracked_fish.catching_difficulty]) * delta
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

func update_rod_direction_sprites():
	# Hide all sprites first
	for sprite in left_rod_sprites + right_rod_sprites + idle_rod_sprites + middle_rod_sprites:
		sprite.hide()
		
	# Get arrow key held down and show the appropriate sprites based on direction	
	var sprites_to_show := []
	if Input.is_action_pressed("ui_left"):
		sprites_to_show = right_rod_sprites
	elif Input.is_action_pressed("ui_right"):
		sprites_to_show = left_rod_sprites
	elif Input.is_action_pressed("ui_down"):
		sprites_to_show = middle_rod_sprites
	else:
		sprites_to_show = idle_rod_sprites
	
	for sprite in sprites_to_show:
		sprite.show()

func update_bars_visibility():
	# Hide stamina bar unless level > 1
	if fish_stamina_bar:
		fish_stamina_bar.visible = Globals.fisher_level > 1
		fish_stamina_bar_label.visible = Globals.fisher_level > 1
	
	# Hide rod health bar unless level > 2 
	if rod_health_bar:
		rod_health_bar.visible = Globals.fisher_level > 2
		rod_health_bar_label.visible = Globals.fisher_level > 2

func fade_to_background(new_background: Sprite2D) -> void:
	if current_background == new_background:
		return
		
	# Fade out current background
	if current_background:
		var tween := create_tween()
		tween.tween_property(current_background, "modulate:a", 0.0, FADE_DURATION)
	
	# Fade in new background to 0.5 opacity
	var tween := create_tween()
	tween.tween_property(new_background, "modulate:a", 0.5, FADE_DURATION)
	current_background = new_background

func update_background_state():
	var player_direction := get_player_direction()
	
	if is_fish_tired:
		fade_to_background(fish_tired_background)
	elif player_direction == fish_direction:
		fade_to_background(yanking_background)
	elif player_direction == "none" or player_direction != fish_direction:
		fade_to_background(danger_background)
	
func calculate_current_EXP(size: float) -> int:
	var exp_base := size
	var tracked_fish: Fish = Globals.DexInstance.tracked_fish
		
	# Add difficulty bonus
	var difficulty_bonus: int
	match tracked_fish.catching_difficulty:
		Difficulty.EASY:
			difficulty_bonus = 1
		Difficulty.MEDIUM:
			difficulty_bonus = 2
		Difficulty.HARD:
			difficulty_bonus = 3
		Difficulty.EXTREME:
			difficulty_bonus = 5
		_:
			difficulty_bonus = 0
		
	# Add fish-specific difficulty multiplier
	var fish_multiplier: float = 1.0
	match Difficulty:
		"easy":
			fish_multiplier = 1.0
		"medium": 
			fish_multiplier = 1.5
		"hard":
			fish_multiplier = 2.0
		"extreme":
			fish_multiplier = 3.0
		
	# Calculate final EXP
	exp_base = (exp_base + difficulty_bonus * 10) * fish_multiplier
		
	return int(exp_base)

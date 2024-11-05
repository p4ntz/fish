extends Node
class_name Fish

# Basic Information
@export var fish_name: String
@export var scientific_name: String
@export var description: String

# Statistics
@export var amount_caught: int = 0
@export var times_spotted: int = 0
@export var personal_best: float = 0.0
@export var total_weight_caught: float = 0.0

# Size Properties
@export var min_size: float
@export var max_size: float
@export var average_size: float
@export var current_size: float
@export var size_unit: String = "cm"

# Spawning/Catching Properties
@export var locations: Array = []
@export var seasons: Array[String] = ["Spring", "Summer", "Fall", "Winter"]
@export var time_of_day: Array[String] = ["Morning", "Afternoon", "Evening", "Night"]
@export var depth_range: Vector2 = Vector2(0.0, 10.0)  # min and max depth

# Rarity and Value
@export var rarity: float = 1.0  # 0.0 to 1.0
@export var base_value: int = 0
@export_range(1, 5) var star_rating: int = 1  # Limit from 1 to 5

# Behavior Flags (booleans)
@export var is_discovered: bool = false
@export var is_nocturnal: bool = false
@export var can_be_caught_in_rain: bool = true
@export var requires_special_bait: bool = false
@export var is_legendary: bool = false
@export var is_catchable: bool = true

# Enums
enum Difficulty { EASY, MEDIUM, HARD, EXTREME }
enum FishType { COMMON, RARE, EXOTIC, LEGENDARY }
@export var catching_difficulty: Difficulty = Difficulty.EASY
@export var fish_type: FishType = FishType.COMMON

# Special Requirements
@export var required_fishing_level: int = 1
@export var required_bait_types: Array[String] = []
@export var special_conditions: Array[String] = []

# Achievement/Collection
@export var achievement_points: int = 10
@export var collection_category: String = "Common"
@export var collection_number: int = 0

# Visual/UI Properties
@export var icon_path: String = ""
@export var sprite_path: String = ""

enum ColorVariant { NORMAL, RED, GREEN, BLUE, RAINBOW }
@export var current_color: ColorVariant = ColorVariant.NORMAL
@export var color_spawn_chances: Dictionary = {
	ColorVariant.NORMAL: 85.0,  # 85% chance
	ColorVariant.RED: 5.0,      # 5% chance
	ColorVariant.GREEN: 5.0,    # 5% chance
	ColorVariant.BLUE: 4.0,     # 4% chance
	ColorVariant.RAINBOW: 1.0	# 1% chance
}
	
@export var color_value_multipliers: Dictionary = {
	ColorVariant.NORMAL: 1.0,
	ColorVariant.RED: 2.0,
	ColorVariant.GREEN: 2.0,
	ColorVariant.BLUE: 2.0,
	ColorVariant.RAINBOW: 10.0
}
	
# Statistics Tracking
var largest_caught: float = 0.0
var smallest_caught: float = 0.0
var last_caught_date: int = 0  # Unix timestamp
var last_caught_location: String = ""

# Feel Free to add more vars or Methods
 
# Methods
func calculate_current_EXP(size: float) -> int:
	var exp_base := size + (rarity * 10)
	
	# Add difficulty bonus
	var difficulty_bonus: int
	match catching_difficulty:
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
	
	exp_base += difficulty_bonus * 10
	
	# First catch bonus
	if not is_discovered:
		exp_base += 50
	
	# Color variant multiplier
	exp_base *= color_value_multipliers[current_color]
	
	return int(exp_base)  # Convert to integer

	
# Function to randomly determine fish color when caught
func roll_color_variant() -> void:
	var total := 0.0
	var roll := randf() * 100  # Random number between 0 and 100
	
	for color in color_spawn_chances.keys():
		total += color_spawn_chances[color]
		if roll <= total:
			current_color = color
			break

# Helper function to get color name as string
func get_color_name() -> String:
	return ColorVariant.keys()[current_color]

func can_be_caught_now(current_time: String, current_season: String) -> bool:
	return time_of_day.has(current_time) and seasons.has(current_season)

func record_catch(size: float, location: String) -> void:
	amount_caught += 1
	total_weight_caught += size
	current_size = size
	if size > largest_caught:
		largest_caught = size
	if smallest_caught == 0 or size < smallest_caught:
		smallest_caught = size
	last_caught_location = location
	last_caught_date = Time.get_unix_time_from_system()
	is_discovered = true

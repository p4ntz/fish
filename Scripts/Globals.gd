extends Node

# This whole script is refed as Globals basically everywhere. It's in Project Settings > Autoload.

@export var DexInstance: Dex = Dex.new().init_data()
@export var IsFishing: bool = false
@export var FishWasCaught: bool = false
@export var fish_array: Array = []

@export var SizeDecimalPlaces: float = 0.1
@export var MusicVolume: float = 0.1

# Array to store fishing locations and their types
@export var fishing_locations: Array = []
@export var current_fishing_location: String = "air"  # Store the current water body type

func add_fishing_location(location: Vector2, water_type: String):
	fishing_locations.append({
		"position": location,
		"type": water_type
	})
	print("Added new fishing location: ", water_type, " at ", location)
	
func get_fishing_locations() -> Array:
	return fishing_locations
	
func set_current_fishing_location(water_type: String):
	current_fishing_location = water_type
	print("Now fishing in: ", current_fishing_location)
	var location_exists = false
	for location in fishing_locations:
		if location["type"] == water_type:
			location_exists = true
			total_locations_discovered += 1
			print("Total locations discovered: ", total_locations_discovered)
			break
	if not location_exists:
		add_fishing_location(Vector2.ZERO, water_type)
	
func get_current_fishing_location() -> String:
	return current_fishing_location

# Fisher stats
@export var fisher_level: int = 1
@export var fisher_experience: int = 0
@export var fisher_experience_total: int = 0
@export var fisher_experience_required: int = 0

func _ready():
	fisher_experience_required = get_required_experience(fisher_level + 1)

func get_required_experience(target_level: int) -> int:
	return round(pow(target_level, 1.8) + target_level * 4 + 100)

func gain_experience(amount: int) -> void:
	fisher_experience += amount
	fisher_experience_total += amount
	while fisher_experience >= fisher_experience_required:
		print(fisher_experience)
		print(fisher_experience_required)
		var keep := fisher_experience - fisher_experience_required
		fisher_experience = keep
		level_up()

func level_up() -> void:
	fisher_level += 1
	fisher_experience_required = get_required_experience(fisher_level + 1)

# fish game Stats
@export var maximum_rod_health: float = 200
@export var base_fish_stamina: float = 100
@export var base_fish_turn_speed: float = 1
@export var base_fish_recovery_speed: float = 50
@export var rod_damage_rate: float = 50
@export var fish_catch_rate: float = 10
@export var fish_held_catch_rate: float = 12
@export var base_fish_stamina_drain: float = 50

# Player Stats
@export var total_fish_caught: int = 0
@export var total_fish_weight: float = 0
@export var total_fish_caught_active: int = 0
@export var total_locations_discovered: int = 0
@export var total_fish_dex_entries: int = 0

# Seasons
const SEASONS: Array = ["Spring", "Summer", "Fall", "Winter"]
@export var current_season: String = ""

func set_current_season(season: String): 
	current_season=season
	print("Season has changed to: ", current_season)

# Time of Day
const TIMES_OF_DAY: Array = ["Morning", "Afternoon", "Evening", "Night"]
@export var current_time_of_day: String = ""

func set_current_time_of_day(time_of_day: String):
	current_time_of_day=time_of_day
	print("Time of day has changed to: ", current_time_of_day)

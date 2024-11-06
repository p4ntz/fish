extends Node

# This whole script is refed as Globals basically everywhere. It's in Project Settings > Autoload.

@export var DexInstance: Dex = Dex.new().init_data()
@export var IsFishing: bool = false
@export var FishWasCaught: bool = false

@export var SizeDecimalPlaces: float = 0.1
@export var MusicVolume: float = 0.1

# Array to store fishing locations and their types
@export var fishing_locations: Array = []
@export var current_fishing_location: String = ""  # Store the current water body type

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
	while fisher_experience_total >= fisher_experience_required:
		fisher_experience -= fisher_experience_required
		level_up()
		if fisher_experience < fisher_experience_required:
			break

func level_up() -> void:
	fisher_level += 1
	fisher_experience_required = get_required_experience(fisher_level + 1)

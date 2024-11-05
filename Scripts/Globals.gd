extends Node

# This whole script is refed as Globals basically everywhere. It's in Project Settings > Autoload.

@export var DexInstance: Dex = Dex.new().init_data()
@export var IsFishing: bool = false
@export var FishWasCaught: bool = false

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
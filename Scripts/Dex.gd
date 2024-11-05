extends Node
class_name Dex

@export var FishData: Dictionary
@export var LocationData: Dictionary
@export var tracked_fish: Fish

# this is a hacky data insertion for now just to have some test data. It can be expanded easily in the future.
func init_data() -> Dex:
	var file := "res://Scripts/fish.json"
	var json_as_text := FileAccess.get_file_as_string(file)
	var fishNames: Dictionary = JSON.parse_string(json_as_text)
	var locations: Array = []
	for index in fishNames.keys():      
		var fish = Fish.new()
		fish.fish_name = fishNames[index]["fish_name"]
		fish.catching_difficulty = fishNames[index]["difficulty"]
		fish.rarity = fishNames[index]["rarity"]
		fish.description = fishNames[index]["description"]
		fish.scientific_name = fishNames[index]["scientific_name"]
		fish.locations = fishNames[index]["locations"]
		for location in fishNames[index]["locations"]:
			if not location in locations:
				locations.append(fishNames[index]["locations"])
		FishData[fishNames[index]] = fish
	for location in locations:
		# init location info empty atm. make a json file for location data later and load the fish into it or something
		LocationData[location] = {}
	return self

func random_fish() -> Fish:
	var selected: int = randi_range(0,len(FishData.keys()) - 1)
	var check_fish: Fish = FishData[FishData.keys()[selected]]
	#if not check_fish.can_be_caught_now():
		
	tracked_fish = check_fish
	return tracked_fish

func free_fish() -> void:
	tracked_fish = null
	return

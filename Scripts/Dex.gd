extends Node
class_name Dex

@export var FishData: Dictionary
@export var LocationData: Dictionary
@export var tracked_fish: Fish

# this is a hacky data insertion for now just to have some test data. It can be expanded easily in the future.
func init_data() -> Dex:
    var fishNames: Dictionary = {
                                    0:{"fish_name":"goldfish", "difficulty": Fish.Difficulty.EASY, "rarity":0.1},
                                    1:{"fish_name":"bass","difficulty": Fish.Difficulty.MEDIUM, "rarity":0.5},
                                    2:{"fish_name":"salmon","difficulty": Fish.Difficulty.HARD, "rarity":1.0}
                                }
    for index in range(3):
        var fish = Fish.new()
        fish.fish_name = fishNames[index]["fish_name"]
        fish.catching_difficulty = fishNames[index]["difficulty"]
        fish.rarity = fishNames[index]["rarity"]
        FishData[fishNames[index]] = fish
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
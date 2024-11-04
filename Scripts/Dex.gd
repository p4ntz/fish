extends Node
class_name Dex

@export var Data: Dictionary
@export var tracked_fish: Fish

# this is a hacky data insertion for now just to have some test data. It can be expanded easily in the future.
func init_data() -> Dex:
    var fishNames: Array = ["goldfish","bass","salmon"]
    for index in range(3):
        var fish = Fish.new()
        fish.fish_name = fishNames[index]
        Data[fishNames[index]] = fish
    return self

func random_fish() -> Fish:
    var selected: int = randi_range(0,len(Data.keys()))       
    tracked_fish = Data[Data.keys()[selected]]
    return tracked_fish

func free_fish() -> void:
    tracked_fish = null
    return
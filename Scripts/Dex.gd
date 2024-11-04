extends Node
class_name Dex

@export var Data: Dictionary

func init_data() -> Dex:
    var fishNames: Array = ["goldfish","bass","salmon"]
    for index in range(3):
        var fish = Fish.new()
        fish.fish_name = fishNames[index]
        Data[fishNames[index]] = fish
    return self

func random_fish() -> Fish:
    var selected: int = randi_range(0,len(Data.keys()))       
    return Data[Data.keys()[selected]]
extends Node

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var fish = Globals.DexInstance.tracked_fish
	print(fish)
	$GridContainer/FishName.text = fish.fish_name
	$GridContainer/Size.text = str("Size: ", snapped(fish.current_size, 0.01), fish.size_unit)
	# Will need another to change the filepath for the sprite of the fish eventually.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#	func _process(delta: float) -> void:
#		pass


func _on_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/fisher.tscn")

func _input(event):
	if event.is_action_pressed("ui_accept"):
		get_tree().change_scene_to_file("res://Scenes/fisher.tscn")

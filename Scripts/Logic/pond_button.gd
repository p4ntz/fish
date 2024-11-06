extends Button

func _ready():
	visible = false

func _process(_delta):
	visible = Globals.total_fish_caught > 0

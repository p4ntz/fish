extends Label

func update_text(level, _experience, _required_exp):
	text = "Level: " + str(Globals.fisher_level)

func _process(_delta):
	update_text(Globals.fisher_level, Globals.fisher_experience, Globals.fisher_experience_required)

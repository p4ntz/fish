extends ProgressBar

# TODO: Make the EXP bar update smoother

func _process(_delta):
	var current_exp = Globals.fisher_experience
	var needed_exp = Globals.fisher_experience_required
	max_value = needed_exp
	value = current_exp

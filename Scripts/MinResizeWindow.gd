extends Control
var min_size := Vector2i(300, 400)
func _ready():
	ProjectSettings.set_setting("display/window/size/min_width", min_size.x)
	ProjectSettings.set_setting("display/window/size/min_height", min_size.y)
	DisplayServer.window_set_min_size(min_size)
func _process(delta):
	var current_size := DisplayServer.window_get_size()
	if current_size.x < min_size.x or current_size.y < min_size.y:
		DisplayServer.window_set_size(Vector2i(max(current_size.x, min_size.x), max(current_size.y, min_size.y)))

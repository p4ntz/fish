extends Label

# Called when the node enters the scene tree for the first time.
func _ready():
	var player: AudioStreamPlayer = AudioStreamPlayer.new()

	var file := FileAccess.open("res://Sound/A Fishy Menu Draft 1.mp3", FileAccess.READ)
	var sound := AudioStreamMP3.new()
	sound.data = file.get_buffer(file.get_length())
	sound.loop = true
	add_child(player)
	
	player.stream = sound
	player.autoplay = true
	player.play()		
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

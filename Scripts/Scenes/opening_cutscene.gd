extends Node

# For loading the bubble scene
@export var bubble_scene: PackedScene

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Ensure waves and labels are visible
	$PresentedBy.visible = true
	$Wave1.visible = true
	$Wave2.visible = true
	#hide end-of-scene text
	$IntroFishText.visible = false
	$IntroPressStart.visible = false
	# Sets fade out layer alpha to 0
	$Fade/FadeToGreen.color = Color(0.608,0.737,0.059,0)
	# Play the opening cutscene
	opening_wave_cutscene()

# Transitions to the main menu scene on pressing accept
func _input(event):
	if event.is_action_pressed("ui_accept"):
		$OpeningMusic.stop()
		$OpeningConfirmation.play()
		$FishVoices.play()
		await get_tree().create_timer(2).timeout
		fade_transition("res://Scenes/Title Screen.tscn")
		

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

# The base function for the opening cutscene
func opening_wave_cutscene() -> void:
	$OpeningMusic.play()
	move_wave_1(true)
	await get_tree().create_timer(0.25).timeout
	move_wave_2(true)
	await get_tree().create_timer(15.75).timeout
	clear_waves()
	

# Moves the 1st wave back and forth
func move_wave_1(input: bool) -> void:
	var move = input
	var loops = 0
	while move == true:
		$Wave1/Path2D_Wave1/PathFollow2D_Wave1.progress_ratio = 0
		await get_tree().create_timer(0.5).timeout
		$Wave1/Path2D_Wave1/PathFollow2D_Wave1.progress_ratio = .25
		await get_tree().create_timer(0.5).timeout
		$Wave1/Path2D_Wave1/PathFollow2D_Wave1.progress_ratio = .375
		await get_tree().create_timer(0.5).timeout
		$Wave1/Path2D_Wave1/PathFollow2D_Wave1.progress_ratio = .45
		await get_tree().create_timer(0.5).timeout
		$Wave1/Path2D_Wave1/PathFollow2D_Wave1.progress_ratio = .5
		await get_tree().create_timer(0.5).timeout
		$Wave1/Path2D_Wave1/PathFollow2D_Wave1.progress_ratio = .45
		await get_tree().create_timer(0.5).timeout
		$Wave1/Path2D_Wave1/PathFollow2D_Wave1.progress_ratio = .375
		await get_tree().create_timer(0.5).timeout
		$Wave1/Path2D_Wave1/PathFollow2D_Wave1.progress_ratio = .25
		await get_tree().create_timer(0.5).timeout
		loops += 1
		if loops >= 4:
			move = false
	
# Moves the 2nd wave back and forth
func move_wave_2(input: bool) -> void:
	var move = input
	var loops = 0
	while move == true:
		$Wave2/Path2D_Wave2/PathFollow2D_Wave2.progress_ratio = 0
		await get_tree().create_timer(0.5).timeout
		$Wave2/Path2D_Wave2/PathFollow2D_Wave2.progress_ratio = .25
		await get_tree().create_timer(0.5).timeout
		$Wave2/Path2D_Wave2/PathFollow2D_Wave2.progress_ratio = .375
		await get_tree().create_timer(0.5).timeout
		$Wave2/Path2D_Wave2/PathFollow2D_Wave2.progress_ratio = .45
		await get_tree().create_timer(0.5).timeout
		$Wave2/Path2D_Wave2/PathFollow2D_Wave2.progress_ratio = .5
		await get_tree().create_timer(0.5).timeout
		$Wave2/Path2D_Wave2/PathFollow2D_Wave2.progress_ratio = .45
		await get_tree().create_timer(0.5).timeout
		$Wave2/Path2D_Wave2/PathFollow2D_Wave2.progress_ratio = .3755
		await get_tree().create_timer(0.5).timeout
		$Wave2/Path2D_Wave2/PathFollow2D_Wave2.progress_ratio = .25
		await get_tree().create_timer(0.5).timeout
		loops += 1
		if loops >= 4:
			move = false
	
# Moves the waves off the top of the screen
func clear_waves() -> void:
	$Wave1/Path2D_Wave1/PathFollow2D_Wave1.progress_ratio = 0
	$Wave2/Path2D_Wave2/PathFollow2D_Wave2.progress_ratio = 0
	await get_tree().create_timer(0.25).timeout
	$Wave1/Path2D_Wave1/PathFollow2D_Wave1.progress_ratio = .125
	$Wave2/Path2D_Wave2/PathFollow2D_Wave2.progress_ratio = .1
	await get_tree().create_timer(0.25).timeout
	$Wave1/Path2D_Wave1/PathFollow2D_Wave1.progress_ratio = .25
	$Wave2/Path2D_Wave2/PathFollow2D_Wave2.progress_ratio = .2
	await get_tree().create_timer(0.25).timeout
	$Wave1/Path2D_Wave1/PathFollow2D_Wave1.progress_ratio = .375
	$Wave2/Path2D_Wave2/PathFollow2D_Wave2.progress_ratio = .35
	await get_tree().create_timer(0.25).timeout
	$Wave1/Path2D_Wave1/PathFollow2D_Wave1.progress_ratio = .5
	$Wave2/Path2D_Wave2/PathFollow2D_Wave2.progress_ratio = .45
	await get_tree().create_timer(0.25).timeout
	$Wave1/Path2D_Wave1/PathFollow2D_Wave1.progress_ratio = .625
	$Wave2/Path2D_Wave2/PathFollow2D_Wave2.progress_ratio = .6
	await get_tree().create_timer(0.25).timeout
	$Wave1/Path2D_Wave1/PathFollow2D_Wave1.progress_ratio = .75
	$Wave2/Path2D_Wave2/PathFollow2D_Wave2.progress_ratio = .7
	await get_tree().create_timer(0.25).timeout
	$Wave1/Path2D_Wave1/PathFollow2D_Wave1.progress_ratio = .875
	$Wave2/Path2D_Wave2/PathFollow2D_Wave2.progress_ratio = .875
	await get_tree().create_timer(0.25).timeout
	$Wave1/Path2D_Wave1/PathFollow2D_Wave1.progress_ratio = 1
	$Wave2/Path2D_Wave2/PathFollow2D_Wave2.progress_ratio = 1
	$PresentedBy.visible = false
	await get_tree().create_timer(0.25).timeout
	$Wave1.visible = false
	$Wave2.visible = false
	move_fish_up()
	spawn_bubbles(25)

# Moves the fish sprite to the center of the screen
func move_fish_up() -> void:
	var location: float = 0
	while location < .9:
		location += 0.1
		print(location)
		$FishPath/FishPathFollower.progress_ratio = location
		if location > .9:
			$IntroFishText.visible = true
			$IntroPressStart.visible = true
		await get_tree().create_timer(0.1).timeout
	
# Spawns in bubble objects
func spawn_bubbles(number: int) -> void:
	var loops: int = 0
	while loops < number:
		loops += 1
		var bubble = bubble_scene.instantiate()
		var bubble_spawn_location = $BubbleSpawn/BubbleSpawnLocation
		bubble_spawn_location.progress_ratio = randf()
		bubble.position = bubble_spawn_location.position
		add_child(bubble)
		await get_tree().create_timer(0.05).timeout
		
# Fades the screen to green and changes the scene
func fade_transition(scene: String) -> void:
	$Fade/FadeToGreen.color = Color(0.608,0.737,0.059,.25)
	await get_tree().create_timer(0.1).timeout
	$Fade/FadeToGreen.color = Color(0.608,0.737,0.059,.5)
	await get_tree().create_timer(0.1).timeout
	$Fade/FadeToGreen.color = Color(0.608,0.737,0.059,.275)
	await get_tree().create_timer(0.1).timeout
	$Fade/FadeToGreen.color = Color(0.608,0.737,0.059,1)
	await get_tree().create_timer(.5).timeout
	get_tree().change_scene_to_file(scene)

# loop the cutscene when the music stops
func _on_opening_music_finished() -> void:
	fade_transition("res://Scenes/opening_cutscene.tscn")

extends Node


@onready var player = $Player
@onready var hud = $Hud
@onready var joystick = $Hud/Joystick
var score
var speed
var follow_touch
var difficulty_index
var music_volume
var sound_volume
var start_wait_time
var debug_progress = 50 #5


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	coord_utils.window_size_changed.connect(on_window_size_changed)
	if follow_touch != null: print("follow_touch: %s" % str(follow_touch))
	data_manage.is_show_log = true
	if !load_data(): 
		print("Game: 新建数据!")
		if !save_data(true): print("Game: 保存数据失败!")
		else: update_data()
	else:
		update_data()
	call_deferred("_initialize_player")
	$AudioStreamLobbyMusic.play()
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
	
func on_window_size_changed(window_size):
	pass

##数据加载
func load_data():
	#数据加载
	follow_touch = data_manage.get_object("follow_touch")
	if follow_touch != null:
		hud.sprite2d_joystick_weapon.follow_touch = follow_touch
	else: return false
		
	difficulty_index = data_manage.get_object("difficulty_index")
	if difficulty_index != null:
		_on_difficulty_modification(difficulty_index)
	else: return false
		
	music_volume = data_manage.get_object("music_volume")
	if music_volume != null:
		set_music_volume(music_volume)
	else: return false
		
	sound_volume = data_manage.get_object("sound_volume")
	if sound_volume != null:
		set_sound_volume(sound_volume)
	else: return false
	return true

##数据保存
func save_data(init = false):
	if init:
		if !data_manage.set_object("follow_touch", false, 1):
			return false
		if !data_manage.set_object("difficulty_index", 0, 2):
			return false
		if !data_manage.set_object("music_volume", 1.0, 3):
			return false
		if !data_manage.set_object("sound_volume", 1.0, 4):
			return false
	else:
		if !data_manage.set_object("follow_touch", follow_touch, 1):
			return false
		if !data_manage.set_object("difficulty_index", difficulty_index, 2):
			return false
		if !data_manage.set_object("music_volume", music_volume, 3):
			return false
		if !data_manage.set_object("sound_volume", sound_volume, 4):
			return false
		
	return true
	
func update_data():
	print("update_data: 更新数据.")
	hud.sprite2d_joystick.follow_touch = follow_touch
	hud.check_follw_touch.button_pressed = follow_touch
	
	_on_difficulty_modification(difficulty_index)
	hud.button_option.selected = difficulty_index
	
	set_music_volume(music_volume)
	hud.hslider_background_music.value = music_volume * 100
	
	set_sound_volume(sound_volume)
	hud.hslider_kill_music.value = sound_volume * 100
	pass

func game_over():
	$SoundGhostWin.play()
	$ScoreTimer.stop()
	#$MobTimer.stop()
	$Generate/ObjectTimer.stop()
	$GeneratePropBullet/ObjectTimer.stop()
	$GeneratePropHealth/ObjectTimer.stop()
	$Music.stop()
	#$DeathSound.play(0)
	hud.show_game_over()


func new_game():
	$AudioStreamLobbyMusic.stop()
	get_tree().call_group("ghost", "queue_free")
	$Music.stream_paused = false
	$Music.playing = false
	$Music.play(0)
	score = 0
	player.start()
	$StartTimer.start()
	hud.update_score(score)
	start_wait_time = 5 + 1


func _on_mob_timer_timeout() -> void:
	pass

func _on_score_timer_timeout() -> void:
	score += 1
	hud.add_progress(1 + debug_progress)	
	hud.update_score(score)


func _on_start_timer_timeout() -> void:
	var audio_stream = load("res://dodge_the_creeps_2d_assets/art/CF/幽灵出现倒计时_%s.wav" % (start_wait_time - 1))
	if start_wait_time - 1 != 0:
		hud.show_message(str(start_wait_time - 1))
	if start_wait_time > 0 and !$SoundGhostRefreshCountDown.is_playing():
		$SoundGhostRefreshCountDown.stream = audio_stream
		$SoundGhostRefreshCountDown.play()
	start_wait_time -= 1
	
	if start_wait_time <= 0:
		#$MobTimer.start()
		$SoundGhostRefresh.play()
		$Player/TimerBullet.start()
		$Generate/ObjectTimer.start()
		$GeneratePropBullet/ObjectTimer.start()
		$GeneratePropHealth/ObjectTimer.start()
		$ScoreTimer.start()
	else: 
		$StartTimer.start()

func _initialize_player() -> void:
	if player and hud:
		player.joystick = hud.sprite2d_joystick
		player.joystick_weapon = hud.sprite2d_joystick_weapon
		player.activity_range = $ColorRect.size
		hud.difficulty_modification.connect(_on_difficulty_modification)
		_on_difficulty_modification(difficulty_index)
		hud.set_progress_max(200)
		print("Player 初始化成功.")
	else:
		print("Player or HUD 无效!")

func _on_difficulty_modification(index: int):
	difficulty_index = index
	match difficulty_index:
		0:
			$Generate.speed_max = 400
			$Generate.generate_speed = 0.060
			$GeneratePropHealth.generate_speed = 60
		1:
			$Generate.speed_max = 600
			$Generate.generate_speed = 0.060
			$GeneratePropHealth.generate_speed = 50
		2:
			$Generate.speed_max = 800
			$Generate.generate_speed = 0.065
			$GeneratePropHealth.generate_speed = 40
		3:
			$Generate.speed_max = 900
			$Generate.generate_speed = 0.070
			$GeneratePropHealth.generate_speed = 30
		4:
			$Generate.speed_max = 1000
			$Generate.generate_speed = 0.075
			$GeneratePropHealth.generate_speed = 20
	if !save_data(): print("Game: difficulty_index: 保存数据失败!")
	pass


func _on_hud_sound_change(volume_percentage: float) -> void:
	sound_volume = volume_percentage
	set_sound_volume(sound_volume)
	pass # Replace with function body.

func set_sound_volume(volume_percentage: float) -> void:
	player.get_node("SoundKill").set_volume_linear(volume_percentage)
	player.get_node("PickUp").set_volume_linear(volume_percentage)
	player.get_node("SoundHit").set_volume_linear(volume_percentage)
	#$DeathSound.set_volume_linear(volume_percentage)
	print("设置音效音量: ", volume_percentage)
	if !save_data(): print("Game: sound_volume: 保存数据失败!")
	pass

func _on_hud_music_change(volume_percentage: float) -> void:
	music_volume = volume_percentage
	set_music_volume(music_volume)
	pass # Replace with function body.

func set_music_volume(volume_percentage: float) -> void:
	$Music.set_volume_linear(volume_percentage)
	print("设置音乐音量: ", volume_percentage)
	if !save_data(): print("Game: music_volume: 保存数据失败!")
	pass


func _on_timer_sava_data_timeout() -> void:
	if !save_data(): print("Game: AutoSaveData: 保存数据失败!")
	pass # Replace with function body.


func _on_hud_follow_touch_change(change: bool) -> void:
	follow_touch = change
	if !save_data(): print("Game: follow_touch: 保存数据失败!")
	pass # Replace with function body.


func _on_generate_ghost_count(count: int) -> void:
	if $Label/LabelGhostCount: $Label/LabelGhostCount.text = str(count)
	pass # Replace with function body.


func _on_player_kill() -> void:
	hud.add_progress(1)	
	pass # Replace with function body.


func _on_hud_progress_max() -> void:
	player.ghost_hunter_time += 8
	player.transfiguration_ghost_hunter_start()
	pass # Replace with function body.

extends Node


@onready var player = $Player
@onready var hud = $Hud
@onready var joystick = $Hud/Joystick
var score
var speed


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	call_deferred("_initialize_player")
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	#speed = player.speed * joystick.get_touch_radius_percent()
		#
	#var velocity = Vector2.ZERO # The player's movement vector.
	#velocity = joystick.get_now_pos()
#
	#if velocity.length() > 0:
		#velocity = velocity.normalized() * speed
		#player.animated.play()
	#else:
		#player.animated.stop()
		#
	#player.position += velocity * delta
	#player.position = player.position.clamp(Vector2.ZERO, $ColorRect.size)
	#
	#if velocity.x != 0:
		#player.animated.animation = "walk"
		#player.animated.flip_v = false
		## See the note below about the following boolean assignment.
		#player.animated.flip_h = velocity.x < 0
	#elif velocity.y != 0:
		#player.animated.animation = "up"
		#player.animated.flip_v = velocity.y > 0
	pass
	

func game_over():
	$ScoreTimer.stop()
	#$MobTimer.stop()
	$Generate/ObjectTimer.stop()
	$Music.stop()
	$DeathSound.play(0)
	hud.show_game_over()


func new_game():
	get_tree().call_group("mobs", "queue_free")
	$Music.stream_paused = false
	$Music.playing = false
	$Music.play(0)
	score = 0
	player.start()
	$StartTimer.start()
	hud.update_score(score)
	hud.show_message("Get Ready")


func _on_mob_timer_timeout() -> void:
	pass

func _on_score_timer_timeout() -> void:
	score += 1
	hud.update_score(score)


func _on_start_timer_timeout() -> void:
	#$MobTimer.start()
	$Player/TimerBullet.start()
	$Generate/ObjectTimer.start()
	$ScoreTimer.start()

func _initialize_player() -> void:
	if player and hud:
		player.joystick = hud.get_node("Joystick")
		player.activity_range = $ColorRect.size
		print("Player 初始化成功.")
	else:
		print("Player or HUD 无效!")

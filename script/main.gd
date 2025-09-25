extends Node


@export var mob_scene: PackedScene
var score
var speed


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	$HUD/joystick.screen_size = $Player.screen_size
	$HUD/settings.screen_size = $Player.screen_size
	
	speed = $Player.speed * $HUD/joystick.get_touch_radius_percent()
	
	var velocity = Vector2.ZERO # The player's movement vector.
	velocity = $HUD/joystick.get_now_pos()

	if velocity.length() > 0:
		velocity = velocity.normalized() * speed
		$Player/AnimatedSprite2D.play()
	else:
		$Player/AnimatedSprite2D.stop()
		
	$Player.position += velocity * delta
	$Player.position = $Player.position.clamp(Vector2.ZERO, $Player.screen_size)
	
	if velocity.x != 0:
		$Player/AnimatedSprite2D.animation = "walk"
		$Player/AnimatedSprite2D.flip_v = false
		# See the note below about the following boolean assignment.
		$Player/AnimatedSprite2D.flip_h = velocity.x < 0
	elif velocity.y != 0:
		$Player/AnimatedSprite2D.animation = "up"
		$Player/AnimatedSprite2D.flip_v = velocity.y > 0
	pass


func game_over():
	$ScoreTimer.stop()
	$MobTimer.stop()
	$Music.stop()
	$DeathSound.play()
	$HUD.show_game_over()


func new_game():
	get_tree().call_group("mobs", "queue_free")
	$Music.play()
	score = 0
	$Player.start($StartPosition.position)
	$StartTimer.start()
	$HUD.update_score(score)
	$HUD.show_message("Get Ready")


func _on_mob_timer_timeout() -> void:
	# Create a new instance of the Mob scene.
	var mob = mob_scene.instantiate()

	# Choose a random location on Path2D.
	var mob_spawn_location = $MobPath/MobSpawnLocation
	mob_spawn_location.progress_ratio = randf()

	# Set the mob's position to the random location.
	mob.position = mob_spawn_location.position

	# Set the mob's direction perpendicular to the path direction.
	var direction = mob_spawn_location.rotation + PI / 2

	# Add some randomness to the direction.
	direction += randf_range(-PI / 4, PI / 4)
	mob.rotation = direction

	# Choose the velocity for the mob.
	var velocity = Vector2(randf_range(200.0, 300.0), 0.0)
	mob.linear_velocity = velocity.rotated(direction)

	# Spawn the mob by adding it to the Main scene.
	add_child(mob)


func _on_score_timer_timeout() -> void:
	score += 1
	$HUD.update_score(score)


func _on_start_timer_timeout() -> void:
	$MobTimer.start()
	$ScoreTimer.start()

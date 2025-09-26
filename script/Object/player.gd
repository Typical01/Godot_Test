extends Area2D

signal hit
signal die


@onready var animated = $Animated
@onready var animation = $AnimationPlayer
@onready var hit_sound = $AudioStreamPlayer2D
@onready var health_list = $HealthList
@onready var weapon = $Weapon
@onready var joystick
@onready var joystick_weapon

@export var speed_scale = 1.0 # 玩家速度的比例
@export var speed = 400 # 玩家速度(像素/秒).
@export var activity_range : Vector2 # How fast the player will move (pixels/sec).
@export var health_icon : Texture2D
@export var bullet : PackedScene

var screen_size: Vector2 # Size of the game window.
var health = 4
var live = true

var is_weapon_hold = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var window := get_window()
	window.size_changed.connect(_on_window_resized)
	_on_window_resized()
	activity_range = screen_size
	health_list.visible = false
	if health_icon:
		for i in range(health):
			health_list.add_icon_item(health_icon, false)
	is_weapon_hold = true
	hide()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if is_weapon_hold:
		weapon.visible = true
	
	var player_speed = speed
	var weapon_speed = speed
	
	var velocity = Vector2.ZERO # The player's movement vector.
	var velocity_weapon = Vector2.ZERO # The player's movement vector.
	if joystick:
		velocity = joystick.get_now_pos()
		player_speed = speed * joystick.get_touch_radius_percent()
		
	if joystick_weapon:
		velocity_weapon = joystick_weapon.get_now_pos()
		weapon_speed = speed * joystick_weapon.get_touch_radius_percent()
	
	if Input.is_action_pressed("move_right"):
		velocity.x += 1
		player_speed = speed
	if Input.is_action_pressed("move_left"):
		velocity.x -= 1
		player_speed = speed
	if Input.is_action_pressed("move_down"):
		velocity.y += 1
		player_speed = speed
	if Input.is_action_pressed("move_up"):
		velocity.y -= 1
		player_speed = speed

	if velocity.length() > 0:
		velocity = velocity.normalized() * player_speed * speed_scale
		velocity_weapon = velocity_weapon.normalized() * weapon_speed * speed_scale
		animated.play()
	else:
		animated.stop()
	
	if live:	
		position += velocity * delta
		position = position.clamp(Vector2.ZERO, activity_range)
			
		if velocity.x != 0:
			animated.animation = "walk"
			animated.flip_v = false
			weapon.flip_v = false
			# See the note below about the following boolean assignment.
			animated.flip_h = velocity.x < 0
			weapon.flip_h = velocity.x > 0
		elif velocity.y != 0:
			animated.animation = "up"
			animated.flip_v = velocity.y > 0
			weapon.flip_v = velocity.y < 0
		
func _on_window_resized():
	screen_size = get_viewport().get_visible_rect().size

func start(pos = Vector2(0.0, 0.0)):
	if pos == Vector2(0.0, 0.0):
		position = screen_size * 0.5
	else:
		position = pos
	show()
	$CollisionShape2D.disabled = false
	live = true
	health = 4
	if health_icon:
		for i in range(health):
			if health_list.item_count < health:
				health_list.add_icon_item(health_icon, false)
	
func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("mobs"):
		if animation.is_playing(): return #等待动画播放完成
		health_list.visible = true
		health -= 1
		hit.emit()
		health_list.remove_item(health_list.item_count - 1)
		animation.play("hit")
		hit_sound.play()
		if health <= 0:
			live = false
			#hide() # Player disappears after being hit.
			die.emit()
			# Must be deferred as we can't change physics properties on a physics callback.
			$CollisionShape2D.set_deferred("disabled", true)


func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == "hit":
		health_list.visible = false
		if health <= 0:
			hide()
	pass # Replace with function body.


func _on_timer_bullet_timeout() -> void:
	var bullet_ins = bullet.instantiate()
	add_child(bullet_ins)
	pass # Replace with function body.

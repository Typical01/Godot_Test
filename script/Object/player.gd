extends Area2D

signal hit
signal die
signal kill


@onready var animated = $Animated
@onready var animation = $AnimationPlayer
@onready var hit_sound = $SoundHit
@onready var health_list = $HealthList
@onready var weapon = $Weapon
@onready var joystick
@onready var joystick_weapon

@export var speed_scale = 1.0 # 玩家速度的比例
@export var speed = 400 # 玩家速度(像素/秒).
@export var activity_range : Vector2 # How fast the player will move (pixels/sec).
@export var activity_range_clamp_start = Vector2(300, 300) # How fast the player will move (pixels/sec).
@export var activity_range_clamp_end = Vector2(300, 300) # How fast the player will move (pixels/sec).
@export var health_icon : Texture2D
@export var bullet : PackedScene

var health = 0
@export var health_max = 4
var live = true
var ghost_hunter = false
var ghost_hunter_time = 8
var kill_count = 0
var bullet_number : int

var is_weapon_hold = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	coord_utils.window_size_changed.connect(on_window_size_changed)
	health_list.visible = false
	is_weapon_hold = true
	$Sprite2D.visible = false
	$GhostHunter.visible = false
	hide()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if !$Knife.get_node("AnimationPlayer").is_playing():
		$Knife.get_node("AnimationPlayer").play("attack_1")
	if !$Knife2.get_node("AnimationPlayer").is_playing():
		$Knife2.get_node("AnimationPlayer").play("attack_2")
	
	if !ghost_hunter and is_weapon_hold:
		weapon.visible = true
	
	var player_speed = speed
	var weapon_speed = speed
	
	var velocity = Vector2.ZERO # The player's movement vector.
	var velocity_weapon = Vector2.ZERO # The player's movement vector.
	if joystick:
		velocity = joystick.get_direction()
		player_speed = speed * joystick.get_intensity()
		
	if joystick_weapon:
		velocity_weapon = joystick_weapon.get_direction()
		weapon_speed = speed * joystick_weapon.get_intensity()
	
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
		position = position.clamp(Vector2.ZERO + activity_range_clamp_start, activity_range - activity_range_clamp_end)
			
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

func on_window_size_changed(_window_size):
	pass

func start(pos = Vector2(0.0, 0.0)):
	if pos == Vector2(0.0, 0.0):
		position = activity_range * 0.5
	else:
		position = pos
	show()
	$CollisionShape2D.disabled = false
	bullet_number = 90
	$BulletCount.text = str(bullet_number)
	set_health(health_max)
	$Knife.visible = false
	$Knife.monitoring = false
	$Knife2.visible = false
	$Knife2.monitoring = false
	
func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("ghost"):
		if animation.is_playing(): return #等待动画播放完成
		set_health(health - 1)
		hit.emit()
		#health_list.remove_item(health_list.item_count - 1)
		hit_sound.play()
		if health <= 0:
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
	if !live: return
	if ghost_hunter: return #幽灵猎手无法使用远程武器
	if bullet_number <= 0: return
	
	# 实例化并转换类型
	var bullet_ins: RigidBody2D = bullet.instantiate() as RigidBody2D
	if not bullet_ins:
		push_error("bullet_timeout: bullet.instantiate() 不是 RigidBody2D")
		return
	bullet_ins.hit_mobs.connect(_on_bullet_hit)
	bullet_ins.kill.connect(_on_bullet_kill)

	# 从摇杆拿方向向量（单位向量），若为 Vector2.ZERO 则默认向右
	var dir: Vector2 = joystick_weapon.get_direction()
	if dir == Vector2.ZERO:
		return

	# 设定子弹位置（这里用当前节点的 global_position，或用 muzzle.global_position）
	#bullet_ins.global_position = global_position
	# 如果你有 muzzle，可以用下面一行替代上一行：
	# bullet_ins.global_position = muzzle.global_position

	# 设置朝向：如果子弹资源默认面朝 +X（向右），直接用 dir.angle()
	# 如果子弹默认面朝上（+Y），添加偏移：deg2rad(-90) 或 deg2rad(90) 视贴图方向而定
	var sprite_forward_offset: float = 0.0 # 根据你的子弹贴图朝向调整（弧度）
	bullet_ins.rotation = dir.angle() + sprite_forward_offset
	weapon.rotation = dir.angle() + sprite_forward_offset

	# 设置速度（direction * speed）
	bullet_ins.linear_velocity = dir * bullet_ins.speed
	# 最后把子弹加入场景树
	add_child(bullet_ins)
	bullet_number -= 1
	#var nodes_in_grp: Array = get_tree().get_nodes_in_group("bullet")
	$BulletCount.text = str(bullet_number)


func _on_area_entered(area: Area2D) -> void:
	$PickUp.play()
	if area.is_in_group("prop_bullet"):
		bullet_number += 90
		$BulletCount.text = str(bullet_number)
		area.queue_free()
	elif area.is_in_group("prop_health"):
		set_health(health + 1)
		$BulletCount.text = str(bullet_number)
		area.queue_free()
	pass

func _on_bullet_hit(_body: Node) -> void:
	$SoundKill.play()
	if $Sprite2D/AnimationHeadShot.is_playing():
		$Sprite2D/AnimationHeadShot.stop()
	$Sprite2D.visible = true
	$Sprite2D/AnimationHeadShot.play("head_shot")
	pass

func set_health(health_number: int):
	# 限制到合法范围
	health_number = clamp(health_number, 0, health_max)
	# 如果没有变化就直接返回（避免不必要的闪烁/动画）
	if health_number == health:
		return
	
	health_list.visible = true
	if health_icon:
		if health > health_number: #减血
			if ghost_hunter: return #幽灵猎手无敌
			var health_difference = health - health_number
			for i in range(health_difference):
				health_list.remove_item(health_list.item_count - 1)
		elif health < health_number: #加血
			var health_difference = health_number - health
			for i in range(health_difference):
				health_list.add_icon_item(health_icon, false)
	animation.play("hit")
	health = health_number
	if health > 0:
		live = true
	else:
		live = false
		$SoundGhostHunterDeath.play()
	pass

func transfiguration_ghost_hunter_start():
	if !ghost_hunter:
		ghost_hunter = true
		$TimerTransfiguration.start()
		weapon.visible = false
		$GhostHunter/AnimationGhostHunter.play("ghost_hunter")
		$Knife.visible = true
		$Knife.monitoring = true
		$Knife2.visible = true
		$Knife2.monitoring = true
		$GhostHunter/AnimationGhostHunter.play("ghost_hunter")
		$AudioStreamGhostHunter.play(41)
	
func transfiguration_ghost_hunter_end():
	weapon.visible = true
	$Knife.visible = false
	$BulletCount.text = str(bullet_number)
	$Knife.monitoring = false
	$Knife2.visible = false
	$Knife2.monitoring = false
	$AudioStreamGhostHunter.stop()
	ghost_hunter = false

func _on_knife_kill() -> void:
	kill_count += 1
	kill.emit()
	pass # Replace with function body.


func _on_knife_2_kill() -> void:
	kill_count += 1
	kill.emit()
	pass # Replace with function body.


func _on_timer_transfiguration_timeout() -> void:
	if ghost_hunter_time > 1:
		ghost_hunter_time -= 1
		$BulletCount.text = str(ghost_hunter_time)
		$TimerTransfiguration.start()
	else:
		transfiguration_ghost_hunter_end()
	pass # Replace with function body.

func _on_bullet_kill():
	kill_count += 1
	kill.emit()
	pass

extends RigidBody2D

@onready var wait_time: float = $TimerOut.wait_time

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var mob_types = Array($AnimatedSprite2D.sprite_frames.get_animation_names())
	$AnimatedSprite2D.animation = mob_types.pick_random()
	$AnimatedSprite2D.play()
	
	var timer = Timer.new()
	add_child(timer)
	timer.wait_time = 0.5
	timer.timeout.connect(_on_timeout)
	timer.start()
	$TimerOut.start()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
	
func _on_visible_on_screen_notifier_2d_screen_entered() -> void:
	$TimerOut.stop()
	$TimerOut.wait_time = wait_time
	pass # Replace with function body.

func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	$TimerOut.start()
	pass
	
	
func _on_timer_out_timeout() -> void:
	queue_free()
	pass # Replace with function body.

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("bullet"):
		queue_free()
	pass # Replace with function body.

func _on_timeout() -> void:
	var time: int = $TimerOut.get_time_left()
	$Label.text = str(time)
	pass # Replace with function body.

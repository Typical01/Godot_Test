extends RigidBody2D

signal hit_mobs(body: Node)
signal kill

@onready var wait_time: float = $TimerOut.wait_time
@export var speed = 900 * 6 # 子弹速度(像素/秒).


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var timer = Timer.new()
	add_child(timer)
	timer.wait_time = 0.5
	timer.timeout.connect(_on_timer_timeout)
	timer.start()
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

func _on_timer_timeout():
	$Label.text = str($TimerOut.get_time_left())
	pass

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("ghost"):
		emit_signal("hit_mobs", body)
		kill.emit()
		queue_free()
	pass # Replace with function body.


func _on_visible_on_screen_notifier_2d_screen_entered() -> void:
	$TimerOut.stop()
	$TimerOut.wait_time = wait_time
	pass # Replace with function body.


func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	$TimerOut.start()
	pass # Replace with function body.


func _on_timer_out_timeout() -> void:
	queue_free()
	pass # Replace with function body.

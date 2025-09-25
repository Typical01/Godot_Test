extends CanvasLayer

# Notifies `Main` node that the button has been pressed
signal start_game

@export var title_name = "真高手就坚持100秒!"
var joystick_position

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	button_is_visible(false)
	button_is_show(false)
	$Message.text = title_name
	joystick_position = $joystick.position
	$settings/Ui.visible = false
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func show_message(text):
	$Message.text = text
	$Message.show()
	$MessageTimer.start()
		
func show_game_over():
	button_is_visible(false)
	button_is_show(false)
	show_message("游戏结束")
	# Wait until the MessageTimer has counted down.
	await $MessageTimer.timeout

	$Message.text = title_name
	$Message.show()
	# Make a one-shot timer and wait for it to finish.
	await get_tree().create_timer(1.0).timeout
	$StartButton.show()
	$ColorRect.show()

func update_score(score):
	$ScoreLabel.text = str(score)

func button_is_visible(is_enable: bool):
	$joystick.is_visible = is_enable

func button_is_show(is_enable: bool):
	if is_enable:
		$joystick.show()
	else:
		$joystick.hide()

func _on_start_button_pressed() -> void:
	$StartButton.hide()
	$settings.hide()
	button_is_visible(true)
	button_is_show(true)
	start_game.emit()


func _on_message_timer_timeout() -> void:
	$Message.hide()


func _on_check_button_follow_touch_toggled(toggled_on: bool) -> void:
	if !toggled_on:
		$joystick.position = joystick_position
	$joystick.bIsFollowTouch = toggled_on
	pass # Replace with function body.
	


func _on_settings_open_setting_ui() -> void:
	#$settings/Ui/CheckButtonFollowTouch/AnimationPlayer.animation_set_next("new_animation", "new_animation")
	#$settings/Ui/CheckButtonFollowTouch/AnimationPlayer.play("new_animation")
	$settings/Ui.visible = true
	pass # Replace with function body.


func _on_close_close_ui() -> void:
	$settings/Ui.visible = false
	pass # Replace with function body.

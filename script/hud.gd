extends CanvasLayer

# Notifies `Main` node that the button has been pressed
signal start_game


@onready var settings_menu = $SettingsMenu
var title_name
var Joystick_position

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	button_is_visible(false)
	button_is_show(false)
	title_name = $Message.text
	Joystick_position = $Joystick.position
	settings_menu.visible = false
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
	$Settings.show()

func update_score(score):
	$ScoreLabel.text = str(score)

func button_is_visible(is_enable: bool):
	$Joystick.is_visible = is_enable

func button_is_show(is_enable: bool):
	if is_enable:
		$Joystick.show()
	else:
		$Joystick.hide()

func _on_start_button_pressed() -> void:
	$StartButton.hide()
	$Settings.hide()
	button_is_visible(true)
	button_is_show(true)
	start_game.emit()


func _on_message_timer_timeout() -> void:
	$Message.hide()


func _on_check_button_follow_touch_toggled(toggled_on: bool) -> void:
	if !toggled_on:
		$Joystick.position = Joystick_position
	$Joystick.bIsFollowTouch = toggled_on
	pass # Replace with function body.
	


func _on_settings_open_setting_ui() -> void:
	#settings_menu/CheckButtonFollowTouch/AnimationPlayer.animation_set_next("new_animation", "new_animation")
	#settings_menu/CheckButtonFollowTouch/AnimationPlayer.play("new_animation")
	settings_menu.visible = true
	$SettingsMenu/AnimationPlayer.play("open_menu")
	pass # Replace with function body.


func _on_close_close_ui() -> void:
	$SettingsMenu/AnimationPlayer.play("close_menu")
	pass # Replace with function body.


func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == "close_menu":
		settings_menu.visible = false
	pass # Replace with function body.

extends CanvasLayer

# Notifies `Main` node that the button has been pressed
signal start_game
signal progress_max
signal follow_touch_change(change: bool) ##修改摇杆跟随
signal difficulty_modification(index: int) ##修改难度
signal sound_change(volume_percentage: float) ##音效音量百分比
signal music_change(volume_percentage: float) ##音乐音量百分比


@onready var label_message = $GameOutsideUi/LabelMessage
@onready var button_start = $GameOutsideUi/ButtonStart
@onready var color_rect_menu_settings = $GameOutsideUi/ColorRectSettingsMenu
@onready var button_option = $GameOutsideUi/ColorRectSettingsMenu/LabelDifficulty/ButtonOption
@onready var check_follw_touch = $GameOutsideUi/ColorRectSettingsMenu/LabelJoystick/CheckFollowTouch
@onready var animation_color_rect_menu_settings = $GameOutsideUi/ColorRectSettingsMenu/Animation
@onready var button_settings = $GameOutsideUi/ButtonSettings
@onready var animation_button_settings = $GameOutsideUi/ButtonSettings/Animation
@onready var timer_message = $TimerMessage
@onready var sprite2d_joystick_weapon = $GamePlayingUi/Sprite2DJoystickWeapon
@onready var sprite2d_joystick = $GamePlayingUi/Sprite2DJoystick
@onready var label_score = $GamePlayingUi/LabelScore
@onready var texture_progress_transfiguration = $GamePlayingUi/TextureProgressTransfiguration
@onready var texture_rect_transfiguration = $GamePlayingUi/TextureRect
@onready var hslider_background_music = $GameOutsideUi/ColorRectSettingsMenu/LabelBackgroundMusic/HSliderBackgroundMusic
@onready var hslider_kill_music = $GameOutsideUi/ColorRectSettingsMenu/LabelKillSound/HSliderKillMusic

@export var label_message_postion = Vector2(0.5, 0.4)
@export var button_start_postion = Vector2(0.5, 0.9)
@export var color_rect_menu_settings_postion = Vector2(0.5, 0.5)
@export var button_settings_postion = Vector2(0.05, 0.9)
@export var label_score_postion = Vector2(0.5, 0.1)
@export var timer_message_postion = Vector2(0.5, 0.1)
@export var sprite2d_joystick_postion = Vector2(0.19, 0.75)
@export var sprite2d_joystick_weapon_postion = Vector2(0.81, 0.75)

var title_name
var joystick_position
var joystick_weapon_position
var music_max
var sound_max


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	coord_utils.window_size_changed.connect(on_window_size_changed)
	GamePlayingUi_is_visible(false)
	GameOutsideUi_is_visible(true)
	title_name = label_message.text
	joystick_position = sprite2d_joystick.position
	joystick_weapon_position = sprite2d_joystick_weapon.position
	color_rect_menu_settings.visible = false
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
	
func on_window_size_changed(window_size):
	coord_utils.set_screen_global_position(label_message, label_message_postion)
	coord_utils.set_screen_global_position(button_start, button_start_postion)
	coord_utils.set_screen_global_position(color_rect_menu_settings, color_rect_menu_settings_postion)
	coord_utils.set_screen_global_position(button_settings, button_settings_postion)
	coord_utils.set_screen_global_position(sprite2d_joystick_weapon, sprite2d_joystick_weapon_postion)
	coord_utils.set_screen_global_position(sprite2d_joystick, sprite2d_joystick_postion)
	coord_utils.set_screen_global_position(label_score, label_score_postion)
	pass

func show_message(text):
	label_message.text = text
	label_message.show()
	timer_message.start()
		
func show_game_over():
	GameOutsideUi_is_visible(true)
	GamePlayingUi_is_visible(false)
	show_message("游戏结束")
	# Wait until the MessageTimer has counted down.
	await timer_message.timeout

	label_message.text = title_name
	label_message.visible = true
	# Make a one-shot timer and wait for it to finish.
	await get_tree().create_timer(1.0).timeout

func update_score(score):
	label_score.text = str(score)

func GamePlayingUi_is_visible(is_enable: bool):
	sprite2d_joystick.visible = is_enable
	sprite2d_joystick.is_visible_by_default = is_enable
	sprite2d_joystick_weapon.visible = is_enable
	sprite2d_joystick_weapon.is_visible_by_default = is_enable
	texture_rect_transfiguration.visible = is_enable
	texture_progress_transfiguration.visible = is_enable
	label_score.visible = is_enable

func GameOutsideUi_is_visible(is_enable: bool):
	label_message.visible = is_enable
	button_start.visible = is_enable
	button_settings.visible = is_enable
	#color_rect_menu_settings.visible = is_enable

func _on_start_button_pressed() -> void:
	GamePlayingUi_is_visible(true)
	GameOutsideUi_is_visible(false)
	start_game.emit()


func _on_message_timer_timeout() -> void:
	label_message.visible = false


func _on_check_button_follow_touch_toggled(toggled_on: bool) -> void:
	if !toggled_on:
		sprite2d_joystick.position = joystick_position
		sprite2d_joystick_weapon.position = joystick_weapon_position
	sprite2d_joystick.follow_touch = toggled_on
	sprite2d_joystick_weapon.follow_touch = toggled_on
	follow_touch_change.emit(toggled_on)
	
	pass # Replace with function body.
	


func _on_settings_open_setting_ui() -> void:
	#color_rect_menu_settings/CheckButtonFollowTouch/AnimationPlayer.animation_set_next("new_animation", "new_animation")
	#color_rect_menu_settings/CheckButtonFollowTouch/AnimationPlayer.play("new_animation")
	color_rect_menu_settings.visible = true
	animation_color_rect_menu_settings.play("open_menu")
	pass # Replace with function body.


func _on_close_close_ui() -> void:
	animation_color_rect_menu_settings.play("close_menu")
	pass # Replace with function body.


func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == "close_menu":
		color_rect_menu_settings.visible = false
	pass # Replace with function body.


func _on_option_button_item_selected(index: int) -> void:
	difficulty_modification.emit(index)
	pass # Replace with function body.

func add_progress(value: int):
	texture_progress_transfiguration.value += value
	if texture_progress_transfiguration.value >= texture_progress_transfiguration.max_value:
		texture_progress_transfiguration.value = 0
		progress_max.emit()
	pass

func set_progress_max(value: int):
	texture_progress_transfiguration.max_value = value
	pass


func _on_h_slider_background_music_drag_ended(value_changed: bool) -> void:
	if value_changed:
		music_max = hslider_background_music.value
		music_change.emit(music_max / 100)
	pass # Replace with function body.


func _on_h_slider_kill_music_drag_ended(value_changed: bool) -> void:
	if value_changed:
		sound_max = hslider_kill_music.value
		sound_change.emit(sound_max / 100)
	pass # Replace with function body.


func _on_settings_mouse_entered() -> void:
	animation_button_settings.play("button_hover")
	pass # Replace with function body.


func _on_settings_mouse_exited() -> void:
	animation_button_settings.play("button_hover_not")
	pass # Replace with function body.

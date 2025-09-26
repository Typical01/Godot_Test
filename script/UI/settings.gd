extends Button

signal open_setting_ui


@export var settings_menu : Node
@export var animation : AnimationPlayer
@export var ui_height_ratio = 0.5 #摇杆: 在屏幕中的高度占比
@export var button_down_animation_name = "button_down" #字符串: [按下按钮]动画名称

var screen_size : Vector2 #屏幕大小


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var window := get_window()
	window.size_changed.connect(_on_window_resized)
	_on_window_resized()
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _on_window_resized():
	var view_size = get_viewport().get_visible_rect().size
	var settings_menu_size = settings_menu.get_rect().size
	settings_menu.global_position = (view_size - settings_menu_size) * 0.5
	pass

func _on_button_up() -> void:
	animation.play(button_down_animation_name)
	open_setting_ui.emit()
	pass # Replace with function body.

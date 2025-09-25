extends Button


signal open_setting_ui
signal set_screen_size


@export var ui_height_ratio = 0.75 #摇杆: 在屏幕中的高度占比


var screen_size : Vector2 #屏幕大小


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if $Ui:
		set_screen_size.emit()
		$Ui.position.x = screen_size.x / 2
		$Ui.position.y = screen_size.y * ui_height_ratio
	pass

func _on_button_up() -> void:
	open_setting_ui.emit()
	pass # Replace with function body.

extends Button

signal buy_container(container_name, container_value)

var container_name: String
var container_value: int
var last_mouse_position

func _on_button_down() -> void:
	last_mouse_position = get_global_mouse_position()

func _on_button_up() -> void:
	var offset: Vector2 = last_mouse_position - get_global_mouse_position()
	if offset.abs() < Vector2(10, 10):
		buy_container.emit(container_name, container_value)

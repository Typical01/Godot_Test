extends Button

signal buy_container(container_name, container_value)

var container_name: String
var container_value: int

func _on_button_up() -> void:
	buy_container.emit(container_name, container_value)

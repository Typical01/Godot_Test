class_name Value extends Control



func _ready() -> void:
	%AddValue.visible = OS.has_feature("editor")

func set_value(number: int) -> void:
	%LabelValue.text = Goods.format_number_with_commas(number)


func _on_add_value_button_up() -> void:
	goods_container_manage.add_value(100000000)

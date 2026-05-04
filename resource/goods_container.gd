class_name GoodsContainer extends ItemData

@export var types: Array

func init(tmp_name: String, _types: Array) -> void:
	name = tmp_name
	types = _types
	texture = load("res://art/texture/ui/container/%s.png" % name)

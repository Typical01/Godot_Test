extends Sprite2D



func _ready() -> void:
	visible = false

func posision_to_print() -> void:
	print("posision_to_print")
	print(position)
	print(offset)

func scale_change(dimensions: Vector2i) -> void:
	scale = dimensions

func color_change(highlight: bool) -> void:
	if highlight:
		self_modulate = Color("007a007a")
	else:
		self_modulate = Color("7a00007a")

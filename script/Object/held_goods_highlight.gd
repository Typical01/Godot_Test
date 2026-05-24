extends TextureRect



func _ready() -> void:
	visible = false

func set_slot_size(dimensions: Vector2i) -> void:
	custom_minimum_size = dimensions * Global.SLOT_SIZE

func color_change(highlight: bool) -> void:
	if highlight:
		self_modulate = Color("007a007a")
	else:
		self_modulate = Color("7a00007a")

extends ColorRect

@export var default_show = false

func _ready() -> void:
	visible = default_show

func set_slot_size(dimensions: Vector2i) -> void:
	size = dimensions * Global.SLOT_SIZE

func color_change(highlight: bool) -> void:
	if highlight:
		self_modulate = Color("007a007a")
	else:
		self_modulate = Color("7a00007a")

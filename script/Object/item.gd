extends TextureRect

@onready var item = $Item

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	custom_minimum_size = Vector2(Global.SLOT_SIZE, Global.SLOT_SIZE)
	size = Vector2(Global.SLOT_SIZE, Global.SLOT_SIZE)
	item.custom_minimum_size = Vector2(Global.SLOT_SIZE - Global.SLOT_SCALE * 1, 
		Global.SLOT_SIZE - Global.SLOT_SCALE * 1)
	item.size = Vector2(Global.SLOT_SIZE - Global.SLOT_SCALE * 1, 
		Global.SLOT_SIZE - Global.SLOT_SCALE * 1)
	item.position = Vector2(Global.SLOT_SCALE * 0.5, Global.SLOT_SCALE * 0.5)
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

extends Control



@export var items: Array[ItemData] = []
@export var inventory_item_scene: PackedScene
@onready var item_grid: GridContainer = %ItemGrid

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#初始化物品
	for i in items:
		add_item(i)
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func add_item(item_data: ItemData) -> void:
	var inventory_item = inventory_item_scene.instantiate()
	inventory_item.data = item_data
	inventory_item.modulate = item_data.color
	add_child(inventory_item)
	print("物品: ", inventory_item.global_position)
	var success = item_grid.attemp_to_item_data(inventory_item)

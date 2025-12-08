extends Control



@export var items: Array[Goods] = []
@export var inventory_item_scene: PackedScene
@onready var item_grid: GridContainer = %ItemGrid

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func add_item(item_data: Goods) -> void:
	var inventory_item = inventory_item_scene.instantiate()
	inventory_item.data = item_data
	add_child(inventory_item)
	#print("物品: ", inventory_item.global_position)
	var success = item_grid.attempt_to_place_item(inventory_item)
	if !success:
		print("ItemContainer: 添加物品[%s]失败, 移除!" % item_data.name)
		remove_child(inventory_item)


func _on_search_button_up() -> void:
	get_search_items()
	pass # Replace with function body.

func get_search_items() -> void:
	for i in range(randi() % 6):
		var reward = Global.safe_box_reward_pool.allocate_single_reward()
		reward.output()
		add_item(reward)
		await get_tree().create_timer(1).timeout

extends Control



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
	if not success:
		#print("ItemContainer: 添加物品[%s]失败, 移除not " % item_data.name)
		remove_child(inventory_item)

func remove_item(item: Node = null) -> void:
	if item == null:
		for i in get_children():
			remove_child(i)
			print("ItemContainer: 移除物品[%s]not " % i.data.name)
			i.queue_free()
	else:
		remove_child(item)
		print("ItemContainer: 移除物品[%s]not " % item.data.name)
		item.queue_free()

func get_search_items(number = randi() % 6) -> void:
	for i in range(number):
		var reward = Global.safe_box_reward_pool.allocate_single_reward()
		#reward.output()
		reward.search = false
		add_item(reward)
		if not reward.search:
			await get_tree().create_timer(\
			Goods.get_quality_time(reward.quality)).timeout

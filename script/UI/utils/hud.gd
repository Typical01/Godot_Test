extends Control



@export var node_pool = []
@export var node_position_data = []



func _ready() -> void:
	coord_utils.window_size_changed.connect(on_window_size_changed)
	on_window_size_changed(get_viewport())

## 窗口: 大小变化
func on_window_size_changed(_window_size):
	for i in node_pool.size():
		coord_utils.set_screen_global_position(node_pool[i], node_position_data[i])



## 添加: 节点, 节点位置百分比
func add_item(item, item_position: Vector2) -> void:
	node_pool.append(item)
	node_position_data.append(item_position)
	coord_utils.set_screen_global_position(item, item_position)

## 删除
func del_item(index: int) -> void:
	node_pool.remove_at(index)
	node_position_data.remove_at(index)

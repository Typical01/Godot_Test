class_name GoodsContainerManage extends Node



## 转移物品: 非发出容器接收; 需检测物品是否能放入
signal shift_goods(index, goods)
signal single_click(position: Vector2)
signal double_click(position: Vector2)
signal drag_move(position: Vector2, delta: Vector2)


var drag_node = null
var goods_data: Goods = null: ## 物品
	get():
		return goods_data
	set(data):
		if not data:
			#push_error("data == null!")
			drag_node.visible = false
			return
		goods_data = data
		drag_node.set_data(data)
		drag_node.init_goods()
		drag_node.show_image_background(false)
		drag_node.visible = true
var container_pool: Array = [] ## 容器池



func _ready() -> void:
	input_recognizer.single_click.connect(on_single_click)
	input_recognizer.double_click.connect(on_single_click)
	input_recognizer.drag_move.connect(on_drag_move)
	
	

func on_single_click(position: Vector2):
	single_click.emit(position)

func on_double_click(position: Vector2):
	double_click.emit(position)

func on_drag_move(position: Vector2, _delta: Vector2):
	drag_move.emit(position)

func init(_drag_node):
	drag_node = _drag_node
	if not drag_node:
		push_error("drag_node == null!")
		return
	drag_node.z_index = 10
	drag_node.visible = false
	add_child(drag_node)

func set_drag_node_position(_global_position):
	if not drag_node: return
	drag_node.global_position = _global_position - (drag_node.size / 2)

## 转移物品
## index: (-1)自动分配
func shift_goods_to(goods, index: int = -1) -> bool:
	var is_shift = false
	for container in container_pool:
		if container != self:
			shift_goods.emit(goods, index)
			is_shift = true
	return is_shift



func add_item(container, _drag_node) -> void:
	init(_drag_node)
	container_pool.append(container)

#func del_item(container_name: String) -> bool:
	#return container_pool.erase(container_name)

func clear():
	container_pool.clear()

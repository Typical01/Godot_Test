class_name GoodsContainerManage extends Node



## 转移物品: 非发出容器接收; 需检测物品是否能放入
signal shift_goods(start_container, index, goods)
signal single_click(position: Vector2)
signal double_click(position: Vector2)
signal long_press_start(position: Vector2)
signal long_press_end(position: Vector2)
signal drag_start(position: Vector2)
signal drag_move(position: Vector2, delta: Vector2)
signal drag_end(position: Vector2)


var drag_node = null
var goods_container = null ## 物品容器
var search_container = null ## 搜索容器
var container_pool: Dictionary = {} ## 容器池
var goods_data: Goods = null ## 物品



func _ready() -> void:
	input_recognizer.single_click.connect(on_single_click)
	input_recognizer.double_click.connect(on_single_click)
	input_recognizer.long_press_start.connect(on_long_press_start)
	input_recognizer.long_press_end.connect(on_long_press_end)
	input_recognizer.drag_start.connect(on_drag_start)
	input_recognizer.drag_move.connect(on_drag_move)
	input_recognizer.drag_end.connect(on_drag_end)

func on_single_click(position: Vector2):
	single_click.emit(position)

func on_double_click(position: Vector2):
	double_click.emit(position)

func on_long_press_start(position: Vector2):
	long_press_start.emit(position)

func on_long_press_end(position: Vector2):
	long_press_end.emit(position)

func on_drag_start(position: Vector2):
	drag_start.emit(position)

func on_drag_move(position: Vector2):
	drag_move.emit(position)

func on_drag_end(position: Vector2):
	drag_end.emit(position)

func init():
	if not drag_node:
		push_error("drag_node == null!")
		return
	drag_node.z_index = 10
	drag_node.visible = false
	add_child(drag_node)

func set_goods_data(data: Goods):
	if not data:
		push_error("data == null!")
		return
	goods_data = data
	drag_node.set_data(data)
	drag_node.init_goods()
	drag_node.show_image_background(false)
	drag_node.visible = true

func set_drag_node_position(_global_position):
	if not drag_node: return
	drag_node.global_position = _global_position - drag_node.size / 2

## 设置: 物品/搜索容器
func set_container(_container, _drag_node, is_search: bool):
	if is_search:
		search_container = _container
	else:
		goods_container = _container
	if not drag_node:
		drag_node = _drag_node
		init()

## 转移物品
## index: (-1)自动分配
## is_search: (true)搜索 -> 物品 | (false)物品 -> 搜索
func shift_goods_to(goods, index: int = -1, is_search: bool = true) -> bool:
	if goods_container:
		push_error("物品容器 == null!")
		return false
	if search_container:
		push_error("搜索容器 == null!")
		return false
	if is_search: ## 搜索 -> 物品
		shift_goods.emit(goods_container, index, goods)
	else: ## 物品 -> 搜索
		shift_goods.emit(search_container, index, goods)
	return true



func add_item(container_name: String, container) -> bool:
	return container_pool.set(container_name, container)

func del_item(container_name: String) -> bool:
	return container_pool.erase(container_name)

func clear():
	container_pool.clear()

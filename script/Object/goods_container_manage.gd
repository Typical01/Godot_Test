class_name GoodsContainerManage extends CanvasLayer



## 转移物品: 非发出容器接收; 需检测物品是否能放入
signal shift_goods(index, goods)
signal show_search_container()

#signal single_click_down(global_position: Vector2)
#signal single_click_up(global_position: Vector2)
#signal double_click(global_position: Vector2)
#signal drag_start(global_position: Vector2)
#signal long_press_start(global_position: Vector2)
#signal long_press_end(global_position: Vector2)
#signal drag_move(global_position: Vector2, delta: Vector2)
#signal drag_end(global_position: Vector2)
#signal move(global_position: Vector2)



var value_node: Value = preload("res://scene/object/value.tscn").instantiate()
var info_node: ItemSimpleInformation = preload("res://scene/object/info.tscn").instantiate()



var current_container: GoodsGrid = null ## 当前容器
var last_container: GoodsGrid = null ## 最后的容器
var value: int = 0
var goods_data: Goods = null ## 物品
var drag_node = null
var store: Array = [] ## 仓库: 物品数据
var container_pool: Array = [] ## 容器池



func _ready() -> void:
	layer = 2
	
	input_recognizer.single_click_down.connect(on_single_click_down)
	input_recognizer.single_click_up.connect(on_single_click_up)
	input_recognizer.double_click.connect(on_double_click)
	input_recognizer.long_press_start.connect(on_long_press_start)
	input_recognizer.long_press_end.connect(on_long_press_end)
	input_recognizer.drag_start.connect(on_drag_start)
	input_recognizer.drag_move.connect(on_drag_move)
	input_recognizer.drag_end.connect(on_drag_end)
	input_recognizer.move.connect(on_move)
	
	add_child(value_node)
	info_node.visible = false
	info_node.sell.connect(sell_goods)
	add_child(info_node)
	
	value = Global.game_config.get("货币", 0.0)
	value_node.set_value(value)
	
	data_manage.auto_save.connect(save_store_data)



func on_single_click_down(global_position: Vector2):
	var container: GoodsGrid = has_global_points(global_position)
	if not container:
		return
	#container._on_goods_single_click_down(global_position)

func on_single_click_up(global_position: Vector2):
	var container: GoodsGrid = has_global_points(global_position)
	if not container: 
		set_goods_data(null)
		OverlayStateMonitor.push_overlay("current_container", "null")
		return
	if container != current_container:
		last_container = current_container
	if last_container: 
		OverlayStateMonitor.push_overlay("last_container", last_container.container_name)
	else:
		OverlayStateMonitor.push_overlay("last_container", "null")
	
	current_container = container
	OverlayStateMonitor.push_overlay("current_container", current_container.container_name)
	container._on_goods_single_click_up(global_position)

func on_double_click(global_position: Vector2):
	var container: GoodsGrid = has_global_points(global_position)
	if not container: return
	container._on_goods_double_click(global_position)

func on_long_press_start(global_position: Vector2):
	var container: GoodsGrid = has_global_points(global_position)
	if not container: return
	container._on_goods_drag_start(global_position)

func on_long_press_end(global_position: Vector2):
	var container: GoodsGrid = has_global_points(global_position)
	if not container: return
	container._on_goods_drag_end(global_position)

func on_drag_start(global_position: Vector2):
	var container: GoodsGrid = has_global_points(global_position)
	if not container: return
	if container != current_container: return
	container._on_goods_drag_start(global_position)

func on_drag_move(global_position: Vector2, _delta: Vector2):
	var container: GoodsGrid = has_global_points(global_position)
	if not container: 
		if last_container:
			last_container._on_goods_drag_end(global_position)
		return
	container._on_goods_drag_move(global_position)

func on_drag_end(global_position: Vector2):
	var container: GoodsGrid = has_global_points(global_position)
	if not container: return
	container._on_goods_drag_end(global_position)

func on_move(_global_position: Vector2):
	OverlayStateMonitor.push_overlay("on_move", _global_position)
	#move.emit(_global_position)
	set_drag_node_position(_global_position)
	return
	var container: GoodsGrid = has_global_points(_global_position)
	if container != current_container:
		last_container = current_container
	if last_container: 
		OverlayStateMonitor.push_overlay("last_container", last_container.container_name)
	else:
		OverlayStateMonitor.push_overlay("last_container", "null")
	
	current_container = container
	OverlayStateMonitor.push_overlay("current_container", current_container.container_name)



func init(_drag_node):
	if drag_node:
		return
	if not _drag_node:
		push_error("_drag_node == null!")
		return
	drag_node = _drag_node
	drag_node.z_index = 10
	drag_node.visible = false
	add_child(drag_node)
	
	# 读取: 仓库物品
	read_store_data()

func set_goods_data(goods: Goods = null) -> void:
	goods_data = goods
	if not goods_data:
		#push_error("goods_data == null!")
		info_node.visible = false
		drag_node.visible = false
		return
	OverlayStateMonitor.push_overlay("goods_data", goods_data.name)
	drag_node.set_data(goods_data)
	drag_node.show_image_background(false)

func show_container(container_name: String, is_show: bool = true) -> void:
	for i in container_pool.size():
		var container: GoodsGrid = container_pool[i]
		if container and container.container_name == container_name:
			container.visible = is_show

func show_info(goods: Goods = null, is_show: bool = true) -> void:
	if not goods:
		info_node.show_info(null, false)
		return
	if not goods.search: 
		info_node.show_info(null, false)
		return
	goods_data = goods
	info_node.show_info(goods, is_show)

func show_drag_node(is_show: bool):
	show_info(null, false)
	drag_node.visible = is_show
	
func set_drag_node_position(_global_position):
	if not drag_node: return
	drag_node.global_position = _global_position - (drag_node.size / 2)

func sell_goods() -> void:
	if not current_container:
		push_error("current_container == null!")
		return
	current_container.sell(goods_data, add_value)
	show_info(null, false)
	set_goods_data(null)

## 转移物品
## index: (-1)自动分配
func shift_goods_to(_container_name: String, goods: Goods, index: int = -1, target_container_name: String = "") -> bool:
	if not goods: 
		push_error("goods == null!")
		return false
	var is_shift = false
	for container: GoodsGrid in container_pool:
		if container.container_name == _container_name:
			continue
		if not target_container_name.is_empty() and container.container_name != target_container_name:
			continue
		goods.search = true
		if container.add_item(goods, index) != -1:
			container.save_goods_data()
			is_shift = true
		break
	return is_shift



func add_value(number: int) -> void:
	var tmp_value = value + number
	value = tmp_value
	value_node.set_value(tmp_value)
	Global.game_config["货币"] = tmp_value

func del_value(number: int) -> bool:
	if max(value, number) != value:
		return false
	var tmp_value = value - number
	value = tmp_value
	value_node.set_value(tmp_value)
	Global.game_config["货币"] = tmp_value
	return true



func read_store_data():
	if store.is_empty():
		if Global.game_config.has("仓库"):
			var store_goods_names = Global.game_config.get("仓库", null)
			if not store_goods_names is Array:
				push_error("[仓库]不是 Array!")
				return
			var goods_pool: Dictionary = Global.goods_container_reward_pool.goods_pool
			for i in store_goods_names.size():
				var store_goods_data: Goods = goods_pool.get(store_goods_names[i], null)
				if store_goods_data:
					var tmp_goods = store_goods_data.duplicate()
					tmp_goods.search = true
					store.append(tmp_goods)

func save_store_data():
	var store_goods_name = []
	for i in store.size():
		var data = store[i]
		if not data:
			push_error("data == null!")
			continue
		store_goods_name.append(data.name)
	Global.game_config.set("仓库", store_goods_name)



func add_item(container: GoodsGrid) -> void:
	OverlayStateMonitor.push_overlay(container.container_name, Rect2(container.global_position, container.size))
	#container.gui_input.connect(input_recognizer._on_input)
	container_pool.append(container)

func del_item(container_name: String) -> void:
	container_pool = container_pool.filter(func(item): 
		if item.container_name != container_name:
			return item
		)

func find_item(container_name: String) -> GoodsGrid:
	for i in container_pool.size():
		var container: GoodsGrid = container_pool[i]
		if container and container.container_name == container_name:
			return container
	return null

func clear():
	container_pool.clear()

## 坐标是否在指定范围
func has_global_points(_global_position: Vector2) -> GoodsGrid:
	for i in container_pool.size():
		var container: GoodsGrid = container_pool[i]
		if container.has_global_point(_global_position):
			return container
	return null

extends Control



## ============================ 信号 =============================

signal select(self_node)
signal move(self_node)
signal cancel(self_node)



## ============================ 变量 =============================

@onready var slot_grid_node = %SlotGrid
@onready var goods_grid_node = %GoodsGrid
@export var slot_grid_scene: PackedScene ## 场景: 槽位列表
@export var goods_grid_scene: PackedScene ## 场景: 物品列表
@export var highlight_scene: PackedScene ## 场景: 物品列表

var highlight_node = null
@export var slot_size: int = Global.SLOT_SIZE ## 物品槽大小
@export var dimensions: Vector2i = Vector2i(5, 5) ## 网格大小: X,Y
@export var is_search_container: bool = false ## 是否为: 搜索/物品容器

@onready var slot_data = goods_grid_node.data
var current_index: int = -1
var item_sum: Dictionary = {}



## ============================ 基础实现 =============================

func _ready() -> void:
	OverlayStateMonitor.is_performance = false
	
	slot_data.resize(dimensions.x * dimensions.y)
	slot_data.fill(null)
	size = dimensions * slot_size



## ============================ 回调 =============================

## 创建: 槽位
func _on_slot_grid_on_data_fill(self_node) -> void:
	self_node.set_template(slot_grid_scene)
	self_node.custom_minimum_size = custom_minimum_size
	self_node.columns = dimensions.x
	self_node.fill_item(null, dimensions.x * dimensions.y)

func on_goods_set_search(_global_position, is_search: bool):
	var index = goods_grid_node.get_index_of_position(_global_position)
	slot_data[index].is_search = is_search

func _on_goods_drag_start(_global_position):
	goods_grid_node.drag_start_item(_global_position)

func _on_goods_drag_end(_global_position):
	goods_grid_node.drag_end_item(_global_position)

## 创建: 槽位
func _on_goods_grid_on_data_fill(self_node) -> void:
	self_node.set_template(goods_grid_scene)
	self_node.custom_minimum_size = custom_minimum_size
	self_node.columns = dimensions.x
	self_node.fill_item(null, dimensions.x * dimensions.y)
	if highlight_scene:
		highlight_node = highlight_scene.instantiate()
	else:
		push_error("highlight_scene == null!")
	goods_container_manage.set_container(self, self_node.drag_node.duplicate(),is_search_container)
	goods_container_manage.drag_start.emit(_on_goods_drag_start)
	goods_container_manage.drag_end.emit(_on_goods_drag_end)

func _on_goods_grid_on_entry_connect_callback(control: Variant) -> void:
	if control == null: 
		push_error("control == null!")
		return
	control.connect("on_button_down", _on_goods_drag_start)
	control.connect("on_button_up", _on_goods_drag_end)
	control.connect("on_set_search", on_goods_set_search)

func _on_goods_grid_on_entry_disconnect_callback(control: Variant) -> void:
	if control == null: 
		push_error("control == null!")
		return
	control.disconnect("on_button_down", _on_goods_drag_start)
	control.disconnect("on_button_up", _on_goods_drag_end)
	control.disconnect("on_set_search", on_goods_set_search)

func _on_goods_grid_on_entry_updated(index: int, control, data) -> void:
	if not control:
		push_error("[%s]control == null!" % [index])
		return
	if not data or index != data.start_index:
		control.mouse_filter = MOUSE_FILTER_IGNORE
		control.set_goods_size(Vector2(1 * slot_size, 1 * slot_size))
		control.visible = false
		return
	control.set_data(data)
	control.init_goods()
	control.mouse_filter = MOUSE_FILTER_PASS
	control.visible = true

func _on_goods_grid_on_drag_start_item(index: int, data: Variant, global_mouse_position: Vector2) -> void:
	if not data:
		push_error("[%s]data == null!" % [index])
		return
	if goods_grid_node.drag_node:
		goods_grid_node.drag_node.visible = false
		current_index = data.start_index
		if index != data.start_index:
			data = slot_data[data.start_index]
			if not data:
				push_error("[%s]data == null!" % [index])
				return
			current_index = data.start_index
		goods_container_manage.set_goods_data(data)
		goods_container_manage.set_drag_node_position(global_mouse_position)
		#OverlayStateMonitor.push_overlay("start_data", data)
		OverlayStateMonitor.push_overlay("current_index", current_index)
		if not data.is_search:
			highlight_node.visible = false
			return
		highlight_node.set_slot_size(data.dimensions)
		highlight_node.global_position = get_coords_from_slot_index(
		get_slot_from_center_position(global_mouse_position, data))
		if not goods_is_fits(index, data).is_empty():
			highlight_node.color_change(true)
		else:
			highlight_node.color_change(false)
		highlight_node.visible = true

func _on_goods_grid_on_drag_move_item(global_mouse_position: Vector2) -> void:
	var data
	if goods_grid_node.drag_index == -2: # 通过容器管理获取
		data = goods_container_manage.goods_data
	else:
		data = slot_data[goods_grid_node.drag_index]
	if not data: 
		OverlayStateMonitor.push_overlay("[%s]data == null!" % [get_instance_id()], global_mouse_position)
		push_error("[%s][%s]data == null!" % [get_instance_id(), global_mouse_position])
		return
	OverlayStateMonitor.push_overlay("[%s]data == null!" % [get_instance_id()], data.name)
	var index = get_slot_from_center_position(global_mouse_position, data)
	highlight_node.global_position = get_coords_from_slot_index(index)
	goods_container_manage.set_drag_node_position(global_mouse_position)
	if global_mouse_position < global_position or \
	global_mouse_position > global_position + size:
		highlight_node.visible = false
	else:
		highlight_node.visible = true
	if not goods_is_fits(index, data).is_empty():
		highlight_node.color_change(true)
	else:
		highlight_node.color_change(false)

func _on_goods_grid_on_drag_end_item(index: int, end_index: int, global_mouse_position: Vector2) -> void:
	if index == -1:
		if goods_container_manage.drag_node:
			goods_container_manage.drag_node.visible = false
		return
	
	var message = "\n"
	for i in slot_data.size():
		var tmp_data = slot_data[i]
		if tmp_data:
			message += "[%s-%s], %s" % [i, tmp_data.start_index, "\n" if (i % 5) == 4 else ""]
		else:
			message += "[%s-%s], %s" % [i, null, "\n" if (i % 5) == 4 else ""]
	#OverlayStateMonitor.push_overlay("end_start_index", message)
	
	highlight_node.visible = false
	var data = slot_data[current_index]
	var start_index = get_slot_from_center_position(global_mouse_position, data)
	if not try_place_goods(start_index, data):
		pass
	message = "\n"
	for i in slot_data.size():
		var tmp_data = slot_data[i]
		if tmp_data:
			message += "[%s-%s], %s" % [i, tmp_data.start_index, "\n" if (i % 5) == 4 else ""]
		else:
			message += "[%s-%s], %s" % [i, null, "\n" if (i % 5) == 4 else ""]
	#OverlayStateMonitor.push_overlay("end_start_index2", message)

func _on_goods_grid_mouse_entered():
	 # 通过容器管理转移
	if not goods_container_manage.goods_data:
		push_error("goods_data == null!")
		return
	goods_grid_node.drag_index = -2

func _on_goods_grid_mouse_exited():
	goods_grid_node.drag_index = -1
	var start_position = get_coords_from_slot_index(-1)
	goods_container_manage.drag_end_item(start_position)


## ============================ 数据管理 =============================

## 搜索物品
## is_search: 是否搜索
func get_search_items(number = randi() % 6, is_search = false) -> void:
	#OverlayStateMonitor.push_overlay("number", number)
	while(number > 0):
		var goods = Global.safe_box_reward_pool.allocate_single_reward()
		goods.is_search = is_search
		goods.output()
		var successful = add_item(goods)
		if not successful: # 添加到容器失败, 重新生成
			var count = 0
			for i in slot_data:
				if i != null:
					count += 1
			if count == slot_data.size():
				push_error("容器已满!")
				return
			continue
		elif successful and not goods.is_search: # 等待动画
			await get_tree().create_timer(Goods.get_quality_time(goods.quality)).timeout
		number -= 1
		#OverlayStateMonitor.push_overlay("number", number)

func add_item(data: Goods, index: int = -1) -> bool:
	var successful = attempt_to_place_item(data, index)
	if successful == -1:
		push_error("添加[%s][%s]失败!" % [index, data.name])
		return false
	data.start_index = successful
	goods_grid_node.update_item(successful, data)
	return true

func remove_item(index: int) -> void:
	if not canfine(index):
		return
	var data = slot_data[index]
	if not data:
		push_error("[%s]移除物品失败!" % [index])
		return
	del_item_to_slot_data(index, data)
	goods_grid_node.update_item(index, data)

func clear(sell: Callable = Callable()) -> void:
	cancel.emit(self)
	for i in slot_data.size():
		var data = slot_data[i]
		if data and i == data.start_index:
			if sell: # 出售物品
				sell.call(data)
	slot_data.resize(dimensions.x * dimensions.y)
	goods_grid_node.fill_item(null)
	slot_data.fill(null)


## ============================ 物品行为 =============================

## 为物品寻找并分配一个合适的位置
## data: 要放置的物品
func attempt_to_place_item(data, index: int = -1) -> int:
	if not data: # 非空
		return -1
	if index != -1: # 检查指定索引槽位
		var slot_array = goods_is_fits(data, index)
		if not slot_array.is_empty():
			# 写入占用数据
			add_item_to_slot_data(data, index, slot_array)
			return index
	else:
		# 扫描所有槽位，寻找可以放置的位置
		for start_index in range(slot_data.size()):
			var slot_array = goods_is_fits(start_index, data)
			if not slot_array.is_empty():
				# 写入占用数据
				add_item_to_slot_data(start_index, data, slot_array)
				return start_index
	return -1

## 拿起物品
func held_item(_position: Vector2) -> void:
	pass

## 放置物品
## index: 放置位置
func try_place_goods(index: int, data) -> bool:
	if not data:
		push_error("[%s]data == null!" % [index])
		return false
	if index == data.start_index:
		return false # 放回原位: 拿起时, 只隐藏物品
	var slot_array = goods_is_fits(index, data)
	if slot_array.is_empty():
		return false # 槽位不够替换
	swap_item_to_slot_data(index, data, slot_array) # 替换所有槽位
	return true

## 增加: 物品计数
func add_goods_count(data):
	var item_count = item_sum.get(data.name, 0)
	item_sum.set(data.name, item_count + 1)

## 减少: 物品计数
func del_goods_count(data):
	var item_count = item_sum.get(data.name, 0)
	if item_count > 0:
		item_sum.set(data.name, item_count - 1)



## ============================ 数据操作 =============================

## 添加
func add_item_to_slot_data(index: int, data, slot_array: Array[int] = []) -> bool:
	if not canfine(index):
		return false
	if slot_array.is_empty():
		slot_array = get_item_index_occupy_slot(index, data)
		if slot_array.is_empty():
			return false
	data.start_index = index
	for i in slot_array:
		goods_grid_node.update_item(i, data)
	#print("add: %s" % [slot_array])
	add_goods_count(data)
	return true

## 删除
func del_item_to_slot_data(index: int, data, slot_array: Array[int] = []) -> bool:
	if not canfine(index):
		return false
	if slot_array.is_empty():
		slot_array = get_item_index_occupy_slot(index, data)
		if slot_array.is_empty():
			return false
	data.start_index = -1
	for i in slot_array:
		if slot_data[i] == data:
			slot_data[i] = null
			goods_grid_node.update_item(i, data.start_index + i)
	#print("del: %s" % [slot_array])
	del_goods_count(data)
	return true

## 交换
func swap_item_to_slot_data(index: int, data, slot_array: Array[int] = []) -> bool:
	if not canfine(index):
		return false
	if slot_array.is_empty():
		slot_array = goods_is_fits(index, data)
		if slot_array.is_empty():
			return false
	
	var message = "\n"
	for i in slot_data.size():
		var tmp_data = slot_data[i]
		if tmp_data:
			message += "[%s][%s(%s)], %s" % [i, tmp_data.name, tmp_data.start_index, "\n" if (i % 5) == 4 else ""]
		else:
			message += "[%s][%s], %s" % [i, null, "\n" if (i % 5) == 4 else ""]
	OverlayStateMonitor.push_overlay("init", message)
	
	# 先删除原对象槽位
	var start_data = get_item_index_occupy_slot(data.start_index, data)
	for i in start_data.size(): 
		if slot_data[start_data[i]] == data:
			slot_data[start_data[i]] = null
			#print("swap_item(del): %s-%s [%s]" % [data.start_index, index, start_data[i]])
	message = "\n"
	for i in slot_data.size():
		var tmp_data = slot_data[i]
		if tmp_data:
			message += "[%s][%s(%s)], %s" % [i, tmp_data.name, tmp_data.start_index, "\n" if (i % 5) == 4 else ""]
		else:
			message += "[%s][%s], %s" % [i, null, "\n" if (i % 5) == 4 else ""]
	OverlayStateMonitor.push_overlay("del_target_index", message)
	
	# 将目标槽位对象转移到原对象槽位
	for i in slot_array.size():
		var target_data_dict: Dictionary = {} # 保存的目标槽位原索引
		var target_data = slot_data[slot_array[i]]
		if target_data:
			var old_index = target_data_dict.get(target_data, -1) # 保存的目标槽位原索引
			if old_index == -1: # 未保存
				if start_data.has(slot_array[i]): # 目标槽位与原槽位不能完全重合
					continue
				target_data.start_index = start_data[i] # 先交换索引
				target_data_dict.set(target_data, target_data.start_index)
			else: # 保存
				old_index = min(old_index, start_data[i]) # 首槽位
				if start_data.has(slot_array[i]): # 目标槽位与原槽位不能完全重合
					continue
				target_data.start_index = old_index # 先交换索引
				target_data_dict.set(target_data, target_data.start_index)
			print("target_data: %s-%s" % [target_data.start_index, target_data_dict])
		goods_grid_node.swap_item(slot_array[i], start_data[i])
		#print("swap_item(add): %s-%s [%s->%s]" % [data.start_index, index, slot_array[i], start_data[i]])
	message = "\n"
	for i in slot_data.size():
		var tmp_data = slot_data[i]
		if tmp_data:
			message += "[%s][%s(%s)], %s" % [i, tmp_data.name, tmp_data.start_index, "\n" if (i % 5) == 4 else ""]
		else:
			message += "[%s][%s], %s" % [i, null, "\n" if (i % 5) == 4 else ""]
	OverlayStateMonitor.push_overlay("swap_start_index", message)
	
	# 保存原对象槽位到目标槽位
	for i in slot_array.size():
		goods_grid_node.update_item(slot_array[i], data)
		#print("swap_item(update): %s-%s [%s]" % [data.start_index, index, start_data[i]])
	message = "\n"
	for i in slot_data.size():
		var tmp_data = slot_data[i]
		if tmp_data:
			message += "[%s][%s(%s)], %s" % [i, tmp_data.name, tmp_data.start_index, "\n" if (i % 5) == 4 else ""]
		else:
			message += "[%s][%s], %s" % [i, null, "\n" if (i % 5) == 4 else ""]
	OverlayStateMonitor.push_overlay("update_start_index", message)
	
	data.start_index = index
	goods_grid_node.update_view()
	#message = "\n"
	#for i in slot_data.size():
		#var tmp_data = slot_data[i]
		#if tmp_data:
			#message += "[%s]%s, %s" % [i, tmp_data.name, "\n" if (i % 5) == 4 else ""]
		#else:
			#message += "[%s]%s, %s" % [i, null, "\n" if (i % 5) == 4 else ""]
	#OverlayStateMonitor.push_overlay("end", message)
	return true

## 移动物品
func move_item(data, index: int) -> void:
	del_item_to_slot_data(data, data.start_index)
	add_item_to_slot_data(data, index)



## ============================ 网格行为 =============================

## 改为字典
## 获取: 物品能放入指定索引的所有槽位; 除去物品占用后的空槽位; 索引原物品占用槽位
## 返回: 非空
## [
##   [index_slot], 索引占用槽位
##   [empty_slot], 目标索引剩余空槽位
##   [occupy_1]... 目标索引物品1槽位
## ]
#var result_slot: Array[Array] = []
	#var index_slot: Array[int] = []
	#var empty_slot: Array[int] = []
	#if is_swap:
		#var start_index_slot = get_item_index_occupy_slot(data.start_index, data) # 原槽位
		#for i in index_occupy_slot.size(): # 目标索引占用槽位
			#var occupy_data = slot_data[index_occupy_slot[i]]
			#if occupy_data and occupy_data != data: # 已有物品占用
				#var occupy_slot = get_item_index_occupy_slot(
					#occupy_data.start_index, slot_data[occupy_data.start_index])
				#result_slot.append(occupy_slot)
			#else: # 未占用
				#if start_index_slot.has(index_occupy_slot[i]): # 与目标索引占用槽位不重叠
					#empty_slot.append(index_occupy_slot[i])
		#for i in result_slot.size(): # 已有物品
				#for i_occupy in occupy_slot.size(): # 占用槽位中物品的槽位
					#if 
					#occupy_data = occupy_slot[i_occupy]

## 获取: 物品能放入索引的所有槽位
func goods_is_fits(index: int, data) -> Array[int]:
	## 占用槽位->非原占用槽位的空槽位->占用槽位中的物品所需空槽位
	var index_occupy_slot = get_item_index_occupy_slot(index, data)
	if index_occupy_slot.is_empty(): return []
	for i in index_occupy_slot.size():
		var new_data = slot_data[index_occupy_slot[i]]
		if new_data and new_data != data: # 已占用
			return []
	return index_occupy_slot

## 获取: 物品当前索引会占用的槽位
## data: 数据尺寸
## index: 会占用的槽位
## is_rotated: 旋转后的物品
func get_item_index_occupy_slot(index: int, data) -> Array[int]:
	if not data:
		return []
	if not canfine(index, data): return [] # 越界
	
	if data.is_rotated:
		data.dimensions = Goods.get_rotated_dimensions(data.dimensions)
	var item_slot: Array[int]
	item_slot.resize(data.dimensions.x * data.dimensions.y)
	item_slot.fill(0)
	var count = 0
	for y in range(data.dimensions.y):
		for x in range(data.dimensions.x):
			var start_index = index + x + y * dimensions.x
			item_slot[count] = start_index
			count += 1
			#print("\t[%s]: %s" % [count, start_index])
	return item_slot

## 边界检查: 数据/容器
func canfine(index: int, data = null) -> bool:
	if index < 0 or index >= slot_data.size(): # 数据越界
		return false
	if data != null: # 容器越界
		# 边界越界: X
		if (index % dimensions.x) + data.dimensions.x > dimensions.x:
			return false
		# 边界越界: Y
		if floor(float(index) / dimensions.x) + data.dimensions.y > dimensions.y:
			return false
	return true

## 获取: 中心坐标 > 首槽位
func get_slot_from_center_position(coords: Vector2, data) -> int:
	var item_offset_position = Vector2(0, 0)
	var offset_slot_size = roundi(float(slot_size) / 2)
	if data.dimensions.x > 1:
		item_offset_position.x = offset_slot_size * (data.dimensions.x - 1)
	if data.dimensions.y > 1:
		item_offset_position.y = offset_slot_size * (data.dimensions.y - 1)
	coords -= item_offset_position
	return get_slot_index_from_coords(coords)

## 获取: 首槽位 > 中心坐标
func get_center_position_from_slot(index: int, data) -> Vector2:
	if not canfine(index, data):
		return Vector2()
	var offset_slot_size = roundi(float(slot_size) / 2)
	var item_offset_position = Vector2(offset_slot_size * data.dimensions.x, 
		offset_slot_size * data.dimensions.y)
	var coords = get_coords_from_slot_index(index)
	coords += item_offset_position + global_position
	return coords

## 获取: 坐标 > 槽位索引
func get_slot_index_from_coords(coords: Vector2) -> int:
	if not has_point(coords):
		return -1
	var local = coords - global_position
	local /= slot_size
	var index = int(local.x) + int(local.y) * dimensions.x
	if not canfine(index):
		return -1
	return index

## 获取: 槽位索引 > 坐标
func get_coords_from_slot_index(index: int) -> Vector2:
	var row = index % dimensions.x # 行
	var column = floor(float(index) / dimensions.x) # 列
	return global_position + Vector2(row * slot_size, column * slot_size)

## 坐标是否在指定范围
func has_point(_global_position: Vector2) -> bool:
	var global_rect = Rect2(global_position, size)
	return global_rect.abs().has_point(_global_position)

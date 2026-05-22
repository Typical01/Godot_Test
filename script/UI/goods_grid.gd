extends Control



## ============================ 信号 =============================

signal select(self_node)
signal move(self_node)
signal cancel(self_node)
signal save(self_node)



## ============================ 变量 =============================

@onready var slot_grid_node = %SlotGrid
@onready var goods_grid_node = %GoodsGrid
@export var slot_grid_scene: PackedScene ## 场景: 槽位列表
@export var goods_grid_scene: PackedScene ## 场景: 物品列表
@export var highlight_scene: PackedScene ## 场景: 物品列表

var highlight_node = null
@export var slot_size: int = Global.SLOT_SIZE ## 物品槽大小
@export var dimensions: Vector2i = Vector2i(5, 5) ## 网格大小: X,Y

var searching = false
@onready var slot_data = goods_grid_node.data
var item_sum: Dictionary = {}
var button_groups = ButtonGroup.new()



## ============================ 基础实现 =============================

func _ready() -> void:
	OverlayStateMonitor.is_performance = false
	
	slot_data.resize(dimensions.x * dimensions.y)
	slot_data.fill(null)
	size = dimensions * slot_size



## ============================ 回调 =============================

## 创建: 槽位
func _on_slot_grid_on_data_fill(self_node) -> void:
	self_node.item_size = Vector2i(slot_size, slot_size)
	self_node.set_template(slot_grid_scene)
	self_node.custom_minimum_size = custom_minimum_size
	self_node.columns = dimensions.x
	self_node.fill_item(null, dimensions.x * dimensions.y)

func _on_goods_grid_on_v_value_changed(value) -> void:
	slot_grid_node.v_scroll_bar.value = value



func on_goods_set_search(_global_position, search: bool):
	var index = goods_grid_node.get_index_of_position(_global_position)
	slot_data[index].search = search

func _on_goods_drag_start(_global_position):
	goods_grid_node.drag_start_item(get_global_mouse_position())

func _on_goods_drag_end(_global_position):
	goods_grid_node.drag_end_item(get_global_mouse_position())

## 创建: 槽位
func _on_goods_grid_on_data_fill(self_node) -> void:
	self_node.item_size = Vector2i(slot_size, slot_size)
	self_node.set_template(goods_grid_scene)
	self_node.custom_minimum_size = custom_minimum_size
	self_node.columns = dimensions.x
	self_node.fill_item(null, dimensions.x * dimensions.y)
	if highlight_scene:
		highlight_node = highlight_scene.instantiate()
		self_node.add_child(highlight_node)
	else:
		push_error("highlight_scene == null!")
	goods_container_manage.add_item(self, self_node.drag_node.duplicate())
	self_node.drag_node.visible = false
	goods_container_manage.double_click.connect(index_from_container_coords)
	goods_container_manage.shift_goods.connect(goods_from_container_shift)

func _on_goods_grid_on_node_init(control) -> void:
	control.button_group = button_groups
	
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

func _on_goods_grid_on_drag_start_item(index: int, data: Goods, global_mouse_position: Vector2) -> void:
	if not data:
		push_error("[%s]data == null!" % [index])
		return
	if not data.search: # 未搜索物品无法交互
		return
		
	OverlayStateMonitor.push_overlay("index", index)
	goods_container_manage.goods_data = data
	goods_container_manage.set_drag_node_position(global_mouse_position)
	#OverlayStateMonitor.push_overlay("start_data", data)
	
	highlight_node.set_slot_size(data.dimensions)
	highlight_node.global_position = get_coords_from_slot_index(get_slot_from_center_position(global_mouse_position, data.dimensions))
	OverlayStateMonitor.push_overlay("global_position", highlight_node.global_position)
	var occupy = get_current_index_occupy_slot(data, index)
	if item_is_places(occupy, data):
		highlight_node.color_change(true)
	else:
		highlight_node.color_change(false)
	highlight_node.visible = true

func _on_goods_grid_on_drag_move_item(global_mouse_position: Vector2) -> void:
	var data = goods_container_manage.goods_data
	
	if not data: 
		OverlayStateMonitor.push_overlay("[%s]data == null!" % [get_instance_id()], global_mouse_position)
		push_error("[%s][%s]data == null!" % [get_instance_id(), global_mouse_position])
		return
	OverlayStateMonitor.push_overlay("[%s]data == null!" % [get_instance_id()], data.name)
	var index = get_slot_from_center_position(global_mouse_position, data.dimensions)
	goods_container_manage.set_drag_node_position(global_mouse_position)
	
	highlight_node.global_position = get_coords_from_slot_index(index)
	if global_mouse_position < global_position or \
	global_mouse_position > global_position + size:
		highlight_node.visible = false
	else:
		highlight_node.visible = true
	var occupy = get_current_index_occupy_slot(data, index)
	if item_is_places(occupy, data):
		highlight_node.color_change(true)
	else:
		highlight_node.color_change(false)

func _on_goods_grid_on_drag_end_item(index: int, end_index: int, _global_mouse_position: Vector2) -> void:
	var message = "\n"
	for i in slot_data.size():
		var tmp_data = slot_data[i]
		if tmp_data:
			message += "[%s-%s], %s" % [i, tmp_data.name, "\n" if (i % 5) == 4 else ""]
		else:
			message += "[%s-%s], %s" % [i, null, "\n" if (i % 5) == 4 else ""]
	OverlayStateMonitor.push_overlay("end_start_index", message)
	
	var data = slot_data[index]
	OverlayStateMonitor.push_overlay("end_index", end_index)
	if not try_place_goods(end_index, data):
		pass
	
	message = "\n"
	for i in slot_data.size():
		var tmp_data = slot_data[i]
		if tmp_data:
			message += "[%s-%s], %s" % [i, tmp_data.name, "\n" if (i % 5) == 4 else ""]
		else:
			message += "[%s-%s], %s" % [i, null, "\n" if (i % 5) == 4 else ""]
	OverlayStateMonitor.push_overlay("end_start_index2", message)
	
	highlight_node.visible = false
	goods_container_manage.goods_data = null



## ============================ 数据管理 =============================

## 搜索物品
## is_search: 是否搜索
func get_search_items(container_name: String, is_search = false, number = clampi(randi() % 6, 1, 6)) -> void:
	if searching: 
		return
	searching = true
	#OverlayStateMonitor.push_overlay("number", number)
	var goods_index = []
	var quality = RewardPool.Quality.None
	while(number > 0):
		var goods = Global.goods_container_reward_pool.allocate_single_reward_goods(container_name, quality)
		if not goods: continue
		goods.search = is_search
		#goods.output()
		var successful = add_item(goods)
		if successful == -1: # 添加到容器失败, 重新生成
			var count = 0
			for i in slot_data:
				if i != null:
					count += 1
			if count >= slot_data.size() - 1:
				push_error("容器已满!")
				return
			if quality == RewardPool.Quality.None:
				quality = goods.quality
			else:
				push_error("容器无法放入!")
				return
			print("get_search_items: 重新生成[%s][%s][%s][%s]" % [count, number, RewardPool.quality_to_string(quality), goods.name])
			continue
		goods_index.append(successful)
		quality = RewardPool.Quality.None
		number -= 1
		#OverlayStateMonitor.push_overlay("number", number)
	
	if not is_search:
		for i in goods_index:
			quality = slot_data[i].quality
			var node = goods_grid_node._get_control_at_index(i)
			if not node:
				continue
			node.search()
			await get_tree().create_timer(Goods.get_quality_time(quality)).timeout # 等待动画
	searching = false

func add_item(data: Goods, index: int = -1) -> int:
	var successful = attempt_to_place_item(data, index)
	print("添加[%s][%s]!" % [successful, data.name])
	if successful == -1:
		push_error("添加[%s][%s]失败!" % [index, data.name])
		return -1
	return successful

func remove_item(index: int) -> bool:
	var data = slot_data[index]
	if not data:
		push_error("[%s]移除物品失败!" % [index])
		return false
	var slot_array = get_current_index_occupy_slot(data, index)
	return remove_slot_data(index, data, slot_array)

func index_from_container_coords(_position):
	var index = get_slot_index_from_coords(_position)
	move_slot_data(index, slot_data[index])

func goods_from_container_shift(goods, index):
	add_item(goods, index)

func clear(sell: Callable = Callable()) -> void:
	if searching: return
	cancel.emit(self)
	for i in slot_data.size():
		var data = slot_data[i]
		if data and i == data.start_index:
			if sell: # 出售物品
				sell.call(data)
	slot_data.resize(dimensions.x * dimensions.y)
	goods_grid_node.fill_item(null)
	slot_data.fill(null)

func sells(sell: Callable = Callable(), move_to: Callable = Callable()) -> void:
	if searching: return
	cancel.emit(self)
	for i in slot_data.size():
		var data = slot_data[i]
		if not data:
			continue
		if i == data.start_index:
			if data.quality < RewardPool.Quality.Gold:
				#data.output()
				if sell: # 出售物品
					sell.call(data)
			else:
				if move_to:
					move_to.call(data)
					save.emit(self)
		slot_data[i] = null
	goods_grid_node.update_view()

func save_goods_data(_save: Callable = Callable()):
	var goods_name = []
	for i in slot_data.size():
		var data = slot_data[i]
		if not data:
			continue
		if i == data.start_index:
			goods_name.append(data.name)
	if _save:
		_save.call(goods_name)

## ============================ 物品行为 =============================

## 为物品寻找并分配一个合适的位置
## data: 要放置的物品
func attempt_to_place_item(data: Goods, index: int = -1) -> int:
	if not data: # 非空
		return -1
	if index != -1: # 检查指定索引槽位
		var slot_array = get_current_index_occupy_slot(data, index)
		if item_is_place(slot_array, data):
			# 写入占用数据
			add_slot_data(index, data, slot_array)
			return index
	else: # 扫描所有槽位，寻找可以放置的位置
		for i in range(slot_data.size()):
			var slot_array = get_current_index_occupy_slot(data, i)
			if item_is_place(slot_array, data):
				# 写入占用数据
				add_slot_data(i, data, slot_array)
				return i
	return -1

## 放置物品
## index: 放置位置
func try_place_goods(index: int, data: Goods) -> bool:
	if not data:
		push_error("[%s]data == null!" % [index])
		return false
	if index == data.start_index:
		return false # 放回原位: 拿起时, 只隐藏物品
	return swap_slot_data(index, data) # 替换

## 增加: 物品计数
func add_goods_count(data: Goods):
	var item_count = item_sum.get(data.name, 0)
	item_sum.set(data.name, item_count + 1)

## 减少: 物品计数
func remove_goods_count(data: Goods):
	var item_count = item_sum.get(data.name, 0)
	if item_count > 0:
		item_sum.set(data.name, item_count - 1)



## ============================ 数据操作 =============================

## 添加槽位数据
func add_slot_data(index: int, data: Goods, slot_array: Array) -> bool:
	if not canfine(index):
		return false
	
	data.start_index = index
	for i in slot_array:
		goods_grid_node.update_item(i, data)
	#print("add: %s" % [slot_array])
	add_goods_count(data)
	return true

## 删除槽位数据
func remove_slot_data(index: int, data: Goods, slot_array: Array) -> bool:
	if not canfine(index):
		return false
	
	data.start_index = -1
	for i in slot_array:
		if slot_data[i] == data:
			goods_grid_node.update_item(i, null)
	#print("del: %s" % [slot_array])
	remove_goods_count(data)
	return true

## 交换
func swap_slot_data(index: int, data: Goods) -> bool:
	if not canfine(index):
		return false
	
	var data_slots = get_current_index_occupy_slot(data)
	var data_start_index = data.start_index
	var target_slots = get_current_index_occupy_slot(data, index)
	OverlayStateMonitor.push_overlay("target_slots", target_slots)
	OverlayStateMonitor.push_overlay("data_slots", data_slots)
	# 1.物品小于目标槽位: 将目标槽位移除, 并重新自动寻位添加; 物品放入目标槽位
	# 2.物品大于或等于目标槽位中的所有物品: 交换
	var old_slots = item_is_places(target_slots, data, data_slots)
	if old_slots.is_empty():
		return false
	else:
		# 先移除原物品
		remove_slot_data(data.start_index, data, data_slots)
		
		var max = old_slots[0][0]
		if max == 1: # 将目标槽位物品填入原物品槽位
			for i in old_slots.size() - 1:
				var old_item_slots = old_slots[i + 1] # 目标槽位
				var old_item_index: int = old_item_slots[0] # 目标槽位起始索引
				var old_item: Goods = slot_data[old_item_slots[1][0]] # 目标槽位物品
				remove_slot_data(old_item.start_index, old_item, old_item_slots[1])
				add_slot_data(data_start_index + old_item_index, old_item, get_current_index_occupy_slot(old_item, data_start_index + old_item_index))
			add_slot_data(index, data, target_slots)
		elif max == 0: # 重新选择位置填入
			var old_item_slots = old_slots[1] # 目标槽位
			var old_item: Goods = slot_data[old_item_slots[1][0]] # 目标槽位物品
			remove_slot_data(old_item.start_index, old_item, old_item_slots[1])
			add_slot_data(index, data, target_slots)
			attempt_to_place_item(old_item)
		elif max == -1:
			add_slot_data(index, data, target_slots)
		
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
func move_slot_data(index: int, data: Goods) -> void:
	if goods_container_manage.shift_goods_to(data, -1):
		if not remove_slot_data(index, data, get_current_index_occupy_slot(data, index)):
			push_error("移动物品时, 原容器中删除物品[%s][%s]失败!" % [index, data.name])

## 获取: 物品能放入索引的所有槽位
func item_is_place(occupy_slot: Array, data: Goods) -> bool:
	if occupy_slot.is_empty(): return false
	for i in occupy_slot.size():
		var new_data = slot_data[occupy_slot[i]]
		if new_data and new_data != data: # 已占用
			return false
	return true

## 获取: 物品能放入索引的所有槽位
## target_slot: 目标槽位
## data_slots: 原槽位
## 返回: 所有完全包含/被包含的槽位索引 | [[-1/0/1(空位(包括自身)/小/大于旧槽位), [[旧槽位1起始索引][旧槽位1]]...]
func item_is_places(target_slot: Array, data: Goods, data_slots: Array = []) -> Array:
	if target_slot.is_empty(): return []
	
	var rest_slots = target_slot.filter(func(item): return not item in data_slots)
	
	var old_slots = []
	for i in target_slot.size():
		var old_data = slot_data[target_slot[i]]
		if old_data and old_data != data:
			var old_occupys = get_current_index_occupy_slot(old_data)
			if is_subset(old_occupys, rest_slots): # 大于等于并完全包含旧槽位
				if old_slots.size() == 0:
					old_slots.append([1])
				old_slots.append([i, old_occupys])
			elif is_subset(target_slot, old_occupys): # 小于并完全属于旧槽位
				old_slots.append([0])
				old_slots.append([i, old_occupys])
				return old_slots
			else:
				return []
	if old_slots.size() == 0:
		old_slots.append([-1])
	return old_slots



## ============================ 网格行为 =============================

## 父集是否包含子集
func is_subset(subset: Array, superset: Array) -> bool:
	for element in subset:
		if not superset.has(element):
			return false
	return true

## 获取: 物品当前索引会占用的槽位
## data: 数据尺寸
## index: 占用的槽位
func get_current_index_occupy_slot(data: Goods, index: int = -1) -> Array:
	if not data:
		return []
	if index == -1:
		index = data.start_index
	if not canfine(index, data.dimensions): return [] # 越界
	
	var indexs = []
	var start_pos = _to_coord(index)
	
	for offset in data.get_occupy_offsets():
		var cell_x = start_pos.x + offset.x
		var cell_y = start_pos.y + offset.y
		if _is_valid(cell_x, cell_y):
			indexs.append(_to_index(cell_x, cell_y))
	return indexs

## 边界检查: 数据/容器
func canfine(index: int, data_dimensions: Vector2i = Vector2i(0, 0)) -> bool:
	if index < 0 or index >= slot_data.size(): # 数据越界
		return false
	if data_dimensions.x > 0 or data_dimensions.y > 0: ## 检查 物品规格
		# 边界越界: X
		if (index % dimensions.x) + data_dimensions.x > dimensions.x:
			return false
		# 边界越界: Y
		if floor(float(index) / dimensions.x) + data_dimensions.y > dimensions.y:
			return false
	return true

## 获取: 中心坐标 > 首槽位
func get_slot_from_center_position(coords: Vector2, data_dimensions: Vector2i) -> int:
	var item_offset_position = Vector2(0, 0)
	var offset_slot_size = roundi(float(slot_size) / 2)
	if data_dimensions.x > 1:
		item_offset_position.x = offset_slot_size * (data_dimensions.x - 1)
	if data_dimensions.y > 1:
		item_offset_position.y = offset_slot_size * (data_dimensions.y - 1)
	coords -= item_offset_position
	return get_slot_index_from_coords(coords)

## 获取: 首槽位 > 中心坐标
func get_center_position_from_slot(index: int, data_dimensions: Vector2i) -> Vector2:
	if not canfine(index, data_dimensions):
		return Vector2()
	var offset_slot_size = roundi(float(slot_size) / 2)
	var item_offset_position = Vector2(offset_slot_size * data_dimensions.x, 
		offset_slot_size * data_dimensions.y)
	var coords = get_coords_from_slot_index(index)
	coords += item_offset_position + global_position
	return coords

## 获取: 坐标 > 槽位索引
func get_slot_index_from_coords(coords: Vector2) -> int:
	if not has_point(coords):
		return -1
	var local = coords - global_position
	local /= slot_size
	var index = _to_index(local.x, local.y)
	if not canfine(index):
		return -1
	return index

## 获取: 槽位索引 > 坐标
func get_coords_from_slot_index(index: int) -> Vector2:
	var coords = _to_coord(index)
	return global_position + Vector2(coords.x * slot_size, coords.y * slot_size)

## 坐标是否在指定范围
func has_point(_global_position: Vector2) -> bool:
	var global_rect = Rect2(global_position, size)
	return global_rect.abs().has_point(_global_position)

## 边界检查: 坐标
func _is_valid(x: int, y: int) -> bool:
	return x >= 0 and x < dimensions.x and y >= 0 and y < dimensions.y

## 坐标 -> 索引
func _to_index(x: int, y: int) -> int:
	return y * dimensions.x + x

## 索引 -> 坐标
func _to_coord(index: int) -> Vector2:
	return Vector2(index % dimensions.x, float(index) / dimensions.x)

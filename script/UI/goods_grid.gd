class_name GoodsGrid extends Control



## ============================ 信号 =============================




## ============================ 变量 =============================

@onready var slot_grid_node: VListView = %SlotGrid
@onready var goods_grid_node: VListView = %GoodsGrid
@onready var search_path_follow_node: PathFollow2D = %PathFollow2D
@onready var search_icon_node: Sprite2D = %SearchIcon
@onready var container_name_node: Label = %ContainerName
@onready var background_node: Panel = %Background
@export var slot_grid_scene: PackedScene ## 场景: 槽位列表
@export var goods_grid_scene: PackedScene ## 场景: 物品列表
@export var highlight_scene: PackedScene ## 场景: 物品列表

@export var container_name: String = "容器"
var highlight_node = null
var slot_size: int = Global.SLOT_SIZE ## 物品槽大小
@export var dimensions: Vector2i = Vector2i(5, 5) ## 网格大小: X,Y

var searching = false
@export var show_background = true
@onready var slot_data = goods_grid_node.data
var item_sum: Dictionary = {}
var button_groups = ButtonGroup.new()



## ============================ 基础实现 =============================

func _ready() -> void:
	set_container_state(false)
	OverlayStateMonitor.is_performance = false
	
	slot_data.resize(dimensions.x * dimensions.y)
	slot_data.fill(null)
	custom_minimum_size = dimensions * slot_size
	
	background_node.visible = show_background
	if highlight_scene:
		highlight_node = highlight_scene.instantiate()
		highlight_node.z_index = 2
		background_node.add_child(highlight_node)
	else:
		push_error("highlight_scene == null!")
	
	read_goods_data() # 读取: 仓库物品


func _process(delta: float) -> void:
	if search_icon_node.visible:
		if search_path_follow_node.progress_ratio >= 1.0:
			search_path_follow_node.progress_ratio = 0.0
		search_path_follow_node.progress_ratio += delta * 0.5


## ============================ 回调 =============================

func _on_goods_single_click_up(_global_position):
	#OverlayStateMonitor.push_overlay("_on_goods_single_click_down", _global_position)
	var container = goods_container_manage.has_global_points(position)
	if container != self: return
	var index = get_slot_index_from_coords(_global_position)
	var data: Goods = slot_data[index]
	if not data:
		return
	OverlayStateMonitor.push_overlay("goods_data", data.name)
	if data.search:
		var control = goods_grid_node._get_control_at_index(data.index)
		if not control: 
			control = button_groups.get_pressed_button()
			if control: 
				control.button_pressed = false
			return
		control.button_pressed = true
		goods_container_manage.show_info(data, true)

func _on_goods_double_click(_global_position):
	#OverlayStateMonitor.push_overlay("_on_goods_double_click", _global_position)
	var index = get_slot_index_from_coords(_global_position)
	var data = slot_data[index]
	if not data: return
	if not data.search: return
	move_slot_data(data.index, data)
	goods_container_manage.set_goods_data(null)

func _on_goods_drag_start(_global_position):
	#OverlayStateMonitor.push_overlay("_on_goods_drag_start", _global_position)
	goods_container_manage.show_info(null, false)
	goods_grid_node.drag_start_item(_global_position)

func _on_goods_drag_move(_global_position):
	#OverlayStateMonitor.push_overlay("_on_goods_drag_move", _global_position)
	goods_grid_node.drag_move_item(_global_position)

func _on_goods_drag_end(_global_position):
	#OverlayStateMonitor.push_overlay("_on_goods_drag_end", _global_position)
	goods_grid_node.drag_end_item(_global_position)



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

## 创建: 槽位
func _on_goods_grid_on_data_fill(self_node: VListView) -> void:
	self_node.item_size = Vector2i(slot_size, slot_size)
	self_node.set_template(goods_grid_scene)
	self_node.custom_minimum_size = custom_minimum_size
	self_node.columns = dimensions.x
	self_node.fill_item(null, dimensions.x * dimensions.y)
	goods_container_manage.init(self_node.drag_node.duplicate())
	goods_container_manage.add_item(self)

func _on_goods_grid_on_node_init(control) -> void:
	button_groups.allow_unpress = true
	control.button_group = button_groups

func _on_goods_grid_on_entry_connect_callback(control: Variant) -> void:
	if control == null: 
		push_error("control == null!")
		return

func _on_goods_grid_on_entry_disconnect_callback(control: Variant) -> void:
	if control == null: 
		push_error("control == null!")
		return

func _on_goods_grid_on_entry_updated(index: int, control, data) -> void:
	if not control:
		#push_error("[%s]control == null!" % [index])
		return
	if not data or index != data.index:
		control.set_goods_size(Vector2(slot_size, slot_size))
		control.visible = false
		return
	control.set_data(data)
	control.visible = true

func _on_goods_grid_on_drag_start_item(index: int, data: Goods, global_mouse_position: Vector2) -> void:
	goods_container_manage.set_goods_data(data)
	if not data:
		return
	if not data.search: # 未搜索物品无法交互
		return
	
	#var control = goods_grid_node._get_control_at_index(data.index)
	#if control:
		#control.show_name(false)
	
	goods_container_manage.set_drag_node_position(global_mouse_position)
	goods_container_manage.show_drag_node(true)
	
	show_highlight(data, global_mouse_position)

func _on_goods_grid_on_drag_move_item(index: int, global_mouse_position: Vector2) -> void:
	var data = goods_container_manage.goods_data
	var container = goods_container_manage.current_container
	if container != self: 
		highlight_node.color_change(false)
		return
	if not data: 
		return
	
	goods_container_manage.show_drag_node(true)
	show_highlight(data, global_mouse_position)

func _on_goods_grid_on_drag_end_item(index: int, end_index: int, global_mouse_position: Vector2) -> void:
	var data = goods_container_manage.goods_data
	highlight_node.visible = false
	if not data:
		return
	#var control = goods_grid_node._get_control_at_index(data.index)
	#if control:
		#control.show_name(true)
	end_index = get_slot_from_center_position(global_mouse_position, data.dimensions)
	if not try_place_goods(end_index, data):
		pass
	
	goods_container_manage.set_goods_data(null)



## ============================ 数据管理 =============================

func is_empty() -> bool:
	for i in slot_data.size():
		var data = slot_data[i]
		if data: 
			return false
	return true
	
func set_container_state(is_search: bool = false):
	if is_search:
		search_icon_node.visible = true
		container_name_node.text = "正在搜索中..."
	else:
		search_icon_node.visible = false
		container_name_node.text = container_name

## 搜索物品
## is_search: 是否搜索
func get_search_items(container_name: String, is_search = false, number = clampi(randi() % 6, 1, 6)) -> void:
	if searching:
		return
	searching = true
	set_container_state(true)
	
	var goods_index = []
	goods_index.resize(slot_data.size())
	goods_index.fill(0)
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
				#push_error("容器已满!")
				break
			if quality == RewardPool.Quality.None:
				quality = goods.quality
			else:
				#push_error("容器无法放入!")
				break
			#print("get_search_items: 重新生成[%s][%s][%s][%s]" % [count, number, RewardPool.quality_to_string(quality), goods.name])
			continue
		goods_index[successful] = 1
		quality = RewardPool.Quality.None
		number -= 1
	
	if not is_search:
		for i in goods_index.size():
			var index = goods_index[i]
			if index == 0: continue
			var data: Goods = slot_data[i]
			quality = slot_data[i].quality
			var node = goods_grid_node._get_control_at_index(i)
			if not node:
				continue
			node.search()
			await get_tree().create_timer(Goods.get_quality_time(quality)).timeout # 等待动画
			data.search = true
	
	set_container_state(false)
	searching = false

func add_item(data: Goods, index: int = -1) -> int:
	var successful = attempt_to_place_item(data, index)
	#print("添加[%s][%s]!" % [successful, data.name])
	if successful == -1:
		#push_error("添加[%s][%s]失败!" % [index, data.name])
		return -1
	if container_name == "钥匙卡包":
		if data.type == Goods.Type.KeyCar:
			goods_container_manage.set_container_probability()
	return successful

func remove_item(index: int) -> bool:
	var data = slot_data[index]
	if not data:
		push_error("[%s]移除物品失败!" % [index])
		return false
	var slot_array = get_current_index_occupy_slot(data, index)
	if not remove_slot_data(index, data, slot_array):
		return false
	if container_name == "钥匙卡包":
		if data.type == Goods.Type.KeyCar:
			goods_container_manage.set_container_probability()
	return true

func clear(call_back: Callable = Callable()) -> void:
	if searching: return
	#cancel.emit()
	for i in slot_data.size():
		var data = slot_data[i]
		if data and i == data.index:
			if call_back: # 出售物品
				call_back.call(data)
	slot_data.resize(dimensions.x * dimensions.y)
	goods_grid_node.fill_item(null)
	slot_data.fill(null)

func sell(data: Goods = null, call_back: Callable = Callable()) -> Variant:
	#if searching: return
	if not data:
		return null
	remove_item(data.index)
	if call_back: # 出售物品
		call_back.call(data.value)
		#save.emit(self)
	save_goods_data()
	return data

func sells(call_back: Callable = Callable()) -> bool:
	#if searching: return
	var is_successful = true
	for i in slot_data.size():
		var data: Goods = slot_data[i]
		if not data:
			continue
		if not data.search: 
			is_successful = false
			continue
		if data.index == i:
			if data.type == Goods.Type.KeyCar:
				move_slot_data_keys(data.index, data)
				continue
			if data.quality >= RewardPool.Quality.Red:
				move_slot_data_store(data.index, data)
			else:
				remove_item(data.index)
				if call_back: # 出售物品
					call_back.call(data.value)
					#save.emit(self)
	save_goods_data()
	return is_successful

func read_goods_data(_read: Callable = Callable()):
	# 只读取[仓库/钥匙卡包]物品
	if container_name == "仓库":
		var store = goods_container_manage.store
		for i in store.size():
			var goods_data: Goods = store[i]
			if not goods_data:
				continue
			#print("read_goods_data: %s" % [goods_data.name])
			add_item(goods_data)
			if _read:
				_read.call(goods_data.name)
	elif container_name == "钥匙卡包":
		var keys = goods_container_manage.keys
		for i in keys.size():
			var goods_data: Goods = keys[i]
			if not goods_data:
				continue
			#print("read_goods_data: %s" % [goods_data.name])
			add_item(goods_data)
			if _read:
				_read.call(goods_data.name)

func save_goods_data(_save: Callable = Callable()):
	# 只保存[仓库/钥匙卡包]物品
	if container_name == "仓库":
		goods_container_manage.store.clear() # 清空
		
		for i in slot_data.size():
			var goods_data: Goods = slot_data[i]
			if not goods_data:
				continue
			if i == goods_data.index:
				#print("save_goods_data: %s" % [goods_data.name])
				goods_container_manage.store.append(goods_data)
				if _save:
					_save.call(goods_data.name)
		goods_container_manage.save_store_data()
	elif container_name == "钥匙卡包":
		goods_container_manage.keys.clear() # 清空
		
		for i in slot_data.size():
			var goods_data: Goods = slot_data[i]
			if not goods_data:
				continue
			if i == goods_data.index:
				#print("save_goods_data: %s" % [goods_data.name])
				goods_container_manage.keys.append(goods_data)
				if _save:
					_save.call(goods_data.name)
		goods_container_manage.save_keys_data()



## ============================ 物品行为 =============================

## 为物品寻找并分配一个合适的位置
## data: 要放置的物品
func attempt_to_place_item(data: Goods, index: int = -1, is_write = true, pass_indexs = [], exclude_indexs = []) -> int:
	if not data: # 非空
		return -1
	var ranges = []
	if index == -1:
		ranges = range(slot_data.size())
	else:
		ranges.append(index)
	ranges = ranges.filter(func(item): return not item in exclude_indexs) # 排除索引列表
	for i in ranges:
		var slot_array = get_current_index_occupy_slot(data, i)
		if item_is_place(slot_array, data, pass_indexs, exclude_indexs):
			# 写入占用数据
			if is_write: add_slot_data(i, data, slot_array)
			return i
	return -1

## 放置物品
## index: 放置位置
func try_place_goods(index: int, data: Goods) -> bool:
	if not data:
		push_error("[%s]data == null!" % [index])
		return false
	if index == data.index:
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
	
	data.index = index
	for i in slot_array:
		goods_grid_node.update_item(i, data)
	#print("add: [%s]%s" % [container_name, slot_array])
	add_goods_count(data)
	return true

## 删除槽位数据
func remove_slot_data(index: int, data: Goods, slot_array: Array) -> bool:
	if not canfine(index):
		return false
	
	data.index = -1
	for i in slot_array:
		if slot_data[i] == data:
			goods_grid_node.update_item(i, null)
	#print("del: [%s]%s" % [container_name, slot_array])
	remove_goods_count(data)
	return true

## 交换
func swap_slot_data(index: int, data: Goods) -> bool:
	if not canfine(index):
		return false
	
	var data_slots = get_current_index_occupy_slot(data)
	var target_slots = get_current_index_occupy_slot(data, index)
	# 1.物品小于目标槽位: 将目标槽位移除, 并重新自动寻位添加; 物品放入目标槽位
	# 2.物品大于或等于目标槽位中的所有物品: 交换
	##		[
	##			-2(原位)/-1(无效)/0(空位)/1(覆盖)/2(覆盖并自动寻位)), 
	##			[[旧物品1旧槽位]...], 
	##			[[旧物品1新槽位]...]
	##		]
	var old_datas = item_is_places(target_slots, data, data_slots)
	var code = old_datas[0]
	if code == -1:
		return false
	elif code == 1: # 将目标槽位物品填入原物品槽位
		var old_data_old_slots = old_datas[1] # 旧物品: 旧槽位
		var old_data_new_slots = old_datas[2] # 旧物品: 新槽位
		for i in old_data_old_slots.size():
			var old_data_old_index: int = old_data_old_slots[i][0] # 旧物品: 旧索引
			var old_data_new_index: int = old_data_new_slots[i][0] # 旧物品: 新索引
			var old_item: Goods = slot_data[old_data_old_index] # 旧物品
			remove_slot_data(data.index, data, data_slots) # 先移除原物品
			remove_slot_data(old_data_old_index, old_item, old_data_old_slots[i]) # 再移除目标物品
			add_slot_data(old_data_new_index, old_item, old_data_new_slots[i]) # 添加目标物品
		add_slot_data(index, data, target_slots) # 添加原物品
	elif code == 2: # 重新选择位置填入
		var old_data_old_slots = old_datas[1] # 旧物品: 旧槽位
		var old_data_old_index: int = old_data_old_slots[0][0] # 旧物品: 旧索引
		var old_item: Goods = slot_data[old_data_old_index] # 目标槽位物品
		var pass_indexs = data_slots.duplicate()
		var exclude_indexs = target_slots.duplicate()
		var old_data_new_index = attempt_to_place_item(old_item, -1, false, pass_indexs, exclude_indexs)
		if old_data_new_index == -1:
			return false
		remove_slot_data(data.index, data, data_slots) # 先移除原物品
		remove_slot_data(old_data_old_index, old_item, old_data_old_slots[0]) # 再移除目标物品
		add_slot_data(old_data_new_index, old_item, get_current_index_occupy_slot(old_item, old_data_new_index)) # 添加目标物品
		add_slot_data(index, data, target_slots) # 添加原物品
	else:
		remove_slot_data(data.index, data, data_slots) # 先移除原物品
		add_slot_data(index, data, target_slots) # 添加原物品
	return true

## 移动物品
func move_slot_data(index: int, data: Goods) -> void:
	if not data: 
		push_error("data == null!")
		return
	remove_slot_data(index, data, get_current_index_occupy_slot(data, index))
	if not goods_container_manage.shift_goods_to(container_name, data, -1):
		#push_error("移动物品时, 原容器中删除物品[%s][%s]失败!" % [index, data.name])
		add_slot_data(index, data, get_current_index_occupy_slot(data, index))
	save_goods_data()
	
func move_slot_data_store(index: int, data: Goods) -> void:
	if container_name == "仓库": return
	if not data: 
		push_error("data == null!")
		return
	remove_slot_data(index, data, get_current_index_occupy_slot(data, index))
	if not goods_container_manage.shift_goods_to(container_name, data, -1, "仓库"):
		#push_error("移动物品时, 原容器中删除物品[%s][%s]失败!" % [index, data.name])
		add_slot_data(index, data, get_current_index_occupy_slot(data, index))
	save_goods_data()
	
func move_slot_data_keys(index: int, data: Goods) -> void:
	if container_name == "钥匙卡包": return
	if not data: 
		push_error("data == null!")
		return
	remove_slot_data(index, data, get_current_index_occupy_slot(data, index))
	if not goods_container_manage.shift_goods_to(container_name, data, -1, "钥匙卡包"):
		#push_error("移动物品时, 原容器中删除物品[%s][%s]失败!" % [index, data.name])
		add_slot_data(index, data, get_current_index_occupy_slot(data, index))
	save_goods_data()

## 获取: 物品能放入索引的所有槽位
func item_is_place(occupy_slot: Array, data: Goods, pass_indexs = [], exclude_indexs = []) -> bool:
	if occupy_slot.is_empty(): return false
	for i in occupy_slot.size():
		var index = occupy_slot[i]
		if pass_indexs.find(index) != -1:
			continue
		if exclude_indexs.find(index) != -1:
			return false
		var new_data = slot_data[index]
		if new_data and new_data != data: # 已占用
			return false
	return true

## 获取: 物品能放入索引的所有槽位
## target_slot: 目标槽位
## data_slots: 原槽位
## 返回: 所有完全包含/被包含的槽位索引:
##		[
##			-2(原位)/-1(无效)/0(空位)/1(覆盖)/2(覆盖并自动寻位)), 
##			[[旧物品1旧槽位]...], 
##			[[旧物品1新槽位]...]
##		]
func item_is_places(target_slot: Array, data: Goods, data_slots: Array = []) -> Array:
	var old_slots = []
	old_slots.append(-1)
	old_slots.append([])
	old_slots.append([])
	if target_slot.is_empty(): return old_slots
	
	if target_slot == data_slots: # 原位
		old_slots[0] = -2
		return old_slots
	
	# 找相同并移除: 得到不会被覆盖的空位
	var release_slots = data_slots.filter(func(item): return not item in target_slot) # 释放槽位
	
	# 先找出目标槽位内的所有物品
	var old_data_old_slots = []
	var old_data_old_datas = []
	for i in target_slot.size():
		var old_data: Goods = slot_data[target_slot[i]]
		if old_data and old_data != data: # 跳过: 空位/自身
			var old_data_old_slot: Array = get_current_index_occupy_slot(old_data)
			if old_data_old_slots.find(old_data_old_slot) == -1:
				old_data_old_slots.append(old_data_old_slot)
				old_data_old_datas.append(old_data)
	
	var indexs = range(old_data_old_datas.size())
	# 排序: 物品X/Y轴规格 降序
	indexs.sort_custom(func(i, j): 
		var old_data_a = old_data_old_datas[i]
		var old_data_b = old_data_old_datas[j]
		if old_data_a.dimensions.x > old_data_b.dimensions.x:
			return i
		if old_data_a.dimensions.y > old_data_b.dimensions.y:
			return i
		return j
			)
	var new_old_data_old_slots = []
	for i in indexs:
		new_old_data_old_slots.append(old_data_old_slots[i])
	old_data_old_slots = new_old_data_old_slots
	
	if old_data_old_slots.size() == 0: # 空位
		old_slots[0] = 0
		return old_slots
	for i in old_data_old_slots.size():
		var old_data_old_slot = old_data_old_slots[i] # 旧物品的旧槽位
		var old_data = slot_data[old_data_old_slot[0]] # 旧物品
		
		var index = 0
		while(index < release_slots.size()): # 遍历寻位
			var old_data_new_slot: Array = get_current_index_occupy_slot(old_data, release_slots[index])
			
			# 大于等于并完全包含旧槽位
			if is_subset(old_data_new_slot, release_slots if is_subset(old_data_old_slot, target_slot) else []): 
				old_slots[0] = 1
				old_slots[1].append(old_data_old_slot)
				old_slots[2].append(old_data_new_slot)
				release_slots = release_slots.filter(
					func(item): return not item in old_data_new_slot) # 排除已占用槽位
				index = 0
				break
			# 小于并完全被旧槽位包含
			elif is_subset(target_slot, old_data_old_slot): 
				old_slots[0] = 2
				old_slots[1].append(old_data_old_slot)
				old_slots[2].append([-1]) # 自动重新寻位
				break
			index += 1
		if release_slots.size() != 0 and index == release_slots.size(): # 没有合适旧物品的位置
			# 无效: 跳过
			old_slots[0] = -1
			return old_slots
	return old_slots



## ============================ 网格行为 =============================

## 父集是否包含子集
func is_subset(subset: Array, superset: Array) -> bool:
	if subset.is_empty(): return false
	for element in subset:
		if not superset.has(element):
			return false
	return true

# 去重
func merge_unique(left: Array, right: Array) -> Array:
	var dict = {}
	for v in left + right:
		dict[v] = true
	return dict.keys()

## 获取: 物品当前索引会占用的槽位
## data: 数据尺寸
## index: 占用的槽位
func get_current_index_occupy_slot(data: Goods, index: int = -1) -> Array:
	if not data:
		return []
	if index == -1:
		index = data.index
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

## 获取: 中心坐标 > 偏移坐标
func get_offset_from_center_position(coords: Vector2, data_dimensions: Vector2i) -> Vector2:
	var item_offset_position = Vector2(0, 0)
	var offset_slot_scale = roundi(float(slot_size) / 2)
	if data_dimensions.x > 1:
		item_offset_position.x = offset_slot_scale * (data_dimensions.x - 1)
	if data_dimensions.y > 1:
		item_offset_position.y = offset_slot_scale * (data_dimensions.y - 1)
	coords -= item_offset_position
	return coords

## 获取: 中心坐标 > 首槽位
func get_slot_from_center_position(coords: Vector2, data_dimensions: Vector2i) -> int:
	var item_offset_position = Vector2(0, 0)
	var offset_slot_scale = roundi(float(slot_size) / 2)
	if data_dimensions.x > 1:
		item_offset_position.x = offset_slot_scale * (data_dimensions.x - 1)
	if data_dimensions.y > 1:
		item_offset_position.y = offset_slot_scale * (data_dimensions.y - 1)
	coords -= item_offset_position
	return get_slot_index_from_coords(coords)

## 获取: 首槽位 > 中心坐标
func get_center_position_from_slot(index: int, data_dimensions: Vector2i) -> Vector2:
	if not canfine(index, data_dimensions):
		return Vector2()
	var offset_slot_scale = roundi(float(slot_size) / 2)
	var item_offset_position = Vector2(offset_slot_scale * data_dimensions.x, 
		offset_slot_scale * data_dimensions.y)
	var coords = get_coords_from_slot_index(index)
	coords += item_offset_position
	return coords

## 获取: 坐标 > 槽位索引
func get_slot_index_from_coords(coords: Vector2) -> int:
	if not has_global_point(coords):
		return -1
	var local = coords - goods_grid_node.global_position
	local /= slot_size
	var index = _to_index(local.x, local.y)
	if not canfine(index):
		return -1
	return index

## 获取: 槽位索引 > 坐标
func get_coords_from_slot_index(index: int) -> Vector2:
	if index < 0: return Vector2(0, 0)
	var row = index % dimensions.x
	var col = floor(float(index) / dimensions.x)
	return goods_grid_node.global_position + Vector2(row * slot_size, col * slot_size)

## 坐标是否在指定范围
func has_global_point(_global_position: Vector2) -> bool:
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

func show_highlight(data: Goods, global_mouse_position: Vector2):
	highlight_node.set_slot_size(data.dimensions)
	
	# 当前的中心坐标
	var new_position: Vector2 = global_mouse_position - background_node.global_position - (highlight_node.size / 2)
	# 垂直滚动偏移
	var offset = Vector2(0, int(goods_grid_node.v_scroll_bar.value) % slot_size)
	new_position = round((new_position - offset) / slot_size)
	new_position = new_position * slot_size
	highlight_node.position = new_position
	OverlayStateMonitor.push_overlay("new_position", new_position)
	
	# 获取首槽位: 显示是否可以放入鼠标位置
	var start_index = get_slot_from_center_position(global_mouse_position, data.dimensions)
	if start_index != -1:
		var target_slots = get_current_index_occupy_slot(data, start_index)
		var data_slots = get_current_index_occupy_slot(data)
		var old_datas = item_is_places(target_slots, data, data_slots)
		if old_datas[0] == -1:
			highlight_node.color_change(false)
		elif old_datas[0] == 2: # 重新选择位置填入
			var old_data_old_slots = old_datas[1] # 旧物品: 旧槽位
			var old_data_old_index: int = old_data_old_slots[0][0] # 旧物品: 旧索引
			var old_item: Goods = slot_data[old_data_old_index] # 目标槽位物品
			var pass_indexs = data_slots.duplicate()
			var exclude_indexs = target_slots.duplicate()
			var old_data_new_index = attempt_to_place_item(old_item, -1, false, pass_indexs, exclude_indexs)
			if old_data_new_index == -1:
				highlight_node.color_change(false)
			else:
				highlight_node.color_change(true)
		else:
			highlight_node.color_change(true)
	else:
		highlight_node.color_change(false)
	highlight_node.visible = true

extends GridContainer


signal select(item: Node)
signal cancel()


@onready var input_recognizer_node = %InputRecognizer
@onready var item_grid_node = %ItemGrid
@onready var held_item_highlight_node = %HeldItemHighlight # 物品悬浮槽位时高亮
@export var inventory_item_scene: PackedScene ## 场景: 容器物品

@export var dimensions: Vector2i = Vector2i(5, 5) ## 网格大小: X,Y
@export var slot_data: Array[Node] = [] ## 槽位

var id = get_instance_id()

var select_item = null
var last_select_item = null
var held = false
var held_index = -1
var count = 0
var item_sum: Dictionary = {}


func _ready() -> void:
	input_recognizer_node.single_click.connect(_on_single_click)
	input_recognizer_node.double_click.connect(_on_double_click)
	input_recognizer_node.long_press_start.connect(_on_long_press_start)
	input_recognizer_node.long_press_end.connect(_on_long_press_end)
	input_recognizer_node.drag_start.connect(_on_drag_start)
	input_recognizer_node.drag_move.connect(_on_drag_move)
	input_recognizer_node.drag_end.connect(_on_drag_end)
	
	# 初始化物品网格
	add_theme_constant_override("v_separation", Global.V_SEPARATION)
	#global_position -= Vector2(Global.SLOT_SCALE * 2, Global.SLOT_SCALE * 2)
	init_slot_data()



## ----------------- 回调 -------------------------

## 回调: 单击
func _on_single_click(_position: Vector2) -> void:
	if not has_point(_position): return
	
	last_select_item = select_item ##覆盖旧选项
	var slot_index = get_slot_index_from_coords(_position)
	select_item = slot_data.get(slot_index) # 获取索引项
	restore_select()
	if select_item and select_item.data.search:
		select_item.set_item_select(true)
		select.emit(select_item)
	else:
		cancel.emit()

## 回调: 双击
func _on_double_click(_position: Vector2) -> void:
	if not has_point(_position): return

## 回调: 长按开始
func _on_long_press_start(_position: Vector2) -> void:
	if not has_point(_position): return
	
	held_item(_position)

## 回调: 长按结束
func _on_long_press_end(_position: Vector2) -> void:
	item_place(_position)

## 回调: 拖拽开始
func _on_drag_start(_position: Vector2) -> void:
	if not has_point(_position): return
	
	held_item(_position)

## 回调: 拖拽移动
func _on_drag_move(_position: Vector2) -> void:
	if not select_item: return
	select_item.global_position = _position # 物品: 跟随鼠标
	var inventorys = get_tree().get_nodes_in_group("Inventory")
	var inventory_other = []
	var inventory_ins = self
	for tmp in inventorys:
		if tmp.has_point(_position): 
			inventory_ins = tmp
			break
		inventory_other.append(tmp)
	#print("_on_drag_move: \n\t%s\n\t%s" % [inventory_ins.global_position, 
	#	inventory_ins.size + inventory_ins.global_position])
	var slot_index = inventory_ins.get_slot_index_from_coords(
		clamp(_position, inventory_ins.global_position, 
		inventory_ins.size + inventory_ins.global_position))
	if inventory_ins.item_is_fits(select_item, inventory_ins.get_slot_index_from_coords(
		clamp(_position, inventory_ins.global_position, inventory_ins.size + inventory_ins.global_position))):
		if inventory_ins.has_point(_position):
			inventory_ins.held_item_highlight_node.global_position = \
			inventory_ins.get_coords_from_slot_index(slot_index) # 悬浮物品槽位高亮: 跟随鼠标
			inventory_ins.held_item_highlight_node.color_change(true)
			#held_item_highlight_node.posision_to_print()
	else:
		if inventory_ins.has_point(_position):
			if inventory_ins.canfine(select_item.data.dimensions, slot_index):
				inventory_ins.held_item_highlight_node.global_position = \
				inventory_ins.get_coords_from_slot_index(slot_index) # 悬浮物品槽位高亮: 跟随鼠标
			inventory_ins.held_item_highlight_node.color_change(false)
	
	inventory_ins.held_item_highlight_node.scale_change(select_item.data.dimensions) # 悬浮物品槽位高亮: 缩放
	inventory_ins.held_item_highlight_node.visible = true
	for tmp in inventory_other:
		tmp.held_item_highlight_node.visible = false

## 回调: 拖拽结束
func _on_drag_end(_position: Vector2) -> void:
	held_item_highlight_node.visible = false
	
	item_place(_position)

## 统一物品放置操作
func item_place(_position: Vector2) -> void:
	if select_item:
		if not has_point(_position):
			remove_child(select_item) # 移除子节点
			if not Inventory_place_data(_position, select_item):
				print("没有合适容器/槽位放置, 还原!")
				add_child(select_item)
				try_place_item(select_item, get_coords_from_slot_index(held_index), held_index)
		else:
			try_place_item(select_item, _position, held_index)
		last_select_item = select_item
		select_item = null
	held = false

## 跨容器放置
func Inventory_place_data(_at_position: Vector2, data: Variant) -> bool:
	if not can_item_data(data): 
		push_warning("Inventory_place_data: 物品非所需对象!")
		return false
	var inventorys = get_tree().get_nodes_in_group("Inventory")
	for tmp in inventorys:
		#print("id: ", tmp.id)
		if not tmp.has_point(_at_position):
			continue
		var slot_index = tmp.get_slot_index_from_coords(_at_position)
		if not tmp.item_is_fits(data, slot_index): # 对应容器: 该槽位无法放置
			print(slot_index)
			var success = tmp.attempt_to_place_item(data, -1) # 尝试每个位置
			print("success: ", success)
			if success == -1 : # 没有合适位置放置
				return false
			else:
				tmp.add_child(data)
				tmp.try_place_item(data, tmp.get_coords_from_slot_index(success), success) # 放置
				return true
		else: # 对应容器: 该槽位可以放置
			tmp.add_child(data)
			tmp.try_place_item(data, tmp.get_coords_from_slot_index(slot_index), slot_index) # 放置
			return true
	return false






## ----------------- 数据管理 -------------------------

## 搜索物品
## is_search: 是否搜索
func get_search_items(number = randi() % 6, is_search = false) -> void:
	for i in range(number):
		var item = Global.safe_box_reward_pool.allocate_single_reward()
		#reward.output()
		item.search = is_search
		if add_item(item) and not item.search: # 等待动画
			await get_tree().create_timer(\
			Goods.get_quality_time(item.quality)).timeout

func add_item(item_data: Goods, index: int = -1) -> bool:
	var inventory_item = inventory_item_scene.instantiate()
	inventory_item.data = item_data
	#print("物品: ", inventory_item.global_position)
	var success = attempt_to_place_item(inventory_item, index)
	#print(item_sum)
	if success == -1:
		push_error("ItemInventory: add_item: 添加物品[%s]失败not " % [item_data.name])
	else:
		add_child(inventory_item)
		# 设置 UI 初始位置
		inventory_item.get_placed(get_coords_from_slot_index(success))
	return success

func remove_item(_item = null) -> void:
	if _item and _item is Node:
		if _item as Node:
			del_item_to_slot_data(_item)
			remove_child(_item)
			_item.queue_free()
			print("ItemInventory: remove_item: 移除物品[%s]not " % [_item.data.name])
	elif _item and _item is int:
		if _item as int:
			if _item < 0 or _item >= slot_data.size(): return
			var item = slot_data[_item]
			if item:
				del_item_to_slot_data(item)
				remove_child(item)
				item.queue_free()
				print("ItemInventory: remove_item: 移除物品[%s]not " % [item.data.name])

func clear() -> void:
	#var count = 0
	for item in get_children():
		if item and item.get("data"):
			remove_child(item)
			item.queue_free()
			#count += 1
	slot_data.fill(null)
	#print("ItemInventory: clear: 移除物品数量[%s]not " % [count])

func init_slot_data() -> void:
	slot_data.resize(dimensions.x * dimensions.y)
	slot_data.fill(null)
	size.x = dimensions.x * Global.SLOT_SIZE
	size.y = dimensions.y * Global.SLOT_SIZE
	add_to_group("Inventory")
	#print("ItemInventory: rect: \n\t%s\n\t%s" % [global_position, global_position + size])






## ----------------- 物品行为 -------------------------

## 还原选择状态
func restore_select() -> void:
	if last_select_item and last_select_item != select_item: 
		last_select_item.set_item_select(false)

## 开始拖拽物品
func start_dragging_item(item: Node) -> void:
	if item == null:
		push_error("ItemInventory: start_dragging_item: 物品为 nullnot ")
		return
	held_index = item.data.slot_index # 记录拿起时的槽位
	item.set_item_select(false)
	# 清空 原槽位
	del_item_to_slot_data(item)
	item.get_picked_up()
	#print(held_index)

## 拿起物品
func held_item(_position: Vector2) -> void:
	if held: return
	cancel.emit()
	restore_select()
	var slot_index = get_slot_index_from_coords(_position)
	select_item = slot_data.get(slot_index)
	if select_item:
		start_dragging_item(select_item)
	held = true

## 放置物品
func try_place_item(item:Node, _position: Vector2, reset_index: int) -> void:
	if item == null:
		push_error("ItemInventory: try_place_item: 没有物品被拿起not ")
		return
	var slot_index = get_slot_index_from_coords(_position)
	if item_is_fits(item, slot_index):
		add_item_to_slot_data(item, slot_index)
		item.get_placed(get_coords_from_slot_index(slot_index))
		#print("place[true]: ", get_coords_from_slot_index(slot_index))
	else:
		add_item_to_slot_data(item, reset_index)
		item.get_placed(get_coords_from_slot_index(reset_index))
		#print("place[false]: ", get_coords_from_slot_index(reset_index))

## 检测物品是否为 Node节点
func can_item_data(data: Variant) -> bool:
	if data and data is Node:
		if data.get("data"):
			return true
	return false






## ----------------- 网格行为 -------------------------

## 将物品占用的数据写入 slot_data
func add_item_to_slot_data(item: Node, index: int) -> void:
	for i in get_item_index_occupy_slot(item, index):
		slot_data[i] = item
	#print("add: [%s](%s)" % [item.data.name, index])
	var item_count = item_sum.get(item.data.name, -1)
	if item_count != -1:
		item_sum.set(item.data.name, item_count + 1)
	else:
		item_sum.set(item.data.name, 1)
	item.data.slot_index = index

## 将物品占用的数据从 slot_data 删除 
func del_item_to_slot_data(item: Node) -> void:
	for index in get_item_occupy_slot(item):
		if slot_data[index] == item:
			slot_data[index] = null
	var item_count = item_sum.get(item.data.name, -1)
	if item_count != -1:
		item_sum.set(item.data.name, item_count - 1)
	#print("del: [%s](%s)" % [item.data.name, item.data.slot_index])
	#count += 1
	#print(count)
	item.data.slot_index = -1

## 移动物品
func move_item(item:Node, index: int) -> void:
	del_item_to_slot_data(item)
	add_item_to_slot_data(item, index)

## 移动物品: 跨容器
## 在当前容器中删除物品
## 如果其他容器有效, 直接添加; 否则, 返回物品
func move_item_to_inventory(
	item:Node, 
	other_inventory_index: int, 
	other_inventory_node: Node = null
) -> Node:
	del_item_to_slot_data(item)
	if other_inventory_node:
		other_inventory_node.add_item_to_slot_data(
			item, other_inventory_index)
	item.data.slot_index = -1
	return item

## 获取物品当前索引会占用的槽位
## item: 假定总是有效
## index: 被占用的槽位
func get_item_index_occupy_slot(item: Node, index: int = 0) -> Array[int]:
	if not item:	return []
	if not canfine(item.data.dimensions, index): return [] # 越界
	
	var item_slot : Array[int]
	for y in range(item.data.dimensions.y):
		for x in range(item.data.dimensions.x):
			var slot_index = index + x + y * dimensions.x
			item_slot.append(slot_index)
	return item_slot
	
## 获取物品当前占用槽位
## item: 假定总是有效
func get_item_occupy_slot(item: Node) -> Array[int]:
	if not item: return []
	var index = item.data.slot_index
	if not canfine(item.data.dimensions, index): return [] # 越界
	
	var item_slot : Array[int]
	for y in range(item.data.dimensions.y):
		for x in range(item.data.dimensions.x):
			var slot_index = index + x + y * dimensions.x
			item_slot.append(slot_index)
	return item_slot

## 为物品寻找并分配一个合适的位置
## item: 要放置的物品节点
func attempt_to_place_item(item: Node, index: int = -1) -> int:
	if item == null or item.data == null: # 非空
		return -1
	if not Goods.is_dimensions(item.data.dimensions):
		return -1
	if index != -1: # 检查指定索引槽位
		if item_is_fits(item, index):
			# 写入占用数据
			add_item_to_slot_data(item, index)
			return index
	else:
		# 扫描所有槽位，寻找可以放置的位置
		for slot_index in range(slot_data.size()):
			if item_is_fits(item, slot_index):
				# 写入占用数据
				add_item_to_slot_data(item, slot_index)
				return slot_index
	return -1

## 容器边界检查
func canfine(item_dimensions: Vector2i, index: int) -> bool:
	# 边界越界: X
	if index % dimensions.x + item_dimensions.x > dimensions.x:
		return false
	# 边界越界: Y
	if floor(float(index) / dimensions.x) + item_dimensions.y > dimensions.y:
		return false
	return true

## 检查物品是否能放入指定位置
func item_is_fits(item: Node, index: int) -> bool:
	if index < 0 or index >= slot_data.size():
		return false
	# 物品占用
	var item_slot_array = get_item_index_occupy_slot(item, index)
	if item_slot_array.is_empty(): return false
	for item_slot_index in item_slot_array:
		if slot_data[item_slot_index] != null:
			return false
	return true

## 获取: 坐标 > 槽位索引
func get_slot_index_from_coords(coords: Vector2) -> int:
	var local := coords - global_position
	if local.x < 0 or local.y < 0 or local.x > size.x or local.y > size.y:
		return -1
	local /= Global.SLOT_SIZE
	var index := int(local.x) + int(local.y) * dimensions.x
	if index < 0 or index >= slot_data.size():
		return -1
	return index

## 获取: 槽位索引 > 坐标
func get_coords_from_slot_index(index: int) -> Vector2:
	var row :int = index % dimensions.x # 行
	var column :int = floor(float(index) / dimensions.x) # 列
	return global_position + Vector2(row * Global.SLOT_SIZE, column * Global.SLOT_SIZE)

## 坐标是否在指定范围
func has_point(_position: Vector2) -> bool:
	var global_rect = Rect2(global_position, size + global_position)
	return global_rect.has_point(_position)

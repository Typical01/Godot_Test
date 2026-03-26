extends GridContainer

@export var inventory_slot_scene: PackedScene
@export var dimensions: Vector2i

@export var slot_data: Array[Node] = []
var drag_original_item: Node = null
var drag_original_slot: int = -1
var selected_item = null
var held_item = null
var held_start_position: Vector2
@onready var input_recognizer = %InputRecognizer

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	input_recognizer.single_click.connect(_on_single_click)
	input_recognizer.double_click.connect(_on_double_click)
	input_recognizer.long_press_start.connect(_on_long_press_start)
	input_recognizer.long_press_end.connect(_on_long_press_end)
	input_recognizer.drag_start.connect(_on_drag_start)
	input_recognizer.drag.connect(_on_drag_move)
	input_recognizer.drag_end.connect(_on_drag_end)
	
	# 初始化物品网格
	add_theme_constant_override("v_separation", Global.V_SEPARATION)
	global_position -= Vector2(Global.SLOT_SCALE * 2, Global.SLOT_SCALE * 2)
	
	create_slot()
	init_slot_data()

# ==============================
# 输入事件（点击/拖拽）
# ==============================

func _on_single_click(position: Vector2):
	pass # 不处理

func _on_double_click(position: Vector2):
	pass # 不处理

func _on_long_press_start(position: Vector2):
	var slot_index = get_slot_index_from_coords(position)
	selected_item = slot_data.get(slot_index)
	if selected_item:
		selected_item.modulate = Color(0.8, 0.8, 1.0, 0.9) # 高亮

func _on_long_press_end(position: Vector2):
	if selected_item:
		selected_item.modulate = Color.WHITE
		selected_item = null

func _on_drag_start(position: Vector2):
	held_start_position = position
	if selected_item:
		start_dragging_item(selected_item, position)
		selected_item = null
	else:
		var slot_index = get_slot_index_from_coords(position)
		var item = slot_data.get(slot_index)
		if item:
			start_dragging_item(item, position)

func _on_drag_move(position: Vector2):
	if held_item:
		held_item.global_position = position - held_item.drag_offset

func _on_drag_end(position: Vector2):
	if held_item:
		try_place_item(position)
		held_item = null

# ==============================
# 拖拽物品核心逻辑
# ==============================

func start_dragging_item(item, start_position: Vector2):
	if item == null:
		push_error("start_dragging_item: item is null")
		return

	print("开始拖拽物品: ", item.data.name)

	# 记录原物品和原槽位
	drag_original_item = item
	drag_original_slot = get_slot_index_from_coords(item.global_position)

	# 隐藏原物品
	item.visible = false

	# 创建拖拽副本
	held_item = item.duplicate()
	add_child(held_item)
	held_item.get_picked_up()
	held_item.add_to_group("held_item")
	held_item.drag_offset = held_item.size / 2 if held_item.data else Vector2.ZERO
	held_item.global_position = start_position - held_item.drag_offset
	held_item.anchor_point = start_position
	held_item.z_index = 10

func try_place_item(position: Vector2):
	if held_item == null:
		return

	var offset := Vector2(Global.SLOT_SIZE, Global.SLOT_SIZE) / 2
	var target_index := get_slot_index_from_coords(held_item.anchor_point + offset)

	if target_index < 0 or not can_place_item_at_slot(held_item, target_index):
		# 放置失败 -> 回原位置
		if drag_original_item and drag_original_slot >= 0:
			drag_original_item.visible = true
			drag_original_item.get_placed(get_coords_from_slot_index(drag_original_slot))
			add_item_to_slot_data(drag_original_slot, drag_original_item)
		held_item.get_parent().remove_child(held_item)
		held_item.queue_free()
		held_item = null
		drag_original_item = null
		drag_original_slot = -1
		return

	# 可以放置 -> 更新槽位
	var occupied_slots = get_occupied_slots(held_item, target_index)
	for s in occupied_slots:
		slot_data[s] = held_item
	held_item.get_placed(get_coords_from_slot_index(target_index))
	held_item.z_index = 1
	held_item.remove_from_group("held_item")

	# 删除原物品
	if drag_original_item:
		drag_original_item.queue_free()
	drag_original_item = null
	drag_original_slot = -1
	held_item = null


# ==============================
# 辅助函数
# ==============================

func return_item_to_original_slot():
	if drag_original_item == null:
		push_warning("return_item_to_original_slot: no original item")
		return

	# 回退到原始槽位
	if drag_original_slot >= 0:
		drag_original_item.visible = true
		drag_original_item.get_placed(get_coords_from_slot_index(drag_original_slot))
		add_item_to_slot_data(drag_original_slot, drag_original_item)
		drag_original_item.z_index = 1
		drag_original_item.remove_from_group("held_item")

	# 清理拖拽变量
	drag_original_item = null
	drag_original_slot = -1
	if held_item:
		held_item.get_parent().remove_child(held_item)
		held_item.queue_free()
		held_item = null

## 将物品占用的数据写入 slot_data（不处理 UI） 
func add_item_to_slot_data(index: int, item: Node) -> void: 
	for y in item.data.dimensions.y: 
		for x in item.data.dimensions.x: 
			var slot_index = index + x + y * columns # 边界保护（防止非法 index 写入） 
			if slot_index < 0 or slot_index >= slot_data.size(): 
				continue
			slot_data[slot_index] = item

# 移除物品槽位数据（不记录 original_slot）
func remove_item_from_slot_data(item):
	if item == null:
		return
	for slot_index in range(slot_data.size()):
		if slot_data[slot_index] == item:
			slot_data[slot_index] = null
	item.remove_from_group("held_item")

## 为物品寻找并分配一个合适的位置
## item: 要放置的物品节点（需要 data.dimensions）
## 返回 bool：放置成功或失败
func attempt_to_place_item(item: Node) -> bool:
	if item == null or item.data == null:
		return false
	var dims: Vector2i = item.data.dimensions
	if dims.x <= 0 or dims.y <= 0:
		return false

	# 扫描所有槽位，寻找可以放置的位置
	for slot_index in range(slot_data.size()):
		if item_fits(slot_index, dims):
			# 写入占用数据
			add_item_to_slot_data(slot_index, item)
			# 设置 UI 初始位置（左上角）
			item.get_placed(get_coords_from_slot_index(slot_index))
			return true

	# 没找到可放位置
	return false

## 检查物品是否能放入指定位置
## index: 物品左上角的槽位索引
## dimensions: 物品尺寸（宽 × 高）
func item_fits(index: int, dimensions: Vector2i) -> bool:
	for y in range(dimensions.y):
		for x in range(dimensions.x):
			var current_index := index + x + y * columns
			# 检查是否越界
			if current_index < 0 or current_index >= slot_data.size():
				return false
			# 检查是否被占用
			if slot_data[current_index] != null:
				return false
			# 防止跨行（关键：必须使用整除）
			if (index / columns) != ((index + x) / columns):
				return false
	return true

func can_place_item_at_slot(item: Node, slot_index: int) -> bool:
	if item == null or item.data == null:
		return false
	for y in range(item.data.dimensions.y):
		for x in range(item.data.dimensions.x):
			var check_index := slot_index + x + y * columns
			# 超出边界
			if check_index < 0 or check_index >= slot_data.size():
				return false
			# 槽被占用且不是自己
			if slot_data[check_index] != null and slot_data[check_index] != item:
				return false
	return true

func get_occupied_slots(item: Node, base_index: int) -> Array[int]:
	var slots: Array[int] = []
	if item == null or item.data == null:
		return slots
	for y in range(item.data.dimensions.y):
		for x in range(item.data.dimensions.x):
			var idx := base_index + x + y * columns
			if idx >= 0 and idx < slot_data.size():
				slots.append(idx)
	return slots

func items_in_area(index: int, item_dimensions: Vector2i) -> Array:
	var items: Dictionary = {}
	for y in range(item_dimensions.y):
		for x in range(item_dimensions.x):
			var slot_index := index + x + y * columns
			if slot_index < 0 or slot_index >= slot_data.size():
				continue
			var item := slot_data[slot_index]
			if item != null:
				items[item] = true
	return items.keys()

func get_slot_index_from_coords(coords: Vector2) -> int:
	var local := coords - self.global_position
	if local.x < 0 or local.y < 0:
		return -1
	local /= Global.SLOT_SIZE
	var index := int(local.x) + int(local.y) * columns
	if index < 0 or index >= slot_data.size():
		return -1
	return index

func get_coords_from_slot_index(index: int) -> Vector2:
	var row := index / columns
	var column := index % columns
	return self.global_position + Vector2(column * Global.SLOT_SIZE, row * Global.SLOT_SIZE)

func create_slot() -> void:
	self.columns = dimensions.x
	for y in dimensions.y:
		for x in dimensions.x:
			var inventory_slot = inventory_slot_scene.instantiate()
			inventory_slot.scale = Vector2(Global.SLOT_SCALE, Global.SLOT_SCALE)
			add_child(inventory_slot)

func init_slot_data() -> void:
	slot_data.resize(dimensions.x * dimensions.y)
	slot_data.fill(null)

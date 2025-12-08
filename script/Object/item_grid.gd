extends GridContainer



@export var inventory_slot_scene: PackedScene
@export var dimensions: Vector2i


@export var slot_data: Array[Node] = []
var held_item_intersects: bool = false



# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#初始化物品网格
	add_theme_constant_override("h_separation", Global.H_SEPARATION)    # 水平间隔设为0
	add_theme_constant_override("v_separation", Global.V_SEPARATION)    # 垂直间隔设为0
	global_position -= Vector2(Global.SLOT_SCALE * 2, Global.SLOT_SCALE * 2)
	
	create_slot()
	init_slot_data()
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT && event.is_pressed():
			var held_item = get_tree().get_first_node_in_group("held_item")
			if !held_item:
				var index = get_slot_index_from_coords(get_global_mouse_position())
				#print(index, get_coords_from_slot_index(index))
				var slot_index = get_slot_index_from_coords(get_global_mouse_position())
				var item = slot_data[slot_index]
				if !item:
					return
				if item.get_picked_up():
					remove_item_from_slot_data(item)
			else:
				if !held_item_intersects:
					return
				var offset = Vector2(Global.SLOT_SIZE, Global.SLOT_SIZE) / 2
				var index = get_slot_index_from_coords(held_item.anchor_point + offset)
				var items = items_in_area(index, held_item.data.dimensions)
				if items:
					if items.size() == 1:
						held_item.get_placed(get_coords_from_slot_index(index))
						remove_item_from_slot_data(items[0])
						add_item_to_slot_data(index, held_item)
						items[0].get_picked_up()
					return
				held_item.get_placed(get_coords_from_slot_index(index))
				add_item_to_slot_data(index, held_item)
	if event is InputEventMouseMotion:
		var held_item = get_tree().get_first_node_in_group("held_item")
		if held_item:
			detect_held_item_intersection(held_item)

func detect_held_item_intersection(held_item: Node) -> void:
	var h_rect = Rect2(held_item.anchor_point, held_item.size)
	var g_rect = Rect2(global_position, size)
	var inter = h_rect.intersection(g_rect).size
	held_item_intersects = (inter.x * inter.y) / (held_item.size.x * held_item.size.y) > 0.8

func remove_item_from_slot_data(item: Node) -> void:
	for i in slot_data.size():
		if slot_data[i] == item:
			slot_data[i] = null

func add_item_to_slot_data(index: int, item: Node) -> void:
	for y in item.data.dimensions.y:
		for x in item.data.dimensions.x:
			var slot_index = index + x + y * columns
			slot_data[slot_index] = item
			
##获取指定区域内所有不重复的物品
## index: 区域左上角的起始格子索引
## item_dimensions: 区域的尺寸（宽×高）
func items_in_area(index: int, item_dimensions: Vector2i) -> Array:
	# 使用字典来确保物品不重复（字典键唯一）
	var items: Dictionary = {}
	# 遍历区域内的每一行
	for y in item_dimensions.y:
		# 遍历区域内的每一列
		for x in item_dimensions.x:
			# 计算当前格子在一维数组中的实际索引
			var slot_index = index + x + y * columns
			# 边界检查
			if slot_index < 0 or slot_index >= slot_data.size():
				continue
			# 获取该格子上的物品（可能为null）
			var item = slot_data[slot_index]
			# 如果格子为空，跳过
			if !item:
				continue
			# 如果字典中还没有这个物品，添加它
			if !items.has(item):
				items[item] = true  # 值true是占位符，我们只关心键
	# 如果有找到物品，返回字典的所有键（即物品数组）
	# 否则返回空数组
	return items.keys() if items.size() else []

func create_slot() -> void:
	self.columns = dimensions.y
	for y in dimensions.y:
		for x in dimensions.x:
			var inventory_slot = inventory_slot_scene.instantiate()
			inventory_slot.scale = Vector2(Global.SLOT_SCALE, Global.SLOT_SCALE)
			add_child(inventory_slot)
	pass

func init_slot_data() -> void:
	slot_data.resize(dimensions.x * dimensions.y)
	slot_data.fill(null)
	pass

##为物品寻找并分配一个合适位置
## item: 要放置的物品节点，假设有 data.dimensions 属性
func attempt_to_place_item(item: Node) -> bool:  # 修正了函数名
	var slot_index: int = 0
	# 1. 扫描寻找第一个合适的位置
	while slot_index < slot_data.size():
		# 检查当前位置是否能放下物品
		if item_fits(slot_index, item.data.dimensions):
			break  # 找到合适位置，跳出循环
		slot_index += 1
	# 2. 检查是否找到了位置
	if slot_index >= slot_data.size():
		return false  # 遍历完所有位置都没找到，放置失败
	# 3. 放置物品到找到的位置
	for y in item.data.dimensions.y:
		for x in item.data.dimensions.x:
			# 计算每个格子的索引并标记为被该物品占用
			slot_data[slot_index + x + y * columns] = item
	# 4. 设置物品的初始位置（用于UI显示）
	item.set_init_position(get_coords_from_slot_index(slot_index))
	return true  # 放置成功
		
##检查物品是否能放入指定位置
## index: 物品左上角要放置的格子索引（一维数组索引）
## dimensions: 物品的尺寸（宽×高）
func item_fits(index: int, dimensions: Vector2i) -> bool:
	# 遍历物品占用的每一行（y方向）
	for y in dimensions.y:
		# 遍历物品占用的每一列（x方向）
		for x in dimensions.x:
			# 计算当前格子在一维数组中的实际索引
			var current_index = index + x + y * columns
			# 检查1: 是否超出容器边界
			if current_index >= slot_data.size():
				return false  # 超出边界，放不下
			# 检查2: 格子是否已被占用
			if slot_data[current_index] != null:
				return false  # 格子有东西，放不下
			# 检查3: 是否跨行（防止物品在行尾被分割）
			var split = index / columns != (index + x) / columns
			if split:
				return false  # 物品跨越了行边界，不允许
	# 所有检查都通过，物品可以放置
	return true

##从坐标获取槽位索引
func get_slot_index_from_coords(coords: Vector2i) -> int:
	coords -= Vector2i(self.global_position)
	coords /= Global.SLOT_SIZE
	var index = coords.x + coords.y * columns
	if index > dimensions.x * dimensions.y || index < 0:
		return -1
	return index

##从槽位索引获取坐标
func get_coords_from_slot_index(index: int) -> Vector2i:
	var row = index / columns
	var column = index % columns
	return Vector2i(global_position) + Vector2i(column * Global.SLOT_SIZE, row * Global.SLOT_SIZE)

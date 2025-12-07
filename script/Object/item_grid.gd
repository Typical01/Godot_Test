extends GridContainer



@export var inventory_slot_scene: PackedScene
@export var dimentions: Vector2i


@export var slot_data: Array[Node] = []
var held_item_intersects: bool = false



# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("网格: ", position)
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
				print(index, get_coords_from_slot_index(index))
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
				var items = items_in_area(index, held_item.data.dimentions)
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
	for y in item.data.dimentions.y:
		for x in item.data.dimentions.x:
			var slot_index = index + x + y * columns
			slot_data[slot_index] = item

func items_in_area(index: int, item_dimentions: Vector2i) -> Array:
	var items: Dictionary = {}
	for y in item_dimentions.y:
		for x in item_dimentions.x:
			var slot_index = index + x + y * columns
			var item = slot_data[slot_index]
			if !item:
				continue
			if !items.has(item):
				items[item] = true
	return items.keys() if items.size() else []

func create_slot() -> void:
	self.columns = dimentions.y
	for y in dimentions.y:
		for x in dimentions.x:
			var inventory_slot = inventory_slot_scene.instantiate()
			inventory_slot.scale = Vector2(Global.SLOT_SCALE, Global.SLOT_SCALE)
			add_child(inventory_slot)
			print("物品网格: ", inventory_slot.position)
	pass

func init_slot_data() -> void:
	slot_data.resize(dimentions.x * dimentions.y)
	slot_data.fill(null)
	pass

##尝试获取项目数据
func attemp_to_item_data(item: Node) -> bool:
	var slot_index: int = 0
	while slot_index < slot_data.size():
		if item_fits(slot_index, item.data.dimentions):
			break
		slot_index += 1
	if slot_index >= slot_data.size():
		return false
		
	for y in item.data.dimentions.y:
		for x in item.data.dimentions.x:
			slot_data[slot_index + x + y * columns] = item
			
	item.set_init_position(get_coords_from_slot_index(slot_index))
	return true
		
func item_fits(index: int, dimentions: Vector2i) -> bool:
	for y in dimentions.y:
		for x in dimentions.x:
			var current_index = index + x + y * columns
			if current_index >= slot_data.size():
				return false
			if slot_data[current_index] != null:
				return false
			var split = index / columns != (index + x) / columns
			if split:
				return false
	return true

##从坐标获取槽位索引
func get_slot_index_from_coords(coords: Vector2i) -> int:
	coords -= Vector2i(self.global_position)
	coords /= Global.SLOT_SIZE
	var index = coords.x + coords.y * columns
	if index > dimentions.x * dimentions.y || index < 0:
		return -1
	#print(coords)
	return index

##从槽位索引获取坐标
func get_coords_from_slot_index(index: int) -> Vector2i:
	var row = index / columns
	var column = index % columns
	return Vector2i(global_position) + Vector2i(column * Global.SLOT_SIZE, row * Global.SLOT_SIZE)

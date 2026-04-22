extends GridContainer


@export var inventory_slot_scene: PackedScene ## 容器格子


func _ready() -> void:
	# 初始化物品网格
	add_theme_constant_override("v_separation", Global.V_SEPARATION)
	add_theme_constant_override("h_separation", Global.H_SEPARATION)
	#global_position -= Vector2(Global.SLOT_SCALE * 2, Global.SLOT_SCALE * 2)

## 创建: 槽位
func create_slot(dimensions: Vector2i) -> void:
	columns = dimensions.x
	for y in dimensions.y:
		for x in dimensions.x:
			var inventory_slot = inventory_slot_scene.instantiate()
			inventory_slot.scale = Vector2(Global.SLOT_SCALE, Global.SLOT_SCALE)
			add_child(inventory_slot)
	#size.x = dimensions.x * Global.SLOT_SIZE
	#size.y = dimensions.y * Global.SLOT_SIZE
	#print("ItemGrid: size: ", size)

func _on_item_inventory_ready() -> void:
	#创建槽位
	create_slot(get_parent().dimensions)

## 坐标是否在指定范围
func has_point(_position: Vector2) -> bool:
	var global_rect = Rect2(global_position, size)
	return global_rect.has_point(_position)

func _get_drag_data(at_position: Vector2) -> Variant:
	return null

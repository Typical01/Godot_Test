extends GridContainer


@export var inventory_slot_scene: PackedScene ## 容器格子

func _ready() -> void:
	add_theme_constant_override("v_separation", Global.V_SEPARATION)
	add_theme_constant_override("h_separation", Global.H_SEPARATION)

## 创建: 槽位
func create_slot(dimensions: Vector2i) -> void:
	columns = dimensions.x
	for y in dimensions.y:
		for x in dimensions.x:
			var inventory_slot = inventory_slot_scene.instantiate()
			inventory_slot.scale = Vector2(Global.SLOT_SCALE, Global.SLOT_SCALE)
			add_child(inventory_slot)

func _on_item_inventory_ready() -> void:
	create_slot(get_parent().dimensions)

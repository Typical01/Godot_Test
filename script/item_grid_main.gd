extends CanvasLayer

@onready var goods_store_node: GoodsGrid = %GoodsStore
@onready var show_store_node = %ShowStore

@export var is_search = false
@export var search_count = 50

var last_position = Vector2()

func _ready() -> void:
	#goods_container_manage.show_container(false)
	goods_container_manage.show_search_container.connect(_on_show_search_container)
	pass

func _on_show_search_container():
	%GoodsContainer.visible = true

func _on_sell_button_up() -> void:
	if %GoodsContainer.sells(goods_container_manage.add_value):
		%GoodsContainer.visible = false

func _on_show_store_button_up() -> void:
	var tween = create_tween()
	if show_store_node.rotation_degrees == 90.0: # 显示
		show_store_node.rotation_degrees = -90.0
		tween.tween_property(goods_store_node, "position:x", goods_store_node.position.x - goods_store_node.size.x, 0.5)
	else: # 隐藏
		show_store_node.rotation_degrees = 90.0
		tween.tween_property(goods_store_node, "position:x", goods_store_node.position.x + goods_store_node.size.x, 0.5)

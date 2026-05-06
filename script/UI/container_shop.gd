extends Control


signal buy_container(container_name)



@onready var shop_list_node = %ShopList

@export var buy_container_scene: PackedScene



func _ready() -> void:
	init()

func init() -> void:
	var reward_data = RewardPool.get_reward_data()
	if reward_data.is_empty():
		push_error("reward_data == null!")
		return
	for i in reward_data.size():
		var goods_container_data = reward_data[i]
		if not goods_container_data:
			push_error("goods_container_data == null!")
			continue
		if goods_container_data is not GoodsContainer:
			push_error("goods_container_data != GoodsContainer!")
			continue
		add_item(goods_container_data)

func add_item(containers: GoodsContainer) -> void:
	if not containers: return
	var new_buy_button = buy_container_scene.instantiate()
	new_buy_button.container_name = containers.name
	new_buy_button.container_value = GoodsContainer.quality_to_value(containers.quality)
	new_buy_button.text = "%s [%s]" % [new_buy_button.container_name, new_buy_button.container_value]
	new_buy_button.icon = containers.texture
	new_buy_button.add_theme_constant_override("icon_max_width", 64)
	new_buy_button.visible = true
	new_buy_button.buy_container.connect(on_buy_container)
	shop_list_node.add_child(new_buy_button)

func on_buy_container(containers_name, container_value):
	buy_container.emit(containers_name, container_value)

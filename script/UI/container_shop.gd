extends Control



@onready var shop_list_node = $PanelContainer/ScrollContainer/ShopList
@onready var goods_container_node = $SeekRect/GoodsContainer
@onready var buy_container_node = $PanelContainer/ScrollContainer/ShopList/BuyContainer
@onready var seek_rect_node = $SeekRect
@onready var panel_node = $Panel
@onready var popup_tips_node = $PopupTips
@onready var thrower_node: Thrower = $Panel/Thrower

@export var buy_container_scene: PackedScene
var searching: bool = false



func _ready() -> void:
	init()
	pass

func init() -> void:
	var container_probabilitys = Global.goods_container_reward_pool.container_probabilitys
	for key in container_probabilitys.keys():
		var new_buy_container_button: BuyContainerButton = buy_container_node.duplicate()
		new_buy_container_button.is_can_open = false
		new_buy_container_button.visible = true
		new_buy_container_button.text = "%s[%s]" % [key, Goods.format_number_with_commas(GoodsContainer.quality_to_value(GoodsContainer.string_to_type(key)))]
		new_buy_container_button.container_name = key
		new_buy_container_button.buy_container.connect(on_buy_container)
		shop_list_node.add_child(new_buy_container_button)

func on_open_container(container_name: String, is_open: bool):
	if not is_open:
		popup_tips_node.item_name = "请先清空容器!"
		popup_tips_node._on_show_tips(true, self)

func on_buy_container(container_name: String):
	if searching: return
	if not goods_container_manage.del_value(
	GoodsContainer.quality_to_value(GoodsContainer.string_to_type(container_name))):
		popup_tips_node.item_name = "没钱不要硬玩!"
		popup_tips_node._on_show_tips(true, self)
		return
	searching = true
	panel_node.self_modulate.a = 0.5
	seek_rect_node.visible = true
	
	var goods_container_reward_pool: RewardPool = Global.goods_container_reward_pool.get_reward_pool(container_name)
	OverlayStateMonitor.push_overlay(container_name, goods_container_reward_pool.probabilitys_data)
	var number = clampi(randi() % 8, 4, 8)
	for i in number:
		var goods_container: GoodsContainer = goods_container_reward_pool.allocate_single_reward()
		var new_goods_container_button: BuyContainerButton = goods_container_node.duplicate()
		new_goods_container_button.is_can_open = true
		new_goods_container_button.container_name = goods_container.name
		new_goods_container_button.icon = goods_container.texture
		new_goods_container_button.visible = true
		var tween = create_tween()
		new_goods_container_button.global_position.x = seek_rect_node.global_position.x + seek_rect_node.size.x
		#new_goods_container_button.position.y = panel_node.position.y
		new_goods_container_button.open_container.connect(on_open_container)
		var flyable = FlyableComponent.new()
		new_goods_container_button.add_child(flyable)
		panel_node.add_child(new_goods_container_button)
		tween.tween_property(new_goods_container_button, "global_position:x", seek_rect_node.global_position.x, 0.05)
		await get_tree().create_timer(0.05).timeout
		thrower_node.throw_target(new_goods_container_button)
	
	panel_node.self_modulate.a = 0.0
	seek_rect_node.visible = false
	searching = false

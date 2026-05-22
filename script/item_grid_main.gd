extends Control

var current_inventory = null
var current_item = null
@export var is_search = false
@export var search_count = 50

func _ready() -> void:
	%LabelValue.text = str(Global.game_config.get("货币", -1.0))

func _on_sell_button_up() -> void:
	if not current_item or not current_inventory: 
		%Info.show_info(false)
		return
	add_value(current_item.data.value)
	current_inventory.remove_item(current_item)
	%Info.show_info(false)

func _on_search_button_up() -> void:
	#%GoodsContainer.get_search_items(is_search, search_count)
	pass

func _on_search_2_button_up() -> void:
	%GoodsContainer.sells(sell, move_to)

func _on_item_inventory_select(self_node, item: Node) -> void:
	current_inventory = self_node
	current_item = item
	%Info.show_info(true, item.data)

func sell(data) -> void:
	add_value(data.value)

func move_to(data) -> void:
	%GoodsStore.add_item(data)

func save_goods_data(goods_names):
	Global.game_config["仓库"] = goods_names

func _on_goods_store_save(_self_node: Variant) -> void:
	%GoodsStore.save_goods_data(save_goods_data)
	
func add_value(number: int) -> void:
	%LabelValue.text = str(%LabelValue.text.to_int() + number)
	Global.game_config["货币"] = %LabelValue.text.to_int()

func del_value(number: int) -> bool:
	var current_value = %LabelValue.text.to_int()
	if max(current_value, number) != current_value:
		return false
	%LabelValue.text = str(current_value - number)
	Global.game_config["货币"] = current_value - number
	return true

func _on_item_inventory_cancel(_self_node: Variant) -> void:
	%Info.show_info(false)

func _on_item_inventory_move(_self_node: Variant, _item: Node) -> void:
	%Info.show_info(false)
	print(_self_node.slot_data)

func _on_control_buy_container(container_name: Variant, container_value) -> void:
	#print(container_name, container_value)
	if %GoodsContainer.searching: return
	if del_value(container_value):
		%GoodsContainer.get_search_items(container_name, is_search)
	else:
		%PopupTips._on_show_tips(true, self)

extends Node

var current_inventory = null
var current_item = null
@export var is_search = false

func _on_sell_button_up() -> void:
	if not current_item or not current_inventory: 
		%Info.show_info(false)
		return
	value_change(current_item.data.value)
	current_inventory.remove_item(current_item)
	%Info.show_info(false)

func _on_search_button_up() -> void:
	%GoodsContainer.get_search_items(50, is_search)

func _on_search_2_button_up() -> void:
	%GoodsContainer.clear(self.sell)

func _on_item_inventory_select(self_node, item: Node) -> void:
	current_inventory = self_node
	current_item = item
	%Info.show_info(true, item.data)

func _ready() -> void:
	%LabelValue.text = str(Global.game_config.get("货币", -1.0))

func sell(data) -> void:
	if not data:
		return
	value_change(data.value)

func value_change(number: int) -> void:
	#print("货币: ", number)
	%LabelValue.text = str(%LabelValue.text.to_int() + number)
	Global.game_config["货币"] = %LabelValue.text.to_int()

func _on_item_inventory_cancel(_self_node: Variant) -> void:
	%Info.show_info(false)

func _on_item_inventory_move(_self_node: Variant, _item: Node) -> void:
	%Info.show_info(false)
	print(_self_node.slot_data)

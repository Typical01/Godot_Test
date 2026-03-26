extends Node

var current_item = null
@export var is_search = false

func _on_sell_button_up() -> void:
	if not current_item: 
		%Info.show_info(false)
		return
	value_change(current_item.data.value)
	%ItemInventory.remove_item(current_item)
	%Info.visible = false

func _on_search_button_up() -> void:
	%ItemInventory.get_search_items(4, is_search)

func _on_search_2_button_up() -> void:
	%ItemInventory.clear()

func _on_item_inventory_select(item: Node) -> void:
	current_item = item
	%Info.show_info(true, item.data)

func _ready() -> void:
	%LabelValue.text = str(Global.game_config.get("货币", -1.0))

func value_change(number: int) -> void:
	print("货币: ", number)
	%LabelValue.text = str(%LabelValue.text.to_int() + number)
	Global.game_config["货币"] = %LabelValue.text.to_int()

func _on_item_inventory_cancel() -> void:
	%Info.show_info(false)

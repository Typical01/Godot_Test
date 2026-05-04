# res://script/log.gd
class_name CustomLoggers extends Node

var log_impl

func _ready() -> void:
	# 创建 Logger 实例
	log_impl = CustomLoggersImpl.new()
	# 注册到引擎
	OS.add_logger(log_impl)


## scene_node: get_tree()
## : var dialog = AcceptDialog.new()
func tips_accept_dialog(scene_node: Node, title: String, error_code: String, dialog := AcceptDialog.new(), confirmed_func := Callable(), close_requested_func := Callable()):
	dialog.title = title
	dialog.dialog_text = error_code
	dialog.initial_position = Window.WINDOW_INITIAL_POSITION_CENTER_MAIN_WINDOW_SCREEN
	scene_node.get_tree().root.add_child.call_deferred(dialog)
	await dialog.tree_entered
	dialog.popup_centered()
	if confirmed_func.is_valid(): dialog.confirmed.connect(confirmed_func)
	if close_requested_func.is_valid(): dialog.close_requested.connect(close_requested_func)

extends CanvasLayer


@onready var panle_node:
	get():
		return $Panel
@onready var grid_container_node:
	get():
		return $Panel/GridContainer
@onready var label_node:
	get():
		return $Label
@onready var timer_node:
	get():
		return $Timer

@export var is_performance: bool = true
@export var is_editor: bool = true#OS.has_feature("editor")
var monitors: Dictionary = {}


func _ready() -> void:
	if not is_editor: 
		timer_node.stop()
		visible = false
	_update_performance()
	layer = 100
	print("OverlayStateMonitor 启动.")

func set_columns(_columns: int = 1):
	grid_container_node.columns = _columns

func set_background(is_show: bool = true):
	panle_node.self_modulate = Color.WHITE if is_show else Color.TRANSPARENT

func push_overlay(monitor_name: String, value = null, color := Color.WHITE) -> void:
	if not is_editor: return
	if not monitors.has(monitor_name):
		_add_item(monitor_name)
	var label = monitors[monitor_name]
	if value != null:
		label.text = "%s: %s" % [monitor_name, value]
	else:
		label.text = "%s" % [monitor_name]
	label.self_modulate = color

func _update_performance() -> void:
	if not is_editor: return
	if not is_performance:
		return
	push_overlay(" ", "")
	push_overlay("性能", "")
	push_overlay("    FPS", "[%.1f]" % [Engine.get_frames_per_second()])
	push_overlay("    CPU时间", "[%.2f ms]" % [Performance.get_monitor(Performance.TIME_PROCESS) * 1000]) # 微秒 转 毫秒
	push_overlay("    内存", "[%.1f MB]" % [Performance.get_monitor(Performance.MEMORY_STATIC) / 1024.0]) # KB 转 MB
	push_overlay("", "")

func _add_item(monitor_name: String) -> void:
	var label = label_node.duplicate()
	label.visible = true
	grid_container_node.add_child(label)
	monitors[monitor_name] = label

func _del_item(monitor_name: String) -> void:
	if not monitors.has(monitor_name):
		monitors.erase(monitor_name)
		monitors[monitor_name].queue_free()

func clear() -> void:
	for label in monitors.values():
		label.queue_free()
	monitors.clear()

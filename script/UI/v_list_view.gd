extends ScrollContainer



## ============================ 数据刷新 =============================
signal on_refresh_requested() ## 强制刷新
signal on_items_changed(start_index: int, count: int) ## 条目范围变化
signal on_entry_updated(index: int, control, data) ## 条目刷新
signal on_visible_range_changed(first: int, last: int) ## 可见范围变化
signal on_scroll_completed()

## ============================ 数据加载 =============================
signal on_load_more_requested()
signal on_data_fill() ## 数据填充
signal on_entry_connect_callback(control) ## 条目连接回调
signal on_entry_disconnect_callback(control) ## 条目断开回调
signal on_data_ready(start_index: int, items)

## ============================ 条目生命周期 =============================
signal on_entry_created(control, template_type)
signal on_entry_recycled(control, index: int) ## 回收条目
signal on_entry_destroyed(control)



## ============================ 变量 =============================
@onready var item_container = %ItemContainer

@export var node_scene_template: PackedScene = null ## 节点模板

var _last_visible_first = 0 ## 最后显示范围: 开始索引
var _last_visible_last = 0 ## 最后显示范围: 结束索引

@export var columns: int = 1 ## 列数
@export var item_width: int = 200 ## 项: 宽度
@export var item_height: int = 40 ## 项: 高度
@export var buffer_rows: int = 2 ## 缓冲: 行数

var v_scroll_bar ## 垂直滚动条: 引用
var data = [] ## 数据
var node_pool = [] ## 节点池
var node_pool_size = 0 ## 节点池大小 = (可见列数 + 缓冲行数 * 2) * 列数


## ============================ 基础函数 =============================
func _ready() -> void:
	v_scroll_bar = get_v_scroll_bar()
	
	# 创建节点池
	custom_minimum_size.x = item_width * columns + 10
	v_scroll_bar.value_changed.connect(_update_visible_items)
	
	# 数据初始化
	on_data_fill.emit()
	
	# 连接信号并刷新UI
	call_deferred("_update_node_pool_size")
	call_deferred("_setup_scroll_range")
	call_deferred("_update_visible_items")

func _on_resized() -> void:
	custom_minimum_size.x = item_width * columns + 10
	call_deferred("_update_node_pool_size")
	call_deferred("_update_visible_items")

## 设置节点模板
func set_template(scene:  PackedScene):
	node_scene_template = scene
	_update_node_pool_size()
	_setup_scroll_range()
	_update_visible_items()

## 刷新节点池大小
func _update_node_pool_size():
	if not item_container:
		return
	
	var node_size = node_scene_template.instantiate()
	if node_size.custom_minimum_size.x == 0:
		node_size.custom_minimum_size.x = item_width
	if node_size.custom_minimum_size.y == 0:
		node_size.custom_minimum_size.y = item_height
	item_width = node_size.custom_minimum_size.x
	item_height = node_size.custom_minimum_size.y
	node_size.queue_free()
	var visible_rows = int(size.y /item_height) + 1
	
	node_pool_size = (visible_rows + buffer_rows * 2) * columns
	if node_pool_size == node_pool.size():
		return # 大小合适，不需要重建
	
	if node_pool_size > node_pool.size():
		# 添加新节点
		for i in range(node_pool_size - node_pool.size()):
			if node_scene_template == null:
				push_error("VListView: node_scene_template == null!")
			else:
				var node = node_scene_template.instantiate()
				node.custom_minimum_size = Vector2(item_width, item_height)
				node_pool.append(node)
				item_container.add_child(node)
				on_entry_connect_callback.emit(node)  # 新节点连接信号
	else:
		# 移除多余节点（注意：要断开信号）
		while node_pool.size() > node_pool_size:
			var node = node_pool.pop_back()
			on_entry_disconnect_callback.emit(node)  # 旧节点断开信号
			node.queue_free()
	node_pool_size = node_pool.size()
	print("VListView: node_pool_size: (%s)" % [node_pool_size])

## 设置滚动范围
func _setup_scroll_range():
	var total_rows = ceil(data.size() / float(columns))
	item_container.custom_minimum_size = Vector2(item_width, total_rows * item_height)

## 刷新可见项
func _update_visible_items(scroll_y = 0):
	scroll_y = v_scroll_bar.value
	
	# 计算可见范围(带缓冲)
	var first_row = max(0, int(scroll_y / item_height) - buffer_rows)
	var first_index = first_row * columns
	var visible_rows = int(size.y / item_height) + 1
	var last_row = first_row + visible_rows + buffer_rows * 2
	var last_index = min(data.size() - 1, (last_row + 1) * columns - 1)
	
	if first_index != _last_visible_first or last_index != _last_visible_last:
		_last_visible_first = first_index
		_last_visible_last = last_index
		on_visible_range_changed.emit(first_index, last_index)
	
	for i in range(node_pool.size()):
		var row_offset = i / columns      # 池中的行偏移
		var col = i % columns             # 池中的列
		var data_row = first_row + row_offset
		var data_index = data_row * columns + col
		var item = node_pool[i]
		
		if data_index < data.size():
			on_entry_updated.emit(data_index, item, data[data_index]) # 条目刷新
			# 位置每次都更新（滚动时会变化）
			var new_pos = Vector2(col * item_width, data_row * item_height)
			if item.position != new_pos:
				item.position = new_pos
			item.visible = true
		else:
			item.visible = false

## ============================ 数据变化 =============================

## 添加数据
func add_item(item_data):
	var old_size = data.size()
	data.append(item_data)
	on_items_changed.emit(old_size, 1) # 数据范围变化

	# 更新滚动范围
	_setup_scroll_range()
	_update_visible_items()

## 删除数据
func remove_item(index: int):
	if index < 0 or index >= data.size():
		return
	data.remove_at(index)
	on_items_changed.emit(index, -1) # 数据范围变化

	# 更新滚动范围
	_setup_scroll_range()
	_update_visible_items()

## 修改数据
func update_item(index: int, new_data):
	if index < 0 or index >= data.size():
		return
	data[index] = new_data
	on_entry_updated.emit(index, _get_control_at_index(index), new_data) # 数据范围变化

	# 更新滚动范围
	_setup_scroll_range()
	_update_visible_items()

## 批量添加数据(异步)
func append_items(new_items: Array):
	var old_size = data.size()
	data.append_array(new_items)
	on_items_changed.emit(old_size, new_items.size())
	
	# 更新滚动范围
	_setup_scroll_range()
	_update_visible_items()


## ============================ 刷新控制 =============================

## 强制刷新整个列表
func refresh_list():
	on_refresh_requested.emit() ## 强制刷新
	_update_visible_items()

## 刷新指定索引条目
func refresh_entry(index: int):
	if index >= 0 and index < data.size():
		var control = _get_control_at_index(index)
		if control:
			on_entry_updated.emit(index, control, data[index]) ## 条目刷新


## ============================ 工具 =============================

## 获取指定坐标的索引
func get_index_of_position(_position: Vector2 = get_global_mouse_position()) -> int:
	var container_pos = item_container.global_position
	var relative_x = _position.x - container_pos.x
	var relative_y = _position.y - container_pos.y
	
	# 边界检查
	if relative_x < 0 or relative_x >= columns * item_width:
		return -1
	if relative_y < 0:
		return -1
	var col = floor(relative_x / item_width)
	var row = floor(relative_y / item_height)
	#col = clamp(col, 0, columns - 1)
	#row = clamp(row, 0, int(data.size() / columns) + 1)
	var index = row * columns + col
	return index if index < data.size() else -1

## 获取索引对应的控件(如果可见)
func _get_control_at_index(target_index: int) -> Control:
	var target_row = target_index / columns
	var target_col = target_index % columns
	var scroll_y = v_scroll_bar.value
	var first_row = max(0, int(scroll_y / item_height) - buffer_rows)
	var row_offset = target_row - first_row
	if row_offset < 0:
		return null # 在可见区域上方
	var pool_index = row_offset * columns + target_col
	if pool_index >= node_pool.size():
		return null # 在可见区域下方
	return node_pool[pool_index]

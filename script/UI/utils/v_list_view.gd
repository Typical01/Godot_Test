class_name VListView extends ScrollContainer



## ============================ 数据刷新 =============================
signal on_refresh_requested() ## 强制刷新
signal on_items_changed(start_index: int, count: int) ## 条目范围变化
signal on_entry_updated(index: int, control, data) ## 条目刷新
signal on_v_value_changed(value: float) ## 垂直滚动条变化
signal on_visible_range_changed(first: int, last: int) ## 可见范围变化

## 拖拽: 假定节点继承[Control], 包含函数[set_dray_hover]
signal on_drag_start_item(index: int, data, global_mouse_position: Vector2) ## 拖拽开始
signal on_drag_move_item(index: int, global_mouse_position: Vector2) ## 拖拽移动
signal on_drag_end_item(index: int, end_index: int) ## 拖拽结束

## ============================ 数据加载 =============================
#signal on_load_more_requested()
signal on_data_fill(self_node) ## 数据填充
signal on_node_init(control) ## 条目初始化
signal on_drag_node_init(control) ## 拖拽条目初始化
signal on_entry_connect_callback(control) ## 条目连接
signal on_entry_disconnect_callback(control) ## 条目断开
#signal on_data_ready(start_index: int, items)

## ============================ 条目生命周期 =============================
#signal on_entry_created(control, template_type)
#signal on_entry_recycled(control, index: int) ## 回收条目
#signal on_entry_destroyed(control)



## ============================ 变量 =============================
@onready var item_container:
	get():
		return $ItemContainer
@onready var v_scroll_bar = get_v_scroll_bar()

@export var node_scene_template: PackedScene = null ## 节点模板

var _last_visible_first: int = 0 ## 最后显示范围: 开始索引
var _last_visible_last: int = 0 ## 最后显示范围: 结束索引
var _visible_rows: int = 0 ## 显示范围: 行数

@export var columns: int = 1 ## 列数
@export var item_size: Vector2i = Vector2i(64, 64) ## 项: 高度x宽度
@export var buffer_rows: int = 0 ## 缓冲: 行数
@export var drag_roll_rows: int = 1 ## 拖拽滚动触发的首尾行数
@export var item_interval: int = 1 ## 项之间的间距
@export var is_size_change: bool = true ## 项大小可变化
@export var aligning: bool = true ## 对齐列表/网格
@export var show_drag_node: bool = true ## 显示拖拽节点
@export var default_node_visible: bool = true ## 默认节点显示

var drag_index: int = -1
var drag_node = null
var data = []: ## 数据
	get():
		return data
	set(new_data):
		data = new_data
		_setup_scroll_range()
		_update_visible_items()
var node_pool = [] ## 节点池
var node_pool_size: int = 0 ## 节点池大小 = (可见列数 + 缓冲行数 * 2(上/下不可见列数) * 列数



## ============================ 基础函数 =============================
func _ready() -> void:
	# 创建节点池
	v_scroll_bar.value_changed.connect(_update_visible_items)
	get_tree().root.size_changed.connect(_on_window_resized)
	
	# 数据初始化
	on_data_fill.emit(self)
	update_view()

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion or event is InputEventScreenTouch:
		#OverlayStateMonitor.push_overlay("global_mouse_position", get_global_mouse_position())
		if get_draging():
			drag_move_item(get_global_mouse_position())

func _on_resized() -> void:
	update_view()

func _on_window_resized():
	update_view()


## ============================ 接口 =============================

func update_view():
	await get_tree().process_frame
	#_update_node_pool_size()
	#_setup_scroll_range()
	#_update_visible_items()
	call_deferred("_update_node_pool_size")
	call_deferred("_setup_scroll_range")
	call_deferred("_update_visible_items")

## 设置节点模板, 并刷新节点池和视图显示
func set_template(scene:  PackedScene):
	node_scene_template = scene
	if not node_scene_template:
		push_error("VListView: 节点模板为 null!")
		return
	if drag_node: # 覆盖原节点
		if find_child(drag_node):
			remove_child(drag_node)
	drag_node = node_scene_template.instantiate()
	if not drag_node:
		push_error("VListView: 拖拽节点初始化失败!")
		return
	drag_node.z_index = 10
	drag_node.visible = false
	drag_node.modulate = Color(1, 1, 1, 0.5)
	item_container.add_child(drag_node)
	on_drag_node_init.emit(drag_node)
	if drag_node.has_method("set_dray_hover"):
		drag_node.set_dray_hover(true)
	if drag_node is Control:
		drag_node.mouse_filter = MOUSE_FILTER_IGNORE
	update_view()

## 刷新节点池大小
func _update_node_pool_size():
	if not item_container:
		return
	if not node_scene_template:
		push_error("VListView: 节点模板为 null!")
		return
	
	#OverlayStateMonitor.push_overlay("item_size", item_size)
	if drag_node:
		drag_node.size = Vector2(item_size.x, item_size.y)
	_visible_rows = ceil(size.y / item_size.y)
	#OverlayStateMonitor.push_overlay("_visible_rows", _visible_rows)
	node_pool_size = (_visible_rows + buffer_rows * 2) * columns
	
	if node_pool_size == node_pool.size():
		for i in range(node_pool.size()):
			node_pool[i].size = Vector2(item_size.x, item_size.y) # 刷新节点大小
		return # 大小合适，不重建
	if node_pool_size > node_pool.size():
		# 添加新节点
		for i in range(node_pool_size - node_pool.size()):
			if node_scene_template == null:
				push_error("VListView: node_scene_template == null!")
			else:
				var node = node_scene_template.instantiate()
				node.size = Vector2(item_size.x, item_size.y)
				node_pool.append(node)
				item_container.add_child(node)
				on_node_init.emit(node) # 节点初始化
				on_entry_connect_callback.emit(node)  # 新节点连接信号
	else:
		# 移除多余节点（注意：要断开信号）
		while node_pool.size() > node_pool_size and \
			not node_pool.is_empty():
			var node = node_pool.pop_back()
			on_entry_disconnect_callback.emit(node)  # 旧节点断开信号
			node.queue_free()
	node_pool_size = node_pool.size()
	#print("VListView: node_pool_size: (%s)" % [node_pool_size])

## 设置滚动范围
func _setup_scroll_range():
	if not node_scene_template:
		push_error("VListView: 节点模板为 null!")
		return
	if not drag_node:
		push_error("VListView: drag_node == null!")
		return	
	var total_rows = ceil(float(data.size()) / columns)
	var new_height = total_rows * item_size.y
	
	item_container.custom_minimum_size = Vector2(item_size.x - 2, new_height - 2)
	item_container.position = Vector2(1, 1)
	#OverlayStateMonitor.push_overlay("item_container.custom_minimum_size", item_container.custom_minimum_size)
	#OverlayStateMonitor.push_overlay("size", size)
	#OverlayStateMonitor.push_overlay("data.size()", data.size())
	#OverlayStateMonitor.push_overlay("total_rows", total_rows)

## 刷新可见项
func _update_visible_items(scroll_y: float = v_scroll_bar.value):
	on_v_value_changed.emit(scroll_y)
	
	#OverlayStateMonitor.push_overlay("scroll_y", scroll_y)
	if not node_scene_template:
		push_error("VListView: 节点模板为 null!")
		return
	if not item_container:
		return
	# 计算可见范围(带缓冲)
	var first_row = max(0, int(scroll_y / item_size.y) - buffer_rows)
	var first_index = first_row * columns
	var last_row = first_row + _visible_rows + buffer_rows * 2
	var last_index = min(data.size() - 1, (last_row + 1) * columns - 1)
	var nodes = []
	
	# 可见范围变化
	if first_index != _last_visible_first and last_index != _last_visible_last:
		var first = range(abs(first_index - _last_visible_first))
		var last = range(abs(last_index - _last_visible_last))
		for i in first:
			nodes.append(Vector2(first[i], last[i]))
		OverlayStateMonitor.push_overlay("nodes", nodes)
		
		_last_visible_first = first_index
		_last_visible_last = last_index
		#_visible_rows = last_row - first_row - (buffer_rows * 2)
		on_visible_range_changed.emit(first_index, last_index)
	
	for i in range(node_pool.size()):
		var row = floor(float(i) / columns) # 池中的行
		var col = i % columns # 池中的列
		var data_row = first_row + row
		var data_index = data_row * columns + col
		var item = node_pool[i]
		
		if data_index < data.size():
			var new_pos = Vector2(col * item_size.x, data_row * item_size.y)
			if item.position != new_pos:
				item.position = new_pos
			item.visible = default_node_visible
			on_entry_updated.emit(data_index, item, data[data_index]) # 条目刷新
		else:
			item.visible = false

## 聚焦索引项
func _scroll_to_index(index: int, animat_time: float = 0.1):
	if index < 0 or index >= data.size():
		return
	var row = floor(float(index) / columns)
	var y = row * item_size.y
	var visible_height = size.y
	var scroll_y = y - visible_height / 2 #居中显示
	
	scroll_y = clamp(scroll_y, 0, v_scroll_bar.max_value)
	if animat_time:
		var tween = create_tween()
		tween.tween_property(v_scroll_bar, "value", scroll_y, animat_time)
	else:
		v_scroll_bar.value = scroll_y

## 刷新指定项
func _update_index_item(index: int):
	if index >= 0 and index < data.size():
		var control = _get_control_at_index(index)
		if control:
			control.visible = true
		on_entry_updated.emit(index, control, data[index]) # 数据范围变化
	else:
		push_error("VListView: _update_index_item: [%s] index >= 0 and index < data.size()!" % [index])
		return

## 刷新指定项
func _update_index_item_data(index: int, _data):
	var control = _get_control_at_index(index)
	if control:
		control.visible = true
	on_entry_updated.emit(index, control, _data) # 数据范围变化

## 限制拖拽节点的位置
func clamp_drag_node_position(global_mouse_position: Vector2):
	if aligning:
		var index = get_index_of_position(global_mouse_position)
		var control = _get_control_at_index(index)
		if control:
			var rect = control.get_rect()
			drag_node.position = rect.position
	else:
		drag_node.position = global_mouse_position - (drag_node.size / 2)

## ============================ 数据接口 =============================

## 正在拖拽中时返回: true
func get_draging() -> bool:
	if drag_index >= 0 and show_drag_node: return true 
	else: return false

## 清空数据
func clear_item():
	data.clear()
	update_view() # 更新滚动范围

## 填充数据
func fill_item(item_data = null, count: int = data.size()):
	if count != data.size():
		data.resize(count)
	data.fill(item_data)
	update_view() # 更新滚动范围

## 添加数据
func add_item(item_data):
	var index = data.size()
	data.append(item_data)
	on_items_changed.emit(index, 1) # 数据范围变化
	#_update_index_item(index, control, item_data) # 数据范围变化

	_setup_scroll_range() # 更新滚动范围
	_update_visible_items()

## 删除数据
func remove_item(index: int) -> int:
	if index < 0 or index >= data.size():
		return -1
	data.remove_at(index)
	on_items_changed.emit(index, -1) # 数据范围变化
	
	_setup_scroll_range() # 更新滚动范围
	_update_visible_items()
	return 0

## 修改数据
func update_item(index: int, new_data):
	if index < 0 or index >= data.size():
		return
	data[index] = new_data
	_update_index_item_data(index, new_data) # 数据范围变化

	_setup_scroll_range() # 更新滚动范围
	#_update_visible_items()

## 插入数据
func insert_item(index: int, new_data):
	if index < 0 or index >= data.size():
		return
	var old_size = data.size()
	data.insert(index, new_data)
	on_items_changed.emit(old_size, 1) # 数据范围变化

	_setup_scroll_range() # 更新滚动范围
	_update_visible_items()

## 交换数据
func swap_item(index: int, target_index: int) -> int:
	if index < 0 or index >= data.size():
		return -1
	if target_index < 0 or target_index >= data.size():
		return -1
	var tmp = data[index]
	data[index] = data[target_index]
	data[target_index] = tmp
	_update_index_item_data(index, data[index]) # 数据范围变化
	_update_index_item_data(target_index, data[target_index]) # 数据范围变化

	_setup_scroll_range() # 更新滚动范围
	#_update_visible_items()
	return 0

## 移动数据
func move_item(index: int, target_index: int) -> int:
	if index < 0 or index >= data.size():
		return -1
	if target_index < 0 or target_index >= data.size():
		return -1
	var index_data = data.pop_at(index)
	data.insert(target_index, index_data)

	_setup_scroll_range() # 更新滚动范围
	_update_visible_items()
	return 0

## 批量添加数据(异步)
func append_items(new_items: Array):
	var old_size = data.size()
	data.append_array(new_items)
	on_items_changed.emit(old_size, new_items.size())
	
	_setup_scroll_range() # 更新滚动范围
	#_update_visible_items()

## 拖拽开始: 刷新拖拽节点数据
func drag_start_item(global_mouse_position: Vector2 = get_global_mouse_position()):
	var index = get_index_of_position(global_mouse_position)
	drag_index = index
	if drag_node and show_drag_node:
		drag_node.visible = true
	on_drag_start_item.emit(drag_index, data[drag_index], global_mouse_position)
	clamp_drag_node_position(global_mouse_position)

## 拖拽移动: 跟随鼠标并自动跟随滚动
func drag_move_item(global_mouse_position: Vector2 = get_global_mouse_position()):
	var index = get_index_of_position(global_mouse_position)
	clamp_drag_node_position(global_mouse_position)
	## 鼠标处于视图 顶/底部时, 缓慢向上/下滚动视图
	#global_mouse_position -= item_container.global_position
	#if global_mouse_position.y < drag_roll_rows * item_size.y:
		#v_scroll_bar.value -= 1
	#if global_mouse_position.y > (_visible_rows - drag_roll_rows) * item_size.y:
		#v_scroll_bar.value += 1
	on_drag_move_item.emit(index, global_mouse_position)

## 拖拽结束: 还原状态
func drag_end_item(global_mouse_position: Vector2 = get_global_mouse_position()):
	var end_index = get_index_of_position(global_mouse_position)
	if drag_node and show_drag_node:
		drag_node.visible = false
	if end_index != -1:
		#move_item(drag_index, end_index)
		pass
	on_drag_end_item.emit(drag_index, end_index, global_mouse_position)
	drag_index = -1


## ============================ 刷新控制 =============================

## 强制刷新整个列表
func refresh_list():
	on_refresh_requested.emit() ## 强制刷新
	_update_visible_items()

## 刷新指定索引条目
func refresh_entry(index: int):
	if index >= 0 and index < data.size():
		_update_index_item(index) ## 条目刷新


## ============================ 工具 =============================

## 获取指定坐标的索引
func get_index_of_position(_global_position: Vector2 = get_global_mouse_position()) -> int:
	var container_pos = item_container.global_position - global_position
	var local_position = _global_position - global_position
	var relative_x = local_position.x - container_pos.x
	var relative_y = local_position.y - container_pos.y
	# 边界检查
	if relative_x < 0 or relative_x >= columns * item_size.x:
		return -1
	if relative_y < 0:
		return -1
	var col = floor(relative_x / item_size.x)
	var row = floor(relative_y / item_size.y)
	var index = row * columns + col
	return index if index < data.size() else -1

## 获取索引对应的控件(如果可见)
func _get_control_at_index(target_index: int) -> Control:
	var target_row = floor(float(target_index) / columns)
	var target_col = target_index % columns
	var scroll_y = v_scroll_bar.value
	var first_row = max(0, int(scroll_y / item_size.y) - buffer_rows)
	# 在可见区域上方
	var row_offset = target_row - first_row
	if row_offset < 0:
		return null
	var pool_index = row_offset * columns + target_col
	# 在可见区域下方
	if pool_index >= node_pool.size():
		return null
	return node_pool[pool_index]

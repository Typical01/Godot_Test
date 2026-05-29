class_name VListView extends ScrollContainer



## ============================ 数据刷新 =============================
signal on_item_updated(index: int, control, datas) 			## 条目刷新
signal on_v_value_changed(value: float) 					## 垂直滚动条变化
signal on_visible_range_changed(indexs: Array) 				## 可见范围变化

## 拖拽: 假定节点继承[Control]
signal on_drag_start_item(
	index: int, datas, global_mouse_position: Vector2) 		## 拖拽开始
signal on_drag_move_item(
	index: int, global_mouse_position: Vector2) 			## 拖拽移动
signal on_drag_end_item(
	index: int, end_index: int) 							## 拖拽结束

## ============================ 数据加载 =============================
#signal on_load_more_requested()
signal on_data_fill(self_node) 								## 数据填充
signal on_item_init(control) 								## 条目初始化
signal on_drag_node_init(control) 							## 拖拽条目初始化
signal on_item_connect_callback(control) 					## 条目连接
signal on_item_disconnect_callback(control) 				## 条目断开



## ============================ 变量 =============================
@onready var item_container_node:
	get():
		return $ItemContainer
@onready var v_scroll_bar = get_v_scroll_bar()

@export var node_scene_template: PackedScene = null ## 节点模板


@export var columns: int = 1						## 列数
@export var item_size: Vector2i = Vector2i(64, 64) 	## 项: 高度x宽度
@export var buffer_rows: int = 0 					## 缓冲: 行数
@export var drag_roll_margin_pixel: int = 20 		## 拖拽滚动: 内边距像素
@export var item_interval: int = 0 					## 项之间的间距
@export var aligning: bool = true 					## 对齐列表/网格
@export var show_drag_node: bool = true 			## 显示拖拽节点
@export var default_node_visible: bool = true 		## 默认节点显示

var _last_first: int = -1 					## 最后显示范围: 开始索引
var _visible_rows: int = -1 							## 显示范围: 行数
var _last_indexs: Array = [] 						## 最后显示范围: 索引列表

var drag_index: int = -1
var drag_node = null
var datas = []: ## 数据
	get():
		return datas
	set(new_data):
		datas = new_data
		_update_scroll_range()
		_update_visible_items()
var node_pool = [] 				## 节点池
var node_pool_size: int = 0 	## 节点池大小 = (可见列数 + 缓冲行数 * 2(上/下不可见列数) * 列数



## ============================ 基础实现 =============================
func _ready() -> void:
	# 创建节点池
	v_scroll_bar.value_changed.connect(_update_visible_items) # 连接: 垂直滚动
	get_tree().root.size_changed.connect(_on_window_resized) # 连接: 主视口大小变化
	
	on_data_fill.emit(self) # 信号: 数据填充
	update_view()

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion or event is InputEventScreenTouch:
		if get_draging():
			drag_move_item(get_global_mouse_position())

func _on_resized() -> void:
	update_view()

func _on_window_resized():
	update_view()



## ============================ 常规接口 =============================

## 正在拖拽中时返回: true
func get_draging() -> bool:
	if drag_index >= 0 and show_drag_node: return true 
	else: return false



## ============================ 刷新控制 =============================

## 刷新整个列表
func refresh_list():
	_update_visible_items()

## 刷新指定项
func update_index_item(index: int):
	if index >= 0 and index < datas.size():
		on_item_updated.emit(index, get_control_from_index(index), datas[index]) # 数据范围变化
	else:
		push_error("VListView: update_index_item: [%s] index >= 0 and index < datas.size()!" % [index])
		return

## 刷新指定项
func update_index_item_data(index: int, data):
	on_item_updated.emit(index, get_control_from_index(index), data) # 数据范围变化

## 拖拽开始: 刷新拖拽节点数据
func drag_start_item(global_mouse_position: Vector2 = get_global_mouse_position()):
	var index = get_index_from_position(global_mouse_position)
	drag_index = index
	if show_drag_node and drag_node:
		drag_node.visible = true
	on_drag_start_item.emit(drag_index, datas[drag_index], global_mouse_position)
	clamp_drag_node_position(global_mouse_position)

## 拖拽移动: 跟随鼠标并自动跟随滚动
func drag_move_item(global_mouse_position: Vector2 = get_global_mouse_position()):
	var index = get_index_from_position(global_mouse_position)
	clamp_drag_node_position(global_mouse_position)
	## 鼠标处于视图 顶/底部时, 缓慢向上/下滚动视图
	#global_mouse_position -= item_container_node.global_position
	#if global_mouse_position.y < drag_roll_rows * item_size.y:
		#v_scroll_bar.value -= 1
	#if global_mouse_position.y > (_visible_rows - drag_roll_rows) * item_size.y:
		#v_scroll_bar.value += 1
	on_drag_move_item.emit(index, global_mouse_position)

## 拖拽结束: 还原状态
func drag_end_item(global_mouse_position: Vector2 = get_global_mouse_position()):
	var end_index = get_index_from_position(global_mouse_position)
	if show_drag_node and drag_node:
		drag_node.visible = false
	if end_index != -1:
		#move_item(drag_index, end_index)
		pass
	on_drag_end_item.emit(drag_index, end_index, global_mouse_position)
	drag_index = -1



## ============================ 数据接口 =============================

## 清空数据
func clear_item():
	datas.clear()
	_last_indexs.clear()  # 重置映射
	_update_scroll_range() # 更新滚动范围
	_update_visible_items() # 刷新可见项

## 填充数据
func fill_item(item_data = null, count: int = datas.size()):
	if count != datas.size():
		datas.resize(count)
	datas.fill(item_data)
	update_view()

## 添加数据
func add_item(new_data):
	var index = datas.size()
	datas.append(new_data)
	update_index_item_data(index, new_data) # 数据范围变化
	_update_scroll_range() # 更新滚动范围

## 删除数据
func remove_item(index: int) -> int:
	if index < 0 or index >= datas.size():
		return -1
	datas.remove_at(index)
	_last_indexs.clear()  # 重置映射
	_update_scroll_range() # 更新滚动范围
	_update_visible_items() # 刷新可见项
	return 0

## 修改数据
func update_item(index: int, new_data):
	if index < 0 or index >= datas.size():
		return
	datas[index] = new_data
	update_index_item_data(index, new_data) # 数据范围变化

## 插入数据
func insert_item(index: int, new_data):
	if index < 0 or index > datas.size():
		return
	datas.insert(index, new_data)
	_last_indexs.clear()  # 重置映射
	_update_scroll_range() # 更新滚动范围
	_update_visible_items() # 刷新可见项

## 交换数据
func swap_item(index: int, target_index: int) -> int:
	if index < 0 or index >= datas.size():
		return -1
	if target_index < 0 or target_index >= datas.size():
		return -1
	var tmp = datas[index]
	datas[index] = datas[target_index]
	datas[target_index] = tmp
	update_index_item_data(index, datas[index]) # 数据范围变化
	update_index_item_data(target_index, datas[target_index]) # 数据范围变化
	_update_scroll_range() # 更新滚动范围
	return 0

## 移动数据
func move_item(index: int, target_index: int) -> int:
	if index < 0 or index >= datas.size():
		return -1
	if target_index < 0 or target_index >= datas.size():
		return -1
	var index_data = datas.pop_at(index)
	datas.insert(target_index, index_data)

	_last_indexs.clear()  # 重置映射
	_update_scroll_range() # 更新滚动范围
	_update_visible_items() # 刷新可见项
	return 0

## 批量添加数据
func append_items(new_items: Array):
	datas.append_array(new_items)
	
	_update_scroll_range() # 更新滚动范围



## ============================ 工具 =============================

## 获取: 指定坐标的索引
func get_index_from_position(_global_position: Vector2 = get_global_mouse_position()) -> int:
	var container_pos = item_container_node.global_position - global_position
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
	return index if index < datas.size() else -1

## 获取: 索引对应的控件(如果可见)
func get_control_from_index(target_index: int) -> Control:
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



## ============================ 内部接口 =============================

## 刷新: 视图(节点池/滚动范围/可见项)
func update_view():
	await get_tree().process_frame
	call_deferred("_update_node_pool_size")
	call_deferred("_update_scroll_range")
	call_deferred("_update_visible_items")

## 设置: 节点模板, 并刷新视图
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
	item_container_node.add_child(drag_node)
	on_drag_node_init.emit(drag_node)
	if drag_node is Control:
		drag_node.mouse_filter = MOUSE_FILTER_IGNORE
	update_view()

## 刷新节点池大小
func _update_node_pool_size():
	if not item_container_node:
		return
	if not node_scene_template:
		push_error("VListView: 节点模板为 null!")
		return
	
	if drag_node:
		drag_node.size = Vector2(item_size.x, item_size.y)
	_visible_rows = ceil(item_container_node.size.y / item_size.y) # 最小可见行
	OverlayStateMonitor.push_overlay("[%s]_visible_rows" % [get_instance_id()], _visible_rows)
	node_pool_size = (_visible_rows + buffer_rows * 2) * columns
	OverlayStateMonitor.push_overlay("[%s]node_pool_size" % [get_instance_id()], node_pool_size)
	
	if node_pool_size == node_pool.size():
		for i in range(node_pool.size()):
			node_pool[i].size = Vector2(item_size.x, item_size.y) # 刷新节点大小
		return # 大小合适，不重建
	
	# 节点池大小变化，清空映射
	_last_indexs.clear()
	
	if node_pool_size > node_pool.size():
		# 添加新节点
		for i in range(node_pool_size - node_pool.size()):
			if node_scene_template == null:
				push_error("VListView: node_scene_template == null!")
			else:
				var node = node_scene_template.instantiate()
				node.size = Vector2(item_size.x, item_size.y)
				node_pool.append(node)
				item_container_node.add_child(node)
				on_item_init.emit(node) # 节点初始化
				on_item_connect_callback.emit(node)  # 新节点连接信号
	else:
		# 移除多余节点（注意：要断开信号）
		while node_pool.size() > node_pool_size and \
			not node_pool.is_empty():
			var node = node_pool.pop_back()
			on_item_disconnect_callback.emit(node)  # 旧节点断开信号
			node.queue_free()
	node_pool_size = node_pool.size()
	#print("VListView: node_pool_size: (%s)" % [node_pool_size])

## 刷新: 滚动范围
func _update_scroll_range():
	if not node_scene_template:
		push_error("VListView: 节点模板为 null!")
		return
	if not drag_node:
		push_error("VListView: drag_node == null!")
		return	
	var total_rows = ceil(float(datas.size()) / columns)
	var new_height = total_rows * item_size.y
	
	item_container_node.custom_minimum_size = Vector2(item_size.x - 2, new_height - 2)
	item_container_node.position = Vector2(1, 1)

## 刷新可见项
func _update_visible_items(scroll_y: float = v_scroll_bar.value):
	on_v_value_changed.emit(scroll_y)
	
	if not node_scene_template:
		push_error("节点模板为 null!")
		return
	if not item_container_node:
		push_error("项容器为 null!")
		return
	
	# 计算可见范围(带缓冲)
	var first_row = max(0, int(scroll_y / item_size.y) - buffer_rows) # 起始行: 以[缓冲行]开始
	var first_index = first_row * columns # 起始索引
	var last_row = first_row + _visible_rows + buffer_rows * 2 # 结束行: 以[缓冲行]结束
	var last_index = min(datas.size() - 1, 
	last_row * columns - 1) # 结束索引: 以[缓冲行/最大大小]结束
	
	# 可见范围未变化
	if first_index == _last_first:
		return
		
	var new_indexs = range(first_index, last_index + 1) # new_indexs(1, 2, 3) | _last_indexs(0, 1, 2)
	# 初始化: 映射[last_index - last_node]
	if _last_indexs.is_empty():
		for i in node_pool.size():
			if i < new_indexs.size():
				var data_index = new_indexs[i]
				_last_indexs.append(data_index)
				var row = floor(float(data_index) / columns)
				var col = data_index % columns
				node_pool[i].position = Vector2(col * item_size.x, row * item_size.y)
				node_pool[i].visible = default_node_visible
				on_item_updated.emit(data_index, node_pool[i], datas[data_index])
			else:
				node_pool[i].visible = false
	else:
		# 需要刷新的索引
		var add_update_indexs = new_indexs.filter(func(item): return not _last_indexs.has(item)) # 3
		var sub_update_indexs = _last_indexs.filter(func(item): return not new_indexs.has(item)) # 0
		
		# _last_nodes = (1, 2, 0)
		# _last_indexs = (1, 2, 3)
		
		for i in range(abs(first_index - _last_first)):
			var sub_update_index = sub_update_indexs[i] # 减少的刷新索引
			var add_update_index = add_update_indexs[i] # 新增的刷新索引
			
			# 找到持有旧数据索引的物理节点
			var node_idx = _last_indexs.find(sub_update_index)
			var item_node = node_pool[node_idx]
			
			# 计算新位置
			var new_data_row = floor(float(add_update_index) / columns) # 池中的行
			var new_col = add_update_index % columns # 池中的列
			var new_pos = Vector2(new_col * item_size.x, new_data_row * item_size.y)
			
			# 更新节点
			item_node.position = new_pos
			item_node.visible = default_node_visible
			on_item_updated.emit(add_update_index, item_node, datas[add_update_index])
			
			# 同步映射关系
			_last_indexs[node_idx] = add_update_index
	
	_last_first = first_index
	on_visible_range_changed.emit(first_index, last_index)

## 聚焦索引项
func scroll_to_index(index: int, animat_time: float = 0.1):
	if index < 0 or index >= datas.size():
		return
	var row = floor(float(index) / columns)
	var y = row * item_size.y
	var visible_height = item_container_node.size.y
	var scroll_y = y - visible_height / 2 #居中显示
	
	scroll_y = clamp(scroll_y, 0, v_scroll_bar.max_value)
	if animat_time:
		var tween = create_tween()
		tween.tween_property(v_scroll_bar, "value", scroll_y, animat_time)
	else:
		v_scroll_bar.value = scroll_y

## 限制拖拽节点的位置
func clamp_drag_node_position(global_mouse_position: Vector2):
	if aligning:
		var index = get_index_from_position(global_mouse_position)
		var control = get_control_from_index(index)
		if control:
			var rect = control.get_rect()
			drag_node.position = rect.position
	else:
		drag_node.position = global_mouse_position - (drag_node.size / 2)

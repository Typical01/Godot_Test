extends Sprite2D



# 节点引用
@onready var joystick_handle: Sprite2D = $Handle
@onready var joystick_range: Sprite2D = $Range

# 摇杆配置
@export_category("Joystick Configuration")
@export var max_handle_distance: float = 70.0
@export var is_visible_by_default: bool = true

# 触摸行为
@export_category("Touch Behavior")
@export var follow_touch: bool = false
@export var use_trigger_area: bool = true  # 默认启用触发区域

# 屏幕适配
@export_category("Screen Adaptation")
@export var update_screen_size_continuously: bool = false
@export var screen_position_ratio: Vector2 = Vector2(0.5, 0.75)

# 触发区域配置
@export_category("Trigger Area")
@export var trigger_area_width: float = 0.0
@export var trigger_area_height: float = 0.0

# 内部变量
var active_touch_index: int = -1
var is_joystick_active: bool = false
var trigger_area_center: Vector2 = Vector2.ZERO
var trigger_area_size: Vector2 = Vector2.ZERO



func _ready() -> void:
	coord_utils.window_size_changed.connect(on_window_size_changed)
	
	_initialize_joystick()
	if trigger_area_width == 0.0 and\
		trigger_area_height == 0.0:
		set_custom_trigger_size(
			joystick_range.get_rect().size.x * joystick_range.scale.x, 
			joystick_range.get_rect().size.y * joystick_range.scale.y)
		# 延迟一帧计算触发区域，确保所有节点都已就位
	call_deferred("_calculate_trigger_area")


func _process(_delta: float) -> void:	
	# 每帧更新触发区域位置（如果启用）
	if use_trigger_area and joystick_range:
		_update_trigger_area_position()


func _input(event) -> void:
	# 如果摇杆不可见且没有激活，直接返回
	if not is_visible_by_default and not is_joystick_active:
		return
	
	# 处理触摸事件
	if event is InputEventScreenTouch:
		_handle_touch_event(event)
	
	# 处理拖拽事件 - 只有激活的摇杆才处理拖拽
	elif event is InputEventScreenDrag and is_joystick_active:
		_handle_drag_event(event)


func on_window_size_changed(window_size):
	update_screen_ratio(window_size)
	pass


# 初始化摇杆
func _initialize_joystick() -> void:
	# 自动计算摇杆最大距离（基于纹理尺寸）
	if texture:
		var texture_size: Vector2 = region_rect.size if region_enabled else texture.get_size()
		var scale_factor = Vector2(abs(scale.x), abs(scale.y))
		var display_size = texture_size * scale_factor
		var padding = 8.0
		max_handle_distance = max((min(display_size.x, display_size.y) * 0.5) - padding, 0.0)
	else:
		push_warning("Joystick: 没有找到纹理，使用默认最大距离: %s" % str(max_handle_distance))
	
	# 设置初始可见性
	if follow_touch:
		visible = false
	else:
		visible = is_visible_by_default
		coord_utils.set_screen_global_position(self, screen_position_ratio)


# 计算触发区域
func _calculate_trigger_area() -> void:
	if not joystick_range:
		return
	
	if not use_trigger_area:
		return
	
	# 使用自定义尺寸或默认尺寸
	if trigger_area_width > 0 and trigger_area_height > 0:
		trigger_area_size = Vector2(trigger_area_width, trigger_area_height)
	else:
		# 如果没有设置自定义尺寸，使用范围节点的显示尺寸
		var texture_size: Vector2
		if joystick_range.region_enabled:
			texture_size = joystick_range.region_rect.size
		elif joystick_range.texture:
			texture_size = joystick_range.texture.get_size()
		else:
			texture_size = Vector2(200, 200)  # 默认尺寸
		
		var _global_scale = joystick_range.global_scale.abs()
		trigger_area_size = texture_size * _global_scale
	
	# 更新触发区域位置
	_update_trigger_area_position()
	
	#print("触发区域计算完成: 中心 ", trigger_area_center, " 尺寸 ", trigger_area_size)


# 更新触发区域位置
func _update_trigger_area_position() -> void:
	if not joystick_range or not use_trigger_area:
		return
	
	# 使用范围节点的全局位置作为触发区域中心
	trigger_area_center = joystick_range.global_position


# 处理触摸事件
func _handle_touch_event(event: InputEventScreenTouch) -> void:
	if event.is_pressed():
		_handle_touch_press(event)
	else:
		_handle_touch_release(event)


# 处理触摸按下 - 修复触发区域检测逻辑
func _handle_touch_press(event: InputEventScreenTouch) -> void:
	# 检查是否已经有活跃的触摸
	if active_touch_index != -1:
		print("已有活跃触摸，忽略新触摸: ", event.index)
		return
	
	# 检查是否在触发区域内（如果启用）
	if use_trigger_area:
		if not _is_point_in_trigger_area(event.position):
			#print("触摸点不在触发区域内: ", event.position)
			#print("触发区域中心: ", trigger_area_center, " 尺寸: ", trigger_area_size)
			return
		else:
			#print("触摸点在触发区域内，激活摇杆: ", event.position)
			pass
	else:
		#print("未启用触发区域，直接激活摇杆: ", event.position)
		pass
	
	# 只有通过触发区域检测（或未启用触发区域）才会执行到这里
	active_touch_index = event.index
	is_joystick_active = true
	
	if follow_touch:
		global_position = event.position
		joystick_handle.position = Vector2.ZERO
		visible = true
	else:
		_update_handle_position(event.position)


# 处理触摸释放
func _handle_touch_release(event: InputEventScreenTouch) -> void:
	# 只处理与当前活跃触摸匹配的释放事件
	if event.index == active_touch_index:
		#print("释放摇杆，触摸索引: ", event.index)
		_reset_joystick()
		active_touch_index = -1
		is_joystick_active = false


# 处理拖拽事件
func _handle_drag_event(event: InputEventScreenDrag) -> void:
	# 只处理与当前活跃触摸匹配的拖拽事件
	if event.index == active_touch_index:
		_update_handle_position(event.position)


# 更新摇杆手柄位置
func _update_handle_position(touch_position: Vector2) -> void:
	var local_touch_pos: Vector2 = to_local(touch_position)
	var distance = local_touch_pos.length()
	
	if distance > max_handle_distance:
		if distance > 0.0:
			joystick_handle.position = local_touch_pos.normalized() * max_handle_distance
		else:
			joystick_handle.position = Vector2.ZERO
	else:
		joystick_handle.position = local_touch_pos


# 重置摇杆位置
func _reset_joystick() -> void:
	var tween = create_tween()
	tween.tween_property(joystick_handle, "position", Vector2.ZERO, 0.1).set_trans(Tween.TRANS_LINEAR)
	
	if follow_touch:
		visible = false


# 检查点是否在触发区域内
func _is_point_in_trigger_area(global_point: Vector2) -> bool:
	if not use_trigger_area:
		return true
	
	# 确保触发区域已计算
	if trigger_area_size == Vector2.ZERO:
		_calculate_trigger_area()
		if trigger_area_size == Vector2.ZERO:
			# 如果仍然无法计算，默认返回true
			return true
	
	# 使用矩形检测
	var half_size = trigger_area_size * 0.5
	var rect = Rect2(trigger_area_center - half_size, trigger_area_size)
	var is_in_rect = rect.has_point(global_point)
	
	# 调试输出
	#if OS.is_debug_build():
		#print("检测点 ", global_point, " 在矩形 ", rect, " 内: ", is_in_rect)
	
	return is_in_rect

# 公共接口方法

# 获取摇杆强度（0.0 到 1.0）
func get_intensity() -> float:
	var distance = joystick_handle.position.length()
	if max_handle_distance <= 0.0:
		return 0.0
	return clamp(distance / max_handle_distance, 0.0, 1.0)


# 获取摇杆方向向量（标准化）
func get_direction() -> Vector2:
	var handle_pos = joystick_handle.position
	var length = handle_pos.length()
	if length == 0.0:
		return Vector2.ZERO
	return handle_pos / length


# 获取原始手柄位置
func get_handle_position() -> Vector2:
	return joystick_handle.position


# 检查摇杆是否处于活动状态
func is_active() -> bool:
	return is_joystick_active


# 强制显示/隐藏摇杆
func set_joystick_visible(_visible: bool) -> void:
	is_visible_by_default = _visible
	visible = _visible


# 更新屏幕位置比例（仅对固定位置摇杆有效）
func update_screen_ratio(new_ratio: Vector2) -> void:
	screen_position_ratio = new_ratio
	if not follow_touch:
		coord_utils.set_screen_global_position(self, screen_position_ratio)


# 启用/禁用触发区域
func set_trigger_area_enabled(enabled: bool) -> void:
	use_trigger_area = enabled
	if enabled:
		_calculate_trigger_area()


# 设置自定义触发区域尺寸
func set_custom_trigger_size(width: float, height: float) -> void:
	trigger_area_width = width
	trigger_area_height = height
	_calculate_trigger_area()


# 调试方法：可视化触发区域
func debug_draw_trigger_area() -> void:
	if not use_trigger_area:
		return
	
	# 打印触发区域信息
	print("=== 触发区域调试信息 ===")
	print("触发区域中心: ", trigger_area_center)
	print("触发区域尺寸: ", trigger_area_size)
	print("范围节点全局位置: ", joystick_range.global_position)
	print("范围节点全局缩放: ", joystick_range.global_scale)
	
	# 计算并显示触发区域边界
	var half_size = trigger_area_size * 0.5
	var top_left = trigger_area_center - half_size
	var bottom_right = trigger_area_center + half_size
	print("触发区域边界: 左上 ", top_left, " 右下 ", bottom_right)
	print("=========================")

# 新增：强制重新计算触发区域
func recalculate_trigger_area() -> void:
	_calculate_trigger_area()


# 新增：获取触发区域信息（用于调试）
func get_trigger_area_info() -> Dictionary:
	return {
		"center": trigger_area_center,
		"size": trigger_area_size,
		"enabled": use_trigger_area,
		"range_node_position": joystick_range.global_position if joystick_range else Vector2.ZERO
	}


# 新增：手动设置触发区域（用于调试）
func set_trigger_area_manual(center: Vector2, size: Vector2) -> void:
	trigger_area_center = center
	trigger_area_size = size
	use_trigger_area = true
	print("手动设置触发区域: 中心 ", center, " 尺寸 ", size)

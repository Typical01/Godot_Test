extends Sprite2D


@export var bIsFollowTouch = false # true: 摇杆出现在手指处；false: 固定在场景中的某点
@export var max_length = 70.0 #摇杆指针: 最远长度
@export var joystick_effective_range = Rect2(0, 0, 0, 0) #摇杆: 有效范围
var screen_size : Vector2 #屏幕大小
@export var joystick_height_ratio = 0.75 #摇杆: 在屏幕中的高度占比
@export var is_visible = true #是否可见
var on_draging = -1 #指针: 当前拖拽数量

@onready var point: Node2D = $point
@onready var joystick: Node2D = $joystick

func _ready() -> void:
	joystick.self_modulate = Color(1, 1, 1, 0.08)
	self_modulate = Color(1, 1, 1, 0.00)
	
	if bIsFollowTouch:
		visible = false
	# 如果是非跟随模式，确保 visible = true，且 global_position 已在编辑器里设置好
	else:
		if is_visible:
			visible = true
			
	if joystick_effective_range == Rect2(0, 0, 0, 0):
		joystick_effective_range = get_rect()


func _process(delta: float) -> void:
	if !bIsFollowTouch:
		global_position.x = screen_size.x / 2
		global_position.y = screen_size.y * joystick_height_ratio
	pass


func _input(event):
	if !is_visible: return #不显示时不处理
		
	# 处理按下（开始拖拽）
	if event is InputEventScreenTouch and event.is_pressed():
		on_draging = event.get_index()
		# 如果已有正在拖拽的手指，忽略其他按下
		if on_draging != -1:
			return
		if !is_in_the_range(event.position): 
			return #不在范围时不处理
			
		if bIsFollowTouch:
			# 跟随模式：把摇杆移动到触摸点（全局）
			global_position = event.position
			point.position = Vector2.ZERO
			visible = true
		else:
			# 固定模式：摇杆位置不变，只更新 point（会在后面的拖动逻辑里处理）
			# 这里可以在按下时先尝试处理一次（例如直接设置 point）
			_update_point_from_event(event)
		return

	# 释放（抬起）
	if event is InputEventScreenTouch and not event.is_pressed():
		if event.get_index() == on_draging or event.get_index() == -1:
			# 回到中心并 tween
			var tween = create_tween()
			tween.tween_property(point, "position", Vector2.ZERO, 0.06).set_trans(Tween.TRANS_LINEAR)
			on_draging = -1
		if bIsFollowTouch:
			visible = false
		return

	# 拖动（或按下并移动）
	if event is InputEventScreenDrag or (event is InputEventScreenTouch and event.is_pressed()):
		# 多点触控：只响应当前正在拖拽的指
		if on_draging != -1 and event.get_index() != on_draging:
			return
		_update_point_from_event(event)
		return

# 把 event.position 转换为本地坐标并更新 point（封装函数）
func _update_point_from_event(event) -> void:
	# 将屏幕/视口坐标转换到当前 joystick 节点的局部坐标系
	# 这样无论节点在何处（固定或全局移动）都一致
	var local_pos: Vector2 = to_local(event.position)
	var dist = local_pos.length()
	if dist > max_length:
		if dist > 0.0:
			point.position = local_pos / dist * max_length
		else:
			point.position = Vector2.ZERO
	else:
		point.position = local_pos

# 简单工具：归一化 Rect2（把负 size 转为正并把 position 调整到左上角）
func _rect_normalized(r: Rect2) -> Rect2:
	var p = r.position
	var s = r.size
	if s.x < 0:
		p.x += s.x
		s.x = -s.x
	if s.y < 0:
		p.y += s.y
		s.y = -s.y
	return Rect2(p, s)

# 把 background.get_rect() (本地 rect) 转成 屏幕/全局 Rect2（尽量简单）
func _local_rect_to_screen_rect(bg: Node, local_rect: Rect2) -> Rect2:
	var r = _rect_normalized(local_rect)
	if bg is Control:
		# Control 的 get_global_position() 是左上角位置，直接偏移即可
		var gp = (bg as Control).get_global_position() + r.position
		return Rect2(gp, r.size)
	elif bg is Node2D:
		# Node2D 可能有旋转/缩放，安全做法：把四个角点变换为全局后重建包围矩形
		var n = bg as Node2D
		var a = n.to_global(r.position)
		var b = n.to_global(r.position + Vector2(r.size.x, 0))
		var c = n.to_global(r.position + r.size)
		var d = n.to_global(r.position + Vector2(0, r.size.y))
		var minx = min(min(a.x, b.x), min(c.x, d.x))
		var miny = min(min(a.y, b.y), min(c.y, d.y))
		var maxx = max(max(a.x, b.x), max(c.x, d.x))
		var maxy = max(max(a.y, b.y), max(c.y, d.y))
		return Rect2(Vector2(minx, miny), Vector2(maxx - minx, maxy - miny))
	else:
		# 其他类型按原样返回（假设已是屏幕坐标）
		return r

# 主判断函数：position 是 屏幕/全局坐标（InputEvent.position）
func is_in_the_range(position: Vector2) -> bool:
	# 优先使用导出的 joystick_effective_range（如果设置了）
	var local_rect = joystick_effective_range
	if local_rect.size == Vector2.ZERO:
		# 如果没有通过导出设置过范围，则使用节点自身的 rect
		local_rect = get_rect()
	var screen_rect = _local_rect_to_screen_rect(self, local_rect)
	return screen_rect.has_point(position)

# 返回 0~1 的百分比（当前位置到半径的占比）
func get_touch_radius_percent() -> float:
	var d = get_point_pos().length()
	if max_length <= 0.0:
		return 0.0
	return clamp(d / max_length, 0.0, 1.0)

#返回 摇杆指针位置
func get_point_pos() -> Vector2:
	return point.position

#返回
func get_now_pos() -> Vector2:
	var p = get_point_pos()
	var l = p.length()
	if l == 0.0:
		return Vector2.ZERO
	return p / l

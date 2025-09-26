extends Sprite2D


@onready var point: Node2D = $Point

@export var bIsFollowTouch = false ##摇杆跟随
@export var max_length = 70.0 ##最远触发位置
@export var process_update_screen_size = false ##实时更新: 屏幕大小
@export var joystick_height_ratio = 0.75 ##摇杆在屏幕中的Y轴位置(按照百分比)
@export var is_visible = true ##可见

var screen_size : Vector2 ##屏幕大小
var on_draging = -1 ##多指


func _ready() -> void:
	# 获取屏幕/视口尺寸
	screen_size = get_viewport_rect().size

	# 根据 Sprite2D 的纹理与缩放自动计算 max_length（半径）
	var fallback = max_length
	if texture:
		var tex_size: Vector2
		if region_enabled:
			tex_size = region_rect.size
		else:
			tex_size = texture.get_size()
		var sprite_scale = Vector2(abs(scale.x), abs(scale.y))
		var displayed_size = tex_size * sprite_scale
		var padding = 8.0
		# 以较小边的一半为最大半径（减去 padding）
		max_length = max((min(displayed_size.x, displayed_size.y) * 0.5) - padding, 0.0)
	else:
		push_warning("Joystick: Sprite2D 没有 texture，使用默认 max_length(%s)" % str(fallback))
		max_length = fallback

	# 初始可见性 / 跟随触摸逻辑
	if bIsFollowTouch:
		visible = false
	else:
		visible = is_visible

	# 如果用户没有设置有效范围，则默认使用整个屏幕
	#if joystick_effective_range == Rect2(0, 0, 0, 0):
		#joystick_effective_range = Rect2(Vector2.ZERO, screen_size)

	# 如果是非跟随模式，把摇杆放在屏幕底部指定高度
	if not bIsFollowTouch:
		global_position = Vector2(screen_size.x * 0.5, screen_size.y * joystick_height_ratio)

func _process(delta: float) -> void:
	if process_update_screen_size:
		screen_size = get_viewport_rect().size
	if !bIsFollowTouch:
		global_position.x = screen_size.x / 2
		global_position.y = screen_size.y * joystick_height_ratio
	pass


func _input(event):
	if !is_visible: return #不显示时不处理
		
	# 处理按下（开始拖拽）
	if event is InputEventScreenTouch and event.is_pressed():
		on_draging = event.get_index()
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
			tween.tween_property(point, "position", Vector2.ZERO, 0.1).set_trans(Tween.TRANS_LINEAR)
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

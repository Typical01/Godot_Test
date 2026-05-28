extends Node
class_name FlyableComponent

## 抛射参数
@export var friction: float = 800.0           # 摩擦力（像素/秒²）
@export var bounce_factor: float = 0.6        # 边界反弹系数
@export var bound_margin: int = 20            # 距离窗口边缘的最小距离
@export var destroy_out_of_bounds: bool = true   # 超出边界是否销毁
@export var out_of_bounds_timeout: float = 2.0   # 超出边界多久后销毁
@export var auto_return: bool = false          # 停止后是否自动归位
@export var return_duration: float = 0.3      # 归位动画时长

## 内部状态
var is_flying: bool = false
var velocity: Vector2 = Vector2.ZERO
var original_parent: Node = null
var original_position: Vector2 = Vector2.ZERO
var out_of_bounds_timer: float = 0.0
var _return_tween: Tween = null

var _control: Control


func _ready():
	_control = get_parent() as Control
	if not _control:
		push_error("FlyableComponent must be a child of a Control node")
		return
	
	original_parent = _control.get_parent()
	original_position = _control.position
	
	# 确保 Control 可以接收鼠标事件（如果需要）
	#_control.mouse_filter = Control.MOUSE_FILTER_IGNORE


## 启动抛射
func launch(direction: Vector2, initial_speed: float) -> void:
	if is_flying:
		return
	
	# 如果当前有 Tween 在运行，先杀掉
	if _control and _control.get_tree():
		var existing_tween = _control.get_tree().get_first_node_in_group("throw_tween")
		if existing_tween:
			existing_tween.kill()
	
	is_flying = true
	velocity = direction.normalized() * initial_speed
	out_of_bounds_timer = 0.0
	
	# 可选：提升 Z 轴顺序，让抛射中的控件显示在最前
	if _control:
		_control.z_index = 0


## 停止抛射（可选：归位或停留在当前位置）
func stop_and_return() -> void:
	if not is_flying:
		return
	
	is_flying = false
	velocity = Vector2.ZERO
	
	if auto_return and _control:
		_return_to_original_position()


func _process(delta: float):
	if not is_flying or not _control:
		return
	
	# 应用摩擦力
	var speed = velocity.length()
	if speed > 0:
		var friction_delta = friction * delta
		if speed > friction_delta:
			velocity = velocity.normalized() * (speed - friction_delta)
		else:
			velocity = Vector2.ZERO
			is_flying = false
			if auto_return:
				_return_to_original_position()
			return
	
	# 移动位置
	var new_pos = _control.position + velocity * delta
	var old_pos = _control.position
	_control.position = _clamp_to_bounds_with_bounce(new_pos)
	
	# 边界超出检测
	_check_out_of_bounds(delta)


## 带反弹的边界限制
func _clamp_to_bounds_with_bounce(pos: Vector2) -> Vector2:
	var viewport_rect = _control.get_viewport_rect()
	var min_x = bound_margin
	var min_y = bound_margin
	var max_x = viewport_rect.size.x - _control.size.x - bound_margin
	var max_y = viewport_rect.size.y - _control.size.y - bound_margin
	
	var new_pos = pos
	var bounced = false
	
	if new_pos.x < min_x:
		new_pos.x = min_x
		velocity.x = -velocity.x * bounce_factor
		bounced = true
	elif new_pos.x > max_x:
		new_pos.x = max_x
		velocity.x = -velocity.x * bounce_factor
		bounced = true
	
	if new_pos.y < min_y:
		new_pos.y = min_y
		velocity.y = -velocity.y * bounce_factor
		bounced = true
	elif new_pos.y > max_y:
		new_pos.y = max_y
		velocity.y = -velocity.y * bounce_factor
		bounced = true
	
	if bounced and velocity.length() < 30:
		is_flying = false
		if auto_return:
			_return_to_original_position()
	
	return new_pos


## 检测并处理超出边界的情况
func _check_out_of_bounds(delta: float):
	var viewport_rect = _control.get_viewport_rect()
	var margin_rect = viewport_rect.grow(-bound_margin)
	var center = _control.position + _control.size / 2
	
	if not margin_rect.has_point(center):
		out_of_bounds_timer += delta
		if destroy_out_of_bounds and out_of_bounds_timer > out_of_bounds_timeout:
			_control.queue_free()
			is_flying = false
	else:
		out_of_bounds_timer = 0.0


## 归位到原始位置（带缓动）
func _return_to_original_position():
	if not _control:
		return
	
	is_flying = false
	velocity = Vector2.ZERO
	
	# 杀掉旧的 tween（如果存在）
	if _return_tween and _return_tween.is_valid():
		_return_tween.kill()
		_return_tween = null
	
	# 创建新 tween
	_return_tween = _control.create_tween()
	_return_tween.set_trans(Tween.TRANS_BACK)
	_return_tween.set_ease(Tween.EASE_OUT)
	_return_tween.tween_property(_control, "position", original_position, return_duration)
	
	_return_tween.finished.connect(func():
		_return_tween = null
		_control.z_index = 0
	, CONNECT_ONE_SHOT)


func _on_return_finished():
	_control.z_index = 0

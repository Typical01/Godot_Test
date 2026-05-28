extends Node2D
class_name Thrower

## 发射初速度
@export var initial_speed: float = 2400.0

## 摆动范围（角度，单位：度）
@export var swing_range: float = 10.0  # 左右各30度

## 摆动速度（度/秒）
@export var swing_speed: float = 1.0

## 基准方向（向下）
@export var base_direction: Vector2 = Vector2.DOWN

## 是否持续摆动
@export var auto_swing: bool = true

## 显示箭头
@export var _debug: bool = false

## 当前实时方向（只读）
var current_direction: Vector2 = Vector2.DOWN


func _process(delta: float):
	if not auto_swing:
		return
	
	# 方式一：用 sin 来回摆动
	var angle_rad = deg_to_rad(swing_range * sin(Time.get_ticks_msec() / 1000.0 * swing_speed))
	
	# 方式二：用 pingpong 线性来回（注释掉上面，取消注释下面）
	# var t = Time.get_ticks_msec() / 1000.0 * swing_speed / 90.0
	# var angle_deg = pingpong(t, 1.0) * swing_range * 2 - swing_range
	# var angle_rad = deg_to_rad(angle_deg)
	
	# 计算最终方向
	var rotated_dir = base_direction.rotated(angle_rad)
	current_direction = rotated_dir.normalized()
	
	# 可选：更新节点的旋转角度（让编辑器里的箭头也跟着转）
	rotation = angle_rad
	
	# 每帧更新 debug 视图
	queue_redraw()


## 获取当前方向（供外部调用）
func get_current_direction() -> Vector2:
	return current_direction


## 抛射目标（使用当前实时方向）
func throw_target(target: Control) -> void:
	var flyable = target.get_node_or_null("FlyableComponent")
	if not flyable:
		flyable = FlyableComponent.new()
		target.add_child(flyable)
	
	# 使用当前摆动方向
	var number = randf()
	while(number < 0.5):
		number *= 2
	flyable.launch(current_direction, initial_speed * (clampf(number, 0.0, 0.9)))


## 手动抛射（指定特定方向，忽略摆动）
func throw_target_with_direction(target: Control, direction: Vector2) -> void:
	var flyable = target.get_node_or_null("FlyableComponent")
	if not flyable:
		flyable = FlyableComponent.new()
		target.add_child(flyable)
	var number = randf()
	while(number < 0.5):
		number *= 2
	flyable.launch(direction.normalized(), initial_speed * (clampf(number, 0.0, 0.9)))


## 可视化调试（在编辑器中显示方向箭头）
func _draw():
	if not _debug: return
	
	var arrow_length = 60.0
	var arrow_end = current_direction * arrow_length
	draw_line(Vector2.ZERO, arrow_end, Color.YELLOW, 3.0)
	
	# 绘制箭头头部
	var arrow_head_size = 10.0
	var perpendicular = current_direction.orthogonal() * arrow_head_size * 0.5
	draw_line(arrow_end, arrow_end - current_direction * arrow_head_size + perpendicular, Color.YELLOW, 3.0)
	draw_line(arrow_end, arrow_end - current_direction * arrow_head_size - perpendicular, Color.YELLOW, 3.0)
	
	# 绘制摆动范围示意弧线
	var radius = 50.0
	var start_angle = -deg_to_rad(swing_range / 2)
	var end_angle = deg_to_rad(swing_range / 2)
	draw_arc(Vector2.ZERO, radius, start_angle, end_angle, 32, Color.YELLOW, 1.0, true)

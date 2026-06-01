extends RigidBody3D

# 定义6个方向及其对应的点数（根据你的骰子模型实际朝向调整）
@export var face_values: Dictionary = {
	Vector3.RIGHT:  3,   # 模型右面 -> 1点
	Vector3.LEFT:   6,   # 左面 -> 6点
	Vector3.UP:     5,   # 上面 -> 2点
	Vector3.DOWN:   1,   # 下面 -> 5点
	Vector3.FORWARD: 4,  # 前面 -> 4点
	Vector3.BACK:   2    # 后面 -> 3点
}

# 投掷参数（可在编辑器中调整）
@export var throw_force_min: float = 5000.0   ## 最小投掷力度
@export var throw_force_max: float = 20000.0  ## 最大投掷力度
@export var throw_torque_min: float = 1000.0  ## 最小旋转扭矩
@export var throw_torque_max: float = 4000.0  ## 最大旋转扭矩
@export var random_direction: bool = true  ## 是否随机方向


@onready var number_node = %LabelNumber

var current_face: int = 1  # 当前朝上的点数
var is_rolling: bool = false
var settle_timer: float = 0.0
var last_velocity: Vector3

func _ready():
	#number_node.visible = false
	# 模拟投掷
	throw_dice()
	pass
	# 确保骰子使用正确的物理材质（有弹性更真实）
	#if not physics_material_override:
	#	physics_material_override = PhysicsMaterial.new()
	#physics_material_override.bounce = 0.4
	#physics_material_override.friction = 0.8

func _integrate_forces(state: PhysicsDirectBodyState3D):
	# 每帧更新当前朝上的面
	current_face = get_top_face()
	
	# 检测是否停止滚动（速度极小且角速度极小）
	var is_moving = state.linear_velocity.length() > 0.1 or state.angular_velocity.length() > 0.1
	
	if is_moving:
		is_rolling = true
		settle_timer = 0.0
	else:
		settle_timer += state.step
		# 停止滚动后0.3秒，认为骰子已稳定
		if settle_timer > 0.3 and is_rolling:
			is_rolling = false
			_on_dice_settled(current_face)

func throw_dice():
	# 随机生成投掷力度
	var force_magnitude = randf_range(throw_force_min, throw_force_max)
	
	# 随机生成旋转扭矩
	var torque_magnitude = randf_range(throw_torque_min, throw_torque_max)
	
	# 计算投掷方向（可选择随机或固定方向）
	var throw_direction: Vector3
	if random_direction:
		# 随机方向：水平方向随机 + 向上的分量（模拟抛起）
		throw_direction = Vector3(
			randf_range(-1.0, 1.0),
			randf_range(0.5, 1.2),  # 向上抛起
			randf_range(-1.0, 1.0)
		).normalized()
	else:
		# 固定方向，例如向前抛
		throw_direction = Vector3(0, 0.8, 1).normalized()
	
	# 随机旋转轴
	var torque_axis = Vector3(
		randf_range(-1.0, 1.0),
		randf_range(-1.0, 1.0),
		randf_range(-1.0, 1.0)
	).normalized()
	
	# 🚀 施加力和扭矩
	apply_central_force(throw_direction * force_magnitude)
	apply_torque(torque_axis * torque_magnitude)
	
	print("投掷! 力度: %.1f, 扭矩: %.1f" % [force_magnitude, torque_magnitude])

func get_top_face() -> int:
	# 获取骰子在全局坐标系中的变换基
	var b := global_transform.basis.orthonormalized()
	
	# 方法1：用全局Y轴（朝上）反向变换到局部坐标，找到最朝上的局部方向
	var local_up = b.inverse() * Vector3.UP
	var best_direction = Vector3.ZERO
	var best_dot = -1.0
	
	# 遍历6个局部方向，找出与全局向上方向最接近的那个
	for direction in face_values.keys():
		var dot = direction.dot(local_up)
		if dot > best_dot:
			best_dot = dot
			best_direction = direction
	
	return face_values[best_direction]

func _on_dice_settled(value: int):
	print("骰子点数是: ", value)
	number_node.visible = true
	number_node.text = str(value)
	# 在这里触发你的游戏逻辑，比如：显示结果、增加分数等

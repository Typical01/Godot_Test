extends Area2D

## 有效范围模式
enum RangeMode {
	In,   	## 在范围内部
	Out,  	## 在范围外部
	Border 	## 在边框上
}

@onready var range_shape: CollisionShape2D = $Range
@onready var object_timer: Timer = $ObjectTimer

@export var facing_angle_offset_deg: float = 0.0 ## 资源朝向偏移，0 表示资源 0° 朝右
@export var range_mode: RangeMode = RangeMode.Border ## 范围模式
@export var object_direction: bool = false ## 是否设置生成对象朝向（朝向区域内部）
@export var border_thickness: float = 1.0 ## 边框厚度（像素）
@export var speed_min: float = 200.0 ## 速度: 最小
@export var speed_max: float = 300.0 ## 速度: 最大
@export var generate_speed: float = 0.5 ## 生成速度
@export var object_scale = Vector2(1.0, 1.0) ##场景对象: 缩放

@export var object_scene: PackedScene ##场景: 对象
@export var sound: Node ##节点: 生成音效

var screen_size: Vector2
var rect: Rect2
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	coord_utils.window_size_changed.connect(on_window_size_changed)
	
	$ObjectTimer.wait_time = generate_speed
	_rng.randomize()

	# 连接计时器信号
	if object_timer:
		object_timer.connect("timeout", Callable(self, "_on_object_timer_timeout"))

	# 检查 range_shape 是否存在且为 CollisionShape2D
	if not range_shape:
		push_error("Generate: 找不到子节点 $Range（CollisionShape2D）")
	pass


func _process(delta: float) -> void:
	pass
	
	
func on_window_size_changed(window_size):
	if window_size != screen_size:
		screen_size = window_size
		update_range_shape()
		# 补全, 将屏幕大小设置为shape2d
		range_shape.shape.size = screen_size * object_scale
		# 取得范围的屏幕/全局 Rect2
		rect = get_background_screen_rect(range_shape)
		#rect.size *= object_scale
	print("Generate: 窗口大小修改 ", screen_size)
	print("Generate: 范围大小修改 ", range_shape.shape.size)
	pass

# 将当前 screen_size 应用到 range_shape（CollisionShape2D）
func update_range_shape() -> void:
	if range_shape == null or range_shape.shape == null:
		push_warning("range_shape or its shape is null; cannot update shape size.")
		return

	var s = range_shape.shape

	# 把 CollisionShape2D 放到屏幕中心（转换为本地坐标）
	var screen_center := screen_size * 0.5
	# to_local 接受全局坐标并返回本地坐标（Area2D/Node2D）
	range_shape.position = to_local(screen_center)

	# 根据不同 shape 类型调整参数
	if s is RectangleShape2D:
		# RectangleShape2D 使用 extents（半宽半高）
		# 减去一点边框厚度以避免越界（如果需要）
		var ext := (screen_size * 0.5) - Vector2(border_thickness, border_thickness)
		# 防止负值
		ext.x = max(ext.x, 0.0)
		ext.y = max(ext.y, 0.0)
		s.extents = ext

	elif s is CircleShape2D:
		# 半径设为屏幕最短边的一半（并减去边框）
		var r = min(screen_size.x, screen_size.y) * 0.5 - border_thickness
		s.radius = max(r, 0.0)

	elif s is CapsuleShape2D:
		# CapsuleShape2D 在 Godot 4 有 radius 和 height
		# 我们把半径设为屏幕宽的一半，高度设为屏幕高减去直径
		var rad := (screen_size.x * 0.5) - border_thickness
		rad = max(rad, 0.0)
		var h := screen_size.y - rad * 2.0 - border_thickness * 2.0
		h = max(h, 0.0)
		# 注意属性名可能依 Godot 版本略有差异（height / length）
		if "radius" in s:
			s.radius = rad
		if "height" in s:
			s.height = h

	elif s is ConvexPolygonShape2D:
		# 把多边形设置为覆盖整个屏幕（矩形多边形）
		var p := PackedVector2Array()
		p.append(Vector2(-screen_size.x * 0.5 + border_thickness, -screen_size.y * 0.5 + border_thickness))
		p.append(Vector2(screen_size.x * 0.5 - border_thickness, -screen_size.y * 0.5 + border_thickness))
		p.append(Vector2(screen_size.x * 0.5 - border_thickness, screen_size.y * 0.5 - border_thickness))
		p.append(Vector2(-screen_size.x * 0.5 + border_thickness, screen_size.y * 0.5 - border_thickness))
		# ConvexPolygonShape2D 的点集合在 points 或 polygon（视 Godot 版本），优先尝试 points
		if "points" in s:
			s.points = p
		elif "polygon" in s:
			s.polygon = p
		else:
			push_warning("ConvexPolygonShape2D: couldn't find points/polygon property to set.")

	else:
		# 其他不常见的 shape，尝试打印提示
		push_warning("Unsupported shape type: %s. Please handle it manually." % [s.get_class()])

func _on_object_timer_timeout() -> void:
	# 使用导出的 object_scene（若为空则仅打印）
	if not object_scene:
		print("Generate: object_scene 未设置（将使用默认生成）。")
	# 如果 rect 是空（例如 shape 不是 RectangleShape2D），跳过
	if rect.size == Vector2.ZERO:
		print("Generate: range_shape 未返回有效 Rect2。")
		return
	#print(rect)
	if sound and sound is AudioStreamPlayer: sound.play()
	spawn_object_by_range(rect)
	pass


## 将 CollisionShape2D 的矩形区域转换成屏幕/全局坐标系 Rect2
func get_background_screen_rect(cshape: CollisionShape2D) -> Rect2:
	if not cshape:
		return Rect2()
	var shape = cshape.shape
	if shape is RectangleShape2D:
		var half_extents: Vector2 = shape.extents
		# 四个角点（相对于 cshape 的本地坐标）
		var a = Vector2(-half_extents.x, -half_extents.y)
		var b = Vector2(half_extents.x, -half_extents.y)
		var c = Vector2(half_extents.x, half_extents.y)
		var d = Vector2(-half_extents.x, half_extents.y)

		# 转换到全局（CanvasItem 的 to_global）
		a = cshape.to_global(a)
		b = cshape.to_global(b)
		c = cshape.to_global(c)
		d = cshape.to_global(d)

		var minx = min(a.x, b.x, c.x, d.x)
		var miny = min(a.y, b.y, c.y, d.y)
		var maxx = max(a.x, b.x, c.x, d.x)
		var maxy = max(a.y, b.y, c.y, d.y)
		return Rect2(Vector2(minx, miny), Vector2(maxx - minx, maxy - miny))

	# 暂不支持其它 shape 类型
	return Rect2()


## 生成对象（优先使用 object_scene，如果没有则生成简单的 Area2D 作为后备）
# screen_pos: 屏幕坐标（例如 UI / 屏幕像素坐标）
# screen_rect: 目标区域的屏幕/全局 Rect2（用于计算朝向）
# side: 若 <=0 则使用屏幕最小边长
# set_dir: 是否设置方向（对象朝向区域内部）
func _spawn_object_at_screen_position(screen_pos: Vector2, screen_rect: Rect2, side: float = -1.0, set_dir: bool = false) -> Node2D:
	if side <= 0.0:
		side = min(screen_size.x, screen_size.y)

	# 屏幕 -> 世界坐标
	var world_pos: Vector2 = get_viewport().get_canvas_transform().affine_inverse() * screen_pos

	var inst: Node2D = null

	# ---------- 实例化对象 ----------
	if object_scene:
		var obj = object_scene.instantiate()
		if obj is Node2D:
			inst = obj
		else:
			var wrapper = Node2D.new()
			wrapper.add_child(obj)
			inst = wrapper
	else:
		# 后备 Area2D
		var a = Area2D.new()
		var cs = CollisionShape2D.new()
		var rect_shape = RectangleShape2D.new()
		rect_shape.extents = Vector2(side * 0.5, side * 0.5)
		cs.shape = rect_shape
		a.add_child(cs)
		inst = a

	# ---------- 加入场景 ----------
	var parent_node: Node = get_parent() if get_parent() else get_tree().get_root()
	if parent_node:
		parent_node.add_child(inst)
	else:
		get_tree().get_root().add_child(inst)

	# ---------- 设置位置 ----------
	if inst is Node2D:
		inst.global_position = world_pos

	# ---------- 设置朝向 ----------
	if set_dir and inst is Node2D:
		var dir = _get_random_direction_by_range(screen_pos, screen_rect)
		var world_target = world_pos + dir
		inst.global_rotation = (world_target - world_pos).angle() + deg_to_rad(facing_angle_offset_deg)

		# 自动修正镜像 / 父节点 scale 导致的反向
		var forward_world := inst.to_global(Vector2.RIGHT) - inst.global_position
		if forward_world.dot(dir) < 0.0:
			inst.global_rotation += PI
			
		# 线速度
		var speed = _rng.randf_range(speed_min, speed_max)
		# 假设对象有 velocity 属性
		if "velocity" in inst:
			inst.velocity = dir.normalized() * speed
		# 如果是 RigidBody2D，可以改成 linear_velocity
		elif "linear_velocity" in inst:
			inst.linear_velocity = dir.normalized() * speed

	return inst


# ---------- 根据生成位置和 range_mode 随机生成方向 ----------
func _get_random_direction_by_range(screen_pos: Vector2, screen_rect: Rect2) -> Vector2:
	if screen_rect.size == Vector2.ZERO:
		return Vector2(_rng.randf_range(-1.0,1.0), _rng.randf_range(-1.0,1.0)).normalized()

	var center = screen_rect.position + screen_rect.size * 0.5
	var dir_to_center = center - screen_pos

	match range_mode:
		RangeMode.In:
			var angle = dir_to_center.angle() + deg_to_rad(_rng.randf_range(-45, 45))
			return Vector2(cos(angle), sin(angle)).normalized()
		RangeMode.Border:
			var angle = dir_to_center.angle() + deg_to_rad(_rng.randf_range(-30, 30))
			return Vector2(cos(angle), sin(angle)).normalized()
		RangeMode.Out:
			var clamped = Vector2(
				clamp(screen_pos.x, screen_rect.position.x, screen_rect.position.x + screen_rect.size.x),
				clamp(screen_pos.y, screen_rect.position.y, screen_rect.position.y + screen_rect.size.y)
			)
			var angle = (clamped - screen_pos).angle() + deg_to_rad(_rng.randf_range(-20, 20))
			return Vector2(cos(angle), sin(angle)).normalized()
		_:
			return Vector2(_rng.randf_range(-1.0,1.0), _rng.randf_range(-1.0,1.0)).normalized()


func spawn_object_by_range(screen_rect: Rect2) -> void:
	var spawn_pos: Vector2
	match range_mode:
		RangeMode.In:
			spawn_pos = _rand_point_inside_rect(screen_rect)
		RangeMode.Out:
			spawn_pos = _rand_point_outside_rect(screen_rect)
		RangeMode.Border:
			spawn_pos = _rand_point_on_border(screen_rect, border_thickness, null)
		_:
			spawn_pos = _rand_point_inside_rect(screen_rect)

	var obj = _spawn_object_at_screen_position(spawn_pos, screen_rect, -1.0, object_direction)
	if obj:
		obj.name = "spawned_obj_%d" % _rng.randi()
	pass


## ---------- 随机点生成器（基于屏幕/全局坐标） ----------
func _rand_point_inside_rect(screen_rect: Rect2) -> Vector2:
	var x = _rng.randf_range(screen_rect.position.x, screen_rect.position.x + screen_rect.size.x)
	var y = _rng.randf_range(screen_rect.position.y, screen_rect.position.y + screen_rect.size.y)
	return Vector2(x, y)


func _rand_point_outside_rect(screen_rect: Rect2) -> Vector2:
	var tries = 0
	while tries < 64:
		var x = _rng.randf_range(0.0, screen_size.x)
		var y = _rng.randf_range(0.0, screen_size.y)
		var p = Vector2(x, y)
		if not screen_rect.has_point(p):
			return p
		tries += 1
	var corners = [Vector2(0,0), Vector2(screen_size.x,0), Vector2(0,screen_size.y), Vector2(screen_size.x, screen_size.y)]
	return corners[_rng.randi_range(0, corners.size() - 1)]


func _rand_point_on_border(screen_rect: Rect2, thickness: float, direction = null) -> Vector2:
	var r = screen_rect
	var t = clamp(thickness, 0.0, min(r.size.x, r.size.y) * 0.5)

	if direction and direction != Vector2.ZERO:
		var d = direction.normalized()
		if abs(d.x) >= abs(d.y):
			if d.x > 0:
				var x = _rng.randf_range(r.position.x + r.size.x - t, r.position.x + r.size.x)
				var y = _rng.randf_range(r.position.y, r.position.y + r.size.y)
				return Vector2(x, y)
			else:
				var x = _rng.randf_range(r.position.x, r.position.x + t)
				var y = _rng.randf_range(r.position.y, r.position.y + r.size.y)
				return Vector2(x, y)
		else:
			if d.y > 0:
				var y = _rng.randf_range(r.position.y + r.size.y - t, r.position.y + r.size.y)
				var x = _rng.randf_range(r.position.x, r.position.x + r.size.x)
				return Vector2(x, y)
			else:
				var y = _rng.randf_range(r.position.y, r.position.y + t)
				var x = _rng.randf_range(r.position.x, r.position.x + r.size.x)
				return Vector2(x, y)

	var edge = _rng.randi_range(0, 3)
	if edge == 0:
		var x = _rng.randf_range(r.position.x, r.position.x + t)
		var y = _rng.randf_range(r.position.y, r.position.y + r.size.y)
		return Vector2(x, y)
	elif edge == 1:
		var y = _rng.randf_range(r.position.y, r.position.y + t)
		var x = _rng.randf_range(r.position.x, r.position.x + r.size.x)
		return Vector2(x, y)
	elif edge == 2:
		var x = _rng.randf_range(r.position.x + r.size.x - t, r.position.x + r.size.x)
		var y = _rng.randf_range(r.position.y, r.position.y + r.size.y)
		return Vector2(x, y)
	else:
		var y = _rng.randf_range(r.position.y + r.size.y - t, r.position.y + r.size.y)
		var x = _rng.randf_range(r.position.x, r.position.x + r.size.x)
		return Vector2(x, y)

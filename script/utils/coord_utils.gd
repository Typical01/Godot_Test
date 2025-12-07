# res://utils/coord_utils.gd
extends Node
class_name CoordUtils


signal window_size_changed(window_size)



var window = null
var screen_size: Vector2



func _ready() -> void:
	window = get_window()
	window.size_changed.connect(on_window_size_changed)
	on_window_size_changed()
	pass


func on_window_size_changed():
	screen_size = get_viewport().get_visible_rect().size
	window_size_changed.emit(screen_size)
	pass


# -----------------------
# 窗口 / 视口 尺寸相关
# -----------------------
## 设置在屏幕中的全局位置: 节点, 在屏幕中的比例, 是否枢轴居中
func set_screen_global_position(node: Node, screen_position_ratio: Vector2, pivot_offset_center = true) -> void:
	var pos := Vector2(screen_size.x * screen_position_ratio.x, screen_size.y * screen_position_ratio.y)
	if pivot_offset_center:
		align_node_center_to_pos(node, pos)
	else:
		# 不以中心对齐，直接放到 pos（注意 Control 的 global_position 是左上角）
		node.global_position = pos


# pos: 目标屏幕像素位置（例如 screen_size * ratio）
func align_node_center_to_pos(node: Node, pos: Vector2) -> void:
	# Control (UI) - size 可能在 _ready() 未稳定，按需 deferred
	if node is Control:
		var size = node.size
		if size == Vector2.ZERO:
			size = node.get_minimum_size()
			if size == Vector2.ZERO:
				call_deferred("_deferred_align_control_center", node, pos)
				return
		node.global_position = pos - size * 0.5
		return

	# Sprite2D / Node2D
	if node is Sprite2D:
		# 计算显示尺寸（纹理大小 * 缩放）
		var sprite_size := Vector2.ZERO
		if node.texture:
			sprite_size = node.texture.get_size() * node.scale
		# 根据 centered 属性决定如何赋值
		if node.centered:
			# position 是精灵中心 -> 直接把中心放到 pos
			node.global_position = pos
		else:
			# position 是左上角 -> 把左上角放到 pos - size/2
			node.global_position = pos - sprite_size * 0.5
		return

	# 其他 Node2D（比如自定义 Node2D）
	if node is Node2D:
		# 如果你想按中心对齐，尝试寻找 node 的“尺寸”来源再处理；保守做法直接设置
		node.global_position = pos
		return

	# 默认兜底
	node.global_position = pos


func _deferred_align_control_center(node: Control, pos: Vector2) -> void:
	var size := node.size
	if size == Vector2.ZERO:
		size = node.get_minimum_size()
	node.global_position = pos - size * 0.5


# 返回“渲染视口的可见矩形大小”（像素）
# 推荐用于 UI/像素布局：优先使用 viewport 的 visible_rect，因为 DisplayServer 在某些 4.4 情况下会混淆窗口/viewport。
func get_viewport_size() -> Vector2:
	# 若从 Node 上下文调用，建议传入节点并用 node.get_viewport()，但作为单例我们尝试从 SceneTree root 拿
	var root = get_tree().get_root()
	if root:
		var vp := root.get_viewport()
		if vp:
			return vp.get_visible_rect().size
	# 回退
	return DisplayServer.window_get_size()


# 返回 OS 窗口大小（注意：在某些 4.4 情况下文档与行为可能不一致）
func get_window_size() -> Vector2:
	return DisplayServer.window_get_size()


# -----------------------
# 屏幕 <-> 世界 坐标转换
# -----------------------

func debug_screen_to_world(screen_pos: Vector2, camera: Camera2D = null) -> void:
	print("screen_pos:", screen_pos)
	print("camera passed:", camera)
	var cam := camera
	if cam == null:
		var vp = get_viewport() # 如果在单例，请用 get_tree().get_root().get_viewport(0)
		print("viewport:", vp)
		if vp:
			cam = vp.get_camera_2d()  # 尝试从 viewport 拿当前 camera2d
			print("viewport.get_camera_2d():", cam)
	if cam:
		var t = cam.get_canvas_transform()
		print("camera canvas_transform:", t)
		print("canvas_transform.inverse:", t.affine_inverse())
		print("mapped:", t.affine_inverse() * screen_pos)
	else:
		var vp = get_viewport()
		if vp:
			var t2 = vp.get_canvas_transform()
			print("root viewport canvas_transform:", t2)
			print("root inverse:", t2.affine_inverse())
			print("mapped:", t2.affine_inverse() * screen_pos)


# 屏幕（viewport / event.position） -> 世界(canvas) 坐标
# 优先：传入当前使用的 Camera2D（更精确，考虑 camera zoom/offset/rotation）
# 备选：camera 为 null 时尝试用 viewport 的 canvas_transform（对简单场景通常可用）
func screen_to_world(screen_pos: Vector2, camera: Camera2D = null) -> Vector2:
	if camera != null:
		return camera.get_canvas_transform().affine_inverse() * screen_pos
	# 备用：从根 viewport 获取 canvas_transform
	var root = get_tree().get_root()
	if root:
		var vp = root.get_viewport()
		if vp:
			return vp.get_canvas_transform().affine_inverse() * screen_pos
	push_warning("screen_to_world：未找到摄像头且没有根视口; 返回屏幕位置")
	return screen_pos


# 世界(canvas) -> 屏幕坐标
func world_to_screen(world_pos: Vector2, camera: Camera2D = null) -> Vector2:
	if camera != null:
		return camera.get_canvas_transform() * world_pos
	var root = get_tree().get_root()
	if root:
		var vp = root.get_viewport()
		if vp:
			return vp.get_canvas_transform() * world_pos
	push_warning("world_to_screen：未找到相机和根视口; 返回 world_pos")
	return world_pos


# -----------------------
# 局部节点坐标 <-> 屏幕 坐标
# -----------------------

# 把 Node2D 的局部坐标转换成屏幕坐标（方便把 UI/提示放在节点上）
# node: Node2D 实例；local_pos: 节点局部坐标（比如 Vector2.ZERO）
# camera: 推荐传入当前 Camera2D（若不传会尝试用 root viewport transform）
func node_local_to_screen(node: Node2D, local_pos: Vector2, camera: Camera2D = null) -> Vector2:
	var world_pos = node.to_global(local_pos) # Node2D.to_global 可用
	return world_to_screen(world_pos, camera)


# 把屏幕坐标转换为某个 Node2D 的局部坐标
func screen_to_node_local(node: Node2D, screen_pos: Vector2, camera: Camera2D = null) -> Vector2:
	var world_pos = screen_to_world(screen_pos, camera)
	return node.to_local(world_pos)


# -----------------------
# 辅助：尝试找到当前场景的 active Camera2D（若你没有显式传 camera）
# 说明：项目中最好显式传入 camera（性能/确定性更好），此函数为备选查找策略。
# -----------------------
func find_current_camera2d() -> Camera2D:
	var root_scene = get_tree().get_current_scene()
	if not root_scene:
		return null
	# 优先查找 current = true 的 Camera2D
	for c in root_scene.get_children():
		if c is Camera2D and c.current:
			return c
	# 退而求其次：深度搜索第一个 Camera2D（如果你只有一个 camera）
	var all = root_scene.get_tree().get_nodes_in_group("Camera2D")
	for n in all:
		if n is Camera2D:
			return n
	# 无结果
	return null

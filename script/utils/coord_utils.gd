# res://utils/coord_utils.gd
extends Node
class_name CoordUtils

# -----------------------
# 窗口 / 视口 尺寸相关
# -----------------------

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

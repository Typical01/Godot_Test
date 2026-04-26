extends TextureRect



@export var horizontal_offset: float = 20  # 气泡与鼠标的水平间距
@export var vertical_offset: float = 20  # 气泡与鼠标的垂直间距
@export_multiline var item_name: String:  # 气泡提示文本
	get():
		return %Tips.text
	set(new_text):
		%Tips.text = new_text



func _ready() -> void:
	#%Tips.text = item_name
	pass

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		set_tips_position()
	if event is InputEventScreenDrag:
		set_tips_position()

func _on_mouse_entered() -> void:
	%Tips.visible = true

func _on_mouse_exited() -> void:
	%Tips.visible = false



func set_tips_position():
	# 1. 获取信息
	var mouse_pos: Vector2 = get_viewport().get_mouse_position()
	var screen_size: Vector2 = get_viewport().get_visible_rect().size
	var bubble_size: Vector2 = %Tips.size
	# 2. 水平自适应：决定气泡显示在鼠标左侧还是右侧
	var bubble_pos_x: float
	# 如果鼠标在屏幕右侧，气泡显示在左侧
	if mouse_pos.x > screen_size.x / 2:
		bubble_pos_x = mouse_pos.x - bubble_size.x - horizontal_offset
	else:  # 鼠标在屏幕左侧，气泡显示在右侧
		bubble_pos_x = mouse_pos.x + horizontal_offset
	# 3. 垂直自适应：决定气泡显示在鼠标上方还是下方
	var bubble_pos_y: float
	# 如果鼠标在屏幕下半部分，气泡显示在上方
	if mouse_pos.y > screen_size.y / 2:
		bubble_pos_y = mouse_pos.y - bubble_size.y - vertical_offset
	else:  # 鼠标在屏幕上半部分，气泡显示在下方
		bubble_pos_y = mouse_pos.y + vertical_offset
	# 4. 组合位置并应用边界保护
	var bubble_pos = Vector2(bubble_pos_x, bubble_pos_y)
	bubble_pos.x = clamp(bubble_pos.x, 10, screen_size.x - bubble_size.x - 10)
	bubble_pos.y = clamp(bubble_pos.y, 10, screen_size.y - bubble_size.y - 10)
	# 5. 应用位置
	%Tips.global_position = bubble_pos

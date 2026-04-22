extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	visible = false
	%InfoBorder.position -= Vector2(1, 1)
	%SellBorder.position -= Vector2(1, 1)
	self_modulate = Color(1, 1, 1, 0)
	pass # Replace with function body.


func _process(delta: float) -> void:
	if not visible: set_container_size()

func show_info(is_show: bool, data: Goods = null):
	visible = is_show
	if not is_show: return
	%InfoValue.text = str(data.value)
	%GoodsName.text = data.name
	position = get_global_mouse_position() + pivot_offset

func set_container_size():
	# 1. 获取信息
	var mouse_pos: Vector2 = get_viewport().get_mouse_position()
	var screen_size: Vector2 = get_viewport().get_visible_rect().size
	var bubble_size: Vector2 = %ItemSimpleInformation.size  # 提前获取尺寸，避免重复调用
	# 2. 水平自适应：决定气泡显示在鼠标左侧还是右侧
	var bubble_pos_x: float
	var horizontal_offset: float = 10  # 气泡与鼠标的水平间距
	# 如果鼠标在屏幕右侧，气泡显示在左侧
	if mouse_pos.x > screen_size.x / 2:
		bubble_pos_x = mouse_pos.x - bubble_size.x - horizontal_offset
	else:  # 鼠标在屏幕左侧，气泡显示在右侧
		bubble_pos_x = mouse_pos.x + horizontal_offset
	# 3. 垂直自适应：决定气泡显示在鼠标上方还是下方
	var bubble_pos_y: float
	var vertical_offset: float = 10  # 气泡与鼠标的垂直间距
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
	%Info.global_position = bubble_pos
	
	%SellBorder.size = %Sell.size + Vector2(2, 2)
	%ItemSimpleInformation.size = %InfoContainer.size + Vector2(8, 8)
	%InfoBorder.size = %ItemSimpleInformation.size + Vector2(2, 2)

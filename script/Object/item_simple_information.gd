class_name ItemSimpleInformation extends Control


signal sell()


@export var info_offset: Vector2 = Vector2(20, 20) ## 气泡与鼠标的间距



func _ready() -> void:
	#visible = false
	self_modulate = Color(1, 1, 1, 0)



func show_info(data: Goods = null, is_show: bool = true):
	if not is_show: 
		visible = false
		return
	if not data:
		#push_error("data == null!")
		visible = false
		return
	set_container_size()
	visible = true
	%InfoValue.text = str(data.value)
	%GoodsName.text = data.name

func set_container_size():
	# 1. 获取信息
	var mouse_pos: Vector2 = get_viewport().get_mouse_position()
	var screen_size: Vector2 = get_viewport().get_visible_rect().size
	var bubble_size: Vector2 = %ItemSimpleInformation.size  # 提前获取尺寸，避免重复调用
	# 2. 水平自适应：决定气泡显示在鼠标左侧还是右侧
	var bubble_pos_x: float
	# 如果鼠标在屏幕右侧，气泡显示在左侧
	if mouse_pos.x > screen_size.x / 2:
		bubble_pos_x = mouse_pos.x - bubble_size.x - info_offset.x
	else:  # 鼠标在屏幕左侧，气泡显示在右侧
		bubble_pos_x = mouse_pos.x + info_offset.x
	# 3. 垂直自适应：决定气泡显示在鼠标上方还是下方
	var bubble_pos_y: float
	# 如果鼠标在屏幕下半部分，气泡显示在上方
	if mouse_pos.y > screen_size.y / 2:
		bubble_pos_y = mouse_pos.y - bubble_size.y - info_offset.y
	else:  # 鼠标在屏幕上半部分，气泡显示在下方
		bubble_pos_y = mouse_pos.y + info_offset.y
	# 4. 组合位置并应用边界保护
	var bubble_pos = Vector2(bubble_pos_x, bubble_pos_y)
	#bubble_pos.x = clamp(bubble_pos.x, 10, screen_size.x - bubble_size.x - 10)
	#bubble_pos.y = clamp(bubble_pos.y, 10, screen_size.y - bubble_size.y - 10)
	# 5. 应用位置
	global_position = bubble_pos
	
	#%SellBorder.size = %Sell.size + Vector2(2, 2)
	%ItemSimpleInformation.size = %Control.size - Vector2(2, 2)
	%ItemSimpleInformation.position = Vector2(1, 1)
	%PanelContainer.size = %Control.size + Vector2(2, 2)



func _on_sell_button_up() -> void:
	sell.emit()

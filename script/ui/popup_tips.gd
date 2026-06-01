extends CanvasLayer


@export var item_name: String = "Name":
	set(new_text):
		item_name = new_text
		%ItemName.text = new_text

@export var fade_in_duration: float = 0.3
@export var fade_out_duration: float = 0.3
@export var display_duration: float = 1.0  # 显示持续时间
@export var vertical_offset: float = 20.0  # 距离顶部的偏移
@export var enter_distance: float = 50.0   # 进入距离（从上方多少像素开始）

@onready var tween: Tween
var parent_rect: Rect2
var target_position: Vector2  # 目标显示位置
var start_position: Vector2   # 进入起始位置（上方）

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	layer = 100
	
	%ItemName.text = item_name
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

# 显示/隐藏提示
func _on_show_tips(is_show: bool, parent_node: Control):
	update_position(parent_node)
	if is_show:
		# 淡入效果
		_fade_in()
	else: 
		# 淡出效果
		_fade_out()

# 更新位置
func update_position(parent_node: Control):
	if not parent_node:
		printerr("PopupTips: update_position: 传入父节点为空!")
		return
	if parent_node:
		var parent_global_pos = parent_node.global_position
		var parent_size = parent_node.size
		parent_rect = Rect2(parent_global_pos, parent_size)
	# 计算目标位置（父节点顶部居中显示）
	var target_x = parent_rect.position.x + (parent_rect.size.x - %PopupTip.size.x) / 2
	var target_y = parent_rect.position.y + vertical_offset
	target_position = Vector2(target_x, target_y)
	# 计算起始位置（目标位置上方的 enter_distance 像素处）
	start_position = target_position + Vector2(0, -enter_distance)
	# 初始设置为起始位置
	%PopupTip.global_position = start_position
	#print("目标位置: ", target_position)
	#print("起始位置: ", start_position)

func _fade_in():
	visible = true
	# 停止之前的补间动画
	if tween and tween.is_valid():
		tween.kill()
	# 创建新的补间动画
	tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	# 透明度从0到1
	%PopupTip.modulate = Color(1, 1, 1, 0)
	tween.tween_property(%PopupTip, "modulate", Color.WHITE, fade_in_duration)
	# 位置从起始位置移动到目标位置
	tween.parallel().tween_property(%PopupTip, "global_position", target_position, fade_in_duration)
	tween.tween_callback(func(): 
		# 淡入完成后开始计时淡出
		if display_duration > 0:
			get_tree().create_timer(display_duration).timeout.connect(_fade_out)
	)

# 淡出效果
func _fade_out():
	# 停止之前的补间动画
	if tween and tween.is_valid():
		tween.kill()
	# 创建淡出动画
	tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	# 透明度从1到0
	tween.tween_property(%PopupTip, "modulate", Color(1, 1, 1, 0), fade_out_duration)
	# 位置从当前位置退回到起始位置
	tween.parallel().tween_property(%PopupTip, "global_position", start_position, fade_out_duration)
	tween.tween_callback(func(): 
		visible = false
	)

func set_tips_color(color: Color = Color(0, 255, 0, 1)) -> void:
	var panel = %TipsColor as Panel
	var style_box: StyleBoxFlat
	var existing_style = panel.get_theme_stylebox("panel")
	if existing_style is StyleBoxFlat:
		style_box = existing_style.duplicate() as StyleBoxFlat
	else:
		style_box = StyleBoxFlat.new()
		# 设置一些默认属性
		style_box.corner_radius_top_left = 32
		style_box.corner_radius_top_right = 32
		style_box.corner_radius_bottom_left = 32
		style_box.corner_radius_bottom_right = 32
	style_box.bg_color = color
	panel.add_theme_stylebox_override("panel", style_box)

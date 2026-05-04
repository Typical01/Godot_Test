class_name InputRecognizer extends Node

# === 配置常量 ===
const LONG_PRESS_TIME: float = 0.2      # 长按判定时间 (秒)
const DOUBLE_CLICK_TIME: float = 0.1    # 双击间隔时间 (秒)
const CLICK_MOVE_THRESHOLD: float = 5.0 # 点击 / 拖拽移动阈值 (像素)

# === 状态枚举 ===
enum InputState {
	IDLE,           # 空闲状态
	FIRST_PRESS,    # 第一次按下 (等待 release / long-press / drag)
	FIRST_RELEASE,  # 第一次释放 (短按，等待可能的双击)
	LONG_PRESS,     # 已进入长按状态
	DRAGGING        # 正在拖拽 (mouse 或 touch drag)
}

# === 信号 (回调接口) ===
signal single_click(position: Vector2)
signal double_click(position: Vector2)
signal long_press_start(position: Vector2)
signal long_press_end(position: Vector2)
signal drag_start(position: Vector2)
signal drag_move(position: Vector2, delta: Vector2)
signal drag_end(position: Vector2)

# === 状态变量 ===
var state: InputState = InputState.IDLE
var click_timer: float = 0
var double_click_timer: float = 0
var last_press_position: Vector2 = Vector2.ZERO
var last_release_position: Vector2 = Vector2.ZERO
var current_drag_position: Vector2 = Vector2.ZERO
var is_pointer_pressed: bool = false  # 表示当前有按下 (mouse button 或 touch press)


func _process(delta: float) -> void:
	# 定时更新，用于检测长按和双击超时
	_update_timers(delta)
	
func _input(event: InputEvent) -> void:
	# 统一处理鼠标 和 触摸 (single-touch) 事件
	if event is InputEventMouseButton:
		# 鼠标左键按下 / 释放
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_on_press(event.position)
			else:
				_on_release(event.position)
	elif event is InputEventMouseMotion:
		_on_motion(event.position)
	elif event is InputEventScreenTouch:
		# 触摸 (按下 / 释放)
		if event.pressed:
			_on_press(event.position)
		else:
			_on_release(event.position)
	elif event is InputEventScreenDrag:
		# 触摸拖动 (finger drag)
		_on_drag_motion(event.position, event.relative)

func _on_press(position: Vector2) -> void:
	is_pointer_pressed = true
	match state:
		InputState.IDLE:
			state = InputState.FIRST_PRESS
			last_press_position = position
			click_timer = 0
		InputState.FIRST_RELEASE:
			# 检查是否为双击
			if position.distance_to(last_release_position) <= CLICK_MOVE_THRESHOLD:
				state = InputState.IDLE
				double_click_timer = 0
				emit_signal("double_click", position)
			else:
				# 被当作新的点击
				state = InputState.FIRST_PRESS
				last_press_position = position
				click_timer = 0
				double_click_timer = 0
		_:
			# 其他状态：重置 (避免状态混乱)，并当作新一次点击
			_reset_state()
			state = InputState.FIRST_PRESS
			last_press_position = position
			click_timer = 0

func _on_release(position: Vector2) -> void:
	is_pointer_pressed = false
	match state:
		InputState.FIRST_PRESS:
			# 是短按 + 释放 → 可能是单击 (单击 / 长按 / 双击等待状态)
			if click_timer < LONG_PRESS_TIME:
				state = InputState.FIRST_RELEASE
				last_release_position = position
				double_click_timer = 0
			else:
				# 如果按下时间已超过 LONG_PRESS_TIME，视为长按 + 释放
				state = InputState.IDLE
				emit_signal("long_press_end", position)
		InputState.DRAGGING:
			# 拖拽结束
			state = InputState.IDLE
			emit_signal("drag_end", position)
		InputState.LONG_PRESS:
			# 长按释放
			state = InputState.IDLE
			emit_signal("long_press_end", position)
		_:
			# 其他情况，重置
			state = InputState.IDLE

func _on_motion(position: Vector2) -> void:
	# 仅处理鼠标移动 (mouse motion)，用于拖拽判断
	if state == InputState.FIRST_PRESS:
		if position.distance_to(last_press_position) > CLICK_MOVE_THRESHOLD:
			# 从点击转为拖拽
			state = InputState.DRAGGING
			current_drag_position = position
			emit_signal("drag_start", last_press_position)
	elif state == InputState.LONG_PRESS:
		# 如果是长按 + 移动，也视为拖拽
		state = InputState.DRAGGING
		current_drag_position = position
		emit_signal("drag_start", last_press_position)
	elif state == InputState.DRAGGING:
		var delta_move = position - current_drag_position
		emit_signal("drag_move", position, delta_move)
		current_drag_position = position

func _on_drag_motion(position: Vector2, relative: Vector2) -> void:
	# 处理触摸拖动 (InputEventScreenDrag)
	# 如果当前不是拖拽状态 (刚按下 / 长按 / 空闲)，马上进入拖拽
	if state in [InputState.FIRST_PRESS, InputState.LONG_PRESS, InputState.IDLE]:
		state = InputState.DRAGGING
		current_drag_position = position
		emit_signal("drag_start", position)
	else:
		# 已在拖拽中，继续拖动
		var delta_move = relative
		emit_signal("drag_move", position, delta_move)
		current_drag_position = position

func _update_timers(delta: float) -> void:
	if state == InputState.FIRST_PRESS:
		click_timer += delta
		if click_timer >= LONG_PRESS_TIME and is_pointer_pressed:
			state = InputState.LONG_PRESS
			emit_signal("long_press_start", last_press_position)
	elif state == InputState.FIRST_RELEASE:
		double_click_timer += delta
		if double_click_timer >= DOUBLE_CLICK_TIME:
			# 超过双击等待时间 → 视为单击 (single click)
			state = InputState.IDLE
			emit_signal("single_click", last_release_position)

func _reset_state() -> void:
	# 重置状态
	state = InputState.IDLE
	click_timer = 0
	double_click_timer = 0
	last_press_position = Vector2.ZERO
	last_release_position = Vector2.ZERO
	current_drag_position = Vector2.ZERO
	is_pointer_pressed = false

func cancel_current_action() -> void:
	# 如果当前正在拖拽，可以调用此函数取消拖拽
	if state == InputState.DRAGGING:
		emit_signal("drag_end", current_drag_position)
	_reset_state()

# 获取当前状态（调试用）
func get_state_name() -> String:
	return InputState.keys()[state]

# 判断是否正在拖拽
func is_dragging() -> bool:
	return state == InputState.DRAGGING

# 判断是否正在长按
func is_long_pressing() -> bool:
	return state == InputState.LONG_PRESS

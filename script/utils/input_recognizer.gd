class_name InputRecognizer extends CanvasLayer

# === 配置常量 ===
const LONG_PRESS_TIME: float = 0.2      ## 长按判定时间 (秒)
const DOUBLE_CLICK_TIME: float = 0.3    ## 双击间隔时间 (秒)
const CLICK_MOVE_THRESHOLD: float = 25.0 ## 点击 / 拖拽移动阈值 (像素)

# === 状态枚举 ===
enum InputState {
	IDLE,           	## 空闲
	FIRST_PRESS,    	## 首次按下 (等待 release / long-press / drag)
	FIRST_RELEASE,  	## 首次释放 (短按 / 等待双击)
	DOUBLE_PRESS,  		## 二次按下 (等待双击释放)
	LONG_PRESS,     	## 长按
	DRAGGING        	## 拖拽 (mouse 或 touch drag)
}

# === 信号 (回调接口) ===
signal single_click_down(_global_position: Vector2)
signal single_click_up(_global_position: Vector2)
signal double_click(_global_position: Vector2)
signal long_press_start(_global_position: Vector2)
signal long_press_end(_global_position: Vector2)
signal drag_start(_global_position: Vector2)
signal drag_move(_global_position: Vector2, _delta: Vector2)
signal drag_end(_global_position: Vector2)
signal move(_global_position: Vector2)



# === 状态变量 ===
var state: InputState = InputState.IDLE
var click_timer: float = 0
var double_click_timer: float = 0
var last_press_position: Vector2 = Vector2.ZERO
var current_drag_position: Vector2 = Vector2.ZERO
var is_pointer_pressed: bool = false  ## 表示当前有按下 (mouse button 或 touch press)



func _process(delta: float) -> void:
	# 定时更新，用于检测长按和双击超时
	_update_timers(delta)

#func _input(event: InputEvent) -> void:
	#if event is InputEventMouseMotion:
		#move.emit(get_viewport().get_mouse_position())
	#elif event is InputEventScreenDrag:
		#move.emit(get_viewport().get_mouse_position())

func on_gui_input(event: InputEvent) -> void:
	var _position = event.position
	# 统一处理鼠标 和 触摸 (single-touch) 事件
	if event is InputEventMouseButton:
		# 鼠标左键按下 / 释放
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_on_press(_position)
			else:
				_on_release(_position)
	elif event is InputEventMouseMotion:
		_on_motion(_position)
	elif event is InputEventScreenTouch:
		# 触摸 (按下 / 释放)
		if event.pressed:
			_on_press(_position)
		else:
			_on_release(_position)
	elif event is InputEventScreenDrag:
		# 触摸拖动 (finger drag)
		_on_drag_motion(_position, event.relative)

func _input(event: InputEvent) -> void:
	var global_position = get_viewport().get_mouse_position()
	# 统一处理鼠标 和 触摸 (single-touch) 事件
	if event is InputEventMouseButton:
		# 鼠标左键按下 / 释放
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_on_press(global_position)
			else:
				_on_release(global_position)
	elif event is InputEventMouseMotion:
		_on_motion(global_position)
	elif event is InputEventScreenTouch:
		# 触摸 (按下 / 释放)
		if event.pressed:
			_on_press(global_position)
		else:
			_on_release(global_position)
	elif event is InputEventScreenDrag:
		# 触摸拖动 (finger drag)
		_on_drag_motion(global_position, event.relative)



func _update_timers(delta: float) -> void:
	match state:
		# 首次按下不松 -> 长按
		InputState.FIRST_PRESS:
			click_timer += delta
			if click_timer >= LONG_PRESS_TIME and is_pointer_pressed:
				state = InputState.LONG_PRESS
				long_press_start.emit(last_press_position)
	double_click_timer += delta

func _on_press(global_position: Vector2) -> void:
	is_pointer_pressed = true
	match state:
		# 等待 -> 首次按下
		InputState.IDLE: 
			state = InputState.FIRST_PRESS
			last_press_position = global_position
			click_timer = 0
			double_click_timer = 0
			single_click_down.emit(global_position)
		# 首次释放 -> 双击: 位置偏移未超过移动阈值 / 新的单击: 位置偏移超过移动阈值
		InputState.FIRST_RELEASE: 
			var distance = global_position.distance_to(last_press_position)
			if double_click_timer < DOUBLE_CLICK_TIME:
				if distance <= CLICK_MOVE_THRESHOLD: # 双击
					state = InputState.IDLE
					single_click_down.emit(global_position)
					double_click.emit(global_position)
			else: #新的单击
				state = InputState.FIRST_PRESS
				last_press_position = global_position
				click_timer = 0
				double_click_timer = 0
				single_click_down.emit(global_position)
		#_:
			## 其他状态: 重置, 并当作新一次点击
			#_reset_state(InputState.FIRST_PRESS)
			#last_press_position = global_position

func _on_release(global_position: Vector2) -> void:
	is_pointer_pressed = false
	match state:		
		# 首次按下 → 单击/双击
		InputState.FIRST_PRESS:
			single_click_up.emit(global_position)
			state = InputState.FIRST_RELEASE
			last_press_position = global_position
			click_timer = 0
		# 拖拽中 -> 拖拽结束
		InputState.DRAGGING:
			state = InputState.IDLE
			drag_end.emit(global_position)
		# 长按 -> 长按结束
		InputState.LONG_PRESS:
			state = InputState.IDLE
			long_press_end.emit(global_position)
		#_:
			## 其他情况: 重置
			#_reset_state()

func _on_motion(global_position: Vector2) -> void:
	# 仅处理鼠标移动 (mouse motion)，用于拖拽判断
	move.emit(global_position)
	
	# 按下 + 移动 -> 拖拽开始
	match state:
		InputState.FIRST_PRESS:
			if global_position.distance_to(last_press_position) > CLICK_MOVE_THRESHOLD:
				state = InputState.DRAGGING
				current_drag_position = global_position
				drag_start.emit(last_press_position)
		# 长按 + 移动 -> 拖拽开始
		InputState.LONG_PRESS:
			state = InputState.DRAGGING
			current_drag_position = global_position
			drag_start.emit(last_press_position)
		# 拖拽移动
		InputState.DRAGGING:
			var delta_move = global_position - current_drag_position
			drag_move.emit(global_position, delta_move)
			current_drag_position = global_position

func _on_drag_motion(global_position: Vector2, relative: Vector2) -> void:
	# 处理触摸拖动 (InputEventScreenDrag)
	move.emit(global_position)
	
	# 按下 + 移动 -> 拖拽开始
	match state:
		InputState.FIRST_PRESS:
			if global_position.distance_to(last_press_position) > CLICK_MOVE_THRESHOLD:
				state = InputState.DRAGGING
				current_drag_position = global_position
				drag_start.emit(last_press_position)
		# 长按 + 移动 -> 拖拽开始
		InputState.LONG_PRESS:
			state = InputState.DRAGGING
			current_drag_position = global_position
			drag_start.emit(last_press_position)
		# 拖拽移动
		InputState.DRAGGING:
			drag_move.emit(global_position, relative)
			current_drag_position = global_position

func _reset_state(_state: InputState = InputState.IDLE) -> void:
	# 重置状态
	state = _state
	click_timer = 0
	double_click_timer = 0
	last_press_position = Vector2.ZERO
	current_drag_position = Vector2.ZERO
	is_pointer_pressed = false

func cancel_current_action() -> void:
	# 如果当前正在拖拽，可以调用此函数取消拖拽
	if state == InputState.DRAGGING:
		drag_end.emit(current_drag_position)
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

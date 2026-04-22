class_name InputRecognizer
extends Node

# =====================
# 配置
# =====================
const LONG_PRESS_TIME := 0.15 ## 长按触发阈值
const DOUBLE_CLICK_TIME := 0.3 ## 双击触发阈值
const CLICK_MOVE_PIXEL := 5.0 ## 拖拽移动像素阈值

# =====================
# 信号
# =====================
signal single_click(pos)
signal double_click(pos)
signal long_press_start(pos)
signal long_press_end(pos)
signal drag_start(pos)
signal drag_move(pos)
signal drag_end(pos)

# =====================
# 内部状态
# =====================
var _press := false ## 按下
var _press_pos := Vector2.ZERO ## 按下位置
var _press_time := 0.0 ## 按下时间
var _last_click_pos := Vector2.ZERO ## 上次按下位置
var _last_click_time := -1.0 ## 上次按下时间

var _long_press_trigger := false ## 长按触发
var _dragging := false ## 拖拽



func get_dragging() -> bool:
	return _dragging

# =====================
func _process(delta):
	if _press:
		_press_time += delta

		# 长按开始（只触发一次）
		if not _long_press_trigger and _press_time >= LONG_PRESS_TIME:
			_long_press_trigger = true
			#print("InputRecognizer: long_press_start")
			long_press_start.emit(_press_pos)

# =====================
func _unhandled_input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_on_press(event.position)
		else:
			_on_release(event.position)

	elif event is InputEventMouseMotion:
		_on_motion(event.position)

# =====================
func _on_motion(pos: Vector2):
	if not _press:
		return

	# 超出拖拽阈值
	if not _dragging and pos.distance_to(_press_pos) > CLICK_MOVE_PIXEL:
		_dragging = true
		#print("InputRecognizer: drag_start")
		drag_start.emit(_press_pos)

	if _dragging:
		#print("InputRecognizer: drag_move")
		drag_move.emit(pos)

# =====================
func _on_release(pos: Vector2):
	if not _press:
		return
	_press = false

	# 拖拽
	if _dragging:
		#print("InputRecognizer: drag_end")
		drag_end.emit(pos)
		if _long_press_trigger: 
			long_press_end.emit(pos)
		_reset()
		return

	# 长按
	if _long_press_trigger:
		#print("InputRecognizer: long_press_end")
		long_press_end.emit(pos)
		_reset()
		return

	# ===== 单击 / 双击判定 =====
	var now := Time.get_ticks_msec() / 1000.0

	if now - _last_click_time <= DOUBLE_CLICK_TIME \
	and pos.distance_to(_last_click_pos) <= CLICK_MOVE_PIXEL:
		#print("InputRecognizer: double_click")
		double_click.emit(pos)
		_last_click_time = -1.0
	else:
		#print("InputRecognizer: single_click")
		single_click.emit(pos)
		_last_click_time = now
		_last_click_pos = pos

	_reset()

# =====================
func _on_press(pos: Vector2):
	#print("InputRecognizer: press")
	_press = true
	_press_time = 0.0
	_press_pos = pos
	_long_press_trigger = false
	_dragging = false
	
# =====================
func _reset():
	_press = false
	_press_time = 0.0
	_long_press_trigger = false
	_dragging = false

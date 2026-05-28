class_name BuyContainerButton extends Button

signal buy_container(container_name)
signal open_container(container_name, is_open: bool)

var long_press_time: float = 0.1
var press_timer: Timer

var is_can_open: bool = false
var draging: bool = false
var container_name: String = "null"
var container_value: int

func _ready() -> void:
	press_timer = Timer.new()
	press_timer.wait_time = long_press_time
	press_timer.one_shot = true
	add_child(press_timer)
	
	press_timer.timeout.connect(_on_long_press)
	pass

func _gui_input(event: InputEvent) -> void:
	var _global_mouse_position = get_global_mouse_position()
	if event is InputEventMouseMotion:
		if draging:
			global_position = _global_mouse_position - (size * scale) / 2

func open() -> void:
	if not is_can_open:
		buy_container.emit(container_name)
		return
	if draging: return
	goods_container_manage.show_search_container.emit()
	var container_grid = goods_container_manage.find_item("搜索容器")
	if not container_grid:
		push_error("container_grid == null!")
		return
	#goods_container_manage.show_container(true)
	if not container_grid.searching:
		if container_grid.is_empty():
			open_container.emit(container_name, true)
			var number = clampi(randi() % 2, 1, 2) if container_name == "衣服" else clampi(randi() % 6, 1, 6)
			container_grid.get_search_items(container_name, false, number)
			queue_free()
		else:
			open_container.emit(container_name, false)

func _on_long_press():
	draging = true

func _on_button_down() -> void:
	press_timer.start()

func _on_button_up() -> void:
	open()
	press_timer.stop()
	draging = false

extends Sprite2D


@onready var item = $InventoryItem
@onready var audio_player = $AudioStreamPlayer
@onready var quality_border = $QualityBorder
@onready var rect = $Rect
@onready var search_icon = $SearchIcon
@onready var search_background = $Rect/SearchBackground
@onready var item_name = $ItemName


var data: Goods = null
var is_picked = false
var size: Vector2:
	get():
		return Vector2(data.dimensions.x, data.dimensions.y) * Global.SLOT_SIZE

var anchor_point: Vector2:
	get():
		return global_position - size / 2

func _ready() -> void:
	if data:
		item.texture = data.texture
	item_name.text = data.name
	self_modulate = get_color(data.quality)
	quality_border.modulate = get_color(data.quality)
	audio_player.stream = load("res://art/item_slot/音效/%s.wav" % Goods.get_color_from_string(data.quality))
	set_all_scale(Vector2(Global.SLOT_SCALE, Global.SLOT_SCALE))
	var animation_length = 1.0
	get_node("AnimationPlayer").play_section("search", 0.0, animation_length)

func _process(delta: float) -> void:
	if is_picked:
		global_position = get_global_mouse_position()

##设置槽元素大小不匹配设定大小的缩放
func set_all_scale(scale_num):
	#整个槽的缩放
	scale = scale_num
	if !item.texture:
		return
	
	#纹理/UI元素的缩放
	var slot_size_scale: Vector2 = item.texture.get_size() / Global.TEXTURE_SIZE
	scale *= slot_size_scale
	if slot_size_scale > Vector2(1, 1):
		item.scale /= slot_size_scale #物品
	rect.scale /= scale
	rect.position -= rect.size / 2
	search_icon.scale /= scale #搜索图标
	#search_icon.position -= rect.size / 2
	#search_background.scale *= slot_size_scale
	item_name.scale /= scale #物品名
	item_name.position -= rect.size / 2 - Vector2(3, 0.5)
	rect.size = item.texture.get_size() * scale_num #搜索
	search_background.scale *= scale_num

func set_init_position(pos: Vector2) -> void:
	global_position = pos + size / 2
	anchor_point = global_position - size / 2

func get_picked_up() -> bool:
	if !data.search:
		return false
	audio_player.play()
		
	self_modulate = get_color(data.quality, 0.0)
	item_name.visible = false
	
	add_to_group("held_item")
	is_picked = true
	z_index	= 10
	anchor_point = global_position - size / 2
	return true

func get_placed(pos: Vector2i) -> void:
	audio_player.play()
	self_modulate = get_color(data.quality, 0.28)
	item_name.visible = true
	
	is_picked = false
	global_position = pos + Vector2i(size / 2)
	anchor_point = global_position - size / 2
	z_index	= 0
	remove_from_group("held_item")

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT && event.is_pressed():
			if is_picked:
				do_rotation()

func do_rotation() -> void:
	if !data.search:
		return
	
	data.is_rotated = !data.is_rotated
	data.dimensions = Vector2i(data.dimensions.y, data.dimensions.x)
	var tween = create_tween()
	tween.tween_property(item, "rotation_degrees", 90 if data.is_rotated else 0, 0.3)
	await tween.finished
	tween.kill()
	anchor_point = global_position - size / 2

func get_color(quality_color: Goods.Quality, alpha: float = 0.28) -> Color:
	match quality_color:
		Goods.Quality.White:
			return Color(0.2, 0.2, 0.2, alpha)
		Goods.Quality.Green:
			return Color(0.02, 0.1, 0.02, alpha)
		Goods.Quality.Blue:
			return Color(0.05, 0.2, 0.4, alpha)
		Goods.Quality.Purple:
			return Color(0.135, 0.05, 0.2, alpha)
		Goods.Quality.Gold:
			return Color(0.8, 0.4, 0.05, alpha)
		Goods.Quality.Red:
			return Color(1, 0.05, 0.05, alpha)
		_:
			printerr("未处理的品质颜色: ", quality_color)
			return Color(1, 1, 1, alpha) # 返回灰色作为默认值

func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == "search":
		search_icon.visible = false
		rect.visible = false
		audio_player.play()
		# 淡出（从不透明到透明）
		var tween = create_tween()
		tween.tween_property(self, "self_modulate:a", 0.50, 0.15)
		tween.tween_property(self, "self_modulate:a", 0.28, 0.25)
		if data.quality >= Goods.Quality.Gold:
			get_node("AnimationPlayer").play("quality_border")
		else:
			quality_border.visible = false
		
		data.search = true
	elif anim_name == "quality_border":
		quality_border.visible = false
	
	pass # Replace with function body.


func _on_audio_stream_player_finished() -> void:
	audio_player.stream = load("res://art/item_slot/音效/打开背包.wav")
	pass # Replace with function body.

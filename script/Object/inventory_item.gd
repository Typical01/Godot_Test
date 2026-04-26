extends Sprite2D


@onready var item = $InventoryItem
@onready var audio_player = $AudioStreamPlayer
@onready var quality_border = $QualityBorder
@onready var rect = $Rect
@onready var search_icon = $SearchIcon
@onready var search_background = $Rect/SearchBackground
@onready var item_name = $ItemName
@onready var select_border = $SelectBorder

@export var data: Goods = null
var is_picked = false
var size: Vector2:
	get():
		return Vector2(data.dimensions.x, data.dimensions.y) * Global.SLOT_SIZE
var anchor_point: Vector2:
	get():
		return global_position - size / 2
var original_item_scale = Vector2(1, 1)
var drag_offset = Vector2(0, 0)


func _ready() -> void:
	item.visible = false
	select_border.visible = false
	init_item(set_all_scale.bind(Vector2(Global.SLOT_SCALE, Global.SLOT_SCALE)))

func _enter_tree() -> void:
	item = $InventoryItem
	audio_player = $AudioStreamPlayer
	quality_border = $QualityBorder
	rect = $Rect
	search_icon = $SearchIcon
	search_background = $Rect/SearchBackground
	item_name = $ItemName
	select_border = $SelectBorder
	
	item.visible = false
	select_border.visible = false
	init_item()

func _input(event: InputEvent) -> void:	
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT && event.is_pressed():
			if is_picked:
				do_rotation()

func init_item(set_all_scale_callback: Callable = Callable()) -> void:
	if not data:
		return
	item.texture = data.texture
	item_name.text = data.name
	self_modulate = Goods.get_color(data.quality)
	quality_border.modulate = Goods.get_color(data.quality)
	audio_player.stream = load("res://art/item_slot/音效/%s.wav" % [Goods.get_color_from_string(data.quality)])
	if set_all_scale_callback: set_all_scale_callback.call()
	if data.search:
		search_icon.visible = false
		rect.visible = false
		item.visible = true
		audio_player.stream = load("res://art/item_slot/音效/打开背包.wav")
		item.scale = original_item_scale
		quality_border.visible = false
	else:
		get_node("AnimationPlayer").play_section("search", 0.0, Goods.get_quality_time(data.quality))

func set_item_hover(is_select: bool):
	if is_select:
		add_to_group("hover_item")
		self.self_modulate = Goods.get_color(data.quality, 0.42)
	else:
		remove_from_group("hover_item")
		self.self_modulate = Goods.get_color(data.quality, 0.28)
		
func set_item_select(is_select: bool):
	if is_select and data.search:
		add_to_group("select_item")
		select_border.visible = true
	else:
		remove_from_group("select_item")
		select_border.visible = false

##设置槽元素大小不匹配设定大小的缩放
func set_all_scale(scale_num):
	#整个槽的缩放
	scale = scale_num
	if not item.texture:
		return
	
	#纹理/UI元素的缩放
	var slot_size_scale: Vector2 = item.texture.get_size() / Global.TEXTURE_SIZE
	scale *= slot_size_scale
	if slot_size_scale > Vector2(1, 1):
		item.scale /= slot_size_scale #物品
	original_item_scale = item.scale - Vector2(0.08, 0.08)
	item.scale *= Vector2(1.25, 1.25)
	rect.scale /= scale
	rect.position -= rect.size / 2
	search_icon.scale /= scale #搜索图标
	#search_icon.position -= rect.size / 2
	item_name.scale /= scale #物品名
	item_name.position -= rect.size / 2 - Vector2(3, 0.5)
	rect.size = item.texture.get_size() * scale_num #搜索
	search_background.scale *= scale_num
	select_border.position -= select_border.texture.get_size() / 2

func set_init_position(pos: Vector2) -> void:
	global_position = pos + size / 2
	anchor_point = global_position - size / 2

func get_dimensions():
	return data.dimensions

func get_picked_up() -> bool:
	if not data.search:
		return false
	is_picked = true
	item_name.visible = false
	audio_player.play()
	self_modulate = Goods.get_color(data.quality, 0.0)
	add_to_group("held_item")
	z_index = 10
	anchor_point = global_position - size / 2
	modulate = Color(0.8, 0.8, 0.8, 0.9) # 高亮
	return true

## 放置
func get_placed(pos: Vector2i) -> void:
	audio_player.play()
	self_modulate = Goods.get_color(data.quality, 0.28)
	item_name.visible = true
	is_picked = false
	global_position = pos + Vector2i(size / 2)
	anchor_point = global_position - size / 2
	z_index = 0
	modulate = Color(1, 1, 1, 1) # 高亮
	remove_from_group("held_item")

func do_rotation() -> void:
	return
	#if not data.search:
		#return
	#data.is_rotated = not data.is_rotated
	#data.dimensions = Vector2i(data.dimensions.y, data.dimensions.x)
	#var tween = create_tween()
	#tween.tween_property(item, "rotation_degrees", 90 if data.is_rotated else 0, 0.3)
	#await tween.finished
	#tween.kill()
	#anchor_point = global_position - size / 2

func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == "search":
		search_icon.visible = false
		rect.visible = false
		item.visible = true
		audio_player.play()
		# 淡出（从不透明到透明）
		if data.quality >= Goods.Quality.Gold:
			var tween = create_tween()
			tween.tween_property(self, "self_modulate:a", 0.50, 0.15)
			tween.tween_property(self, "self_modulate:a", 0.28, 0.15)
		var tween2 = create_tween()
		tween2.tween_property(item, "scale", original_item_scale, 0.1)
		if data.quality >= Goods.Quality.Gold:
			get_node("AnimationPlayer").play("quality_border")
		else:
			quality_border.visible = false
		
		data.search = true
	elif anim_name == "quality_border":
		quality_border.visible = false


func _on_audio_stream_player_finished() -> void:
	audio_player.stream = load("res://art/item_slot/音效/打开背包.wav")

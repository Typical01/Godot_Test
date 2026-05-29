extends Button




## ============================ 变量 =============================

var quality_color_node:
	get():
		return $QualityColor
var goods_texture_node:
	get():
		return $GoodsTexture
var quality_border_node:
	get():
		return $QualityBorder
var search_background_rect_node:
	get():
		return $SearchBackgroundRect
var search_icon_node:
	get():
		return $SearchIcon
var search_path_node: Path2D:
	get():
		return $Path2D
var search_path_follow_node: PathFollow2D:
	get():
		return $Path2D/PathFollow2D
var search_background_node:
	get():
		return $SearchBackgroundRect/SearchBackground
var goods_name_node:
	get():
		return $GoodsName
var highlight_node:
	get():
		return $Highlight
var animation_player_node: AnimationPlayer:
	get():
		return $AnimationPlayer
var audio_player_node:
	get():
		return $AudioStreamPlayer


var sound_stream = preload("res://art/sound/打开背包.wav")

@export var goods_name: String = "null" ## 物品名称
@export var goods_texture: Texture2D = null ## 物品纹理
var slot_size: int = Global.SLOT_SIZE ## 物品槽大小
@export var quality: RewardPool.Quality = RewardPool.Quality.None ## 品质颜色
@export var quality_color: Color = Color() ## 品质颜色
@export var dimensions: Vector2i = Vector2i(1, 1) ## 物品规格
var is_search = false ## 搜索物品播放完成
var is_rotated = false ## 旋转物品
var is_held = false ## 拿起物品
var is_highlight = false ## 高光


## ============================ 基础实现 =============================

func _ready() -> void:
	pass
	
func _input(event: InputEvent) -> void:	
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT && event.is_pressed():
			rotated()



## ============================ 接口 =============================

## 返回: 物品大小
func get_goods_size() -> Vector2:
	return Vector2(dimensions.x * slot_size, dimensions.y * slot_size)

func reset_animation():
	animation_player_node.stop()

# 显示: 名称
func show_name(is_show: bool):
	if is_show:
		goods_name_node.visible = true
	else:
		goods_name_node.visible = false

# 显示: 名称/品质
func show_image_background(is_show: bool):
	if is_show:
		goods_name_node.visible = true
		quality_color_node.visible = true
		self.self_modulate.a = 1.0
	else:
		goods_name_node.visible = false
		quality_color_node.visible = false
		self.self_modulate.a = 0.0

## 显示状态: -1(初始)/0(未搜索)/1(已搜索)
func show_status(code: int = 0):
	if code == -1: # 初始
		quality_border_node.visible = true
		search_background_rect_node.visible = true
		search_icon_node.visible = false
		show_image_background(true)
	elif code == 0: # 未搜索
		quality_border_node.visible = true
		search_background_rect_node.visible = true
		search_icon_node.visible = true
	elif code == 1: # 已搜索
		if is_search: quality_border_node.visible = false
		search_background_rect_node.visible = false
		search_icon_node.visible = false

##设置: 物品大小
func set_goods_size(_size: Vector2 = get_goods_size()):
	size = _size
	
	#quality_color_node.size = size
	#goods_texture_node.size = size
	if goods_name_node.size.x != size.x:
		if size.x > slot_size:
			goods_name_node.size.x = size.x
		else:
			goods_name_node.size.x = 54
	#quality_border_node.size = size
	#search_background_rect_node.size = size
	search_path_node.position = size / 2 - Vector2(16, 16)
	highlight_node.size = size

## ============================ 接口 =============================



func set_data(data: Goods) -> void:
	if not data:
		push_error("ItemGoods: set_data: data == null!")
		return
	goods_name = data.name
	goods_texture = data.texture
	quality = data.quality
	quality_color = Goods.get_color(data.quality)
	dimensions = data.dimensions
	is_search = data.search
	is_rotated = data.rotate
	init_goods()

func init_goods() -> void:
	set_goods_size()
	reset_animation()
	show_status(1 if is_search else -1)
	show_highlight(false)
	
	goods_texture_node.texture = goods_texture
	goods_name_node.text = goods_name
	quality_color_node.self_modulate = quality_color
	quality_border_node.self_modulate = quality_color
	audio_player_node.stream = load("res://art/sound/%s.wav" % [RewardPool.quality_to_string(quality)])
	if is_search:
		goods_texture_node.scale = Vector2(1, 1)
		audio_player_node.stream = sound_stream

func search() -> void:
	#print("ItemGoods: [%s]搜索中..." % [goods_name_node.text])
	search_icon_node.visible = true
	var tween = create_tween()
	var time = Goods.get_quality_time(quality)
	var timer = get_tree().create_timer(time)
	while(time > 1.0):
		tween.tween_property(search_path_follow_node, "progress_ratio", 1, 1)
		tween.tween_callback(func(): search_path_follow_node.progress_ratio = 0.0)
		time -= 1
	tween.tween_property(search_path_follow_node, "progress_ratio", time, time)
	tween.tween_callback(func(): search_path_follow_node.progress_ratio = 0.0)
	await timer.timeout
	
	var tween2 = create_tween()
	tween2.set_parallel(true)  # 并行
	goods_texture_node.scale = Vector2(1.45, 1.45)
	audio_player_node.play()
	# 淡出（从不透明到透明）
	#if quality >= RewardPool.Quality.Purple:
	quality_border_node.self_modulate.a = 1
	quality_color_node.self_modulate.a = 1.0
	tween2.tween_property(quality_border_node, "self_modulate:a", 0.18, 0.25)
	tween2.tween_property(quality_color_node, "self_modulate:a", 0.18, 0.5)
	tween2.tween_property(goods_texture_node, "scale", Vector2(1, 1), 0.1)
	if quality >= RewardPool.Quality.Purple:
		show_status(1)
		animation_player_node.play("quality_border")
		await get_tree().create_timer(0.25).timeout
	is_search = true
	show_status(1)

## 拿起
func piked_up() -> void:
	if not is_search and is_held:
		return
	is_held = true
	audio_player_node.play()
	show_image_background(false)

## 放置
func placed() -> void:
	if not is_search and not is_held:
		return
	audio_player_node.play()
	show_image_background(true)
	is_held = false

## 旋转
func rotated() -> void:
	if is_rotated: # 已旋转
		pass
	else: # 未旋转
		pass
	return
	#if not data.search:
		#return
	#data.is_rotated = not data.is_rotated
	#data.dimensions = Vector2i(data.dimensions.y, data.dimensions.x)
	#tween.tween_property(goods_texture_node, "rotation_degrees", 90 if data.is_rotated else 0, 0.3)
	#await tween.finished
	#tween.kill()
	#anchor_point = global_position - size / 2

## 显示悬停效果
func show_hover(is_hover: bool) -> void:
	if is_hover:
		highlight_node.self_modulate = Color(1, 1, 1, 0.2)
		if not is_highlight:
			highlight_node.visible = true
	else:
		if not is_highlight:
			highlight_node.visible = false
		highlight_node.self_modulate = Color(1, 1, 1, 1)

## 显示高亮效果
func show_highlight(is_show: bool = false) -> void:
	is_highlight = is_show
	if is_highlight:
		highlight_node.visible = true
	else:
		highlight_node.visible = false



## ============================ 信号 =============================

func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name.is_empty():
		pass

func _on_audio_stream_player_finished() -> void:
	audio_player_node.stream = sound_stream

func _on_toggled(toggled_on: bool) -> void:
	show_highlight(toggled_on)

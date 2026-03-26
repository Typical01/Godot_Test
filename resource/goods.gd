class_name Goods extends ItemData

enum Class {
	None = -1,
	CraftCollection, ##工艺收藏品
	Household ##家用物品
}
enum Quality {
	None = -1,
	White,
	Green,
	Blue,
	Purple,
	Gold,
	Red,
	Orange
}
enum Slot {
	None = -1,
	Slot_1_1,
	Slot_1_2,
	Slot_1_3,
	Slot_1_4,
	Slot_2_1,
	Slot_2_2,
	Slot_2_3,
	Slot_3_1,
	Slot_3_2,
	Slot_3_3,
	Slot_3_4,
	Slot_4_1
}

@export var quality: Quality = Quality.None
@export var slot: Slot = Slot.None
@export var value: int = 0
@export var goods_class: Class = Class.None
@export var search = false
@export var slot_index: int = -1



func init(tmp_name: String, tmp_quality: Quality, tmp_slot: Slot, tmp_value: int, tmp_class: Class = Class.CraftCollection) -> void:
	name = tmp_name
	quality = tmp_quality
	slot = tmp_slot
	value = tmp_value
	goods_class = tmp_class
	
	texture = load("res://art/item_slot/物品/%s.png" % name)
	dimensions = get_slot_dimensions(slot)

func output():
	print("goods::output: [%s]%s (价值: %d, 格数: %dx%d)" % [
		Goods.get_color_from_string(quality), 
		name,
		value, 
		get_slot_dimensions(slot).x, 
		get_slot_dimensions(slot).y
	])
	
##将物品尺寸转换为: 宽x高
static func get_slot_dimensions(slot_type: Slot) -> Vector2i:
	match slot_type:
		# 1x系列 (宽1)
		Slot.Slot_1_1:
			return Vector2i(1, 1)    # 1x1
		Slot.Slot_1_2:
			return Vector2i(1, 2)    # 1x2
		Slot.Slot_1_3:
			return Vector2i(1, 3)    # 1x3
		Slot.Slot_1_4:
			return Vector2i(1, 4)    # 1x4
		# 2x系列 (宽2)
		Slot.Slot_2_1:
			return Vector2i(2, 1)    # 2x1
		Slot.Slot_2_2:
			return Vector2i(2, 2)    # 2x2
		Slot.Slot_2_3:
			return Vector2i(2, 3)    # 2x3
		# 3x系列 (宽3)
		Slot.Slot_3_1:
			return Vector2i(3, 1)    # 3x1
		Slot.Slot_3_2:
			return Vector2i(3, 2)    # 3x2
		Slot.Slot_3_3:
			return Vector2i(3, 3)    # 3x3
		Slot.Slot_3_4:
			return Vector2i(3, 4)    # 3x4
		# 4x系列 (宽4)
		Slot.Slot_4_1:
			return Vector2i(4, 1)    # 4x1
		_:
			return Vector2i(1, 1)    # 默认值

##将品质颜色转换为: 字符串
static func get_color_from_string(quality_color: Quality) -> String:
	match quality_color:
		Goods.Quality.White:
			return "白"
		Goods.Quality.Green:
			return "绿"
		Goods.Quality.Blue:
			return "蓝"
		Goods.Quality.Purple:
			return "紫"
		Goods.Quality.Gold:
			return "金"
		Goods.Quality.Red:
			return "红"
		Goods.Quality.Orange:
			return "橙"
		_:
			printerr("未处理的品质颜色[Enum]: ", quality_color)
			return "null" # 返回灰色作为默认值

static func get_quality_time(quality_color: Goods.Quality) -> float:
	match quality_color:
		Goods.Quality.White:
			return 1.0
		Goods.Quality.Green:
			return 1.0
		Goods.Quality.Blue:
			return 1.0
		Goods.Quality.Purple:
			return 1.5
		Goods.Quality.Gold:
			return 2.0
		Goods.Quality.Red:
			return 2.5
		Goods.Quality.Orange:
			return 2.5
		_:
			printerr("未处理的品质颜色[时间]: ", quality_color)
			return 1.0 # 返回灰色作为默认值
			
static func get_color(quality_color: Goods.Quality, alpha: float = 0.28) -> Color:
	match quality_color:
		Goods.Quality.White:
			return Color(0.278, 0.278, 0.278, alpha)
		Goods.Quality.Green:
			return Color(0.0, 0.278, 0.0, alpha)
		Goods.Quality.Blue:
			return Color(0.05, 0.2, 0.4, alpha)
		Goods.Quality.Purple:
			return Color(0.216, 0.0, 0.376, alpha)
		Goods.Quality.Gold:
			return Color(0.8, 0.4, 0.05, alpha)
		Goods.Quality.Red:
			return Color(0.706, 0.051, 0.051, alpha)
		Goods.Quality.Orange:
			return Color(0.706, 0.051, 0.051, alpha)
		_:
			printerr("未处理的品质颜色: ", quality_color)
			return Color(1, 1, 1, alpha) # 返回灰色作为默认值

##将品质字符串转换为: 颜色
static func get_string_from_color(quality_string: String) -> Quality:
	match quality_string:
		"白":
			return Goods.Quality.White
		"绿":
			return Goods.Quality.Green
		"蓝":
			return Goods.Quality.Blue
		"紫":
			return Goods.Quality.Purple
		"金":
			return Goods.Quality.Gold
		"红":
			return Goods.Quality.Red
		"橙":
			return Goods.Quality.Orange
		_:
			printerr("未处理的品质颜色: ", quality_string)
			return Goods.Quality.None

##获取物品占用的格子总数
static func get_slot_cell_count(slot_type: Slot) -> int:
	var dim = get_slot_dimensions(slot_type)
	return dim.x * dim.y

##检查是否为正方形物品
static func is_square_slot(slot_type: Slot) -> bool:
	var dim = get_slot_dimensions(slot_type)
	return dim.x == dim.y

##检查物品是否可以旋转（非正方形且不是1x1）
static func can_rotate_slot(slot_type: Slot) -> bool:
	var dim = get_slot_dimensions(slot_type)
	return dim.x != dim.y and dim.x > 1 and dim.y > 1

##获取旋转后的尺寸（交换宽高）
static func get_rotated_dimensions(slot_type: Slot) -> Vector2i:
	var dim = get_slot_dimensions(slot_type)
	return Vector2i(dim.y, dim.x)

##获取旋转后的Slot枚举（如果存在）
static func get_rotated_slot(slot_type: Slot) -> Slot:
	var dim = get_slot_dimensions(slot_type)
	var rotated = Vector2i(dim.y, dim.x)
	# 反向查找对应的枚举
	return get_slot_from_dimensions(rotated.x, rotated.y)

##根据宽高获取Slot枚举（反向查找）
static func get_slot_from_dimensions(width: int, height: int) -> Slot:
	var target = Vector2i(width, height)
	# 遍历所有Slot值查找匹配
	for slot_value in Slot.values():
		if get_slot_dimensions(slot_value) == target:
			return slot_value
	# 没有找到，返回默认
	return Slot.None

static func is_dimensions(_dimensions: Vector2i) -> bool:
	if _dimensions.x <= 0 or _dimensions.y <= 0: # 大小有效
		return false
	return true

##Slot转换为字符串表示
static func slot_to_string(slot_type: Slot) -> String:
	var dim = get_slot_dimensions(slot_type)
	return "%dx%d" % [dim.x, dim.y]

##带描述的字符串
static func slot_to_description(slot_type: Slot) -> String:
	var size_str = slot_to_string(slot_type)
	var cell_count = get_slot_cell_count(slot_type)
	var shape = "正方形" if is_square_slot(slot_type) else "长方形"
	return "%s (%s, 共%d格)" % [size_str, shape, cell_count]

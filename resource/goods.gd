class_name Goods extends ItemData

enum Type {
	None = -1,
	CraftCollection,   ## 工艺收藏
	KeyCar,            ## 钥匙
	EnergyFuel,        ## 能源燃料
	Medical,           ## 医疗道具
	Electronic,        ## 电子物品
	Document,          ## 资料情报
	ToolMaterial,      ## 工具材料
	HomeItem,          ## 家居物品
}

@export var quality: RewardPool.Quality = RewardPool.Quality.None
@export var value: int = 0
@export var goods_class: Type = Type.None
@export var is_search = false
@export var start_index: int = -1
var slot_index: Array[int] = []



func init(tmp_name: String, tmp_quality: RewardPool.Quality, _dimensions: Vector2i, 
	tmp_value: int, tmp_class: Type = Type.CraftCollection) -> void:
	name = tmp_name
	quality = tmp_quality
	dimensions = _dimensions
	value = tmp_value
	goods_class = tmp_class
	texture = load("res://art/texture/物品/%s.png" % name)

func output():
	print("Goods::output: [%s]%s (价值: %d) | %s (%s, 共%d格)" % [
		RewardPool.quality_to_string(quality), 
		name,
		value,
		slot_to_string(dimensions),
		"正方形" if is_square(dimensions) else "长方形",
		get_slot_count(dimensions)
	])

func is_valid() -> bool:
	if dimensions.x <= 0 or dimensions.y <= 0:
		return false
	return true
	
##获取物品占用的格子总数
static func get_slot_count(data_dimensions: Vector2i) -> int:
	return data_dimensions.x * data_dimensions.y

##检查是否为正方形物品
static func is_square(data_dimensions: Vector2i) -> bool:
	return data_dimensions.x == data_dimensions.y

##检查物品是否可以旋转（非正方形）
static func can_rotate(data_dimensions: Vector2i) -> bool:
	return data_dimensions.x != data_dimensions.y

##获取旋转后的尺寸（交换宽高）
static func get_rotated_dimensions(data_dimensions: Vector2i) -> Vector2i:
	return Vector2i(data_dimensions.y, data_dimensions.x)

##Slot转换为字符串表示
static func slot_to_string(ata_dimensions: Vector2i) -> String:
	return "%dx%d" % [ata_dimensions.x, ata_dimensions.y]

static func get_color(quality_color: RewardPool.Quality, alpha: float = 0.18) -> Color:
	match quality_color:
		RewardPool.Quality.White:
			return Color(0.278, 0.278, 0.278, alpha)
		RewardPool.Quality.Green:
			return Color(0.0, 0.45, 0.1, alpha)
		RewardPool.Quality.Blue:
			return Color(0.2, 0.44, 0.64, alpha)
		RewardPool.Quality.Purple:
			return Color(0.3, 0.0, 0.4, alpha)
		RewardPool.Quality.Gold:
			return Color(0.66, 0.48, 0.0, alpha)
		RewardPool.Quality.Red:
			return Color(0.78, 0.0, 0.0, alpha)
		RewardPool.Quality.Orange:
			return Color(0.78, 0.0, 0.0, alpha)
		_:
			return Color(1, 1, 1, alpha)

static func get_quality_time(quality_color: RewardPool.Quality) -> float:
	match quality_color:
		RewardPool.Quality.White:
			return 1.0
		RewardPool.Quality.Green:
			return 1.0
		RewardPool.Quality.Blue:
			return 1.0
		RewardPool.Quality.Purple:
			return 1.5
		RewardPool.Quality.Gold:
			return 2.0
		RewardPool.Quality.Red:
			return 4.0
		RewardPool.Quality.Orange:
			return 4.0
		_:
			return 1.0

static func string_to_type(category_name: String) -> int:
	match category_name:
		"工艺藏品":
			return Goods.Type.CraftCollection
		"钥匙":
			return Goods.Type.KeyCar
		"能源燃料":
			return Goods.Type.EnergyFuel
		"资料情报":
			return Goods.Type.Document
		"医疗道具":
			return Goods.Type.Medical
		"电子物品":
			return Goods.Type.Electronic
		"工具材料":
			return Goods.Type.ToolMaterial
		"家居物品":
			return Goods.Type.HomeItem
	return Goods.Type.None

static func type_to_string(class_type: int) -> String:
	match class_type:
		Goods.Type.CraftCollection:
			return "工艺藏品"
		Goods.Type.KeyCar:
			return "钥匙"
		Goods.Type.EnergyFuel:
			return "能源燃料"
		Goods.Type.Document:
			return "资料情报"
		Goods.Type.Medical:
			return "医疗道具"
		Goods.Type.Electronic:
			return "电子物品"
		Goods.Type.ToolMaterial:
			return "工具材料"
		Goods.Type.HomeItem:
			return "家居物品"
	return "未知"

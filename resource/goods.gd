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

@export var dimensions: Vector2i = Vector2i(0, 0):					## 形状规格
	get():
		if rotate:
			return Vector2i(dimensions.y, dimensions.x)
		else:
			return dimensions
@export var index: int = -1									## 起始索引
@export var shape: Array = []:										## 形状矩阵
	get():
		if rotate:
			return rotated()
		else:
			return shape
@export var quality: RewardPool.Quality = RewardPool.Quality.None	## 品质
@export var value: int = 0											## 价值
@export var type: Type = Type.None									## 物品类型
@export var search = false											## 是否搜索



func init(tmp_name: String, tmp_quality: RewardPool.Quality, _dimensions: Vector2i, 
	tmp_value: int, tmp_type: Type = Type.None, tmp_shape: Array = []) -> void:
	name = tmp_name
	quality = tmp_quality
	dimensions = _dimensions
	if tmp_shape.is_empty():
		shape = Goods.rect(dimensions.x, dimensions.y)
	value = tmp_value
	type = tmp_type
	texture = load("res://art/texture/物品/%s.png" % name)

func output():
	print("Goods::output: [%s]%s (价值: %d) | %s, 共%s格 | \n%s" % [
		RewardPool.quality_to_string(quality), 
		name,
		value,
		"正方形" if is_square() else "长方形",
		dimensions_to_string(),
		shape_to_string()
	])

## 是否有效
func is_valid() -> bool:
	if dimensions.x <= 0 or dimensions.y <= 0:
		return false
	return true

## 获取物品占用的相对偏移坐标
func get_occupy_offsets() -> Array:
	var offsets = []
	for y in range(shape.size()):
		for x in range(shape[y].size()):
			if shape[y][x] == 1:
				offsets.append(Vector2(x, y))
	return offsets

## 获取旋转后物品的形状
func rotated() -> Array:
	var rows = shape.size()
	var cols = shape[0].size()
	var rotates = []
	for x in range(cols):
		var new_row = []
		for y in range(rows - 1, -1, -1):
			new_row.append(shape[y][x])
		rotates.append(new_row)
	return rotates

## 检查是否为正方形物品
func is_square() -> bool:
	return dimensions.x == dimensions.y

## 检查物品是否可以旋转(非正方形)
func can_rotate() -> bool:
	return not is_square()

## 形状转换为字符串表示
func shape_to_string() -> String:
	var result = "\t"
	for y in range(shape.size()):
		var row = shape[y]
		for x in range(row.size()):
			var cell = row[x]
			result += "X" if cell == 1 else " "
		result += "\n\t"
	return result

## 规格转换为字符串表示
func dimensions_to_string() -> String:
	return "%dx%d" % [dimensions.x, dimensions.y]

## 规则形状生成
static func rect(x: int, y: int) -> Array:
	var tmp_shape = []
	for i in range(y):
		var row = []
		for j in range(x):
			row.append(1)
		tmp_shape.append(row)
	return tmp_shape

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
		RewardPool.Quality.Pink:
			return Color(0.66, 0.48, 0.0, alpha)
		RewardPool.Quality.Gold:
			return Color(0.78, 0.0, 0.0, alpha)
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
		RewardPool.Quality.Pink:
			return 1.5
		RewardPool.Quality.Gold:
			return 2.0
		RewardPool.Quality.Red:
			return 2.0
		RewardPool.Quality.Orange:
			return 2.0
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
	return "所有"

static func get_all_type() -> Array:
	return ["工艺藏品", "钥匙", "能源燃料", "资料情报", "医疗道具", "电子物品", "工具材料", "家居物品"]

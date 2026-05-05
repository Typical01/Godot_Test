class_name GoodsContainer extends ItemData

@export var types: Array

func init(tmp_name: String, _types: Array) -> void:
	name = tmp_name
	types = _types
	texture = load("res://art/texture/ui/container/%s.png" % name)

func output():
	print("GoodsContainer::output: [%s]%s" % [
		name,
		types
	])

static func string_to_type(category_name: String) -> RewardPool.Quality:
	match category_name:
		"普通":
			return RewardPool.Quality.White
		"机密":
			return RewardPool.Quality.Green
		"绝密":
			return RewardPool.Quality.Blue
		_:
			return RewardPool.Quality.None

## 容器类型
static func type_to_string(class_enum: RewardPool.Quality) -> String:
	match class_enum:
		RewardPool.Quality.White:
			return "普通"
		RewardPool.Quality.Green:
			return "机密"
		RewardPool.Quality.Blue:
			return "绝密"
		_:
			return "普通"

class_name GoodsContainer extends ItemData

@export var types: Array
@export var quality: RewardPool.Quality

func init(tmp_name: String, _types: Array, _quality: RewardPool.Quality = RewardPool.Quality.White) -> void:
	name = tmp_name
	types = _types
	quality = _quality
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
static func type_to_string(type: RewardPool.Quality) -> String:
	match type:
		RewardPool.Quality.White:
			return "普通"
		RewardPool.Quality.Green:
			return "机密"
		RewardPool.Quality.Blue:
			return "绝密"
		_:
			return "普通"

## 容器类型
static func quality_to_value(_quality: RewardPool.Quality) -> int:
	match _quality:
		RewardPool.Quality.White:
			return 0
		RewardPool.Quality.Green:
			return 1000000
		RewardPool.Quality.Blue:
			return 3000000
		_:
			return 0

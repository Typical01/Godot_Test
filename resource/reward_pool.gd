class_name RewardPool extends Resource

# === 实例数据成员：每个RewardPool实例都有自己的数据 ===
var orange_goods_array: Array[Goods] = []
var red_goods_array: Array[Goods] = []
var gold_goods_array: Array[Goods] = []
var purple_goods_array: Array[Goods] = []
var blue_goods_array: Array[Goods] = []
var green_goods_array: Array[Goods] = []
var white_goods_array: Array[Goods] = []

# 实例级别的映射和配置
var quality_to_array: Dictionary = {}
var quality_name_to_enum: Dictionary = {}
var quality_probabilities: Array = []

# === 构造函数：初始化时接收配置 ===
func _init(config: Dictionary = {}):
	_build_quality_dictionaries()
	if not config.is_empty():
		load_config(config)

# === 私有方法：构建实例内部的映射关系 ===
func _build_quality_dictionaries():
	# 品质名称到枚举的映射（固定不变）
	quality_name_to_enum = {
		"白": Goods.Quality.White,
		"绿": Goods.Quality.Green,
		"蓝": Goods.Quality.Blue,
		"紫": Goods.Quality.Purple,
		"金": Goods.Quality.Gold,
		"红": Goods.Quality.Red,
		"橙": Goods.Quality.Orange
	}
	
	# 品质枚举到数组的映射（指向本实例的数组）
	quality_to_array = {
		Goods.Quality.White: white_goods_array,
		Goods.Quality.Green: green_goods_array,
		Goods.Quality.Blue: blue_goods_array,
		Goods.Quality.Purple: purple_goods_array,
		Goods.Quality.Gold: gold_goods_array,
		Goods.Quality.Red: red_goods_array,
		Goods.Quality.Orange: orange_goods_array
	}

# === 核心方法：加载配置到本实例 ===
func load_config(config: Dictionary) -> bool:
	#if config.is_empty() or not config.has("基本设置"):
	#	print("RewardPool: 配置无效或缺少[基本设置]")
	#	return false
	
	#var base_setting = config["基本设置"]
	#if not base_setting is Dictionary:
	#	return false
	
	# 1. 加载概率配置
	if config.has("概率") and config["概率"] is Array:
		quality_probabilities = config["概率"]
		print("RewardPool: 加载概率配置成功")
	else:
		print("RewardPool: 配置中缺少概率数组，使用默认值")
		quality_probabilities = [0.02, 0.02, 0.30, 0.41, 0.00, 0.23, 0.0198, 0.0002]
	
	# 2. 清空现有数组
	_clear_all_arrays()
	
	# 3. 加载物品配置
	var goods_object = config.get("物品", {})
	if not goods_object is Dictionary:
		print("RewardPool: 配置中物品格式错误")
		return false
	
	var success = true
	for quality_name in quality_name_to_enum.keys():
		if goods_object.has(quality_name):
			var target_array = quality_to_array[quality_name_to_enum[quality_name]]
			success = success and _load_items_from_data(goods_object[quality_name], target_array, quality_name)
		else:
			print("RewardPool: 配置中缺少品质[%s]的物品列表" % quality_name)
	
	print("RewardPool: 配置加载完成，总计 %d 种物品" % _get_total_item_count())
	return success

func _clear_all_arrays():
	orange_goods_array.clear()
	red_goods_array.clear()
	gold_goods_array.clear()
	purple_goods_array.clear()
	blue_goods_array.clear()
	green_goods_array.clear()
	white_goods_array.clear()

func _load_items_from_data(item_data_array: Array, target_array: Array, quality_name: String) -> bool:
	if not item_data_array is Array:
		return false
	
	for item_data in item_data_array:
		if not item_data is Dictionary:
			continue
		
		var goods = _create_goods_from_data(item_data, quality_name)
		if goods:
			target_array.append(goods)
	
	print("RewardPool: 品质[%s] 加载了 %d 个物品" % [quality_name, target_array.size()])
	return true

func _create_goods_from_data(item_data: Dictionary, quality_name: String) -> Goods:
	var name = item_data.get("物品名称", "")
	if name.is_empty():
		return null
	
	var goods = Goods.new()
	goods.init(name,quality_name_to_enum[quality_name], 
	item_data.get("物品格数", Goods.Slot.Slot_1_1), 
	int(item_data.get("物品价值", 0)),
	item_data.get("物品类型", Goods.Class.CraftCollection)
	)
	
	return goods

func _get_total_item_count() -> int:
	return (orange_goods_array.size() + red_goods_array.size() + 
			gold_goods_array.size() + purple_goods_array.size() + 
			blue_goods_array.size() + green_goods_array.size() + 
			white_goods_array.size())

# === 核心功能：奖励分配 ===
## 单个分配
func allocate_single_reward() -> Goods:
	var quality = _get_random_quality()
	if quality == null:
		return null
	
	var item_array: Array = quality_to_array.get(quality, [])
	if not item_array or item_array.is_empty():
		push_error("RewardPool: 品质[%d]的物品数组为空" % [quality])
		return null
	
	var random_index = randi() % item_array.size()
	return item_array[random_index].duplicate()

## 指定数量分配
func allocate_multiple_rewards(count: int = 10) -> Array[Goods]:
	var rewards: Array[Goods] = []
	for i in range(count):
		var reward = allocate_single_reward()
		if reward:
			rewards.append(reward)
	return rewards

func _get_random_quality() -> Goods.Quality:
	if quality_probabilities.is_empty():
		print("RewardPool: 概率配置未加载")
		return Goods.Quality.White
	
	var rand_value = randf()
	var cumulative = 0.0
	
	for i in range(quality_probabilities.size()):
		cumulative += quality_probabilities[i]
		if rand_value <= cumulative:
			return _index_to_quality(i)
	
	return Goods.Quality.White

func _index_to_quality(idx: int) -> Goods.Quality:
	match idx:
		0: return Goods.Quality.White
		1: return Goods.Quality.Green
		2: return Goods.Quality.Blue
		3: return Goods.Quality.Purple
		4: return Goods.Quality.Gold  # 粉色槽位暂时映射到金色
		5: return Goods.Quality.Gold
		6: return Goods.Quality.Red
		7: return Goods.Quality.Orange
		_: return Goods.Quality.White

# === 查询与调试方法 ===
func get_items_by_quality(quality: Goods.Quality) -> Array[Goods]:
	return quality_to_array.get(quality, []).duplicate()

func get_items_by_quality_name(quality_name: String) -> Array[Goods]:
	var quality = quality_name_to_enum.get(quality_name)
	if quality == null:
		return []
	return get_items_by_quality(quality)

func get_probability_by_quality(quality: Goods.Quality) -> float:
	var idx = _quality_to_index(quality)
	if idx >= 0 and idx < quality_probabilities.size():
		return quality_probabilities[idx]
	return 0.0

func _quality_to_index(quality: Goods.Quality) -> int:
	match quality:
		Goods.Quality.White: return 0
		Goods.Quality.Green: return 1
		Goods.Quality.Blue: return 2
		Goods.Quality.Purple: return 3
		Goods.Quality.Gold: return 5  # 注意：配置数组中金色在索引5
		Goods.Quality.Red: return 6
		Goods.Quality.Orange: return 7
		_: return -1

func print_summary():
	print("=== RewardPool 统计信息 ===")
	print("概率配置: %s" % str(quality_probabilities))
	for quality_name in ["白", "绿", "蓝", "紫", "金", "红", "橙"]:
		var quality = quality_name_to_enum[quality_name]
		var arr = quality_to_array[quality]
		var prob = get_probability_by_quality(quality)
		print("品质[%s]: 概率=%.2f%%, 物品数=%d" % [quality_name, prob * 100, arr.size()])

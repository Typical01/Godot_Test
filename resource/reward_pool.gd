class_name RewardPool extends RefCounted

## ============================ 信号 =============================





## ============================ 变量 =============================

## 品质
enum Quality {
	None = -1,
	White,
	Green,
	Blue,
	Purple,
	Pink,
	Gold,
	Red,
	Orange
}

## 奖励池名称
var name: String = "null"
var reward_types: Array = []
static var quality_reward_data: Dictionary = {} ## 品质奖励
#{
	#"奖励池名称": {
		#"白": [...]
		#...
	#}
#}
var probabilitys_data: Array = [] ## 概率

## ============================ 基础实现 =============================

##
func init(reward_pool_name: String, reward_types_name: Array, probabilitys: Array) -> bool:
	# 清空现有概率数组
	probabilitys_data.clear()
	name = reward_pool_name
	reward_types = reward_types_name
	
	# 加载概率数组
	if probabilitys.is_empty():
		probabilitys = [0.02, 0.02, 0.30, 0.41, 0.00, 0.23, 0.0198, 0.0002]
		push_warning("RewardPool: 概率数组无效, 使用默认值: %s!" % [probabilitys])
	probabilitys_data = probabilitys.duplicate()
	return true

func add_qualitys_reward(quality_reward: Dictionary) -> bool:
	for key in quality_reward.keys():
		quality_reward_data.set(key, quality_reward[key].duplicate())
		print("key: %s, data: %s" % [key, quality_reward[key].size()])
	#print("quality_reward_data: ", quality_reward_data)
	return true

func del_qualitys_reward(reward_name: String) -> bool:
	return quality_reward_data.erase(reward_name)



## ============================ 接口: 奖励分配 =============================

## 单次分配
func allocate_single_reward(quality: Quality = Quality.None) -> Object:
	if quality == Quality.None or quality == Quality.Pink: # 未指定
		quality = _get_random_quality() # 随机
	var type = get_reward_types_random()
	var qualitys_reward = get_qualitys_reward(type, quality) # 白(0)[{奖励}...]
	if qualitys_reward.is_empty():
		push_error("品质奖励数组[%s][%s] == null!" % [type, quality_to_string(quality)])
		return null
	var rand_quality_index = randi() % qualitys_reward.size()
	var qualitys = qualitys_reward[rand_quality_index] # {奖励}
	#var rand_reward_index = randi() % qualitys.size()
	return qualitys.duplicate()

## 指定数量分配
func allocate_multiple_rewards(quality: Quality = Quality.None, count: int = 10) -> Array[Object]:
	var rewards: Array[Object] = []
	for i in range(count):
		var reward = allocate_single_reward(quality)
		if reward:
			rewards.append(reward)
	return rewards

## ============================ 接口: 获取 =============================

func get_reward_types_random() -> String:
	return reward_types[randi() % reward_types.size()]

static func get_quality_random() -> int:
	return randi() % RewardPool.Quality.Orange

## 获取: 随机品质
func _get_random_quality() -> Quality:
	var probabilities = get_probabilitys()
	if probabilities.is_empty():
		push_error("概率数组 == null!")
		return Quality.None
	
	var rand_value = randf()
	var cumulative = 0.0 # 累计奖励阈值
	for i in range(probabilities.size()):
		if probabilities[i] == 0.0:
			continue
		cumulative += probabilities[i]
		if rand_value <= cumulative:
			return index_to_quality(i)
	return Quality.None

## 获取: 概率列表
func get_probabilitys() -> Array:
	return probabilitys_data

## 获取: 指定奖励池的对应品质列表
func get_qualitys_reward(reward_name: String, quality: Quality) -> Array:
	var reward = quality_reward_data.get(reward_name, [])
	if reward.is_empty():
		return []
	var object = reward.get(quality_to_string(quality), [])
	return object

## 字符串 转 品质
static func string_to_quality(quality_name: String) -> Quality:
	match quality_name:
		"白":
			return RewardPool.Quality.White
		"绿":
			return RewardPool.Quality.Green
		"蓝":
			return RewardPool.Quality.Blue
		"紫":
			return RewardPool.Quality.Purple
		"粉":
			return RewardPool.Quality.Pink
		"金":
			return RewardPool.Quality.Gold
		"红":
			return RewardPool.Quality.Red
		"橙":
			return RewardPool.Quality.Orange
		_:
			return RewardPool.Quality.None

## 品质 转 字符串
static func quality_to_string(quality: RewardPool.Quality) -> String:
	match quality:
		RewardPool.Quality.White:
			return "白"
		RewardPool.Quality.Green:
			return "绿"
		RewardPool.Quality.Blue:
			return "蓝"
		RewardPool.Quality.Purple:
			return "紫"
		RewardPool.Quality.Gold:
			return "金"
		RewardPool.Quality.Red:
			return "红"
		RewardPool.Quality.Orange:
			return "橙"
		_:
			return "白"

## 品质 转 索引
static func quality_to_index(quality: Quality) -> int:
	match quality:
		Quality.White: return 0
		Quality.Green: return 1
		Quality.Blue: return 2
		Quality.Purple: return 3
		Quality.Pink: return 4
		Quality.Gold: return 5
		Quality.Red: return 6
		Quality.Orange: return 7
		_: return -1

## 索引 转 品质
static func index_to_quality(index: int) -> Quality:
	match index:
		0: return Quality.White
		1: return Quality.Green
		2: return Quality.Blue
		3: return Quality.Purple
		4: return Quality.Pink
		5: return Quality.Gold
		6: return Quality.Red
		7: return Quality.Orange
		_: return Quality.None

func output():
	print("=== [%s] 统计信息 ===" % [name])
	print("\t概率配置: %s" % [get_probabilitys()])

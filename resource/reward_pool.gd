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
## 品质奖励池数量: [[]x7]
var qualitys_reward_size: Array[int] = []

## 品质等级： 白(0)-绿(1)-蓝(2)-紫(3)-粉(4)-金(5)-红(6)-橙(7)
var reward_data: Dictionary = {}

## ============================ 基础实现 =============================

##
func init(reward_pool_name: String, probabilitys: Array, qualitys_reward: Dictionary) -> bool:
	# 清空现有概率数组
	reward_data.clear()
	name = reward_pool_name
	
	# 加载概率数组
	if not probabilitys.is_empty():
		print("RewardPool: 概率数组有效: %s" % [probabilitys])
	else:
		probabilitys = [0.02, 0.02, 0.30, 0.41, 0.00, 0.23, 0.0198, 0.0002]
		push_warning("RewardPool: 概率数组无效, 使用默认值: %s!" % [probabilitys])
	reward_data.set("概率", probabilitys)
	# 刷新: 品质奖励池大小
	if not update_qualitys_reward_size(qualitys_reward): return false
	return true



## ============================ 接口: 奖励分配 =============================

## 单个分配
func allocate_single_reward(quality: Quality = Quality.None) -> Object:
	if quality == Quality.None: # 未指定
		quality = _get_random_quality() # 随机
	var qualitys_reward: Array = get_qualitys_reward(quality) # [白(0)[奖励], 绿(1)[奖励]...]
	if qualitys_reward.is_empty():
		push_error("品质奖励数组[%d] == null!" % [quality])
		return null
	var rand_quality_index = randi() % qualitys_reward_size.size()
	var qualitys = qualitys_reward[rand_quality_index] # 白(0)[奖励]
	var rand_reward_index = randi() % qualitys.size()
	return qualitys[rand_reward_index].duplicate()

## 指定数量分配
func allocate_multiple_rewards(count: int = 10) -> Array[Object]:
	var rewards: Array[Object] = []
	for i in range(count):
		var reward = allocate_single_reward()
		if reward:
			rewards.append(reward)
	return rewards

## 刷新: 品质奖励池大小
func update_qualitys_reward_size(qualitys_reward: Dictionary) -> bool:
	if qualitys_reward.is_empty():
		push_error("品质奖励池无效!")
		return false
	reward_data.set("品质奖励池", qualitys_reward)
	qualitys_reward_size.clear()
	
	qualitys_reward_size.resize(7)
	qualitys_reward_size.fill(0)
	
	var sum = 0
	for key in qualitys_reward.keys():
		var index = string_to_quality(key)
		qualitys_reward_size[index] = qualitys_reward[key].size()
		sum += qualitys_reward_size[index]
		print("RewardPool: key[%s]index[%s]." % [key, index])
	print("RewardPool: 品质奖励池有效, 大小: %s" % [qualitys_reward_size])
	print("RewardPool: 总计 [%d] 种奖励." % sum)
	return true

## ============================ 接口: 获取 =============================

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

func get_probabilitys() -> Array[float]:
	return reward_data.get("概率", [])

func get_qualitys_reward(quality: Quality) -> Array[Array]:
	var qualitys_reward = reward_data.get("品质奖励池", [])
	if qualitys_reward.is_empty():
		return []
	else:
		return qualitys_reward[quality_to_index(quality)]

## 品质 转 字符串
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
	for i in qualitys_reward_size.size():
		var probability = get_probabilitys()[i]
		var quality = quality_to_string(quality_to_index(i))
		var sum = qualitys_reward_size[i]
		print("\t品质[%s]: 概率=%.2f%%, 物品数=%d" % [quality, probability * 100, sum])

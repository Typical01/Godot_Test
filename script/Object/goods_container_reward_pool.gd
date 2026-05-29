class_name GoodsContainerRewardPool extends RefCounted



var config # 配置文件引用
var container_probabilitys: Dictionary
var container_data: Dictionary
var goods_probabilitys: Dictionary ## 物品概率
var goods_pool: Dictionary = {} # 物品池: key: 物品名 | value: 物品数据
var reward_pools: Dictionary = {}



func init(_config) -> bool:
	config = _config
	var container_qualitys_reward = extract_container_reward_pool()
	if container_qualitys_reward.is_empty():
		push_error("提取: 容器奖励池失败!")
		return false
	set_container_reward(container_qualitys_reward)
	var goods_qualitys_reward = extract_goods_reward_pool()
	if goods_qualitys_reward.is_empty():
		push_error("提取: 物品奖励池失败!")
		return false
	set_goods_reward(goods_qualitys_reward)
	#print("reward_pools: ", reward_pools)
	return true
	
## 设置: 容器本身的概率
## container_probabilitys: ["普通"] = [0.6, 0.3, 0.1, 0, 0, 0, 0]
## container_qualitys_reward: ["品质] = {"白": [&收纳袋, &收纳盒, &快递盒, &抽屉柜, &储物柜, &井盖, &鸟窝, &电脑机箱]...}
func set_container_reward(container_qualitys_reward: Dictionary) -> bool:
	var reward = RewardPool.new()
	for key in container_probabilitys.keys(): # [0.6, 0.3, 0.1, 0, 0, 0, 0]
		if container_probabilitys.size() > 3:
			push_error("容器: 只有 3 级!")
			return false
		var reward_pool = RewardPool.new()
		if not reward_pool.init(key, ["容器"], container_probabilitys[key]):
			push_error("容器: [%s] 奖励池初始化失败!" % [key])
			return false
		#reward_pool.output()
		reward_pools.set(key, reward_pool)
		#print("GoodsContainerRewardPool: 容器: [%s]奖励池创建成功！" % [key])
	reward.add_qualitys_reward(container_qualitys_reward)
	return true
	
## 设置: 容器中物品的概率
## goods_probabilitys: { "保险箱": [0.02, 0.02, 0.20, 0.40, 0.00, 0.33, 0.0405, 0.0005]... }
## goods_qualitys_reward: ["品质]: {"工艺藏品": {"白": [{"物品名称": "绷带", "物品格数": [1, 1], "物品价值": 5}...]}...}
func set_goods_reward(goods_qualitys_reward: Dictionary) -> bool:
	var goods_level = goods_probabilitys.size()
	if goods_level < 7:
		push_error("物品: 概率有 7 级, 当前等级[%s]!" % [goods_level])
		return false
	var reward = RewardPool.new()
	for key in goods_probabilitys.keys(): # "保险箱": [0.02, 0.02, 0.20, 0.40, 0.00, 0.33, 0.0405, 0.0005]
		#for key2 in goods_qualitys_reward.keys():
		var reward_pool = RewardPool.new()
		if not reward_pool.init(key, get_container_types(key), goods_probabilitys[key]):
			push_error("物品: [%s]奖励池初始化失败!" % [key])
			return false
		#reward_pool.output()
		reward_pools.set(key, reward_pool)
		#print("GoodsContainerRewardPool: 物品: [%s]奖励池创建成功！" % [key])
	reward.add_qualitys_reward(goods_qualitys_reward)
	return true

## 获取: 容器奖励池
func get_map_level_probabilitys(_map_level: String) -> Array:
	return container_probabilitys.get(_map_level, null) # 容器概率

## 获取: 奖励池
func get_reward_pool(reward_pool_name: String) -> RewardPool:
	#print("获取: 物品奖励池[%s]." % [reward_pool_name])
	return reward_pools.get(reward_pool_name, null)

func is_empty() -> bool:
	return reward_pools.is_empty()

## 提取: 容器奖励池
func extract_container_reward_pool() -> Dictionary:
	var qualitys = {}
	if not config is Dictionary or not config.has("容器"):
		push_error("Json对象没有[容器]!")
		return {}
	var container = config["容器"]
	if not container is Dictionary or not container.has("概率"):
		push_error("Json对象[容器]没有[概率]!")
		return {}
	container_probabilitys = container["概率"] # {"普通": [0.6, 0.3, 0.1, 0, 0, 0, 0], "机密":[]...}
	if not container_probabilitys is Dictionary or container_probabilitys.is_empty():
		push_error("Json对象[容器][概率]没有数据!")
		return {}
		
	if not container is Dictionary or not container.has("品质"):
		push_error("Json对象[容器]没有[品质]!")
		return {}
	var container_qualitys = container["品质"] # {"白": [{"名称": "收纳袋", "类型": ...}...]}
	if not container_qualitys is Dictionary or container_qualitys.is_empty():
		push_error("Json对象[容器][品质]没有数据!")
		return {}
		
	if not container is Dictionary or not container.has("物品概率"):
		push_error("Json对象[容器]没有[物品概率]!")
		return {}
	goods_probabilitys = container["物品概率"] # {"收纳袋":[0.02, 0.02, 0.20, 0.40, 0.00, 0.33, 0.0405, 0.0005]...}
	if not goods_probabilitys is Dictionary or goods_probabilitys.is_empty():
		push_error("Json对象[容器][物品概率]没有数据!")
		return {}
	var container_quality_array = {}
	for key in container_qualitys.keys(): #"白": [{"名称": "收纳袋", "类型": ...}...]
		var quality_array = []
		#print("key: ", key)
		var data = container_qualitys[key] #[{"名称": "收纳袋", "类型": ...}...]
		for i in data.size(): # {"名称": "收纳袋", "类型": ...}
			var container_name = data[i]["名称"]
			var container_types = data[i]["类型"]
			var container_quality = RewardPool.string_to_quality(key)
			var container_ins = GoodsContainer.new()
			container_ins.init(container_name, container_types, container_quality)
			quality_array.append(container_ins)
			var types = []
			for i2 in container_types.size():
				var type_name = Goods.type_to_string(container_types[i2])
				if type_name == "所有":
					types = Goods.get_all_type()
				else:
					types.append(type_name)
			container_data.set(container_name, types.duplicate())
		container_quality_array.set(key, quality_array.duplicate())
	qualitys.set("容器", container_quality_array.duplicate())
	return qualitys

## 提取: 物品奖励池
func extract_goods_reward_pool() -> Dictionary:
	var goods_qualitys: Dictionary = {} # "工艺藏品": {"白": [{物品}...]}...
	if not config is Dictionary or not config.has("物品"):
		push_error("Json对象没有[物品]!")
		return {}
	var goods_types = config["物品"] # 容器分类
	if not goods_types is Dictionary or goods_types.is_empty():
		push_error("Json对象[物品]没有数据!")
		return {}
	for key_type in goods_types.keys(): # "工艺藏品" = {"白": [{物品}...]}
		var quality_array = {}
		var qualitys = goods_types[key_type] # {"白": [{物品}...]}
		for key_quality in qualitys.keys(): # "白": [{物品}...]
			var goods_array = []
			var goods_data_array = qualitys[key_quality] # [{物品}...]
			for i in goods_data_array.size():
				var goods_data = goods_data_array[i] # {物品}
				if not goods_data is Dictionary:
					push_error("[%s]不是字典!" % [goods_data])
					continue
				var goods_name: String = "extract_goods == null"
				var goods_dimensions: Vector2i = Vector2i(0, 0)
				var goods_value: int = 0
				var goods_type: Goods.Type = Goods.Type.None
				
				# 提取物品数据
				if goods_data.has("物品名称"):
					goods_name = goods_data["物品名称"]
				if goods_data.has("物品格数"):
					var dimensions = goods_data["物品格数"]
					if dimensions is Array and dimensions.size() == 2:
						goods_dimensions.x = dimensions[0]
						goods_dimensions.y = dimensions[1]
				if goods_data.has("物品价值"):
					var value = goods_data["物品价值"]
					if value is int or value is float:
						goods_value = int(value)
				if goods_data.has("物品类型"):
					var type = goods_data["物品类型"]
					if type is int or type is float:
						goods_type = type
				
				# 创建物品对象
				var goods = Goods.new()
				var quality_enum: RewardPool.Quality = RewardPool.string_to_quality(key_quality)
				goods.init(goods_name, quality_enum, goods_dimensions, goods_value, goods_type)
				#goods.output()
				goods_pool.set(goods_name, goods)
				goods_array.append(goods)
			quality_array.set(key_quality, goods_array.duplicate())
		goods_qualitys.set(key_type, quality_array.duplicate())
	return goods_qualitys

func allocate_single_reward_container(quality: RewardPool.Quality = RewardPool.Quality.None) -> Object:
	var container_reward_pool = get_reward_pool(GoodsContainer.type_to_string(randi() % 3))
	if not container_reward_pool:
		push_error("容器池 == null!")
		return null
	#container_reward_pool.output()
	var reward_object = container_reward_pool.allocate_single_reward(quality)
	#reward_object.output()
	return reward_object
	
func allocate_single_reward_goods(container_name: String = "收纳袋", quality: RewardPool.Quality = RewardPool.Quality.None) -> Object:
	var current_container = get_reward_pool(container_name)
	if not current_container:
		push_error("[%s]current_container == null!" % [container_name])
		return
	#current_container.output()
	var reward_object = current_container.allocate_single_reward(quality)
	#reward_object.output()
	return reward_object

func test():
	for i in range(10):
		var container_reward_pool = get_reward_pool(GoodsContainer.type_to_string(randi() % 3))
		if not container_reward_pool:
			push_error("容器池 == null!")
			return
		var reward_object = container_reward_pool.allocate_single_reward()
		#if reward_object:
			#reward_object.output()
	
	for i in range(10):
		var goods_reward_pool = get_reward_pool(get_goods_reward_random())
		if not goods_reward_pool:
			push_error("容器池 == null!")
			return
		var reward_object = goods_reward_pool.allocate_single_reward()
		#if reward_object:
			#reward_object.output()

func get_goods_reward_random() -> String:
	var keys = container_data.keys()
	return keys[randi() % keys.size()]

func get_container_types(container_name: String) -> Array:
	return container_data.get(container_name, [])

func create_config() -> Dictionary:	
	# 基本设置对象
	var base_setting: Dictionary = {}
	
	## 物品概率
	var goods: Dictionary = {}
	var container_class: Dictionary = {}
	var qualitys: Array = []
	
## ============================ 工艺藏品 =============================
	# 橙 品质数组
	qualitys.append({
		"物品名称": "非洲之心",
		"物品类型": Goods.Type.CraftCollection,
		"物品格数": [1, 1],
		"物品品质": RewardPool.Quality.Orange,
		"物品价值": 13145200
	})
	qualitys.append({
		"物品名称": "海洋之泪",
		"物品类型": Goods.Type.CraftCollection,
		"物品格数": [1, 1],
		"物品品质": RewardPool.Quality.Orange,
		"物品价值": 20000000
	})
	container_class["橙"] = qualitys.duplicate()
	qualitys.clear()
	
	qualitys.append({
		"物品名称": "印象派名画",
		"物品类型": Goods.Type.CraftCollection,
		"物品格数": [3, 3],
		"物品品质": RewardPool.Quality.Orange,
		"物品价值": 8000000
	})
	qualitys.append({
		"物品名称": "主战坦克模型",
		"物品类型": Goods.Type.CraftCollection,
		"物品格数": [3, 3],
		"物品价值": 6000000
	})
	qualitys.append({
		"物品名称": "步战车模型",
		"物品类型": Goods.Type.CraftCollection,
		"物品格数": [3, 2],
		"物品价值": 2600000
	})
	qualitys.append({
		"物品名称": "克劳迪乌斯半身像",
		"物品类型": Goods.Type.CraftCollection,
		"物品格数": [2, 3],
		"物品价值": 3200000
	})
	qualitys.append({
		"物品名称": "雷斯的留声机",
		"物品类型": Goods.Type.CraftCollection,
		"物品格数": [2, 3],
		"物品价值": 2800000
	})
	qualitys.append({
		"物品名称": "万金泪冠",
		"物品类型": Goods.Type.CraftCollection,
		"物品格数": [3, 3],
		"物品价值": 4000000
	})
	qualitys.append({
		"物品名称": "纵横",
		"物品类型": Goods.Type.CraftCollection,
		"物品格数": [3, 3],
		"物品价值": 4500000
	})
	container_class["红"] = qualitys.duplicate()
	qualitys.clear()
	
	qualitys.append({
		"物品名称": "鎏金卡牌",
		"物品类型": Goods.Type.CraftCollection,
		"物品格数": [1, 1],
		"物品价值": 240000
	})
	qualitys.append({
		"物品名称": "万足金条",
		"物品类型": Goods.Type.CraftCollection,
		"物品格数": [1, 2],
		"物品价值": 500000
	})
	qualitys.append({
		"物品名称": "名贵机械表",
		"物品类型": Goods.Type.CraftCollection,
		"物品格数": [1, 1],
		"物品价值": 240000
	})
	qualitys.append({
		"物品名称": "滑膛枪展示品",
		"物品类型": Goods.Type.CraftCollection,
		"物品格数": [4, 1],
		"物品价值": 1000000
	})
	qualitys.append({
		"物品名称": "化石",
		"物品类型": Goods.Type.CraftCollection,
		"物品格数": Vector2i(2, 1),
		"物品价值": 240000
	})
	qualitys.append({
		"物品名称": "黄金瞪羚",
		"物品类型": Goods.Type.CraftCollection,
		"物品格数": [2, 2],
		"物品价值": 1000000
	})
	qualitys.append({
		"物品名称": "赛伊德的怀表",
		"物品类型": Goods.Type.CraftCollection,
		"物品格数": [1, 1],
		"物品价值": 240000
	})
	qualitys.append({
		"物品名称": "天圆地方",
		"物品类型": Goods.Type.CraftCollection,
		"物品格数": [2, 2],
		"物品价值": 1200000
	})
	qualitys.append({
		"物品名称": "鱼子酱",
		"物品类型": Goods.Type.HomeItem,
		"物品格数": [1, 1],
		"物品价值": 240000
	})
	container_class["金"] = qualitys.duplicate()
	qualitys.clear()
	
	qualitys.append({
		"物品名称": "雷斯的乐谱本",
		"物品类型": Goods.Type.CraftCollection,
		"物品格数": [1, 2],
		"物品价值": 180000
	})
	qualitys.append({
		"物品名称": "荷美尔陶俑",
		"物品类型": Goods.Type.CraftCollection,
		"物品格数": [1, 2],
		"物品价值": 180000
	})
	qualitys.append({
		"物品名称": "本地特色首饰",
		"物品类型": Goods.Type.CraftCollection,
		"物品格数": [3, 2],
		"物品价值": 500000
	})
	qualitys.append({
		"物品名称": "金笔",
		"物品类型": Goods.Type.CraftCollection,
		"物品格数": [1, 1],
		"物品价值": 80000
	})
	qualitys.append({
		"物品名称": "金枝桂冠",
		"物品类型": Goods.Type.CraftCollection,
		"物品格数": Vector2i(2, 1),
		"物品价值": 180000
	})
	qualitys.append({
		"物品名称": "座钟",
		"物品类型": Goods.Type.CraftCollection,
		"物品格数": [2, 2],
		"物品价值": 400000
	})
	qualitys.append({
		"物品名称": "珠宝头冠",
		"物品类型": Goods.Type.CraftCollection,
		"物品格数": [3, 1],
		"物品价值": 260000
	})
	qualitys.append({
		"物品名称": "阿萨拉酒杯",
		"物品类型": Goods.Type.CraftCollection,
		"物品格数": [1, 1],
		"物品价值": 80000
	})
	qualitys.append({
		"物品名称": "海盗金币",
		"物品类型": Goods.Type.CraftCollection,
		"物品格数": [1, 1],
		"物品价值": 80000
	})
	qualitys.append({
		"物品名称": "勋章",
		"物品类型": Goods.Type.CraftCollection,
		"物品格数": [1, 1],
		"物品价值": 80000
	})
	qualitys.append({
		"物品名称": "发条八音盒",
		"物品类型": Goods.Type.CraftCollection,
		"物品格数": [1, 1],
		"物品价值": 80000
	})
	container_class["粉"] = qualitys.duplicate()
	qualitys.clear()
	
	# 紫 品质数组
	qualitys.append({
		"物品名称": "阿萨拉水壶",
		"物品类型": Goods.Type.CraftCollection,
		"物品格数": [1, 2],
		"物品价值": 45000
	})
	qualitys.append({
		"物品名称": "阿萨拉酒壶",
		"物品类型": Goods.Type.CraftCollection,
		"物品格数": [1, 2],
		"物品价值": 45000
	})
	qualitys.append({
		"物品名称": "阿萨拉提灯",
		"物品类型": Goods.Type.CraftCollection,
		"物品格数": [1, 2],
		"物品价值": 45000
	})
	qualitys.append({
		"物品名称": "黄金饰章",
		"物品类型": Goods.Type.CraftCollection,
		"物品格数": [1, 2],
		"物品价值": 45000
	})
	qualitys.append({
		"物品名称": "仪典匕首",
		"物品类型": Goods.Type.CraftCollection,
		"物品格数": [3, 2],
		"物品价值": 140000
	})
	qualitys.append({
		"物品名称": "图腾箭矢",
		"物品类型": Goods.Type.CraftCollection,
		"物品格数": [1, 1],
		"物品价值": 25000
	})
	qualitys.append({
		"物品名称": "马赛克灯台",
		"物品类型": Goods.Type.CraftCollection,
		"物品格数": [2, 3],
		"物品价值": 140000
	})
	qualitys.append({
		"物品名称": "牛角",
		"物品类型": Goods.Type.CraftCollection,
		"物品格数": Vector2i(2, 1),
		"物品价值": 45000
	})
	qualitys.append({
		"物品名称": "后妃耳环",
		"物品类型": Goods.Type.CraftCollection,
		"物品格数": [1, 1],
		"物品价值": 20000
	})
	qualitys.append({
		"物品名称": "海盗弯刀",
		"物品类型": Goods.Type.CraftCollection,
		"物品格数": [1, 1],
		"物品价值": 20000
	})
	container_class["紫"] = qualitys.duplicate()
	qualitys.clear()
	
	# 蓝 品质数组
	qualitys.append({
		"物品名称": "子弹零件",
		"物品类型": Goods.Type.CraftCollection,
		"物品格数": [1, 2],
		"物品价值": 25000
	})
	qualitys.append({
		"物品名称": "跳舞的女郎",
		"物品类型": Goods.Type.CraftCollection,
		"物品格数": [1, 2],
		"物品价值": 25000
	})
	qualitys.append({
		"物品名称": "海盗银币",
		"物品类型": Goods.Type.CraftCollection,
		"物品格数": [1, 1],
		"物品价值": 10000
	})
	qualitys.append({
		"物品名称": "海盗望远镜",
		"物品类型": Goods.Type.CraftCollection,
		"物品格数": [1, 2],
		"物品价值": 25000
	})
	container_class["蓝"] = qualitys.duplicate()
	qualitys.clear()
	
	# 绿 品质数组
	qualitys.append({
		"物品名称": "非洲木雕",
		"物品类型": Goods.Type.CraftCollection,
		"物品格数": [1, 2],
		"物品价值": 4500
	})
	qualitys.append({
		"物品名称": "非洲鼓",
		"物品类型": Goods.Type.CraftCollection,
		"物品格数": [1, 2],
		"物品价值": 4500
	})
	qualitys.append({
		"物品名称": "海盗铜币",
		"物品类型": Goods.Type.CraftCollection,
		"物品格数": [1, 1],
		"物品价值": 5000
	})
	qualitys.append({
		"物品名称": "阿萨拉陶翁",
		"物品类型": Goods.Type.CraftCollection,
		"物品格数": [2, 2],
		"物品价值": 10000
	})
	qualitys.append({
		"物品名称": "残弹挂坠",
		"物品类型": Goods.Type.CraftCollection,
		"物品格数": [1, 1],
		"物品价值": 2000
	})
	container_class["绿"] = qualitys.duplicate()
	qualitys.clear()
	
	goods["工艺藏品"] = container_class.duplicate()
	container_class.clear()
	
## ============================ 家居物品 =============================

	qualitys.append({
		"物品名称": "扫拖一体机器人",
		"物品类型": Goods.Type.HomeItem,
		"物品格数": [3, 3],
		"物品价值": 3000000
	})
	qualitys.append({
		"物品名称": "强力吸尘器",
		"物品类型": Goods.Type.HomeItem,
		"物品格数": [2, 3],
		"物品价值": 2000000
	})
	container_class["红"] = qualitys.duplicate()
	qualitys.clear()
	
	qualitys.append({
		"物品名称": "高级咖啡豆",
		"物品类型": Goods.Type.HomeItem,
		"物品格数": [1, 2],
		"物品价值": 500000
	})
	qualitys.append({
		"物品名称": "香槟",
		"物品类型": Goods.Type.HomeItem,
		"物品格数": [1, 2],
		"物品价值": 500000
	})
	qualitys.append({
		"物品名称": "鱼子酱",
		"物品类型": Goods.Type.HomeItem,
		"物品格数": [1, 1],
		"物品价值": 240000
	})
	container_class["金"] = qualitys.duplicate()
	qualitys.clear()
	
	qualitys.append({
		"物品名称": "挂耳咖啡",
		"物品类型": Goods.Type.HomeItem,
		"物品格数": [1, 2],
		"物品价值": 180000
	})
	qualitys.append({
		"物品名称": "飞行员眼镜",
		"物品类型": Goods.Type.HomeItem,
		"物品格数": [2, 1],
		"物品价值": 180000
	})
	qualitys.append({
		"物品名称": "龙舌兰",
		"物品类型": Goods.Type.HomeItem,
		"物品格数": [1, 2],
		"物品价值": 180000
	})
	qualitys.append({
		"物品名称": "咖啡",
		"物品类型": Goods.Type.HomeItem,
		"物品格数": [1, 1],
		"物品价值": 80000
	})
	qualitys.append({
		"物品名称": "纯金打火机",
		"物品类型": Goods.Type.HomeItem,
		"物品格数": [1, 1],
		"物品价值": 80000
	})
	qualitys.append({
		"物品名称": "营养粥罐头",
		"物品类型": Goods.Type.HomeItem,
		"物品格数": [1, 1],
		"物品价值": 80000
	})
	qualitys.append({
		"物品名称": "海鲜粥罐头",
		"物品类型": Goods.Type.HomeItem,
		"物品格数": [1, 1],
		"物品价值": 80000
	})
	container_class["粉"] = qualitys.duplicate()
	qualitys.clear()
	
	qualitys.append({
		"物品名称": "咖啡机套组",
		"物品类型": Goods.Type.HomeItem,
		"物品格数": [2, 2],
		"物品价值": 100000
	})
	qualitys.append({
		"物品名称": "姜饼人",
		"物品类型": Goods.Type.HomeItem,
		"物品格数": [1, 2],
		"物品价值": 45000
	})
	qualitys.append({
		"物品名称": "鳄鱼蛋",
		"物品类型": Goods.Type.HomeItem,
		"物品格数": [1, 1],
		"物品价值": 20000
	})
	qualitys.append({
		"物品名称": "鼻通",
		"物品类型": Goods.Type.HomeItem,
		"物品格数": [1, 1],
		"物品价值": 20000
	})
	qualitys.append({
		"物品名称": "爽身粉",
		"物品类型": Goods.Type.HomeItem,
		"物品格数": [1, 1],
		"物品价值": 20000
	})
	qualitys.append({
		"物品名称": "能量凝胶",
		"物品类型": Goods.Type.HomeItem,
		"物品格数": [1, 1],
		"物品价值": 20000
	})
	qualitys.append({
		"物品名称": "电动牙刷",
		"物品类型": Goods.Type.HomeItem,
		"物品格数": [1, 1],
		"物品价值": 20000
	})
	qualitys.append({
		"物品名称": "生津柠檬茶",
		"物品类型": Goods.Type.HomeItem,
		"物品格数": [1, 1],
		"物品价值": 20000
	})
	container_class["紫"] = qualitys.duplicate()
	qualitys.clear()
	
	qualitys.append({
		"物品名称": "时尚周刊",
		"物品类型": Goods.Type.HomeItem,
		"物品格数": [2, 2],
		"物品价值": 100000
	})
	qualitys.append({
		"物品名称": "摩卡咖啡壶",
		"物品类型": Goods.Type.HomeItem,
		"物品格数": [1, 2],
		"物品价值": 25000
	})
	qualitys.append({
		"物品名称": "木雕烟斗",
		"物品类型": Goods.Type.HomeItem,
		"物品格数": [2, 1],
		"物品价值": 25000
	})
	qualitys.append({
		"物品名称": "维生素片",
		"物品类型": Goods.Type.HomeItem,
		"物品格数": [1, 1],
		"物品价值": 10000
	})
	qualitys.append({
		"物品名称": "军用罐头",
		"物品类型": Goods.Type.HomeItem,
		"物品格数": [1, 1],
		"物品价值": 10000
	})
	qualitys.append({
		"物品名称": "刺刀特遣队",
		"物品类型": Goods.Type.HomeItem,
		"物品格数": [1, 1],
		"物品价值": 10000
	})
	qualitys.append({
		"物品名称": "英式袋泡茶",
		"物品类型": Goods.Type.HomeItem,
		"物品格数": [1, 1],
		"物品价值": 10000
	})
	qualitys.append({
		"物品名称": "可乐",
		"物品类型": Goods.Type.HomeItem,
		"物品格数": [1, 1],
		"物品价值": 10000
	})
	qualitys.append({
		"物品名称": "蛋白粉包",
		"物品类型": Goods.Type.HomeItem,
		"物品格数": [1, 1],
		"物品价值": 10000
	})
	qualitys.append({
		"物品名称": "香喷喷炒面",
		"物品类型": Goods.Type.HomeItem,
		"物品格数": [1, 1],
		"物品价值": 10000
	})
	qualitys.append({
		"物品名称": "糖三角",
		"物品类型": Goods.Type.HomeItem,
		"物品格数": [1, 1],
		"物品价值": 10000
	})
	qualitys.append({
		"物品名称": "战队之刃",
		"物品类型": Goods.Type.HomeItem,
		"物品格数": [1, 1],
		"物品价值": 10000
	})
	container_class["蓝"] = qualitys.duplicate()
	qualitys.clear()
	
	qualitys.append({
		"物品名称": "调料套组",
		"物品类型": Goods.Type.HomeItem,
		"物品格数": [2, 2],
		"物品价值": 10000
	})
	qualitys.append({
		"物品名称": "阿萨拉周刊",
		"物品类型": Goods.Type.HomeItem,
		"物品格数": [2, 2],
		"物品价值": 10000
	})
	qualitys.append({
		"物品名称": "袋装咖啡豆",
		"物品类型": Goods.Type.HomeItem,
		"物品格数": [1, 2],
		"物品价值": 4500
	})
	qualitys.append({
		"物品名称": "阿萨拉月刊",
		"物品类型": Goods.Type.HomeItem,
		"物品格数": [2, 2],
		"物品价值": 10000
	})
	qualitys.append({
		"物品名称": "宣传海报",
		"物品类型": Goods.Type.HomeItem,
		"物品格数": [2, 2],
		"物品价值": 10000
	})
	qualitys.append({
		"物品名称": "野外能量棒",
		"物品类型": Goods.Type.HomeItem,
		"物品格数": [1, 1],
		"物品价值": 2000
	})
	qualitys.append({
		"物品名称": "当地咖啡",
		"物品类型": Goods.Type.HomeItem,
		"物品格数": [1, 1],
		"物品价值": 2000
	})
	qualitys.append({
		"物品名称": "强力胶",
		"物品类型": Goods.Type.HomeItem,
		"物品格数": [1, 1],
		"物品价值": 2000
	})
	qualitys.append({
		"物品名称": "迷你氢电池",
		"物品类型": Goods.Type.HomeItem,
		"物品格数": [1, 1],
		"物品价值": 2000
	})
	qualitys.append({
		"物品名称": "电火机",
		"物品类型": Goods.Type.HomeItem,
		"物品格数": [1, 1],
		"物品价值": 2000
	})
	qualitys.append({
		"物品名称": "苹果",
		"物品类型": Goods.Type.HomeItem,
		"物品格数": [1, 1],
		"物品价值": 2000
	})
	qualitys.append({
		"物品名称": "无糖能量棒",
		"物品类型": Goods.Type.HomeItem,
		"物品格数": [1, 1],
		"物品价值": 2000
	})
	qualitys.append({
		"物品名称": "纯净水",
		"物品类型": Goods.Type.HomeItem,
		"物品格数": [1, 1],
		"物品价值": 2000
	})
	container_class["绿"] = qualitys.duplicate()
	qualitys.clear()
	
	qualitys.append({
		"物品名称": "胡椒粉",
		"物品类型": Goods.Type.HomeItem,
		"物品格数": [1, 1],
		"物品价值": 1000
	})
	qualitys.append({
		"物品名称": "酸奶",
		"物品类型": Goods.Type.HomeItem,
		"物品格数": [1, 1],
		"物品价值": 1000
	})
	container_class["白"] = qualitys.duplicate()
	qualitys.clear()
	goods["家居物品"] = container_class.duplicate()
	container_class.clear()
	
	
	
## ============================ 电子物品 =============================

	qualitys.append({
		"物品名称": "曼德尔超算单元",
		"物品类型": Goods.Type.Electronic,
		"物品格数": [3, 3],
		"物品价值": 8000000
	})
	container_class["橙"] = qualitys.duplicate()
	qualitys.clear()
	
	qualitys.append({
		"物品名称": "便携军用雷达",
		"物品类型": Goods.Type.Electronic,
		"物品格数": [3, 3],
		"物品价值": 5000000
	})
	qualitys.append({
		"物品名称": "高速磁盘阵列",
		"物品类型": Goods.Type.Electronic,
		"物品格数": [4, 3],
		"物品价值": 5000000
	})
	qualitys.append({
		"物品名称": "刀片服务器",
		"物品类型": Goods.Type.Electronic,
		"物品格数": [3, 4],
		"物品价值": 4000000
	})
	qualitys.append({
		"物品名称": "飞行记录仪",
		"物品类型": Goods.Type.Electronic,
		"物品格数": [3, 2],
		"物品价值": 3000000
	})
	qualitys.append({
		"物品名称": "笔记本电脑",
		"物品类型": Goods.Type.Electronic,
		"物品格数": [3, 2],
		"物品价值": 3000000
	})
	container_class["红"] = qualitys.duplicate()
	qualitys.clear()
	
	qualitys.append({
		"物品名称": "军用信息终端",
		"物品类型": Goods.Type.Electronic,
		"物品格数": [3, 2],
		"物品价值": 1400000
	})
	qualitys.append({
		"物品名称": "军用电台",
		"物品类型": Goods.Type.Electronic,
		"物品格数": [2, 2],
		"物品价值": 1000000
	})
	qualitys.append({
		"物品名称": "摄影机",
		"物品类型": Goods.Type.Electronic,
		"物品格数": [2, 2],
		"物品价值": 1000000
	})
	qualitys.append({
		"物品名称": "军用无人机",
		"物品类型": Goods.Type.Electronic,
		"物品格数": [2, 2],
		"物品价值": 1000000
	})
	qualitys.append({
		"物品名称": "军用控制终端",
		"物品类型": Goods.Type.Electronic,
		"物品格数": [2, 1],
		"物品价值": 500000
	})
	qualitys.append({
		"物品名称": "显卡",
		"物品类型": Goods.Type.Electronic,
		"物品格数": [2, 1],
		"物品价值": 500000
	})
	qualitys.append({
		"物品名称": "电子脚镣",
		"物品类型": Goods.Type.Electronic,
		"物品格数": [1, 1],
		"物品价值": 240000
	})
	qualitys.append({
		"物品名称": "定位接收器",
		"物品类型": Goods.Type.Electronic,
		"物品格数": [1, 1],
		"物品价值": 240000
	})
	qualitys.append({
		"物品名称": "恒星敏感器",
		"物品类型": Goods.Type.Electronic,
		"物品格数": [1, 1],
		"物品价值": 240000
	})
	container_class["金"] = qualitys.duplicate()
	qualitys.clear()
	
	qualitys.append({
		"物品名称": "大型电台",
		"物品类型": Goods.Type.Electronic,
		"物品格数": [2, 2],
		"物品价值": 340000
	})
	qualitys.append({
		"物品名称": "脑机头戴设备",
		"物品类型": Goods.Type.Electronic,
		"物品格数": [2, 2],
		"物品价值": 340000
	})
	qualitys.append({
		"物品名称": "军用卫星通讯仪",
		"物品类型": Goods.Type.Electronic,
		"物品格数": [2, 2],
		"物品价值": 340000
	})
	qualitys.append({
		"物品名称": "单反相机",
		"物品类型": Goods.Type.Electronic,
		"物品格数": [2, 2],
		"物品价值": 340000
	})
	qualitys.append({
		"物品名称": "镜头",
		"物品类型": Goods.Type.Electronic,
		"物品格数": [1, 1],
		"物品价值": 80000
	})
	qualitys.append({
		"物品名称": "军用望远镜",
		"物品类型": Goods.Type.Electronic,
		"物品格数": [2, 2],
		"物品价值": 340000
	})
	qualitys.append({
		"物品名称": "军用弹道计算机",
		"物品类型": Goods.Type.Electronic,
		"物品格数": [2, 1],
		"物品价值": 180000
	})
	qualitys.append({
		"物品名称": "卫星电话",
		"物品类型": Goods.Type.Electronic,
		"物品格数": [1, 2],
		"物品价值": 180000
	})
	qualitys.append({
		"物品名称": "高速固态硬盘",
		"物品类型": Goods.Type.Electronic,
		"物品格数": [1, 1],
		"物品价值": 80000
	})
	qualitys.append({
		"物品名称": "数码相机",
		"物品类型": Goods.Type.Electronic,
		"物品格数": [1, 1],
		"物品价值": 80000
	})
	qualitys.append({
		"物品名称": "可编程处理器",
		"物品类型": Goods.Type.Electronic,
		"物品格数": [1, 1],
		"物品价值": 80000
	})
	qualitys.append({
		"物品名称": "CPU",
		"物品类型": Goods.Type.Electronic,
		"物品格数": [1, 1],
		"物品价值": 80000
	})
	qualitys.append({
		"物品名称": "手机",
		"物品类型": Goods.Type.Electronic,
		"物品格数": [1, 1],
		"物品价值": 80000
	})
	qualitys.append({
		"物品名称": "军用网络模块",
		"物品类型": Goods.Type.Electronic,
		"物品格数": [1, 1],
		"物品价值": 80000
	})
	qualitys.append({
		"物品名称": "脑机控制端子",
		"物品类型": Goods.Type.Electronic,
		"物品格数": [1, 1],
		"物品价值": 80000
	})
	container_class["粉"] = qualitys.duplicate()
	qualitys.clear()
	
	qualitys.append({
		"物品名称": "军用热像仪",
		"物品类型": Goods.Type.Electronic,
		"物品格数": [2, 3],
		"物品价值": 140000
	})
	qualitys.append({
		"物品名称": "坏的热像仪",
		"物品类型": Goods.Type.Electronic,
		"物品格数": [1, 1],
		"物品价值": 20000
	})
	qualitys.append({
		"物品名称": "广角镜头",
		"物品类型": Goods.Type.Electronic,
		"物品格数": [2, 1],
		"物品价值": 45000
	})
	qualitys.append({
		"物品名称": "GS5 手柄",
		"物品类型": Goods.Type.Electronic,
		"物品格数": [1, 1],
		"物品价值": 20000
	})
	qualitys.append({
		"物品名称": "便携音响",
		"物品类型": Goods.Type.Electronic,
		"物品格数": [2, 1],
		"物品价值": 45000
	})
	qualitys.append({
		"物品名称": "内存条",
		"物品类型": Goods.Type.Electronic,
		"物品格数": [1, 1],
		"物品价值": 20000
	})
	qualitys.append({
		"物品名称": "HIFI声卡",
		"物品类型": Goods.Type.Electronic,
		"物品格数": [2, 1],
		"物品价值": 45000
	})
	qualitys.append({
		"物品名称": "收音机",
		"物品类型": Goods.Type.Electronic,
		"物品格数": [2, 1],
		"物品价值": 45000
	})
	qualitys.append({
		"物品名称": "间谍笔",
		"物品类型": Goods.Type.Electronic,
		"物品格数": [1, 1],
		"物品价值": 20000
	})
	qualitys.append({
		"物品名称": "电子干扰器",
		"物品类型": Goods.Type.Electronic,
		"物品格数": [1, 1],
		"物品价值": 20000
	})
	container_class["紫"] = qualitys.duplicate()
	qualitys.clear()
	
	qualitys.append({
		"物品名称": "液晶显示屏",
		"物品类型": Goods.Type.Electronic,
		"物品格数": [2, 2],
		"物品价值": 60000
	})
	qualitys.append({
		"物品名称": "电子温度计",
		"物品类型": Goods.Type.Electronic,
		"物品格数": [2, 2],
		"物品价值": 60000
	})
	qualitys.append({
		"物品名称": "无线耳机",
		"物品类型": Goods.Type.Electronic,
		"物品格数": [1, 1],
		"物品价值": 10000
	})
	qualitys.append({
		"物品名称": "U盘",
		"物品类型": Goods.Type.Electronic,
		"物品格数": [1, 1],
		"物品价值": 10000
	})
	qualitys.append({
		"物品名称": "移动电源",
		"物品类型": Goods.Type.Electronic,
		"物品格数": [1, 1],
		"物品价值": 10000
	})
	qualitys.append({
		"物品名称": "摄像头",
		"物品类型": Goods.Type.Electronic,
		"物品格数": [1, 1],
		"物品价值": 10000
	})
	qualitys.append({
		"物品名称": "继电器",
		"物品类型": Goods.Type.Electronic,
		"物品格数": [1, 1],
		"物品价值": 10000
	})
	qualitys.append({
		"物品名称": "存储卡",
		"物品类型": Goods.Type.Electronic,
		"物品格数": [1, 1],
		"物品价值": 10000
	})
	qualitys.append({
		"物品名称": "音频播放器",
		"物品类型": Goods.Type.Electronic,
		"物品格数": [1, 1],
		"物品价值": 10000
	})
	container_class["蓝"] = qualitys.duplicate()
	qualitys.clear()
	
	qualitys.append({
		"物品名称": "电源",
		"物品类型": Goods.Type.Electronic,
		"物品格数": [2, 2],
		"物品价值": 10000
	})
	qualitys.append({
		"物品名称": "DVD光驱",
		"物品类型": Goods.Type.Electronic,
		"物品格数": [1, 1],
		"物品价值": 2000
	})
	qualitys.append({
		"物品名称": "键盘",
		"物品类型": Goods.Type.Electronic,
		"物品格数": [2, 1],
		"物品价值": 4500
	})
	qualitys.append({
		"物品名称": "风冷散热器",
		"物品类型": Goods.Type.Electronic,
		"物品格数": [1, 1],
		"物品价值": 2000
	})
	qualitys.append({
		"物品名称": "高频读卡器",
		"物品类型": Goods.Type.Electronic,
		"物品格数": [1, 1],
		"物品价值": 2000
	})
	qualitys.append({
		"物品名称": "电容",
		"物品类型": Goods.Type.Electronic,
		"物品格数": [1, 1],
		"物品价值": 2000
	})
	qualitys.append({
		"物品名称": "机械硬盘",
		"物品类型": Goods.Type.Electronic,
		"物品格数": [1, 1],
		"物品价值": 2000
	})
	qualitys.append({
		"物品名称": "印刷电路板",
		"物品类型": Goods.Type.Electronic,
		"物品格数": [1, 1],
		"物品价值": 2000
	})
	qualitys.append({
		"物品名称": "手机电池",
		"物品类型": Goods.Type.Electronic,
		"物品格数": [1, 1],
		"物品价值": 2000
	})
	container_class["绿"] = qualitys.duplicate()
	qualitys.clear()
	
	qualitys.append({
		"物品名称": "鼠标",
		"物品类型": Goods.Type.Electronic,
		"物品格数": [1, 1],
		"物品价值": 1000
	})
	container_class["白"] = qualitys.duplicate()
	qualitys.clear()
	goods["电子物品"] = container_class.duplicate()
	container_class.clear()
	
	
	
## ============================ 工具材料 =============================

	qualitys.append({
		"物品名称": "强化碳纤维板",
		"物品类型": Goods.Type.ToolMaterial,
		"物品格数": [3, 3],
		"物品价值": 4000000
	})
	qualitys.append({
		"物品名称": "军用炮弹",
		"物品类型": Goods.Type.ToolMaterial,
		"物品格数": [3, 2],
		"物品价值": 2400000
	})
	container_class["红"] = qualitys.duplicate()
	qualitys.clear()
	
	qualitys.append({
		"物品名称": "飞秒激光器",
		"物品类型": Goods.Type.ToolMaterial,
		"物品格数": [3, 1],
		"物品价值": 800000
	})
	qualitys.append({
		"物品名称": "超声切割刀",
		"物品类型": Goods.Type.ToolMaterial,
		"物品格数": [1, 1],
		"物品价值": 240000
	})
	container_class["金"] = qualitys.duplicate()
	qualitys.clear()
	
	qualitys.append({
		"物品名称": "军用炸药",
		"物品类型": Goods.Type.ToolMaterial,
		"物品格数": [2, 2],
		"物品价值": 340000
	})
	qualitys.append({
		"物品名称": "紫外线灯",
		"物品类型": Goods.Type.ToolMaterial,
		"物品格数": [1, 3],
		"物品价值": 260000
	})
	qualitys.append({
		"物品名称": "液压破门器",
		"物品类型": Goods.Type.ToolMaterial,
		"物品格数": [1, 2],
		"物品价值": 180000
	})
	qualitys.append({
		"物品名称": "陆军万用表",
		"物品类型": Goods.Type.ToolMaterial,
		"物品格数": [1, 1],
		"物品价值": 80000
	})
	qualitys.append({
		"物品名称": "移动电缆",
		"物品类型": Goods.Type.ToolMaterial,
		"物品格数": [2, 2],
		"物品价值": 340000
	})
	container_class["粉"] = qualitys.duplicate()
	qualitys.clear()
	
	qualitys.append({
		"物品名称": "自旋型手锯",
		"物品类型": Goods.Type.ToolMaterial,
		"物品格数": [2, 2],
		"物品价值": 100000
	})
	qualitys.append({
		"物品名称": "粉碎钳",
		"物品类型": Goods.Type.ToolMaterial,
		"物品格数": [1, 2],
		"物品价值": 45000
	})
	qualitys.append({
		"物品名称": "植物样本",
		"物品类型": Goods.Type.ToolMaterial,
		"物品格数": [1, 1],
		"物品价值": 20000
	})
	qualitys.append({
		"物品名称": "聚乙烯纤维",
		"物品类型": Goods.Type.ToolMaterial,
		"物品格数": [1, 1],
		"物品价值": 20000
	})
	qualitys.append({
		"物品名称": "特种钢",
		"物品类型": Goods.Type.ToolMaterial,
		"物品格数": [2, 1],
		"物品价值": 45000
	})
	container_class["紫"] = qualitys.duplicate()
	qualitys.clear()
	
	qualitys.append({
		"物品名称": "一包水泥",
		"物品类型": Goods.Type.ToolMaterial,
		"物品格数": [2, 3],
		"物品价值": 80000
	})
	qualitys.append({
		"物品名称": "机械破障锤",
		"物品类型": Goods.Type.ToolMaterial,
		"物品格数": [2, 2],
		"物品价值": 50000
	})
	qualitys.append({
		"物品名称": "芳纶纤维",
		"物品类型": Goods.Type.ToolMaterial,
		"物品格数": [2, 1],
		"物品价值": 25000
	})
	qualitys.append({
		"物品名称": "火药",
		"物品类型": Goods.Type.ToolMaterial,
		"物品格数": [1, 2],
		"物品价值": 25000
	})
	qualitys.append({
		"物品名称": "枪械零件",
		"物品类型": Goods.Type.ToolMaterial,
		"物品格数": [2, 1],
		"物品价值": 25000
	})
	qualitys.append({
		"物品名称": "高精数卡尺",
		"物品类型": Goods.Type.ToolMaterial,
		"物品格数": [1, 1],
		"物品价值": 10000
	})
	qualitys.append({
		"物品名称": "转换插座",
		"物品类型": Goods.Type.ToolMaterial,
		"物品格数": [1, 1],
		"物品价值": 10000
	})
	container_class["蓝"] = qualitys.duplicate()
	qualitys.clear()
	
	qualitys.append({
		"物品名称": "石工锤",
		"物品类型": Goods.Type.ToolMaterial,
		"物品格数": [3, 1],
		"物品价值": 8000
	})
	qualitys.append({
		"物品名称": "手锯",
		"物品类型": Goods.Type.ToolMaterial,
		"物品格数": [2, 1],
		"物品价值": 4500
	})
	qualitys.append({
		"物品名称": "水平仪",
		"物品类型": Goods.Type.ToolMaterial,
		"物品格数": [1, 2],
		"物品价值": 4500
	})
	qualitys.append({
		"物品名称": "压力计",
		"物品类型": Goods.Type.ToolMaterial,
		"物品格数": [1, 2],
		"物品价值": 4500
	})
	qualitys.append({
		"物品名称": "原木木板",
		"物品类型": Goods.Type.ToolMaterial,
		"物品格数": [2, 1],
		"物品价值": 2000
	})
	qualitys.append({
		"物品名称": "电动爆破锤",
		"物品类型": Goods.Type.ToolMaterial,
		"物品格数": [2, 1],
		"物品价值": 4500
	})
	qualitys.append({
		"物品名称": "角磨机",
		"物品类型": Goods.Type.ToolMaterial,
		"物品格数": [2, 2],
		"物品价值": 10000
	})
	qualitys.append({
		"物品名称": "喷漆",
		"物品类型": Goods.Type.ToolMaterial,
		"物品格数": [1, 2],
		"物品价值": 4500
	})
	qualitys.append({
		"物品名称": "LED灯管",
		"物品类型": Goods.Type.ToolMaterial,
		"物品格数": [2, 1],
		"物品价值": 4500
	})
	qualitys.append({
		"物品名称": "螺丝刀",
		"物品类型": Goods.Type.ToolMaterial,
		"物品格数": [1, 1],
		"物品价值": 2000
	})
	qualitys.append({
		"物品名称": "电笔",
		"物品类型": Goods.Type.ToolMaterial,
		"物品格数": [1, 1],
		"物品价值": 2000
	})
	qualitys.append({
		"物品名称": "尖嘴钳",
		"物品类型": Goods.Type.ToolMaterial,
		"物品格数": [1, 1],
		"物品价值": 2000
	})
	qualitys.append({
		"物品名称": "插座",
		"物品类型": Goods.Type.ToolMaterial,
		"物品格数": [1, 1],
		"物品价值": 2000
	})
	qualitys.append({
		"物品名称": "电线",
		"物品类型": Goods.Type.ToolMaterial,
		"物品格数": [1, 1],
		"物品价值": 2000
	})
	qualitys.append({
		"物品名称": "波纹软管",
		"物品类型": Goods.Type.ToolMaterial,
		"物品格数": [1, 1],
		"物品价值": 2000
	})
	qualitys.append({
		"物品名称": "液压扳手",
		"物品类型": Goods.Type.ToolMaterial,
		"物品格数": [1, 1],
		"物品价值": 2000
	})
	container_class["绿"] = qualitys.duplicate()
	qualitys.clear()
	
	qualitys.append({
		"物品名称": "羊角锤",
		"物品类型": Goods.Type.ToolMaterial,
		"物品格数": [2, 1],
		"物品价值": 2500
	})
	qualitys.append({
		"物品名称": "一盒钉子",
		"物品类型": Goods.Type.ToolMaterial,
		"物品格数": [1, 1],
		"物品价值": 1000
	})
	qualitys.append({
		"物品名称": "直角尺",
		"物品类型": Goods.Type.ToolMaterial,
		"物品格数": [1, 2],
		"物品价值": 2500
	})
	qualitys.append({
		"物品名称": "工具刀",
		"物品类型": Goods.Type.ToolMaterial,
		"物品格数": [2, 1],
		"物品价值": 2500
	})
	qualitys.append({
		"物品名称": "油漆刷",
		"物品类型": Goods.Type.ToolMaterial,
		"物品格数": [1, 1],
		"物品价值": 1000
	})
	qualitys.append({
		"物品名称": "布基胶带",
		"物品类型": Goods.Type.ToolMaterial,
		"物品格数": [1, 1],
		"物品价值": 1000
	})
	qualitys.append({
		"物品名称": "精密工具组",
		"物品类型": Goods.Type.ToolMaterial,
		"物品格数": [1, 1],
		"物品价值": 1000
	})
	qualitys.append({
		"物品名称": "防水胶布",
		"物品类型": Goods.Type.ToolMaterial,
		"物品格数": [1, 1],
		"物品价值": 1000
	})
	qualitys.append({
		"物品名称": "网线",
		"物品类型": Goods.Type.ToolMaterial,
		"物品格数": [1, 1],
		"物品价值": 1000
	})
	qualitys.append({
		"物品名称": "测距卷尺",
		"物品类型": Goods.Type.ToolMaterial,
		"物品格数": [1, 1],
		"物品价值": 1000
	})
	container_class["白"] = qualitys.duplicate()
	qualitys.clear()
	goods["工具材料"] = container_class.duplicate()
	container_class.clear()
	
	
	
## ============================ 能源燃料 =============================

	qualitys.append({
		"物品名称": "微型反应炉",
		"物品类型": Goods.Type.EnergyFuel,
		"物品格数": [3, 3],
		"物品价值": 8000000
	})
	container_class["橙"] = qualitys.duplicate()
	qualitys.clear()
	
	qualitys.append({
		"物品名称": "火箭燃料",
		"物品类型": Goods.Type.EnergyFuel,
		"物品格数": [3, 4],
		"物品价值": 5000000
	})
	qualitys.append({
		"物品名称": "试制聚变供能单元",
		"物品类型": Goods.Type.EnergyFuel,
		"物品格数": [3, 3],
		"物品价值": 4000000
	})
	qualitys.append({
		"物品名称": "动力电池组",
		"物品类型": Goods.Type.EnergyFuel,
		"物品格数": [4, 3],
		"物品价值": 4000000
	})
	qualitys.append({
		"物品名称": "装甲车电池",
		"物品类型": Goods.Type.EnergyFuel,
		"物品格数": [3, 2],
		"物品价值": 7000000
	})
	qualitys.append({
		"物品名称": "G18",
		"物品类型": Goods.Type.EnergyFuel,
		"物品格数": [2, 1],
		"物品价值": 20000
	})
	container_class["红"] = qualitys.duplicate()
	qualitys.clear()
	
	qualitys.append({
		"物品名称": "卫星通讯",
		"物品类型": Goods.Type.EnergyFuel,
		"物品格数": [2, 2],
		"物品价值": 1000000
	})
	qualitys.append({
		"物品名称": "高能瓦斯罐",
		"物品类型": Goods.Type.EnergyFuel,
		"物品格数": [2, 2],
		"物品价值": 1000000
	})
	container_class["金"] = qualitys.duplicate()
	qualitys.clear()
	
	qualitys.append({
		"物品名称": "燃料电池",
		"物品类型": Goods.Type.EnergyFuel,
		"物品格数": [2, 3],
		"物品价值": 500000
	})
	qualitys.append({
		"物品名称": "电子氟化液",
		"物品类型": Goods.Type.EnergyFuel,
		"物品格数": [2, 2],
		"物品价值": 340000
	})
	qualitys.append({
		"物品名称": "高性能燃油",
		"物品类型": Goods.Type.EnergyFuel,
		"物品格数": [3, 1],
		"物品价值": 260000
	})
	qualitys.append({
		"物品名称": "航天冷却剂",
		"物品类型": Goods.Type.EnergyFuel,
		"物品格数": [1, 2],
		"物品价值": 180000
	})
	qualitys.append({
		"物品名称": "固体燃料",
		"物品类型": Goods.Type.EnergyFuel,
		"物品格数": [1, 1],
		"物品价值": 80000
	})
	container_class["粉"] = qualitys.duplicate()
	qualitys.clear()
	
	qualitys.append({
		"物品名称": "电动车电池",
		"物品类型": Goods.Type.EnergyFuel,
		"物品格数": [3, 2],
		"物品价值": 140000
	})
	qualitys.append({
		"物品名称": "军用露营灯",
		"物品类型": Goods.Type.EnergyFuel,
		"物品格数": [1, 2],
		"物品价值": 45000
	})
	qualitys.append({
		"物品名称": "燃气喷灯",
		"物品类型": Goods.Type.EnergyFuel,
		"物品格数": [1, 2],
		"物品价值": 45000
	})
	qualitys.append({
		"物品名称": "便携生存套组",
		"物品类型": Goods.Type.EnergyFuel,
		"物品格数": [2, 1],
		"物品价值": 45000
	})
	qualitys.append({
		"物品名称": "信号棒",
		"物品类型": Goods.Type.EnergyFuel,
		"物品格数": [1, 1],
		"物品价值": 20000
	})
	container_class["紫"] = qualitys.duplicate()
	qualitys.clear()
	
	qualitys.append({
		"物品名称": "燃气罐",
		"物品类型": Goods.Type.EnergyFuel,
		"物品格数": [2, 2],
		"物品价值": 45000
	})
	qualitys.append({
		"物品名称": "低级燃料",
		"物品类型": Goods.Type.EnergyFuel,
		"物品格数": [1, 1],
		"物品价值": 10000
	})
	qualitys.append({
		"物品名称": "狩猎火柴",
		"物品类型": Goods.Type.EnergyFuel,
		"物品格数": [1, 1],
		"物品价值": 10000
	})
	qualitys.append({
		"物品名称": "多用途电池",
		"物品类型": Goods.Type.EnergyFuel,
		"物品格数": [1, 1],
		"物品价值": 10000
	})
	qualitys.append({
		"物品名称": "轻型户外炉具",
		"物品类型": Goods.Type.EnergyFuel,
		"物品格数": [2, 2],
		"物品价值": 45000
	})
	container_class["蓝"] = qualitys.duplicate()
	qualitys.clear()
	
	qualitys.append({
		"物品名称": "充电电池组",
		"物品类型": Goods.Type.EnergyFuel,
		"物品格数": [1, 1],
		"物品价值": 2000
	})
	qualitys.append({
		"物品名称": "9V电池",
		"物品类型": Goods.Type.EnergyFuel,
		"物品格数": [1, 1],
		"物品价值": 2000
	})
	container_class["绿"] = qualitys.duplicate()
	qualitys.clear()
	
	qualitys.append({
		"物品名称": "盒装蜡烛",
		"物品类型": Goods.Type.EnergyFuel,
		"物品格数": [2, 2],
		"物品价值": 6000
	})
	container_class["白"] = qualitys.duplicate()
	qualitys.clear()
	goods["能源燃料"] = container_class.duplicate()
	container_class.clear()
	
	
	
## ============================ 医疗道具 =============================

	qualitys.append({
		"物品名称": "复苏呼吸机",
		"物品类型": Goods.Type.Medical,
		"物品格数": [3, 3],
		"物品价值": 9000000
	})
	container_class["橙"] = qualitys.duplicate()
	qualitys.clear()
	
	qualitys.append({
		"物品名称": "ECMO",
		"物品类型": Goods.Type.Medical,
		"物品格数": [3, 3],
		"物品价值": 5000000
	})
	qualitys.append({
		"物品名称": "自动体外除颤器",
		"物品类型": Goods.Type.Medical,
		"物品格数": [2, 3],
		"物品价值": 2400000
	})
	qualitys.append({
		"物品名称": "医疗机器人",
		"物品类型": Goods.Type.Medical,
		"物品格数": [2, 3],
		"物品价值": 2000000
	})
	container_class["红"] = qualitys.duplicate()
	qualitys.clear()
	
	qualitys.append({
		"物品名称": "呼吸机",
		"物品类型": Goods.Type.Medical,
		"物品格数": [2, 2],
		"物品价值": 1000000
	})
	container_class["金"] = qualitys.duplicate()
	qualitys.clear()
	
	qualitys.append({
		"物品名称": "便携氧气筒",
		"物品类型": Goods.Type.Medical,
		"物品格数": [1, 3],
		"物品价值": 260000
	})
	qualitys.append({
		"物品名称": "检眼镜",
		"物品类型": Goods.Type.Medical,
		"物品格数": [1, 2],
		"物品价值": 180000
	})
	qualitys.append({
		"物品名称": "静脉定位器",
		"物品类型": Goods.Type.Medical,
		"物品格数": [1, 1],
		"物品价值": 80000
	})
	qualitys.append({
		"物品名称": "心脏支架",
		"物品类型": Goods.Type.Medical,
		"物品格数": [1, 2],
		"物品价值": 18000
	})
	qualitys.append({
		"物品名称": "哮喘吸入器",
		"物品类型": Goods.Type.Medical,
		"物品格数": [1, 1],
		"物品价值": 80000
	})
	qualitys.append({
		"物品名称": "血氧仪",
		"物品类型": Goods.Type.Medical,
		"物品格数": [1, 1],
		"物品价值": 80000
	})
	qualitys.append({
		"物品名称": "体内除颤器",
		"物品类型": Goods.Type.Medical,
		"物品格数": [1, 1],
		"物品价值": 80000
	})
	qualitys.append({
		"物品名称": "E型滤毒罐",
		"物品类型": Goods.Type.Medical,
		"物品格数": [1, 1],
		"物品价值": 80000
	})
	container_class["粉"] = qualitys.duplicate()
	qualitys.clear()
	
	qualitys.append({
		"物品名称": "离心机",
		"物品类型": Goods.Type.Medical,
		"物品格数": [2, 2],
		"物品价值": 100000
	})
	qualitys.append({
		"物品名称": "生化培养箱",
		"物品类型": Goods.Type.Medical,
		"物品格数": [2, 2],
		"物品价值": 100000
	})
	qualitys.append({
		"物品名称": "血压仪",
		"物品类型": Goods.Type.Medical,
		"物品格数": [2, 2],
		"物品价值": 100000
	})
	qualitys.append({
		"物品名称": "人工膝关节",
		"物品类型": Goods.Type.Medical,
		"物品格数": [1, 2],
		"物品价值": 45000
	})
	qualitys.append({
		"物品名称": "急救喷雾",
		"物品类型": Goods.Type.Medical,
		"物品格数": [1, 1],
		"物品价值": 20000
	})
	qualitys.append({
		"物品名称": "无菌敷料包",
		"物品类型": Goods.Type.Medical,
		"物品格数": [1, 2],
		"物品价值": 45000
	})
	container_class["紫"] = qualitys.duplicate()
	qualitys.clear()
	
	qualitys.append({
		"物品名称": "医疗无人机",
		"物品类型": Goods.Type.Medical,
		"物品格数": [2, 2],
		"物品价值": 45000
	})
	qualitys.append({
		"物品名称": "骨锯",
		"物品类型": Goods.Type.Medical,
		"物品格数": [3, 1],
		"物品价值": 35000
	})
	qualitys.append({
		"物品名称": "额温枪",
		"物品类型": Goods.Type.Medical,
		"物品格数": [1, 1],
		"物品价值": 10000
	})
	qualitys.append({
		"物品名称": "电子显微镜",
		"物品类型": Goods.Type.Medical,
		"物品格数": [1, 3],
		"物品价值": 35000
	})
	qualitys.append({
		"物品名称": "听诊器",
		"物品类型": Goods.Type.Medical,
		"物品格数": [1, 2],
		"物品价值": 25000
	})
	qualitys.append({
		"物品名称": "医用酒精",
		"物品类型": Goods.Type.Medical,
		"物品格数": [1, 1],
		"物品价值": 10000
	})
	container_class["蓝"] = qualitys.duplicate()
	qualitys.clear()
	
	qualitys.append({
		"物品名称": "输液工具",
		"物品类型": Goods.Type.Medical,
		"物品格数": [1, 1],
		"物品价值": 2000
	})
	qualitys.append({
		"物品名称": "小药瓶",
		"物品类型": Goods.Type.Medical,
		"物品格数": [1, 1],
		"物品价值": 2000
	})
	qualitys.append({
		"物品名称": "注射器",
		"物品类型": Goods.Type.Medical,
		"物品格数": [1, 1],
		"物品价值": 2000
	})
	qualitys.append({
		"物品名称": "手术镊子",
		"物品类型": Goods.Type.Medical,
		"物品格数": [1, 1],
		"物品价值": 2000
	})
	container_class["绿"] = qualitys.duplicate()
	qualitys.clear()
	
	qualitys.append({
		"物品名称": "手术剪刀",
		"物品类型": Goods.Type.Medical,
		"物品格数": [1, 1],
		"物品价值": 1000
	})
	qualitys.append({
		"物品名称": "样本试管",
		"物品类型": Goods.Type.Medical,
		"物品格数": [1, 2],
		"物品价值": 2500
	})
	qualitys.append({
		"物品名称": "含氟牙膏",
		"物品类型": Goods.Type.Medical,
		"物品格数": [1, 2],
		"物品价值": 2500
	})
	qualitys.append({
		"物品名称": "外科手套",
		"物品类型": Goods.Type.Medical,
		"物品格数": [1, 1],
		"物品价值": 1000
	})
	container_class["白"] = qualitys.duplicate()
	qualitys.clear()
	goods["医疗道具"] = container_class.duplicate()
	container_class.clear()
	
	
	
## ============================ 资料情报 =============================
	
	qualitys.append({
		"物品名称": "绝密服务器",
		"物品类型": Goods.Type.Document,
		"物品格数": [3, 3],
		"物品价值": 6000000
	})
	container_class["橙"] = qualitys.duplicate()
	qualitys.clear()
	
	qualitys.append({
		"物品名称": "云存储阵列",
		"物品类型": Goods.Type.Document,
		"物品格数": [3, 2],
		"物品价值": 3000000
	})
	container_class["红"] = qualitys.duplicate()
	qualitys.clear()
	
	qualitys.append({
		"物品名称": "已封存音源",
		"物品类型": Goods.Type.Document,
		"物品格数": [2, 2],
		"物品价值": 1000000
	})
	qualitys.append({
		"物品名称": "量子存储",
		"物品类型": Goods.Type.Document,
		"物品格数": [1, 1],
		"物品价值": 240000
	})
	qualitys.append({
		"物品名称": "实验数据",
		"物品类型": Goods.Type.Document,
		"物品格数": [1, 1],
		"物品价值": 240000
	})
	container_class["金"] = qualitys.duplicate()
	qualitys.clear()
	
	qualitys.append({
		"物品名称": "阵列服务器",
		"物品类型": Goods.Type.Document,
		"物品格数": [4, 3],
		"物品价值": 1200000
	})
	qualitys.append({
		"物品名称": "军用地图匣",
		"物品类型": Goods.Type.Document,
		"物品格数": [1, 3],
		"物品价值": 250000
	})
	qualitys.append({
		"物品名称": "脑机报告",
		"物品类型": Goods.Type.Document,
		"物品格数": [2, 2],
		"物品价值": 100000
	})
	qualitys.append({
		"物品名称": "作战计划书",
		"物品类型": Goods.Type.Document,
		"物品格数": [1, 2],
		"物品价值": 25000
	})
	qualitys.append({
		"物品名称": "测试数据",
		"物品类型": Goods.Type.Document,
		"物品格数": [1, 1],
		"物品价值": 80000
	})
	qualitys.append({
		"物品名称": "设计图纸",
		"物品类型": Goods.Type.Document,
		"物品格数": [1, 1],
		"物品价值": 80000
	})
	qualitys.append({
		"物品名称": "藏秘筒",
		"物品类型": Goods.Type.Document,
		"物品格数": [1, 1],
		"物品价值": 80000
	})
	container_class["粉"] = qualitys.duplicate()
	qualitys.clear()
	
	qualitys.append({
		"物品名称": "加密路由器",
		"物品类型": Goods.Type.Document,
		"物品格数": [2, 2],
		"物品价值": 100000
	})
	qualitys.append({
		"物品名称": "残缺的档案",
		"物品类型": Goods.Type.Document,
		"物品格数": [1, 2],
		"物品价值": 45000
	})
	qualitys.append({
		"物品名称": "机密档案",
		"物品类型": Goods.Type.Document,
		"物品格数": [1, 2],
		"物品价值": 45000
	})
	qualitys.append({
		"物品名称": "加密手记",
		"物品类型": Goods.Type.Document,
		"物品格数": [1, 1],
		"物品价值": 20000
	})
	qualitys.append({
		"物品名称": "袖珍录像带",
		"物品类型": Goods.Type.Document,
		"物品格数": [1, 1],
		"物品价值": 20000
	})
	qualitys.append({
		"物品名称": "军事情报",
		"物品类型": Goods.Type.Document,
		"物品格数": [1, 1],
		"物品价值": 20000
	})
	container_class["紫"] = qualitys.duplicate()
	qualitys.clear()
	
	qualitys.append({
		"物品名称": "情报文件",
		"物品类型": Goods.Type.Document,
		"物品格数": [1, 2],
		"物品价值": 25000
	})
	qualitys.append({
		"物品名称": "军情录音",
		"物品类型": Goods.Type.Document,
		"物品格数": [1, 3],
		"物品价值": 35000
	})
	qualitys.append({
		"物品名称": "工牌",
		"物品类型": Goods.Type.Document,
		"物品格数": [1, 1],
		"物品价值": 10000
	})
	qualitys.append({
		"物品名称": "商业文件",
		"物品类型": Goods.Type.Document,
		"物品格数": [1, 1],
		"物品价值": 10000
	})
	container_class["蓝"] = qualitys.duplicate()
	qualitys.clear()
	
	qualitys.append({
		"物品名称": "私密笔记薄",
		"物品类型": Goods.Type.Document,
		"物品格数": [1, 2],
		"物品价值": 5000
	})
	container_class["绿"] = qualitys.duplicate()
	qualitys.clear()
	
	qualitys.append({
		"物品名称": "人像照片",
		"物品类型": Goods.Type.Document,
		"物品格数": [2, 1],
		"物品价值": 2500
	})
	qualitys.append({
		"物品名称": "军情照片",
		"物品类型": Goods.Type.Document,
		"物品格数": [2, 1],
		"物品价值": 2500
	})
	qualitys.append({
		"物品名称": "当地小报",
		"物品类型": Goods.Type.Document,
		"物品格数": [2, 1],
		"物品价值": 2500
	})
	qualitys.append({
		"物品名称": "物流信息单",
		"物品类型": Goods.Type.Document,
		"物品格数": [1, 1],
		"物品价值": 1000
	})
	container_class["白"] = qualitys.duplicate()
	qualitys.clear()
	goods["资料情报"] = container_class.duplicate()
	container_class.clear()
	
## ============================ 钥匙 =============================

	qualitys.append({
		"物品名称": "总裁会客厅",
		"物品类型": Goods.Type.KeyCar,
		"物品格数": [1, 1],
		"物品价值": 9000000
	})
	qualitys.append({
		"物品名称": "变电技术室",
		"物品类型": Goods.Type.KeyCar,
		"物品格数": [1, 1],
		"物品价值": 9000000
	})
	container_class["橙"] = qualitys.duplicate()
	qualitys.clear()
	
	qualitys.append({
		"物品名称": "黑室服务器",
		"物品类型": Goods.Type.KeyCar,
		"物品格数": [1, 1],
		"物品价值": 3400000
	})
	qualitys.append({
		"物品名称": "蓝室核心",
		"物品类型": Goods.Type.KeyCar,
		"物品格数": [1, 1],
		"物品价值": 4000000
	})
	qualitys.append({
		"物品名称": "东楼经理室",
		"物品类型": Goods.Type.KeyCar,
		"物品格数": [1, 1],
		"物品价值": 6000000
	})
	container_class["红"] = qualitys.duplicate()
	qualitys.clear()
	
	qualitys.append({
		"物品名称": "蓝室数据",
		"物品类型": Goods.Type.KeyCar,
		"物品格数": [1, 1],
		"物品价值": 1000000
	})
	qualitys.append({
		"物品名称": "东区吊桥",
		"物品类型": Goods.Type.KeyCar,
		"物品格数": [1, 1],
		"物品价值": 2000000
	})
	qualitys.append({
		"物品名称": "西楼调控房",
		"物品类型": Goods.Type.KeyCar,
		"物品格数": [1, 1],
		"物品价值": 800000
	})
	qualitys.append({
		"物品名称": "西楼监视室",
		"物品类型": Goods.Type.KeyCar,
		"物品格数": [1, 1],
		"物品价值": 600000
	})
	qualitys.append({
		"物品名称": "设备领用室",
		"物品类型": Goods.Type.KeyCar,
		"物品格数": [1, 1],
		"物品价值": 300000
	})
	container_class["粉"] = qualitys.duplicate()
	qualitys.clear()
	
	
	qualitys.append({
		"物品名称": "浮力医务间",
		"物品类型": Goods.Type.KeyCar,
		"物品格数": [1, 1],
		"物品价值": 600000
	})
	qualitys.append({
		"物品名称": "中控室三楼",
		"物品类型": Goods.Type.KeyCar,
		"物品格数": [1, 1],
		"物品价值": 700000
	})
	qualitys.append({
		"物品名称": "3号宿舍",
		"物品类型": Goods.Type.KeyCar,
		"物品格数": [1, 1],
		"物品价值": 2000000
	})
	qualitys.append({
		"物品名称": "员工通道",
		"物品类型": Goods.Type.KeyCar,
		"物品格数": [1, 1],
		"物品价值": 1400000
	})
	qualitys.append({
		"物品名称": "西区大门",
		"物品类型": Goods.Type.KeyCar,
		"物品格数": [1, 1],
		"物品价值": 2000000
	})
	qualitys.append({
		"物品名称": "组装间二楼",
		"物品类型": Goods.Type.KeyCar,
		"物品格数": [1, 1],
		"物品价值": 600000
	})
	qualitys.append({
		"物品名称": "蓝室玻璃房",
		"物品类型": Goods.Type.KeyCar,
		"物品格数": [1, 1],
		"物品价值": 900000
	})
	qualitys.append({
		"物品名称": "售票办公室",
		"物品类型": Goods.Type.KeyCar,
		"物品格数": [1, 1],
		"物品价值": 600000
	})
	qualitys.append({
		"物品名称": "军营保管室",
		"物品类型": Goods.Type.KeyCar,
		"物品格数": [1, 1],
		"物品价值": 500000
	})
	qualitys.append({
		"物品名称": "中心贵宾室",
		"物品类型": Goods.Type.KeyCar,
		"物品格数": [1, 1],
		"物品价值": 400000
	})
	qualitys.append({
		"物品名称": "水泥厂办公",
		"物品类型": Goods.Type.KeyCar,
		"物品格数": [1, 1],
		"物品价值": 300000
	})
	container_class["紫"] = qualitys.duplicate()
	qualitys.clear()
	
	qualitys.append({
		"物品名称": "变电站宿舍",
		"物品类型": Goods.Type.KeyCar,
		"物品格数": [1, 1],
		"物品价值": 200000
	})
	container_class["蓝"] = qualitys.duplicate()
	qualitys.clear()
	goods["钥匙"] = container_class.duplicate()
	container_class.clear()



## ============================ 其他 =============================
	base_setting["物品"] = goods
	
	var container: Dictionary = {}
	container["品质"] = {
		"白": [
			{"名称": "收纳袋", "类型": [Goods.Type.HomeItem]},
			{"名称": "收纳盒", "类型": [Goods.Type.HomeItem]},
			{"名称": "快递盒", "类型": [Goods.Type.HomeItem]},
			{"名称": "抽屉柜", "类型": [Goods.Type.HomeItem]},
			{"名称": "储物柜", "类型": [Goods.Type.ToolMaterial, Goods.Type.HomeItem]},
			{"名称": "井盖", "类型": [Goods.Type.CraftCollection, Goods.Type.HomeItem]},
			{"名称": "鸟窝", "类型": [Goods.Type.CraftCollection, Goods.Type.HomeItem, Goods.Type.Electronic]},
			{"名称": "电脑机箱", "类型": [Goods.Type.Electronic]}
		], 
		"绿": [
			{"名称": "登山包", "类型": [Goods.Type.HomeItem]},
			{"名称": "旅行箱", "类型": [Goods.Type.HomeItem]},
			{"名称": "工具柜", "类型": [Goods.Type.ToolMaterial]},
			{"名称": "野外物资箱", "类型": [Goods.Type.EnergyFuel, Goods.Type.ToolMaterial]},
			{"名称": "电脑", "类型": [Goods.Type.Electronic]},
			{"名称": "军用医疗包", "类型": [Goods.Type.Medical]},
			{"名称": "小保险箱", "类型": [Goods.Type.CraftCollection]}
		], 
		"蓝": [
			{"名称": "手提箱", "类型": [Goods.Type.Document]},
			{"名称": "高级储物箱", "类型": [Goods.Type.Electronic, Goods.Type.ToolMaterial, Goods.Type.HomeItem]},
			{"名称": "服务器", "类型": [Goods.Type.Electronic]},
			{"名称": "医疗物资箱", "类型": [Goods.Type.Medical]},
			{"名称": "衣服", "类型": [Goods.Type.KeyCar]},
			{"名称": "航空箱", "类型": [Goods.Type.EnergyFuel, Goods.Type.ToolMaterial]},
			{"名称": "保险箱", "类型": [Goods.Type.CraftCollection]}
		]
	}
	container["概率"] = {
		"普通": [0.8, 0.19, 0.01, 0, 0, 0, 0],
		"机密": [0.6, 0.35, 0.05, 0, 0, 0, 0],
		"绝密": [0.35, 0.55, 0.1, 0, 0, 0, 0]
	}
	container["物品概率"] = {
		"收纳袋": 		[0.043, 0.103, 0.15, 0.45, 0.2, 0.05, 0.0037, 0.0003],
		"收纳盒": 		[0.043, 0.103, 0.15, 0.45, 0.2, 0.05, 0.0037, 0.0003],
		"快递盒": 		[0.043, 0.103, 0.15, 0.45, 0.2, 0.05, 0.0037, 0.0003],
		"抽屉柜": 		[0.043, 0.103, 0.15, 0.45, 0.2, 0.05, 0.0037, 0.0003],
		"储物柜": 		[0.043, 0.103, 0.15, 0.45, 0.2, 0.05, 0.0037, 0.0003],
		"井盖": 			[0.043, 0.103, 0.15, 0.45, 0.2, 0.05, 0.0037, 0.0003],
		"鸟窝": 			[0.043, 0.103, 0.15, 0.45, 0.2, 0.05, 0.0037, 0.0003],
		"电脑机箱": 		[0.043, 0.103, 0.15, 0.45, 0.2, 0.05, 0.0037, 0.0003],
		
		"登山包": 		[0.0, 0.05, 0.1, 0.35, 0.389, 0.1, 0.01, 0.001],
		"旅行箱": 		[0.0, 0.05, 0.1, 0.35, 0.389, 0.1, 0.01, 0.001],
		"工具柜": 		[0.0, 0.05, 0.1, 0.35, 0.389, 0.1, 0.01, 0.001],
		"野外物资箱": 	[0.0, 0.05, 0.1, 0.35, 0.389, 0.1, 0.01, 0.001],
		"军用医疗包": 	[0.0, 0.05, 0.1, 0.35, 0.389, 0.1, 0.01, 0.001],
		"电脑": 			[0.0, 0.05, 0.1, 0.35, 0.389, 0.1, 0.01, 0.001],
		"小保险箱": 		[0.0, 0.05, 0.1, 0.35, 0.389, 0.1, 0.01, 0.001],
		
		"手提箱": 		[0.0, 0.0, 0.05, 0.35, 0.389, 0.15, 0.05, 0.011],
		"高级储物箱": 	[0.0, 0.0, 0.05, 0.35, 0.389, 0.15, 0.05, 0.011],
		"医疗物资箱": 	[0.0, 0.0, 0.05, 0.35, 0.389, 0.15, 0.05, 0.011],
		"服务器": 		[0.0, 0.0, 0.05, 0.35, 0.389, 0.15, 0.05, 0.011],
		"衣服": 			[0.0, 0.0, 0.05, 0.35, 0.389, 0.15, 0.05, 0.011],
		"航空箱": 		[0.0, 0.0, 0.05, 0.35, 0.389, 0.15, 0.05, 0.011],
		"保险箱": 		[0.0, 0.0, 0.05, 0.35, 0.389, 0.15, 0.05, 0.011]
	}
	base_setting["容器"] = container
	
	if not Global.game_config.has("货币"):
		base_setting["货币"] = 0
	if not Global.game_config.has("仓库"):
		base_setting["仓库"] = []
	if not Global.game_config.has("钥匙卡包"):
		base_setting["钥匙卡包"] = []
	base_setting["版本"] = "0.0.105"
	return base_setting

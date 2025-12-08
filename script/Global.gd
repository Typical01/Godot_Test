extends Node

const SLOT_SIZE = 64
const TEXTURE_SIZE = 64
var SLOT_SCALE = SLOT_SIZE / TEXTURE_SIZE
var H_SEPARATION = 0
var V_SEPARATION = 0


var game_config: Dictionary
var safe_box_reward_pool

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	load_setting(true)
	
	safe_box_reward_pool = RewardPool.new()
	if safe_box_reward_pool.load_config(game_config):
		print("普通奖励池创建成功")
	return
	print("\n=== 测试普通奖励池 ===")
	var normal_reward = safe_box_reward_pool.allocate_single_reward()
	if normal_reward:
		for i in normal_reward:
			print("获得[%s]: %s (价值: %d)" % [\
			Goods.get_color_from_string(i.quality), i.name, i.value])
	
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func load_setting(show_log = false):
	data_manage.is_show_log = show_log
	var base_setting = data_manage.data_file.get("基本设置", {})
	var quality_setting = base_setting.get("概率", {})
	var goods_setting = base_setting.get("物品", {})
	
	if base_setting.is_empty() and quality_setting.is_empty() and \
		goods_setting.is_empty():
		game_config = data_manage.get_object("基本设置")
		print("Global: 获取设置.")
	else:
		data_manage.set_object("基本设置", create_game_config())
		data_manage.save_data()
		game_config = data_manage.get_object("基本设置")
		print("Global: 创建设置.")

func extract_items_by_quality(config: Dictionary, quality: String, quality_array:Array[Goods]) -> bool:
	if config.is_empty() or not config.has("基本设置"):
		print("Global::extract_items_by_quality: Json对象没有[基本设置]!")
		return false
	
	var base_setting = config["基本设置"]
	if not base_setting is Dictionary or not base_setting.has("物品"):
		print("Global::extract_items_by_quality: Json对象没有[物品]!")
		return false
	var goods_object = base_setting["物品"]
	if not goods_object is Dictionary or not goods_object.has(quality):
		print("Global::extract_items_by_quality: Json对象[物品]没有[%s]!" % quality)
		return false
	var item_array = goods_object[quality]
	if not item_array is Array:
		print("Global::extract_items_by_quality: [%s]不是数组!" % quality)
		return false
		
	for item_data in item_array:
		if not item_data is Dictionary:
			continue
		var goods_name: String = ""
		var goods_slot: int = Goods.Slot.Slot_1_1
		var goods_value: int = 0
		var goods_class: int = Goods.Class.CraftCollection
		
		# 提取物品数据
		if item_data.has("物品名称"):
			goods_name = item_data["物品名称"]
			# print("Global::extract_items_by_quality: 物品名称[%s]" % goods_name)
		if item_data.has("物品格数"):
			var slot_value = item_data["物品格数"]
			if slot_value is int:
				goods_slot = slot_value
			# print("Global::extract_items_by_quality: 物品格数[%d]" % goods_slot)
		if item_data.has("物品价值"):
			var value = item_data["物品价值"]
			if value is int or value is float:
				goods_value = int(value)
			# print("Global::extract_items_by_quality: 物品价值[%d]" % goods_value)
		if item_data.has("物品类型"):
			var class_value = item_data["物品类型"]
			if class_value is int:
				goods_class = class_value
			# print("Global::extract_items_by_quality: 物品类型[%d]" % goods_class)
		
		# 创建物品对象
		var goods = Goods.new()
		goods.init(goods_name, Goods.get_string_from_color(quality), goods_slot, goods_value, goods_class)
		quality_array.append(goods)
		# print("Global::extract_items_by_quality: Goods[%s] | Name[%s]" % [str(goods.container_queue_user_widget), goods.get_name()])
	return true


func create_game_config() -> Dictionary:
	var game_config: Dictionary = {}
	# 品质字典
	var quality_dict: Dictionary = {}
	# 橙 品质数组
	var orange_array: Array = []
	orange_array.append({
		"物品名称": "非洲之心",
		"物品类型": Goods.Class.CraftCollection,
		"物品格数": Goods.Slot.Slot_1_1,
		"物品价值": 13000000
	})
	orange_array.append({
		"物品名称": "海洋之泪",
		"物品类型": Goods.Class.CraftCollection,
		"物品格数": Goods.Slot.Slot_1_1,
		"物品价值": 20000000
	})
	quality_dict["橙"] = orange_array
	
	# 红 品质数组
	var red_array: Array = []
	red_array.append({
		"物品名称": "鎏金卡牌",
		"物品类型": Goods.Class.CraftCollection,
		"物品格数": Goods.Slot.Slot_1_1,
		"物品价值": 200000
	})
	red_array.append({
		"物品名称": "万足金条",
		"物品类型": Goods.Class.CraftCollection,
		"物品格数": Goods.Slot.Slot_1_2,
		"物品价值": 350000
	})
	red_array.append({
		"物品名称": "名贵机械表",
		"物品类型": Goods.Class.CraftCollection,
		"物品格数": Goods.Slot.Slot_1_1,
		"物品价值": 300000
	})
	red_array.append({
		"物品名称": "印象派名画",
		"物品类型": Goods.Class.CraftCollection,
		"物品格数": Goods.Slot.Slot_3_3,
		"物品价值": 8000000
	})
	red_array.append({
		"物品名称": "主战坦克模型",
		"物品类型": Goods.Class.CraftCollection,
		"物品格数": Goods.Slot.Slot_3_3,
		"物品价值": 5000000
	})
	red_array.append({
		"物品名称": "步战车模型",
		"物品类型": Goods.Class.CraftCollection,
		"物品格数": Goods.Slot.Slot_3_2,
		"物品价值": 2400000
	})
	red_array.append({
		"物品名称": "滑膛枪展示品",
		"物品类型": Goods.Class.CraftCollection,
		"物品格数": Goods.Slot.Slot_4_1,
		"物品价值": 800000
	})
	red_array.append({
		"物品名称": "化石",
		"物品类型": Goods.Class.CraftCollection,
		"物品格数": Goods.Slot.Slot_2_1,
		"物品价值": 400000
	})
	red_array.append({
		"物品名称": "黄金瞪羚",
		"物品类型": Goods.Class.CraftCollection,
		"物品格数": Goods.Slot.Slot_2_2,
		"物品价值": 450000
	})
	red_array.append({
		"物品名称": "克劳迪乌斯半身像",
		"物品类型": Goods.Class.CraftCollection,
		"物品格数": Goods.Slot.Slot_2_3,
		"物品价值": 3200000
	})
	red_array.append({
		"物品名称": "雷斯的留声机",
		"物品类型": Goods.Class.CraftCollection,
		"物品格数": Goods.Slot.Slot_2_3,
		"物品价值": 2800000
	})
	red_array.append({
		"物品名称": "赛伊德的怀表",
		"物品类型": Goods.Class.CraftCollection,
		"物品格数": Goods.Slot.Slot_1_1,
		"物品价值": 200000
	})
	red_array.append({
		"物品名称": "天圆地方",
		"物品类型": Goods.Class.CraftCollection,
		"物品格数": Goods.Slot.Slot_2_2,
		"物品价值": 850000
	})
	red_array.append({
		"物品名称": "万金泪冠",
		"物品类型": Goods.Class.CraftCollection,
		"物品格数": Goods.Slot.Slot_3_3,
		"物品价值": 2500000
	})
	red_array.append({
		"物品名称": "纵横",
		"物品类型": Goods.Class.CraftCollection,
		"物品格数": Goods.Slot.Slot_3_3,
		"物品价值": 3000000
	})
	quality_dict["红"] = red_array
	
	# 金 品质数组
	var gold_array: Array = []
	gold_array.append({
		"物品名称": "本地特色首饰",
		"物品类型": Goods.Class.CraftCollection,
		"物品格数": Goods.Slot.Slot_3_2,
		"物品价值": 80000
	})
	gold_array.append({
		"物品名称": "金笔",
		"物品类型": Goods.Class.CraftCollection,
		"物品格数": Goods.Slot.Slot_1_1,
		"物品价值": 80000
	})
	gold_array.append({
		"物品名称": "金枝桂冠",
		"物品类型": Goods.Class.CraftCollection,
		"物品格数": Goods.Slot.Slot_2_1,
		"物品价值": 320000
	})
	gold_array.append({
		"物品名称": "座钟",
		"物品类型": Goods.Class.CraftCollection,
		"物品格数": Goods.Slot.Slot_2_2,
		"物品价值": 240000
	})
	gold_array.append({
		"物品名称": "珠宝头冠",
		"物品类型": Goods.Class.CraftCollection,
		"物品格数": Goods.Slot.Slot_3_1,
		"物品价值": 160000
	})
	gold_array.append({
		"物品名称": "阿萨拉特色酒杯",
		"物品类型": Goods.Class.CraftCollection,
		"物品格数": Goods.Slot.Slot_1_1,
		"物品价值": 80000
	})
	gold_array.append({
		"物品名称": "亮闪闪的海盗金币",
		"物品类型": Goods.Class.CraftCollection,
		"物品格数": Goods.Slot.Slot_1_1,
		"物品价值": 80000
	})
	gold_array.append({
		"物品名称": "勋章",
		"物品类型": Goods.Class.CraftCollection,
		"物品格数": Goods.Slot.Slot_1_1,
		"物品价值": 80000
	})
	gold_array.append({
		"物品名称": "发条八音盒",
		"物品类型": Goods.Class.CraftCollection,
		"物品格数": Goods.Slot.Slot_1_1,
		"物品价值": 80000
	})
	quality_dict["金"] = gold_array
	
	# 紫 品质数组
	var purple_array: Array = []
	purple_array.append({
		"物品名称": "仪典匕首",
		"物品类型": Goods.Class.CraftCollection,
		"物品格数": Goods.Slot.Slot_3_2,
		"物品价值": 100000
	})
	purple_array.append({
		"物品名称": "图腾箭矢",
		"物品类型": Goods.Class.CraftCollection,
		"物品格数": Goods.Slot.Slot_1_1,
		"物品价值": 25000
	})
	purple_array.append({
		"物品名称": "马赛克灯台",
		"物品类型": Goods.Class.CraftCollection,
		"物品格数": Goods.Slot.Slot_2_3,
		"物品价值": 100000
	})
	purple_array.append({
		"物品名称": "牛角",
		"物品类型": Goods.Class.CraftCollection,
		"物品格数": Goods.Slot.Slot_2_1,
		"物品价值": 30000
	})
	purple_array.append({
		"物品名称": "后妃耳环",
		"物品类型": Goods.Class.CraftCollection,
		"物品格数": Goods.Slot.Slot_1_1,
		"物品价值": 20000
	})
	purple_array.append({
		"物品名称": "海盗弯刀",
		"物品类型": Goods.Class.CraftCollection,
		"物品格数": Goods.Slot.Slot_1_1,
		"物品价值": 20000
	})
	quality_dict["紫"] = purple_array
	
	# 蓝 品质数组
	var blue_array: Array = []
	blue_array.append({
		"物品名称": "跳舞的女郎",
		"物品类型": Goods.Class.CraftCollection,
		"物品格数": Goods.Slot.Slot_1_2,
		"物品价值": 15000
	})
	blue_array.append({
		"物品名称": "古怪的海盗银币",
		"物品类型": Goods.Class.CraftCollection,
		"物品格数": Goods.Slot.Slot_1_1,
		"物品价值": 10000
	})
	blue_array.append({
		"物品名称": "古老的海盗望远镜",
		"物品类型": Goods.Class.CraftCollection,
		"物品格数": Goods.Slot.Slot_1_2,
		"物品价值": 15000
	})
	quality_dict["蓝"] = blue_array
	
	# 绿 品质数组
	var green_array: Array = []
	green_array.append({
		"物品名称": "锈迹斑斑的海盗铜币",
		"物品类型": Goods.Class.CraftCollection,
		"物品格数": Goods.Slot.Slot_1_1,
		"物品价值": 5000
	})
	green_array.append({
		"物品名称": "阿萨拉特色陶翁",
		"物品类型": Goods.Class.CraftCollection,
		"物品格数": Goods.Slot.Slot_2_2,
		"物品价值": 15000
	})
	green_array.append({
		"物品名称": "残弹挂坠",
		"物品类型": Goods.Class.CraftCollection,
		"物品格数": Goods.Slot.Slot_1_1,
		"物品价值": 2000
	})
	quality_dict["绿"] = green_array
	
	# 白 品质数组
	var white_array: Array = []
	white_array.append({
		"物品名称": "酸奶",
		"物品类型": Goods.Class.Household,
		"物品格数": Goods.Slot.Slot_1_1,
		"物品价值": 5
	})
	quality_dict["白"] = white_array
	
	# 基本设置对象
	var base_setting: Dictionary = {}
	base_setting["概率"] = [
		0.02,   # 白
		0.02,   # 绿
		0.30,   # 蓝
		0.41,   # 紫
		0.00,   # 粉
		0.23,   # 金
		0.0198, # 红
		0.0002  # 橙
	]
	base_setting["物品"] = quality_dict
	game_config["基本设置"] = base_setting
	return game_config

# 使用示例
# var config = create_game_config()
# print(config["基本设置"]["概率"])  # 访问概率数组
# print(config["基本设置"]["物品"]["橙"][0]["物品名称"])  # 访问第一个橙色物品的名称

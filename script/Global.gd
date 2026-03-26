extends Node


const SLOT_SIZE = 64
const TEXTURE_SIZE = 64
var SLOT_SCALE = SLOT_SIZE / TEXTURE_SIZE
var H_SEPARATION = 0
var V_SEPARATION = 0

var game_config: Dictionary
var safe_box_reward_pool


func _ready() -> void:
	#game_config = create_game_config()
	#data_manage.data_file = game_config
	#data_manage.save_data_json()
	load_setting()
	
	safe_box_reward_pool = RewardPool.new()
	if safe_box_reward_pool.load_config(game_config):
		print("Global: 普通奖励池创建成功！")
	return
	print("\n=== 测试普通奖励池 ===")
	var normal_reward = safe_box_reward_pool.allocate_single_reward()
	if normal_reward:
		for i in normal_reward:
			print("获得[%s]: %s (价值: %d)" % [\
			Goods.get_color_from_string(i.quality), i.name, i.value])

func _exit_tree() -> void:
	save_data()
	print("Global: 程序关闭, 保存数据!")

func _notification(what):
	# 检查通知是否为“窗口管理器关闭请求”
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		save_data()
		print("Global: 窗口关闭, 保存数据!")
		get_tree().quit() # 退出

func save_data() -> void:
	data_manage.data_file = game_config
	data_manage.save_data_json()

func load_setting():
	game_config = data_manage.data_file
	var quality_setting = game_config.get("概率", {})
	var goods_setting = game_config.get("物品", {})
	
	if game_config.is_empty() or quality_setting.is_empty() or \
		goods_setting.is_empty():
		print("Global: game_config.is_empty = %s" % game_config.is_empty())
		print("Global: quality_setting.is_empty = %s" % quality_setting.is_empty())
		print("Global: goods_setting.is_empty = %s" % goods_setting.is_empty())
			
		data_manage.data_file = create_game_config()
		data_manage.save_data_json()
		game_config = data_manage.data_file
		print("Global: 创建设置.")
	else:
		if Engine.is_editor_hint():
			game_config["概率"] = [
				0.0,   # 白
				0.0,   # 绿
				0.0,   # 蓝
				0.0,   # 紫
				0.00,  # 粉
				0.1,   # 金
				0.8, 	# 红
				0.1  	# 橙
			]
			print("Global: editor.")
		print("Global: 获取设置.")
		print(quality_setting)

func extract_items_by_quality(config: Dictionary, quality: String, quality_array:Array[Goods]) -> bool:
	var base_setting = config
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
		goods.output()
		quality_array.append(goods)
		# print("Global::extract_items_by_quality: Goods[%s] | Name[%s]" % [str(goods.container_queue_user_widget), goods.get_name()])
	return true


func create_game_config() -> Dictionary:
	# 品质字典
	var quality_dict: Dictionary = {}
	# 橙 品质数组
	var orange_array: Array = []
	orange_array.append({
		"物品名称": "非洲之心",
		"物品类型": Goods.Class.CraftCollection,
		"物品格数": Goods.Slot.Slot_1_1,
		"物品价值": 13145200
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
		"物品价值": 3000000
	})
	red_array.append({
		"物品名称": "滑膛枪展示品",
		"物品类型": Goods.Class.CraftCollection,
		"物品格数": Goods.Slot.Slot_4_1,
		"物品价值": 1000000
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
		"物品价值": 1200000
	})
	red_array.append({
		"物品名称": "万金泪冠",
		"物品类型": Goods.Class.CraftCollection,
		"物品格数": Goods.Slot.Slot_3_3,
		"物品价值": 4000000
	})
	red_array.append({
		"物品名称": "纵横",
		"物品类型": Goods.Class.CraftCollection,
		"物品格数": Goods.Slot.Slot_3_3,
		"物品价值": 3500000
	})
	quality_dict["红"] = red_array
	
	# 金 品质数组
	var gold_array: Array = []
	gold_array.append({
		"物品名称": "雷斯的乐谱本",
		"物品类型": Goods.Class.CraftCollection,
		"物品格数": Goods.Slot.Slot_1_2,
		"物品价值": 150000
	})
	gold_array.append({
		"物品名称": "荷美尔陶俑",
		"物品类型": Goods.Class.CraftCollection,
		"物品格数": Goods.Slot.Slot_1_2,
		"物品价值": 120000
	})
	gold_array.append({
		"物品名称": "本地特色首饰",
		"物品类型": Goods.Class.CraftCollection,
		"物品格数": Goods.Slot.Slot_3_2,
		"物品价值": 200000
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
		"物品价值": 160000
	})
	gold_array.append({
		"物品名称": "座钟",
		"物品类型": Goods.Class.CraftCollection,
		"物品格数": Goods.Slot.Slot_2_2,
		"物品价值": 200000
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
		"物品名称": "阿萨拉风情水壶",
		"物品类型": Goods.Class.CraftCollection,
		"物品格数": Goods.Slot.Slot_1_2,
		"物品价值": 30000
	})
	purple_array.append({
		"物品名称": "阿萨拉特色酒壶",
		"物品类型": Goods.Class.CraftCollection,
		"物品格数": Goods.Slot.Slot_1_2,
		"物品价值": 30000
	})
	purple_array.append({
		"物品名称": "阿萨拉特色提灯",
		"物品类型": Goods.Class.CraftCollection,
		"物品格数": Goods.Slot.Slot_1_2,
		"物品价值": 30000
	})
	purple_array.append({
		"物品名称": "黄金饰章",
		"物品类型": Goods.Class.CraftCollection,
		"物品格数": Goods.Slot.Slot_1_2,
		"物品价值": 35000
	})
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
		"物品名称": "初级子弹生产零件",
		"物品类型": Goods.Class.CraftCollection,
		"物品格数": Goods.Slot.Slot_1_2,
		"物品价值": 15000
	})
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
		"物品名称": "非洲木雕",
		"物品类型": Goods.Class.CraftCollection,
		"物品格数": Goods.Slot.Slot_1_2,
		"物品价值": 3500
	})
	green_array.append({
		"物品名称": "非洲鼓",
		"物品类型": Goods.Class.CraftCollection,
		"物品格数": Goods.Slot.Slot_1_2,
		"物品价值": 3500
	})
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
	# 货币
	var value_setting: int = 0
	base_setting["货币"] = value_setting
	
	base_setting["物品"] = quality_dict
	return base_setting

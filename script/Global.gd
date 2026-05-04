extends Node


const SLOT_SIZE = 64
const TEXTURE_SIZE = 64
var H_SEPARATION = 0
var V_SEPARATION = 0

var game_config: Dictionary
var goods_container_reward_pool = null


func _ready() -> void:
	load_setting(true)
	#print("\n=== 测试普通奖励池 ===")
	#var normal_reward = safe_box_reward_pool.allocate_single_reward()
	#if normal_reward:
		#for i in normal_reward:
			#print("获得[%s]: %s (价值: %d)" % [\
			#Goods.get_color_from_string(i.quality), i.name, i.value])

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

func load_setting(create_config: bool = false):
	game_config = data_manage.data_file
	goods_container_reward_pool = GoodsContainerRewardPool.new()
	if create_config: # 强制创建新配置
		game_config = goods_container_reward_pool.create_config()
		save_data()
	
	if game_config.is_empty():
		print("Global: game_config == null!")
		game_config = goods_container_reward_pool.create_config()
		data_manage.save_data_json()
		if not goods_container_reward_pool.init(game_config):
			return
		print("Global: 创建设置.")
	else:
		if not goods_container_reward_pool.init(game_config):
			return
		print("Global: 获取设置.")
	print("Global: 普通奖励池创建成功！")

extends Node


const SLOT_SIZE = 72

var game_config: Dictionary
var input: InputRecognizer = InputRecognizer.new()
var goods_container_reward_pool: GoodsContainerRewardPool = null


func _ready() -> void:
	load_setting()

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
	
	var version = game_config.get("版本", "")
	var project_varsion = ProjectSettings.get_setting("application/config/version", "null")
	if project_varsion == "null":
		push_error("没有获取到版本!")
	print("版本: ", version)
	if game_config.is_empty() or not game_config.has("容器")or not game_config.has("物品") or version != project_varsion:
		print("Global: game_config == null!")
		game_config = goods_container_reward_pool.create_config()
		save_data()
		if not goods_container_reward_pool.init(game_config):
			return
		print("Global: 创建设置.")
	else:
		if not goods_container_reward_pool.init(game_config):
			return
		print("Global: 获取设置.")
	print("Global: 奖励池创建成功！")

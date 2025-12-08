extends Node
class_name DataManage



var data_file : Dictionary
var is_show_log := false
var save_path = "user://game.dat" :
	set(path):
		save_path = path
		if is_show_log: print("DataManage: 保存路径修改为[%s]!" % save_path)
	get():
		return save_path



func _ready() -> void:
	# 尝试加载；如果不存在就新建
	if not load_data():
		data_file = {}
		save_data()

# 保存
func save_data() -> void:
	if data_file == null:
		data_file = {}
	var file = FileAccess.open(save_path, FileAccess.WRITE)
	if file == null:
		push_error("DataManage: 无法打开文件写入: %s" % save_path)
		return
	file.store_var(data_file)
	file.close()
	if is_show_log: print("DataManage: 保存到文件[%s]!" % save_path)


# 读取
func load_data() -> bool:
	if not FileAccess.file_exists(save_path):
		if is_show_log: print("DataManage: 保存文件[%s]不存在!" % save_path)
		return false
	var file = FileAccess.open(save_path, FileAccess.READ)
	if file == null:
		push_error("DataManage: 打开文件失败: %s" % save_path)
		return false
	# get_var() 返回序列化的 Variant（这里通常是 Dictionary）
	var v = file.get_var()  # 若文件里是带对象序列化的，使用 file.get_var(true)
	file.close()
	if typeof(v) == TYPE_DICTIONARY:
		data_file = v
		if is_show_log: print("DataManage: " % data_file)
		return true
	else:
		push_error("DataManage: 读取到的存档不是 Dictionary，已忽略。")
		data_file = {}
		return false


# 获取对象 —— 更稳健的检查与懒加载
func get_object(object_name: StringName) -> Variant:
	# 如果还未加载过，尝试懒加载一次
	if data_file == null:
		load_data()
		if data_file == null:
			# 保底，避免后续访问 NILL
			data_file = {}
	# 确保类型正确
	if typeof(data_file) != TYPE_DICTIONARY:
		push_error("DataManage: get_object: data_file 类型无效")
		return null

	if data_file.has(object_name):
		return data_file[object_name]
	else:
		if is_show_log:
			print("DataManage-get_object: 对象[%s]不存在!" % object_name)
		return null


# 设置对象
func set_object(object_name: StringName, object = null, count = 0) -> bool:
	if object_name == null:
		if is_show_log: print("DataManage: set_object: 空对象名称[%s]!" % str(count))
		return false
	if object == null:
		if is_show_log: print("DataManage: set_object: 空对象[%s]!" % object_name)
		return false
	
	if data_file == null:
		data_file = {}
	data_file[object_name] = object
	if is_show_log:
		# 注意字符串格式化的正确写法（用数组）
		print("DataManage: set_object: object: [%s] = (%s)" % [object_name, str(object)])
	#_save_data() # 可选：每次设置就保存，或定期保存
	return true

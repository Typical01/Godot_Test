extends Node
class_name DataManage



var data_file : Dictionary = {} :
	set(data):
		data_file = data
	get():
		return data_file 
#var is_show_log := true
var is_show_log := false
var save_path = "user://game.json" :
	set(path):
		save_path = path
		if is_show_log: print("DataManage: 保存路径修改为[%s]!" % save_path)
	get():
		return save_path



func _ready() -> void:
	# 尝试加载；如果不存在就新建
	if not load_data_json():
		data_file = {}
		save_data_json()

# 保存
func save_data() -> void:
	if data_file.is_empty():
		data_file = {}
	var file = FileAccess.open(save_path, FileAccess.WRITE)
	if file == null:
		push_error("DataManage: 无法打开文件写入: %s" % save_path)
		return
	file.store_var(data_file)
	file.close()
	if is_show_log: 
		print("DataManage: 保存到文件[%s]!" % save_path)
		print("DataManage: 详细数据:")
		print(data_file)

# 读取
func load_data() -> bool:
	if not FileAccess.file_exists(save_path):
		if is_show_log: push_error("DataManage: 文件[%s]不存在!" % save_path)
		return false
	if is_show_log: print("DataManage: 打开文件[%s]!" % save_path)
	var file = FileAccess.open(save_path, FileAccess.READ)
	if file == null:
		push_error("DataManage: 打开文件失败: %s" % save_path)
		return false
	# get_var() 返回序列化的 Variant（这里通常是 Dictionary）
	var v = file.get_var()  # 若文件里是带对象序列化的，使用 file.get_var(true)
	file.close()
	if typeof(v) == TYPE_DICTIONARY:
		data_file = v
		if is_show_log: 
			print("DataManage: 详细数据:")
			print(data_file)
		return true
	else:
		push_error("DataManage: 读取到的存档不是 Dictionary，已忽略。")
		data_file = {}
		return false

## 保存 - 使用JSON格式: user://game.json
func save_data_json(_file_name: String = "") -> void:
	if data_file.is_empty():
		data_file = {}
	
	var file
	if !_file_name.is_empty():
		file = FileAccess.open(_file_name, FileAccess.WRITE)
	else:
		file = FileAccess.open(save_path, FileAccess.WRITE)
	if file == null:
		push_error("DataManage: 无法打开文件写入: %s" % save_path)
		return
	
	# 关键改动：将Dictionary转换为JSON字符串
	var json_string = JSON.stringify(data_file, "\t")
	file.store_string(json_string)
	
	file.close()
	if is_show_log: 
		print("DataManage: 保存到文件[%s]!" % save_path)
		print("DataManage: JSON格式内容:")
		print(json_string)  # 打印JSON字符串而不是原始Dictionary

# 读取 - 从JSON格式解析
func load_data_json() -> bool:
	if not FileAccess.file_exists(save_path):
		if is_show_log: push_error("DataManage: 文件[%s]不存在!" % save_path)
		return false
	
	if is_show_log: print("DataManage: 打开文件[%s]!" % save_path)
	
	var file = FileAccess.open(save_path, FileAccess.READ)
	if file == null:
		push_error("DataManage: 打开文件失败: %s" % save_path)
		return false
	
	# 关键改动：读取文本内容并解析JSON
	var json_string = file.get_as_text()
	file.close()
	
	# 解析JSON
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	
	if parse_result == OK:
		var parsed_data = json.get_data()
		if typeof(parsed_data) == TYPE_DICTIONARY:
			data_file = parsed_data
			if is_show_log: 
				print("DataManage: 成功解析JSON数据:")
				print(data_file)
			return true
		else:
			push_error("DataManage: JSON解析结果不是Dictionary，类型为: %s" % typeof(parsed_data))
			data_file = {}
			return false
	else:
		push_error("DataManage: JSON解析失败 (行 %d): %s" % [json.get_error_line(), json.get_error_message()])
		data_file = {}
		return false

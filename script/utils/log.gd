class_name CustomLoggersImpl extends Logger
# 文件路径 user://logs/yyyy-mm-dd_HH-MM-SS.log

# 持有文件对象
var log_file: FileAccess = null

func _init() -> void:
	# 初始化日志文件
	var dt = Time.get_datetime_string_from_system()
	var path = "user://logs/%s.log" % dt
	log_file = FileAccess.open(path, FileAccess.WRITE)
	if log_file:
		# 注册这个实例为 logger
		OS.add_logger(self)

# 收到普通消息（包括 print() 和 engine 消息）
func _log_message(message: String, _error: bool) -> void:
	# 去掉结尾换行
	message = message.trim_suffix("\n")
	# 写文件
	if log_file:
		log_file.store_string("[MSG] %s\n" % message)
		log_file.flush()
	# 同样输出到控制台
	print(message)

# 收到 error / warning
func _log_error(_function: String, file: String, line: int, _code: String, rationale: String, _editor_notify: bool, _error_type: int, _script_backtraces: Array) -> void:
	var err_msg = "[ERR] %s:%d %s" % [file, line, rationale]
	if log_file:
		log_file.store_string(err_msg + "\n")
		log_file.flush()
	print(err_msg)

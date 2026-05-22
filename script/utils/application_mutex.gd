# singleton.gd
# 将此脚本添加为自动加载单例 (Project Settings -> Autoload)
extends Node

# 信号：当检测到另一个实例时发出
signal another_instance_detected

var _mutex: Mutex
var _lock_file: FileAccess
var _is_primary_instance: bool = false

const LOCK_FILE_NAME = "app_instance.lock"
const LOCK_FILE_PATH = "user://" + LOCK_FILE_NAME

func _init():
	_mutex = Mutex.new()
	print("application_mutex: _init(PID: %s)[%s]" % [OS.get_process_id(), Time.get_datetime_string_from_system(false, true)])

func _ready():
	# 尝试获取主实例锁
	_is_primary_instance = _acquire_lock()
	
	if not _is_primary_instance:
		# 不是主实例，显示警告并退出
		call_deferred("_handle_secondary_instance")
	else:
		print("application_mutex: App 程序运行.")

func _acquire_lock() -> bool:
	_mutex.lock()
	var success = false
	
	# 获取锁文件路径
	#var lock_path = ProjectSettings.globalize_path(LOCK_FILE_PATH)
	
	# 检查锁文件是否存在
	if FileAccess.file_exists(LOCK_FILE_PATH):
		# 读取现有锁文件
		var existing_file = FileAccess.open(LOCK_FILE_PATH, FileAccess.READ)
		if existing_file:
			var stored_pid = existing_file.get_64()
			
			# 检查存储的进程是否仍在运行
			if _is_process_running(stored_pid):
				# 另一个实例正在运行，获取锁失败
				print("application_mutex: 检测到运行中的实例 (PID: %s)." % [stored_pid])
				_mutex.unlock()
				return false
			else:
				# 存储的进程已不存在，删除失效的锁文件
				print("application_mutex: 覆盖失效的锁文件(PID: %s)." % [stored_pid])
				DirAccess.remove_absolute(LOCK_FILE_PATH)
	
	# 创建新的锁文件
	_lock_file = FileAccess.open(LOCK_FILE_PATH, FileAccess.WRITE)
	if _lock_file:
		_lock_file.store_64(OS.get_process_id())
		_lock_file.flush()  # 确保写入磁盘
		success = true
		print("application_mutex: 创建锁文件成功(PID: %s)." % [OS.get_process_id()])
	else:
		print("application_mutex: 创建锁文件失败!")
	
	_mutex.unlock()
	return success

func _is_process_running(pid: int) -> bool:
	# 检查进程是否仍在运行（跨平台实现）
	var os_name = OS.get_name()
	
	# 如果是当前进程，认为正在运行
	if pid == OS.get_process_id():
		return true
	
	# 根据不同平台检查进程
	match os_name:
		"Windows":
			return _is_process_running_windows(pid)
		"macOS", "Linux", "FreeBSD", "NetBSD", "OpenBSD":
			return _is_process_running_unix(pid)
		"Android", "iOS":
			# 移动平台通常只能运行一个实例，假设进程不存在
			return false
		_:
			# 未知平台，保守处理：假设进程不存在
			print("application_mutex: 未知平台，无法检查进程状态")
			return false

func _is_process_running_windows(pid: int) -> bool:
	# Windows 使用 tasklist 命令检查进程
	var output = []
	var exit_code = OS.execute("tasklist", ["/FI", "PID eq " + str(pid), "/NH"], output)
	
	if exit_code == 0 and output.size() > 0:
		var output_text = output[0].to_lower()
		# 检查输出中是否包含 PID
		return str(pid) in output_text
	
	return false

func _is_process_running_unix(pid: int) -> bool:
	# Unix-like 系统使用 kill -0 检查进程
	var output = []
	var exit_code = OS.execute("kill", ["-0", str(pid)], output, true)
	
	# kill -0 返回 0 表示进程存在
	return exit_code == 0

func _handle_secondary_instance():
	# 发出信号
	emit_signal("another_instance_detected")
	
	# 等待一小段时间确保场景树已准备就绪
	await get_tree().process_frame
	
	# 显示警告对话框
	_show_warning_dialog()
	
	# 等待后退出
	await get_tree().create_timer(2.0).timeout
	get_tree().quit()

func _show_warning_dialog():
	# 创建警告对话框
	var dialog = AcceptDialog.new()
	GlobalLogger.tips_accept_dialog(self, "警告: 程序已运行!",
		"程序已经在运行中，此实例将自动关闭.", dialog, Callable(), dialog.queue_free)

func _exit_tree():
	# 清理锁文件
	_mutex.lock()
	if _lock_file:
		_lock_file = null  # 关闭文件
		
		# 只有主实例才删除锁文件
		if _is_primary_instance and FileAccess.file_exists(LOCK_FILE_PATH):
			# 验证锁文件是否属于当前进程
			var file = FileAccess.open(LOCK_FILE_PATH, FileAccess.READ)
			if file and file.get_64() == OS.get_process_id():
				DirAccess.remove_absolute(LOCK_FILE_PATH)
				print("application_mutex: 锁文件已删除.")
	_mutex.unlock()

# 公共方法：检查当前是否为主实例
func is_primary_instance() -> bool:
	return _is_primary_instance

# 公共方法：手动检查是否有其他实例运行
func check_other_instance() -> bool:
	return not _acquire_lock()

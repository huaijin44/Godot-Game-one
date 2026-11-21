extends CanvasLayer

@onready var btn_resume = $CenterContainer/VBoxContainer/Btn_Resume
@onready var btn_checkpoint = $CenterContainer/VBoxContainer/Btn_Checkpoint
@onready var btn_restart = $CenterContainer/VBoxContainer/Btn_Restart
@onready var btn_settings = $CenterContainer/VBoxContainer/Btn_Settings
@onready var btn_main_menu = $CenterContainer/VBoxContainer/Btn_MainMenu
@onready var btn_sound = $CenterContainer/VBoxContainer/Btn_Sound

func _ready() -> void:
	# 1. 默认隐藏菜单
	print("【测试】暂停菜单被加载了！")
	hide()
	
	# 2. 连接按钮信号
	btn_resume.pressed.connect(_on_resume_pressed)
	print("【测试】继续按钮的信号连接成功！")
	btn_checkpoint.pressed.connect(_on_checkpoint_pressed)
	btn_restart.pressed.connect(_on_restart_pressed)
	btn_settings.pressed.connect(_on_settings_pressed)
	btn_main_menu.pressed.connect(_on_main_menu_pressed)
	btn_sound.pressed.connect(_on_sound_pressed)
	
	# 初始化声音文字
	update_sound_state()

func _unhandled_input(event: InputEvent) -> void:
	# 监听 ESC 键（默认 ui_cancel）
	if event.is_action_pressed("cancel"):
		if visible:
			_on_resume_pressed() # 如果已经打开，按 ESC 就关闭
		else:
			open_menu()

func open_menu() -> void:
	show()
	get_tree().paused = true # 👈 暂停游戏

func close_menu() -> void:
	hide()
	get_tree().paused = false # 👈 恢复游戏

# --- 按钮功能实现 ---

func _on_resume_pressed() -> void:
	close_menu()

func _on_checkpoint_pressed() -> void:
	close_menu() # 先恢复游戏，再执行重生
	# 寻找场景里的玩家
	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_method("respawn"):
		player.respawn()

func _on_restart_pressed() -> void:
	close_menu()
	# 重置所有全局数据（包括检查点），然后重新加载关卡
	GameManager.reset_stats()
	SceneManager.goto_scene("Level")

func _on_settings_pressed() -> void:
	close_menu()
	# 注意：目前你的设置界面是独立场景，跳转会丢失暂停状态。
	# 最完美的做法是把设置做成弹窗，但眼下你可以直接跳过去：
	SceneManager.goto_scene("Settings")

func _on_main_menu_pressed() -> void:
	close_menu()
	SceneManager.goto_scene("MainMenu")

func _on_sound_pressed() -> void:
	var is_muted = AudioServer.is_bus_mute(0)
	AudioServer.set_bus_mute(0, not is_muted)
	update_sound_state()

func update_sound_state() -> void:
	if AudioServer.is_bus_mute(0):
		btn_sound.text = "声音：关"
	else:
		btn_sound.text = "声音：开"

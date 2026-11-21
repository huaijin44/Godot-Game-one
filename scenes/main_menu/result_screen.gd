extends Control

@onready var score_label = $VBoxContainer/ScoreLabel
@onready var btn_restart = $VBoxContainer/HBoxContainer/Btn_Restart
@onready var btn_next_level = $VBoxContainer/HBoxContainer/Btn_NextLevel
@onready var btn_main_menu = $VBoxContainer/HBoxContainer/Btn_MainMenu

func _ready() -> void:
	# 1. 显示收集到的金币
	score_label.text = "收集金币：" + str(GameManager.coins)
	
	# 2. 连接按钮
	btn_restart.pressed.connect(_on_restart_pressed)
	btn_main_menu.pressed.connect(_on_main_menu_pressed)
	
	# 3. 下一关判断（目前只有一关，先隐藏）
	# 以后如果你做了第二关，可以用变量判断是否解锁
	# 如果你以后想做，逻辑大概是：
	# btn_next_level.pressed.connect(_on_next_level_pressed)

func _on_restart_pressed() -> void:
	# 重新加载当前关卡
	SceneManager.goto_scene("Level")

func _on_main_menu_pressed() -> void:
	SceneManager.goto_scene("MainMenu")

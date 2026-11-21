extends Control

@onready var btn_level1 = $HBoxContainer/Btn_Level1
@onready var btn_back = $Btn_Back

func _ready() -> void:
	# 连接信号
	GameManager.reset_stats()
	btn_level1.pressed.connect(_on_level1_pressed)
	btn_back.pressed.connect(_on_back_pressed)
	for btn in [btn_level1, btn_back]:
		btn.mouse_entered.connect(func():
			btn.pivot_offset = btn.size / 2
			var t = create_tween()
			t.tween_property(btn, "scale", Vector2(1.1, 1.1), 0.1)
		)
		btn.mouse_exited.connect(func():
			var t = create_tween()
			t.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.1)
		)

func _on_level1_pressed() -> void:
	# 进入第一关
	# ⚠️ 注意：这里的 "Level" 必须和 SceneManager.gd 字典里的键名完全一致！
	SceneManager.goto_scene("Level")

func _on_back_pressed() -> void:
	# 返回主界面
	SceneManager.goto_scene("MainMenu")

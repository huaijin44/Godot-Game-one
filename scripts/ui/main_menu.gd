extends Control

# 👇 把 VBoxContainer 改成了 HBoxContainer
@onready var btn_levels = $HBoxContainer/Btn_levels
@onready var btn_settings = $HBoxContainer/Btn_Settings
@onready var btn_sound = $HBoxContainer/Btn_Sound
@onready var player_image = $PlayerImage

var is_sound_on: bool = true
var base_y: float # 记录初始的 Y 坐标

func _ready() -> void:
	btn_levels.pressed.connect(_on_levels_pressed)
	btn_settings.pressed.connect(_on_settings_pressed)
	btn_sound.pressed.connect(_on_sound_pressed)
	base_y = player_image.position.y
	
	var tween = create_tween()
	tween.set_loops() # 无限循环
	# 让主角在 1 秒内向上移动 20 像素，再花 1 秒回落
	tween.tween_property(player_image, "position:y", base_y - 20, 1.0).set_trans(Tween.TRANS_SINE)
	tween.tween_property(player_image, "position:y", base_y, 1.0).set_trans(Tween.TRANS_SINE)
	update_sound_state()
	for btn in $HBoxContainer.get_children():
		if btn is Button:
			# 鼠标移入
			btn.mouse_entered.connect(func():
				btn.pivot_offset = btn.size / 2 # 把中心点设在正中间，保证缩放不偏移
				var twee = create_tween()
				twee.tween_property(btn, "scale", Vector2(1.1, 1.1), 0.1) # 放大 1.1 倍
			)
			# 鼠标移出
			btn.mouse_exited.connect(func():
				var twee = create_tween()
				twee.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.1) # 恢复原样
			)

func _on_levels_pressed() -> void:
	SceneManager.goto_scene("LevelSelect")

func _on_settings_pressed() -> void:
	SceneManager.goto_scene("Settings")

func _on_sound_pressed() -> void:
	var is_muted = AudioServer.is_bus_mute(0)
	AudioServer.set_bus_mute(0, not is_muted)
	update_sound_state()

func update_sound_state() -> void:
	var is_muted = AudioServer.is_bus_mute(0)
	if is_muted:
		btn_sound.text = "声音：关"
	else:
		btn_sound.text = "声音：开"

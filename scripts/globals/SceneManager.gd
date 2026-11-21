extends Node

var transition_rect: ColorRect

# ⚠️ 必须把字典里的名字写对！如果文件叫 level.tscn，这里就写 level
const SCENES = {
	"MainMenu": "res://scenes/main_menu/main_menu.tscn",
	"Settings": "res://scenes/UI/settings_menu.tscn",
	"LevelSelect": "res://scenes/main_menu/level_select.tscn",
	"Level": "res://scenes/Levels/level.tscn" , # 这里改为你实际的场景路径！
	"Result":"res://scenes/main_menu/result_screen.tscn"
}

func _ready() -> void:
	transition_rect = ColorRect.new()
	transition_rect.color = Color.BLACK
	transition_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	transition_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var canvas = CanvasLayer.new()
	canvas.layer = 100 
	canvas.add_child(transition_rect)
	add_child(canvas)
	transition_rect.modulate.a = 0.0

func goto_scene(scene_name: String) -> void:
	# 1. 安全检查：如果字典里没这个名字，直接报错并返回，不黑屏
	if not SCENES.has(scene_name):
		printerr("跳转失败：字典里找不到名为 '", scene_name, "' 的场景，请检查拼写！")
		return
		
	var path = SCENES[scene_name]
	# 2. 安全检查：如果文件不存在，直接报错并返回，不黑屏
	if not ResourceLoader.exists(path):
		printerr("跳转失败：文件不存在 -> ", path)
		return
		
	# 3. 开始黑屏动画
	var tween = create_tween()
	tween.tween_property(transition_rect, "modulate:a", 1.0, 0.3)
	await tween.finished
	
	# 4. 切换场景
	get_tree().change_scene_to_file(path)
	
	# 5. 等待新场景加载完成（这里修复了一个常见的 Godot 异步坑）
	await get_tree().process_frame
	await get_tree().process_frame 
	
	# 6. 无论发生什么，一定要把屏幕变回透明！
	var tween2 = create_tween()
	tween2.tween_property(transition_rect, "modulate:a", 0.0, 0.3)

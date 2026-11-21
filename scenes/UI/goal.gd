extends Area2D

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if body.name == "player":
		# 停止玩家输入，播放胜利动画（可选）
		body.set_physics_process(false) 
		# 跳转到结算界面
		SceneManager.goto_scene("Result")

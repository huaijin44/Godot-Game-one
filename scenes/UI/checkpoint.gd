extends Area2D

var is_activated: bool = false
@onready var anim = $AnimatedSprite2D

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	anim.play("idle") # 初始状态：未激活

func _on_body_entered(body: Node2D) -> void:
	# 如果碰到的是玩家，且还没激活过
	if (body.name == "player" or body.is_in_group("player")) and not is_activated:
		is_activated = true
		
		# 1. 播放激活动画
		anim.play("activate") 
		
		# 2. 保存位置到全局，并回满血
		GameManager.save_checkpoint(global_position)
		
		# 3. 激活动画播完后，切换到常亮的已激活状态
		await anim.animation_finished
		anim.play("activated") 

extends Area2D

@export var knockback_force: Vector2 = Vector2(250, -150) # Y值减小了
@export var damage_amount: int = 1

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if body.name == "player" or body.is_in_group("player"):
		
		var final_knockback_x = 0.0
		var player_velocity_x = body.velocity.x
		
		# 1. 如果玩家有明显的水平移动（正在跑动中撞刺）
		if abs(player_velocity_x) > 10.0: 
			# 获取玩家速度方向 (1为向右，-1为向左)，然后取反
			var dir = sign(player_velocity_x)
			final_knockback_x = -dir * knockback_force.x
			
		# 2. 如果玩家是垂直掉下来碰到刺的（没跑动）
		else:
			# 根据玩家和刺的相对X坐标，决定往哪边弹
			var relative_x = sign(body.global_position.x - global_position.x)
			if relative_x == 0: relative_x = 1 # 防止正好在正中间
			final_knockback_x = relative_x * knockback_force.x
			
		var final_knockback = Vector2(final_knockback_x, knockback_force.y)
		
		# 调用玩家的受击函数
		if body.has_method("take_damage"):
			body.take_damage(final_knockback)

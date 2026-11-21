extends Path2D

@export var speed: float = 150.0 # 电锯移动速度
@export var chain_scroll_speed: float = 150.0 # 👈 新增：链条流动速度

var progress: float = 0.0
var max_length: float = 0.0
var direction: int = 1 

@onready var path_follow = $PathFollow2D
@onready var chain = $chainsprite

func _ready() -> void:
	# 获取当前轨迹的总长度
	max_length = curve.get_baked_length()
	
	# 👇 核心修改：把 Path2D 的曲线变成 Line2D 的点！
	# get_baked_points() 会获取曲线上所有的点
	chain.points = curve.get_baked_points()

	# 连接伤害信号
	$PathFollow2D/hazard.body_entered.connect(_on_body_entered)
	

func _physics_process(delta: float) -> void:
	# 1. 路径移动逻辑（保持你原来的代码不变）
	progress += speed * direction * delta
	path_follow.progress = progress
	
	# 边界检测（保持你原来的代码不变）
	if progress >= max_length:
		progress = max_length
		direction = -1
	elif progress <= 0:
		progress = 0
		direction = 1
		
	# 根据方向控制链条滚动
	var mat = $chainsprite.material as ShaderMaterial
	if mat:
		# 根据电锯是否向右移动调整正负方向
		var current_scroll = chain_scroll_speed if direction > 0 else -chain_scroll_speed
		mat.set_shader_parameter("scroll_speed", current_scroll)


# 删掉原来的 update_chain 函数
# func update_chain() -> void: ...

# 伤害判定（保持不变）
func _on_body_entered(body: Node2D) -> void:
	if body.name == "player" or body.is_in_group("player"):
		if body.has_method("take_damage"):
			var dir = (body.global_position - $PathFollow2D/hazard.global_position).normalized()
			if dir == Vector2.ZERO: dir = Vector2(1, -1).normalized()
			var final_knockback = Vector2(dir.x * 250, -300) 
			body.take_damage(final_knockback)

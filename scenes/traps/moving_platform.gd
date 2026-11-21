extends AnimatableBody2D

@export var move_offset: Vector2 = Vector2(0, -200) # 移动的相对距离（比如向上200像素）
@export var move_time: float = 2.0 # 单程移动时间
@export var wait_time: float = 1.0 # 到达终点后等待时间

@onready var start_position = position # 记录初始位置

func _ready() -> void:
	# 确保动画播放
	$AnimatedSprite2D.play()
	# 开启物理同步（极其重要！）
	sync_to_physics = true
	
	# 启动循环移动
	move_loop()

func move_loop() -> void:
	var tween = create_tween()
	
	# 1. 移动到目标位置
	tween.tween_property(self, "position", start_position + move_offset, move_time).set_trans(Tween.TRANS_SINE)
	# 2. 等待一下
	tween.tween_interval(wait_time)
	# 3. 移动回原位
	tween.tween_property(self, "position", start_position, move_time).set_trans(Tween.TRANS_SINE)
	# 4. 等待一下
	tween.tween_interval(wait_time)
	
	# 设置循环
	tween.set_loops()

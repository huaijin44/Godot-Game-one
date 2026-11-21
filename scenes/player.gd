extends CharacterBody2D

# ================= 常量与枚举 =================
enum State {
	SPAWN,
	IDLE,
	RUN,
	JUMP,
	DOUBLE_JUMP,
	FALL,
	WALL_SLIDE, # <--- 新增：滑墙状态
	WALL_JUMP,
	HURT,
	DEAD
}

# 当前状态
var current_state: State = State.IDLE

# ================= 导出变量（调整手感） =================
@export_group("基础移动参数")
@export var speed: float = 300.0
@export var gravity: float = 1200.0
@export var max_fall_speed: float = 800.0

@export_group("手感调节 (数值越高越干脆/无惯性)")
@export var ground_acceleration: float = 2500.0 # 地面加速度(起步有多快)
@export var ground_friction: float = 4000.0     # 地面摩擦力(松手急停有多快)
@export var air_acceleration: float = 1500.0    # 空中加速度(空中转向有多灵敏)
@export var air_friction: float = 1000.0        # 空中阻力(空中松手减速有多快)

@export_group("跳跃与滑墙参数")
@export var jump_velocity: float = -400.0
@export var double_jump_velocity: float = -350.0
@export var wall_jump_velocity: Vector2 = Vector2(350, -400) # 蹬墙跳推力
@export var wall_slide_speed: float = 150.0 # 滑墙时的最大下落速度

# ================= 状态标记 =================
var can_double_jump: bool = true 
var has_jumped: bool = false     
var is_invincible: bool = false    # 👈 新增：是否处于无敌状态
var invincible_timer: float = 0.0  # 👈 新增：无敌时间倒计时
var hurt_timer: float = 0.0      
var is_hurt: bool = false        

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	add_to_group("player")
	# 👇 核心逻辑：判断是不是第一次进关卡
	if not GameManager.has_checkpoint:
		# 第一次进，去找起点
		var spawn_points = get_tree().get_nodes_in_group("spawn_point")
		if spawn_points.size() > 0:
			global_position = spawn_points[0].global_position
			# 👇 找到了起点，直接把它变成我们的第一个默认检查点！
			# 注意：这里调用 save_checkpoint 会自动回满血，并设 has_checkpoint = true
			GameManager.save_checkpoint(global_position)
	else:
		# 如果不是第一次进（比如你以后做了跨场景传送），直接传送到记录点
		global_position = GameManager.current_checkpoint_pos

	# 初始化状态，播放出生动画
	switch_state(State.SPAWN)
	# 👇 相机运镜进阶
	var cam = $Camera2D
	cam.zoom = Vector2(5.0, 5.0) # 初始放大 1.5 倍（特写）
	
	var tween = create_tween()
	# 等待 0.2 秒，然后用 1 秒平滑拉远
	tween.tween_interval(0.2) 
	tween.tween_property(cam, "zoom", Vector2(3.0, 3.0), 3.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
	# 初始化状态，播放出生动画
	switch_state(State.SPAWN)

func _physics_process(delta: float) -> void:
			# 1. 统一处理重力
	if not is_on_floor() and current_state != State.WALL_JUMP:
		var current_gravity = gravity
		
		# 👇 核心修改：受击时的动态重力
		if current_state == State.HURT:
			if velocity.y < 0:
				current_gravity *= 1.0 # 上升阶段：正常重力（你想飞多高就调多高）
			else:
				current_gravity *= 2.0 # 下落阶段：超级重力，光速落地
				
		velocity.y += current_gravity * delta
		if velocity.y > max_fall_speed:
			velocity.y = max_fall_speed
		
		# 如果是滑墙状态，限制下落速度
		if current_state == State.WALL_SLIDE:
			velocity.y = min(velocity.y, wall_slide_speed)
		else:
			velocity.y = min(velocity.y, max_fall_speed)

	# 2. 根据当前状态执行对应的逻辑
	match current_state:
		State.SPAWN:
			state_spawn(delta)
		State.IDLE:
			state_idle(delta)
		State.RUN:
			state_run(delta)
		State.JUMP:
			state_jump(delta)
		State.DOUBLE_JUMP:
			state_double_jump(delta)
		State.FALL:
			state_fall(delta)
		State.WALL_SLIDE:
			state_wall_slide(delta)
		State.WALL_JUMP:
			state_wall_jump(delta)
		State.HURT:
			state_hurt(delta)
		State.DEAD:
			state_dead(delta)

	# 3. 实际移动
	move_and_slide()

	# 4. 全局落地检测
	# 👇 加上 != State.DEAD 和 != State.SPAWN，死人绝不能复活！
	if is_on_floor() and current_state != State.HURT and current_state != State.IDLE and current_state != State.RUN and current_state != State.DEAD and current_state != State.SPAWN:
		can_double_jump = true
		switch_state(State.IDLE if is_zero_approx(velocity.x) else State.RUN)


# ================= 状态切换控制 =================
func switch_state(new_state: State) -> void:
	if current_state == new_state:
		return
	if current_state == State.DEAD:
		return
	if current_state == State.HURT:
		is_hurt = false
		
	current_state = new_state
	
	match current_state:
		State.SPAWN:
			animated_sprite.play("spawn")
		State.IDLE:
			animated_sprite.play("idle")
		State.RUN:
			animated_sprite.play("run")
		State.JUMP:
			animated_sprite.play("jump")
			velocity.y = jump_velocity
			has_jumped = true
			can_double_jump = true 
		State.DOUBLE_JUMP:
			animated_sprite.play("double_jump")
			velocity.y = double_jump_velocity
			can_double_jump = false
		State.FALL:
			animated_sprite.play("fall")
		State.WALL_SLIDE: # <--- 新增滑墙动画
			animated_sprite.play("wall_slide")
			# 贴墙瞬间给一个小减速，手感更好
			velocity.y *= 0.5 
		State.WALL_JUMP:
			animated_sprite.play("wall_jump")
		State.HURT:
			animated_sprite.play("behit")
			is_hurt = true
			can_double_jump = true 
		State.DEAD:
			animated_sprite.play("death")
			death_timer = 0.0 # 👈 重置一下，防止下次死亡出bug


# ================= 具体状态逻辑 =================

func state_idle(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0, ground_friction * delta)
	var direction: float = Input.get_axis("move_left", "move_right")
	
	if direction != 0:
		animated_sprite.flip_h = (direction < 0)
		switch_state(State.RUN)
	elif Input.is_action_just_pressed("jump"):
		switch_state(State.JUMP)
	elif not is_on_floor():
		switch_state(State.FALL)


func state_run(delta: float) -> void:
	var direction: float = Input.get_axis("move_left", "move_right")
	
	if direction != 0:
		velocity.x = move_toward(velocity.x, direction * speed, ground_acceleration * delta)
		animated_sprite.flip_h = (direction < 0)
	else:
		switch_state(State.IDLE)
		
	if Input.is_action_just_pressed("jump"):
		switch_state(State.JUMP)
	elif not is_on_floor():
		switch_state(State.FALL)


func state_jump(delta: float) -> void:
	handle_air_control()
	
	if Input.is_action_just_released("jump") and velocity.y < 0:
		velocity.y *= 0.5
		
	if Input.is_action_just_pressed("jump") and can_double_jump:
		switch_state(State.DOUBLE_JUMP)
	# 注意：这里不再直接跳，而是检测是否进入滑墙
	elif is_on_wall() and velocity.y > 0: 
		switch_state(State.WALL_SLIDE)
	elif velocity.y >= 0:
		switch_state(State.FALL)


func state_double_jump(delta: float) -> void:
	handle_air_control()
	
	if velocity.y >= 0:
		switch_state(State.FALL)
	elif is_on_wall() and velocity.y > 0:
		switch_state(State.WALL_SLIDE)


func state_fall(delta: float) -> void:
	handle_air_control()
	
	if is_on_wall() and velocity.y > 0:
		# 碰到墙壁开始下滑
		switch_state(State.WALL_SLIDE)
	elif is_on_floor():
		switch_state(State.IDLE if is_zero_approx(velocity.x) else State.RUN)
	elif Input.is_action_just_pressed("jump") and can_double_jump:
		switch_state(State.DOUBLE_JUMP)


# --- 新增：滑墙状态 ---
func state_wall_slide(delta: float) -> void:
	var direction: float = Input.get_axis("move_left", "move_right")
	
	# 1. 朝向墙壁推，或者保持贴墙
	# 如果玩家松开方向键，可以选择掉下去，或者强制吸附。这里我们选择允许松开掉落
	if direction == 0:
		switch_state(State.FALL)
		return
		
	# 2. 蹬墙跳触发
	if Input.is_action_just_pressed("jump"):
		switch_state(State.WALL_JUMP)
		return
		
	# 3. 如果不再贴墙（比如掉出了墙的边缘），转为下落
	if not is_on_wall():
		switch_state(State.FALL)


# --- 蹬墙跳状态 ---
func state_wall_jump(delta: float) -> void:
	# 蹬墙瞬间，给一个反向推力（只在刚进入此状态时执行一次）
	if has_jumped:
		var wall_normal = get_wall_normal()
		# 沿墙壁法线方向弹开，加上向上的速度
		velocity.x = wall_normal.x * wall_jump_velocity.x
		velocity.y = wall_jump_velocity.y
		has_jumped = false
		
	# 蹬墙后短暂滞空，然后转回跳跃或下落状态
	if velocity.y >= 0:
		switch_state(State.FALL)
	elif not is_on_wall():
		# 离开墙壁后，如果还在上升，切回普通跳跃状态以便玩家控制
		switch_state(State.JUMP)


func state_hurt(delta: float) -> void:
	hurt_timer -= delta
	# 👇 改为使用 air_friction（空中阻力）减速，这样能滑行得更远
	velocity.x = move_toward(velocity.x, 0, air_friction * delta) 
	
	if hurt_timer <= 0 :
		switch_state(State.IDLE if is_on_floor() else State.FALL)


func state_spawn(delta: float) -> void:
	# 出场时锁定操作，只受重力影响，不处理任何输入
	if is_on_floor():
		velocity.x = move_toward(velocity.x, 0, ground_friction * delta)
	
	# 等待出场动画播放完毕（假设动画不循环）
	if animated_sprite.is_playing() == false:
		switch_state(State.IDLE)

var death_timer: float = 0.0

func state_dead(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0, ground_friction * delta)
	# 死亡状态只需要乖乖躺平，什么计时器、跳转都不需要了
	# 因为复活逻辑全权交由 take_damage 里的 await 处理了
	
# ================= 辅助函数 =================
func handle_air_control() -> void:
	var direction: float = Input.get_axis("move_left", "move_right")
	var delta = get_physics_process_delta_time()
	
	if direction != 0:
		velocity.x = move_toward(velocity.x, direction * speed, air_acceleration * delta)
		animated_sprite.flip_h = (direction < 0)
	else:
		velocity.x = move_toward(velocity.x, 0, air_friction * delta)

func take_damage(knockback_velocity: Vector2) -> void:
	# 👇 核心拦截：只要在无敌状态，直接免疫！
	if is_invincible or current_state == State.HURT or current_state == State.DEAD: 
		return
	# 1. 扣血
	GameManager.take_damage(1) 
	# 如果血量归零
	if GameManager.current_health <= 0:
		switch_state(State.DEAD)
		shake_camera(15.0, 0.4)
		
		# 等待死亡动画播放（给个 1 秒左右）
		await get_tree().create_timer(1.0).timeout 
		
		respawn() # 👈 调用复活函数，而不是跳转场景
		return
	# 2. 赋予击退速度
	velocity = knockback_velocity
	hurt_timer = 0.4  
	# 3. 强制脱离地面（防止卡刺）
	position.y -= 2 
	# 4. 切换受击状态
	switch_state(State.HURT)
	# 👇 开启 1.2 秒的无敌帧
	start_invincibility(1.2)
	# 5. 镜头抖动
	var camera = $Camera2D 
	if camera:
		var tween = create_tween()
		tween.tween_property(camera, "offset", Vector2(10, 5), 0.05)
		tween.tween_property(camera, "offset", Vector2(-10, -5), 0.05)
		tween.tween_property(camera, "offset", Vector2.ZERO, 0.05)
		
# 👇 新增函数：处理无敌时间与视觉闪烁
func start_invincibility(duration: float) -> void:
	is_invincible = true
	
	# 创建一个 Tween 专门用来做闪烁动画
	var blink_tween = create_tween()
	# 设置循环次数（比如 1.2 秒内，每 0.1 秒闪一次，大概闪 12 次）
	blink_tween.set_loops(int(duration / 0.1)) 
	
	# 让角色变成半透明，再变回不透明
	blink_tween.tween_property(animated_sprite, "modulate:a", 0.2, 0.05)
	blink_tween.tween_property(animated_sprite, "modulate:a", 1.0, 0.05)
	
	# 等待无敌时间结束
	await get_tree().create_timer(duration).timeout
	
	# 无敌结束，清理状态，强制恢复不透明
	is_invincible = false
	blink_tween.kill() # 停掉可能还在运行的闪烁
	animated_sprite.modulate.a = 1.0

# 通用的镜头抖动函数，可以自定义强度和持续时间
func shake_camera(intensity: float = 10.0, duration: float = 0.2) -> void:
	var camera = $Camera2D
	if not camera: return
	
	var tween = create_tween()
	# 抖动 3 次
	for i in range(3):
		var random_offset = Vector2(
			randf_range(-intensity, intensity), 
			randf_range(-intensity, intensity)
		)
		tween.tween_property(camera, "offset", random_offset, duration / 3.0)
	# 最后强制归位
	tween.tween_property(camera, "offset", Vector2.ZERO, duration / 3.0)

func respawn() -> void:
	# 既然必然有检查点，直接传送过去
	global_position = GameManager.current_checkpoint_pos
	GameManager.current_health = GameManager.max_health
	GameManager.health_changed.emit(GameManager.current_health, GameManager.max_health)
	
	# 重置状态并播放出生动画
	velocity = Vector2.ZERO
	
	# 强行把当前状态改掉，打破 switch_state 里的拦截！
	current_state = State.IDLE 
	
	switch_state(State.SPAWN)
	start_invincibility(1.0) 
	
	# 让相机瞬间归位（取消平滑），防止镜头飞行
	$Camera2D.reset_smoothing()

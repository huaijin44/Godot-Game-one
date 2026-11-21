extends Node

# 信号带上当前血量和最大血量
signal health_changed(current: int, max_health: int)
signal coins_changed(new_coins)

# 用半颗心作为单位。6 = 3颗满心，5 = 2满1半
var max_health: int = 6 
var current_health: int = 6
var coins: int = 0
var current_checkpoint_pos: Vector2 = Vector2.ZERO
var has_checkpoint: bool = false

# 扣血（传入1就是扣半颗心）
func take_damage(amount: int) -> void:
	current_health = max(0, current_health - amount)
	health_changed.emit(current_health, max_health)

# 回血
func heal(amount: int) -> void:
	current_health = min(max_health, current_health + amount)
	health_changed.emit(current_health, max_health)

# 增加血量上限并回满
func upgrade_max_health(extra: int) -> void:
	max_health += extra
	current_health = max_health
	health_changed.emit(current_health, max_health)

func save_checkpoint(pos: Vector2) -> void:
	current_checkpoint_pos = pos
	has_checkpoint = true
	current_health = max_health # 碰到检查点，回满血
	health_changed.emit(current_health, max_health)
	
# 重置数据（重新开始关卡时调用）
func reset_stats() -> void:
	max_health = 6
	current_health = 6
	coins = 0
	has_checkpoint = false # 只有重新开始游戏时，才清空检查点
	current_checkpoint_pos = Vector2.ZERO
	health_changed.emit(current_health, max_health)
	coins_changed.emit(coins)

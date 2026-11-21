extends CanvasLayer

@onready var health_container = $UIEoot/HUD/HeartContainer
@onready var coin_label = $UIEoot/HUD/CoinContainer/CoinLabel

# 预加载我们刚才做的心形场景
const HEART_SCENE = preload("res://scenes/UI/heart.tscn")

func _ready() -> void:
	# 连接 GameManager 的信号
	GameManager.health_changed.connect(update_health_ui)
	GameManager.coins_changed.connect(update_coin_ui)
	
	# 初始化时强行刷新一次 UI（防止初始状态不显示）
	update_health_ui(GameManager.current_health, GameManager.max_health)
	update_coin_ui(GameManager.coins)

# --- 动态生成并刷新心形 UI ---
func update_health_ui(current_health: int, max_health: int) -> void:
	# 1. 计算需要多少颗心（如果上限是奇数，向上取整，比如5半血=3颗心）
	var needed_hearts = ceili(max_health / 2.0) 
	
	# 2. 动态生成缺失的心（如果数量不够就补）
	while health_container.get_child_count() < needed_hearts:
		var new_heart = HEART_SCENE.instantiate()
		health_container.add_child(new_heart)
		
	# 3. 动态删除多余的心（如果上限减少了）
	while health_container.get_child_count() > needed_hearts:
		var last_heart = health_container.get_child(health_container.get_child_count() - 1)
		last_heart.queue_free()
		health_container.remove_child(last_heart)

	# 4. 遍历每一个心节点，计算它该显示什么状态
	for i in range(health_container.get_child_count()):
		var heart = health_container.get_child(i)
		
		# 算出当前这颗心对应的血量阈值
		# 第 0 颗心需要 2 点血才满，第 1 颗心需要 4 点血才满...
		var heart_full_value = (i + 1) * 2
		var heart_half_value = (i + 1) * 2 - 1
		
		if current_health >= heart_full_value:
			heart.set_state(2) # 满心
		elif current_health == heart_half_value:
			heart.set_state(1) # 半心
		else:
			heart.set_state(0) # 空心

# --- 刷新金币 UI ---
func update_coin_ui(new_coins: int) -> void:
	coin_label.text = "x " + str(new_coins)

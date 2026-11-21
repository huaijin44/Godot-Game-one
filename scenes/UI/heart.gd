extends TextureRect

# 预加载三张图片（请确保路径和你项目里图片的实际路径一致）
const TEX_FULL = preload("res://assets/ui/heart_full.png")
const TEX_HALF = preload("res://assets/ui/heart_half.png")
const TEX_EMPTY = preload("res://assets/ui/heart_empty.png")

# 外部调用这个函数来改变心的状态：2=满，1=半，0=空
func set_state(state: int) -> void:
	match state:
		2: texture = TEX_FULL
		1: texture = TEX_HALF
		0: texture = TEX_EMPTY

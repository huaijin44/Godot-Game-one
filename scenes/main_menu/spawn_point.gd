extends Node2D

@onready var anim = $AnimatedSprite2D

func _ready() -> void:
	add_to_group("spawn_point")
	anim.play("idle") 
	# 把关于 GameManager 的代码全部删掉！

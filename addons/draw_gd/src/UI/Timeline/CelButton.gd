tool
extends Control

var texture : TextureRect = null

var DrawGD : Node = null

func _enter_tree() -> void:
	var n : Node = get_parent()
	while n:
		if n.name == "DrawGDSingleton":
			DrawGD = n
			break
		n = n.get_parent()

	texture = get_node("MC/CelTexture")


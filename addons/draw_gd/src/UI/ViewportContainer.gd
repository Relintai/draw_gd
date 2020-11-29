tool
extends ViewportContainer

var DrawGD : Node = null

func _enter_tree():
	var n : Node = get_parent()
	while n:
		if n.name == "DrawGDSingleton":
			DrawGD = n
			break
		n = n.get_parent()

func _on_ViewportContainer_mouse_entered() -> void:
	DrawGD.has_focus = true


func _on_ViewportContainer_mouse_exited() -> void:
	DrawGD.has_focus = false

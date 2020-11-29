tool
extends ViewportContainer

var DrawGD : Node = null

func _on_ViewportContainer_mouse_entered() -> void:
	DrawGD.has_focus = true


func _on_ViewportContainer_mouse_exited() -> void:
	DrawGD.has_focus = false

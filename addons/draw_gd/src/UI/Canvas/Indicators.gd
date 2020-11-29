tool
extends Node2D

var DrawGD : Node = null

func _enter_tree():
	var n : Node = get_parent()
	while n:
		if n.name == "DrawGDSingleton":
			DrawGD = n
			break
		n = n.get_parent()

func _input(event : InputEvent) -> void:
	if DrawGD.has_focus and event is InputEventMouseMotion:
		update()


func _draw() -> void:
	# Draw rectangle to indicate the pixel currently being hovered on
	if DrawGD.has_focus and DrawGD.can_draw:
		DrawGD.tools.draw_indicator()

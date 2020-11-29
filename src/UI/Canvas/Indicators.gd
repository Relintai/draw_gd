extends Node2D


func _input(event : InputEvent) -> void:
	if DrawGD.has_focus and event is InputEventMouseMotion:
		update()


func _draw() -> void:
	# Draw rectangle to indicate the pixel currently being hovered on
	if DrawGD.has_focus and DrawGD.can_draw:
		Tools.draw_indicator()

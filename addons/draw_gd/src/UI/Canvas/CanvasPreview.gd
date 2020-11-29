tool
extends Node2D


var frame : int = 0
onready var animation_timer : Timer = $AnimationTimer

var DrawGD : Node = null

func _draw() -> void:
	var current_project : Project = DrawGD.current_project
	if frame >= current_project.frames.size():
		frame = current_project.current_frame

	$AnimationTimer.wait_time = DrawGD.animation_timer.wait_time

	if animation_timer.is_stopped():
		frame = current_project.current_frame
	var current_cels : Array = current_project.frames[frame].cels

	# Draw current frame layers
	for i in range(current_cels.size()):
		var modulate_color := Color(1, 1, 1, current_cels[i].opacity)
		if i < current_project.layers.size() and current_project.layers[i].visible:
			draw_texture(current_cels[i].image_texture, Vector2.ZERO, modulate_color)


func _on_AnimationTimer_timeout() -> void:
	var current_project : Project = DrawGD.current_project

	if frame < current_project.frames.size() - 1:
		frame += 1
	else:
		frame = 0
	update()

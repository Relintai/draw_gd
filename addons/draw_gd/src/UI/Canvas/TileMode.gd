tool
extends Node2D


var location := Vector2.ZERO

var DrawGD : Node = null

func _enter_tree():
	var n : Node = get_parent()
	while n:
		if n.name == "DrawGDSingleton":
			DrawGD = n
			break
		n = n.get_parent()

func _draw() -> void:
	var current_cels : Array = DrawGD.current_project.frames.cels
	var size : Vector2 = DrawGD.current_project.size
	var positions := [
		Vector2(location.x, location.y + size.y), # Down
		Vector2(location.x - size.x, location.y + size.y), # Down left
		Vector2(location.x - size.x, location.y), # Left
		location - size, # Up left
		Vector2(location.x, location.y - size.y), # Up
		Vector2(location.x + size.x, location.y - size.y), # Up right
		Vector2(location.x + size.x, location.y), # Right
		location + size # Down right
	]

	for pos in positions:
		# Draw a blank rectangle behind the textures
		# Mostly used to hide the grid if it goes outside the canvas boundaries
		draw_rect(Rect2(pos, size), DrawGD.default_clear_color)

	for i in range(DrawGD.current_project.layers.size()):
		var modulate_color := Color(1, 1, 1, current_cels[i].opacity)
		if DrawGD.current_project.layers[i].visible: # if it's visible
			if DrawGD.tile_mode:
				for pos in positions:
					draw_texture(current_cels[i].image_texture, pos, modulate_color)

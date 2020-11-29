tool
extends Node2D


var location := Vector2.ZERO
var isometric_polylines := [] # An array of PoolVector2Arrays

var DrawGD : Node = null

func _enter_tree():
	var n : Node = get_parent()
	while n:
		if n.name == "DrawGDSingleton":
			DrawGD = n
			break
		n = n.get_parent()

func _draw() -> void:
	if DrawGD.draw_grid:
		draw_grid(DrawGD.grid_type)


func draw_grid(grid_type : int) -> void:
	var size : Vector2 = DrawGD.current_project.size
	if grid_type == DrawGD.Grid_Types.CARTESIAN || grid_type == DrawGD.Grid_Types.ALL:
		for x in range(DrawGD.grid_width, size.x, DrawGD.grid_width):
			draw_line(Vector2(x, location.y), Vector2(x, size.y), DrawGD.grid_color, true)

		for y in range(DrawGD.grid_height, size.y, DrawGD.grid_height):
			draw_line(Vector2(location.x, y), Vector2(size.x, y), DrawGD.grid_color, true)

	if grid_type == DrawGD.Grid_Types.ISOMETRIC || grid_type == DrawGD.Grid_Types.ALL:
		var i := 0
		for x in range(DrawGD.grid_isometric_cell_size, size.x + 2, DrawGD.grid_isometric_cell_size * 2):
			for y in range(0, size.y + 1, DrawGD.grid_isometric_cell_size):
				draw_isometric_tile(i, Vector2(x, y))
				i += 1


func draw_isometric_tile(i : int, origin := Vector2.RIGHT, cell_size : int = DrawGD.grid_isometric_cell_size) -> void:
	# A random value I found by trial and error, I have no idea why it "works"
	var diff = 1.11754
	var approx_30_degrees = deg2rad(26.565)

	var pool := PoolVector2Array()
	if i < isometric_polylines.size():
		pool = isometric_polylines[i]
	else:
		var a = origin - Vector2(0, 0.5)
		var b = a + Vector2(cos(approx_30_degrees), sin(approx_30_degrees)) * cell_size * diff
		var c = a + Vector2.DOWN * cell_size
		var d = c - Vector2(cos(approx_30_degrees), sin(approx_30_degrees)) * cell_size * diff
		pool.append(a)
		pool.append(b)
		pool.append(c)
		pool.append(d)
		pool.append(a)
		isometric_polylines.append(pool)

	if pool.size() > 2:
		draw_polyline(pool, DrawGD.grid_color)

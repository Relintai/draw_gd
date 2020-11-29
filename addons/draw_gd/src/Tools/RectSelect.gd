tool
extends "res://addons/draw_gd/src/Tools/Base.gd"


var _start := Rect2(0, 0, 0, 0)
var _offset := Vector2.ZERO
var _drag := false
var _move := false


func draw_start(position : Vector2) -> void:
	if DrawGD.selection_rectangle.has_point(position):
		_move = true
		_offset = position
		DrawGD.selection_rectangle.move_start(DrawGD.tools.shift)
		_set_cursor_text(DrawGD.selection_rectangle.get_rect())
	else:
		_drag = true
		_start = Rect2(position, Vector2.ZERO)
		DrawGD.selection_rectangle.set_rect(_start)


func draw_move(position : Vector2) -> void:
	if _move:
		DrawGD.selection_rectangle.move_rect(position - _offset)
		_offset = position
		_set_cursor_text(DrawGD.selection_rectangle.get_rect())
	else:
		var rect := _start.expand(position).abs()
		rect = rect.grow_individual(0, 0, 1, 1)
		DrawGD.selection_rectangle.set_rect(rect)
		_set_cursor_text(rect)


func draw_end(_position : Vector2) -> void:
	if _move:
		DrawGD.selection_rectangle.move_end()
	else:
		DrawGD.selection_rectangle.select_rect()
	_drag = false
	_move = false
	cursor_text = ""


func cursor_move(position : Vector2) -> void:
	if _drag:
		_cursor = Vector2.INF
	elif DrawGD.selection_rectangle.has_point(position):
		_cursor = Vector2.INF
		DrawGD.main_viewport.mouse_default_cursor_shape = Input.CURSOR_MOVE
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	else:
		_cursor = position
		DrawGD.main_viewport.mouse_default_cursor_shape = Input.CURSOR_CROSS


func _set_cursor_text(rect : Rect2) -> void:
	cursor_text = "%s, %s" % [rect.position.x, rect.position.y]
	cursor_text += " -> %s, %s" % [rect.end.x - 1, rect.end.y - 1]
	cursor_text += " (%s, %s)" % [rect.size.x, rect.size.y]

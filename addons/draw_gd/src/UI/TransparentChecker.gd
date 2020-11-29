tool
extends ColorRect

var DrawGD : Node = null

func _ready() -> void:
	rect_size = DrawGD.current_project.size
	if get_parent().get_parent() == DrawGD.main_viewport:
		DrawGD.second_viewport.get_node("Viewport/TransparentChecker")._ready()
		DrawGD.small_preview_viewport.get_node("Viewport/TransparentChecker")._ready()
	material.set_shader_param("size", DrawGD.checker_size)
	material.set_shader_param("color1", DrawGD.checker_color_1)
	material.set_shader_param("color2", DrawGD.checker_color_2)
	material.set_shader_param("follow_movement", DrawGD.checker_follow_movement)
	material.set_shader_param("follow_scale", DrawGD.checker_follow_scale)


func update_offset(offset : Vector2, scale : Vector2) -> void:
	material.set_shader_param("offset", offset)
	material.set_shader_param("scale", scale)


func _on_TransparentChecker_resized():
	material.set_shader_param("rect_size", rect_size)

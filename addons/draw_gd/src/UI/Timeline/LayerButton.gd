tool
class_name LayerButton
extends Button

var i := 0
var visibility_button : BaseButton
var lock_button : BaseButton
var linked_button : BaseButton
var label : Label
var line_edit : LineEdit

var DrawGD : Node = null

func _ready() -> void:
	var n : Node = get_parent()
	while n:
		if n.name == "DrawGDSingleton":
			DrawGD = n
			break
		n = n.get_parent()
		
	visibility_button = DrawGD.find_node_by_name(self, "VisibilityButton")
	lock_button = DrawGD.find_node_by_name(self, "LockButton")
	linked_button = DrawGD.find_node_by_name(self, "LinkButton")
	label = DrawGD.find_node_by_name(self, "Label")
	line_edit = DrawGD.find_node_by_name(self, "LineEdit")

	if DrawGD.current_project.layers[i].visible:
		DrawGD.change_button_texturerect(visibility_button.get_child(0), "layer_visible.png")
		visibility_button.get_child(0).rect_size = Vector2(24, 14)
		visibility_button.get_child(0).rect_position = Vector2(4, 9)
	else:
		DrawGD.change_button_texturerect(visibility_button.get_child(0), "layer_invisible.png")
		visibility_button.get_child(0).rect_size = Vector2(24, 8)
		visibility_button.get_child(0).rect_position = Vector2(4, 12)

	if DrawGD.current_project.layers[i].locked:
		DrawGD.change_button_texturerect(lock_button.get_child(0), "lock.png")
	else:
		DrawGD.change_button_texturerect(lock_button.get_child(0), "unlock.png")

	if DrawGD.current_project.layers[i].new_cels_linked: # If new layers will be linked
		DrawGD.change_button_texturerect(linked_button.get_child(0), "linked_layer.png")
	else:
		DrawGD.change_button_texturerect(linked_button.get_child(0), "unlinked_layer.png")


func _input(event : InputEvent) -> void:
	if (event.is_action_released("ui_accept") or event.is_action_released("ui_cancel")) and line_edit.visible and event.scancode != KEY_SPACE:
		save_layer_name(line_edit.text)


func _on_LayerContainer_pressed() -> void:
	pressed = !pressed
	label.visible = false
	line_edit.visible = true
	line_edit.editable = true
	line_edit.grab_focus()


func _on_LineEdit_focus_exited() -> void:
	save_layer_name(line_edit.text)


func save_layer_name(new_name : String) -> void:
	label.visible = true
	line_edit.visible = false
	line_edit.editable = false
	label.text = new_name
	DrawGD.layers_changed_skip = true
	DrawGD.current_project.layers[i].name = new_name


func _on_VisibilityButton_pressed() -> void:
	DrawGD.current_project.layers[i].visible = !DrawGD.current_project.layers[i].visible
	DrawGD.canvas.update()


func _on_LockButton_pressed() -> void:
	DrawGD.current_project.layers[i].locked = !DrawGD.current_project.layers[i].locked


func _on_LinkButton_pressed() -> void:
	DrawGD.current_project.layers[i].new_cels_linked = !DrawGD.current_project.layers[i].new_cels_linked
	if DrawGD.current_project.layers[i].new_cels_linked && !DrawGD.current_project.layers[i].linked_cels:
		# If button is pressed and there are no linked cels in the layer
		DrawGD.current_project.layers[i].linked_cels.append(DrawGD.current_project.frames[DrawGD.current_project.current_frame])
		DrawGD.current_project.layers[i].frame_container.get_child(DrawGD.current_project.current_frame)._ready()

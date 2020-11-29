tool
extends VBoxContainer


var left_picker : ColorPickerButton = null
var right_picker : ColorPickerButton = null

var DrawGD : Node = null

func _enter_tree() -> void:
	var n : Node = get_parent()
	while n:
		if n.name == "DrawGDSingleton":
			DrawGD = n
			break
		n = n.get_parent()
	
	DrawGD.tools.connect("color_changed", self, "update_color")
	
	left_picker = get_node("ColorButtonsVertical/ColorPickersCenter/ColorPickersHorizontal/LeftColorPickerButton")
	right_picker = get_node("ColorButtonsVertical/ColorPickersCenter/ColorPickersHorizontal/RightColorPickerButton")
	
	left_picker.get_picker().presets_visible = false
	right_picker.get_picker().presets_visible = false


func _on_ColorSwitch_pressed() -> void:
	DrawGD.tools.swap_color()


func _on_ColorPickerButton_color_changed(color : Color, right : bool):
	var button := BUTTON_RIGHT if right else BUTTON_LEFT
	DrawGD.tools.assign_color(color, button)


func _on_ColorPickerButton_pressed() -> void:
	DrawGD.can_draw = false


func _on_ColorPickerButton_popup_closed() -> void:
	DrawGD.can_draw = true


func _on_ColorDefaults_pressed() -> void:
	DrawGD.tools.default_color()


func update_color(color : Color, button : int) -> void:
	if button == BUTTON_LEFT:
		left_picker.color = color
	else:
		right_picker.color = color

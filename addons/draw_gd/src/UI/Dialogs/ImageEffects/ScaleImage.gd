tool
extends ConfirmationDialog

var DrawGD : Node = null

var DrawingAlgos = preload("res://addons/draw_gd/src/Autoload/DrawingAlgos.gd")

func _enter_tree():
	var n : Node = get_parent()
	while n:
		if n.name == "DrawGDSingleton":
			DrawGD = n
			break
		n = n.get_parent()

func _on_ScaleImage_confirmed() -> void:
	var width : int = $VBoxContainer/OptionsContainer/WidthValue.value
	var height : int = $VBoxContainer/OptionsContainer/HeightValue.value
	var interpolation : int = $VBoxContainer/OptionsContainer/InterpolationType.selected
	DrawingAlgos.scale_image(DrawGD, width, height, interpolation)


func _on_ScaleImage_popup_hide() -> void:
	DrawGD.dialog_open(false)

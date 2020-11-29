extends ConfirmationDialog

var DrawingAlgos = preload("res://src/Autoload/DrawingAlgos.gd")

func _on_ScaleImage_confirmed() -> void:
	var width : int = $VBoxContainer/OptionsContainer/WidthValue.value
	var height : int = $VBoxContainer/OptionsContainer/HeightValue.value
	var interpolation : int = $VBoxContainer/OptionsContainer/InterpolationType.selected
	DrawingAlgos.scale_image(width, height, interpolation)


func _on_ScaleImage_popup_hide() -> void:
	DrawGD.dialog_open(false)

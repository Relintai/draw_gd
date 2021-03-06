tool
extends ImageEffect

var DrawingAlgos = preload("res://addons/draw_gd/src/Autoload/DrawingAlgos.gd")

var red := true
var green := true
var blue := true
var alpha := false


func set_nodes() -> void:
	preview = $VBoxContainer/Preview
	selection_checkbox = $VBoxContainer/OptionsContainer/SelectionCheckBox
	affect_option_button = $VBoxContainer/OptionsContainer/AffectOptionButton


func commit_action(_cel : Image, _pixels : Array, _project : Project = DrawGD.current_project) -> void:
	DrawingAlgos.invert_image_colors(_cel, _pixels, red, green, blue, alpha)


func _on_RButton_toggled(button_pressed : bool) -> void:
	red = button_pressed
	update_preview()


func _on_GButton_toggled(button_pressed : bool) -> void:
	green = button_pressed
	update_preview()


func _on_BButton_toggled(button_pressed : bool) -> void:
	blue = button_pressed
	update_preview()


func _on_AButton_toggled(button_pressed : bool) -> void:
	alpha = button_pressed
	update_preview()

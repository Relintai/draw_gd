tool
extends ConfirmationDialog

var DrawingAlgos = preload("res://addons/draw_gd/src/Autoload/DrawingAlgos.gd")

var width := 64
var height := 64
var offset_x := 0
var offset_y := 0
var image : Image
var first_time := true

onready var width_spinbox : SpinBox = $VBoxContainer/OptionsContainer/WidthValue
onready var height_spinbox : SpinBox = $VBoxContainer/OptionsContainer/HeightValue
onready var x_spinbox : SpinBox = $VBoxContainer/OptionsContainer/XSpinBox
onready var y_spinbox : SpinBox = $VBoxContainer/OptionsContainer/YSpinBox
onready var preview_rect : TextureRect = $VBoxContainer/Preview

var DrawGD : Node = null

func _enter_tree() -> void:
	var n : Node = get_parent()
	while n:
		if n.name == "DrawGDSingleton":
			DrawGD = n
			break
		n = n.get_parent()

func _on_ResizeCanvas_about_to_show() -> void:
	if first_time:
		width_spinbox.value = DrawGD.current_project.size.x
		height_spinbox.value = DrawGD.current_project.size.y

	image = Image.new()
	image.create(DrawGD.current_project.size.x, DrawGD.current_project.size.y, false, Image.FORMAT_RGBA8)
	image.lock()
	var layer_i := 0
	for cel in DrawGD.current_project.frames.cels:
		if DrawGD.current_project.layers[layer_i].visible:
			var cel_image := Image.new()
			cel_image.copy_from(cel.image)
			cel_image.lock()
			if cel.opacity < 1: # If we have cel transparency
				for xx in cel_image.get_size().x:
					for yy in cel_image.get_size().y:
						var pixel_color := cel_image.get_pixel(xx, yy)
						var alpha : float = pixel_color.a * cel.opacity
						cel_image.set_pixel(xx, yy, Color(pixel_color.r, pixel_color.g, pixel_color.b, alpha))
			image.blend_rect(cel_image, Rect2(DrawGD.canvas.location, DrawGD.current_project.size), Vector2.ZERO)
		layer_i += 1
	image.unlock()

	update_preview()


func _on_ResizeCanvas_confirmed() -> void:
	DrawingAlgos.resize_canvas(DrawGD, width, height, offset_x, offset_y)
	first_time = false


func _on_WidthValue_value_changed(value : int) -> void:
	width = value
	x_spinbox.min_value = min(width - DrawGD.current_project.size.x, 0)
	x_spinbox.max_value = max(width - DrawGD.current_project.size.x, 0)
	x_spinbox.value = clamp(x_spinbox.value, x_spinbox.min_value, x_spinbox.max_value)
	update_preview()


func _on_HeightValue_value_changed(value : int) -> void:
	height = value
	y_spinbox.min_value = min(height - DrawGD.current_project.size.y, 0)
	y_spinbox.max_value = max(height - DrawGD.current_project.size.y, 0)
	y_spinbox.value = clamp(y_spinbox.value, y_spinbox.min_value, y_spinbox.max_value)
	update_preview()


func _on_XSpinBox_value_changed(value : int) -> void:
	offset_x = value
	update_preview()


func _on_YSpinBox_value_changed(value : int) -> void:
	offset_y = value
	update_preview()


func _on_CenterButton_pressed() -> void:
	x_spinbox.value = (x_spinbox.min_value + x_spinbox.max_value) / 2
	y_spinbox.value = (y_spinbox.min_value + y_spinbox.max_value) / 2


func update_preview() -> void:
	# preview_image is the same as image but offsetted
	var preview_image := Image.new()
	preview_image.create(width, height, false, Image.FORMAT_RGBA8)
	preview_image.blend_rect(image, Rect2(Vector2.ZERO, DrawGD.current_project.size), Vector2(offset_x, offset_y))
	var preview_texture := ImageTexture.new()
	preview_texture.create_from_image(preview_image, 0)
	preview_rect.texture = preview_texture
	update_transparent_background_size(preview_image)


func update_transparent_background_size(preview_image : Image) -> void:
	var image_size_y = preview_rect.rect_size.y
	var image_size_x = preview_rect.rect_size.x
	if preview_image.get_size().x > preview_image.get_size().y:
		var scale_ratio = preview_image.get_size().x / image_size_x
		image_size_y = preview_image.get_size().y / scale_ratio
	else:
		var scale_ratio = preview_image.get_size().y / image_size_y
		image_size_x = preview_image.get_size().x / scale_ratio

	preview_rect.get_node("TransparentChecker").rect_size.x = image_size_x
	preview_rect.get_node("TransparentChecker").rect_size.y = image_size_y


func _on_ResizeCanvas_popup_hide() -> void:
	DrawGD.dialog_open(false)

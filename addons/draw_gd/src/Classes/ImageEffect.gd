tool
class_name ImageEffect extends AcceptDialog
# Parent class for all image effects
# Methods that have "pass" are meant to be replaced by the inherited Scripts

var Export = preload("res://addons/draw_gd/src/Autoload/Export.gd")

enum {CEL, FRAME, ALL_FRAMES, ALL_PROJECTS}

var affect : int = CEL
var pixels := []
var current_cel : Image
var current_frame : Image
var preview_image : Image
var preview_texture : ImageTexture
var preview : TextureRect
var selection_checkbox : CheckBox
var affect_option_button : OptionButton

var DrawGD : Node = null

func _enter_tree() -> void:
	var n : Node = get_parent()
	while n:
		if n.name == "DrawGDSingleton":
			DrawGD = n
			break
		n = n.get_parent()
	
	set_nodes()
	current_cel = Image.new()
	current_frame = Image.new()
	current_frame.create(DrawGD.current_project.size.x, DrawGD.current_project.size.y, false, Image.FORMAT_RGBA8)
	preview_image = Image.new()
	preview_texture = ImageTexture.new()
	connect("about_to_show", self, "_about_to_show")
	connect("popup_hide", self, "_popup_hide")
	connect("confirmed", self, "_confirmed")
	if selection_checkbox:
		selection_checkbox.connect("toggled", self, "_on_SelectionCheckBox_toggled")
	if affect_option_button:
		affect_option_button.connect("item_selected", self, "_on_AffectOptionButton_item_selected")


func _about_to_show() -> void:
	current_cel = DrawGD.current_project.frames[DrawGD.current_project.current_frame].cels[DrawGD.current_project.current_layer].image
	current_frame.fill(Color(0, 0, 0, 0))
	var frame = DrawGD.current_project.frames[DrawGD.current_project.current_frame]
	Export.blend_layers(current_frame, frame)
	if selection_checkbox:
		_on_SelectionCheckBox_toggled(selection_checkbox.pressed)
	else:
		update_preview()
	update_transparent_background_size()


func _confirmed() -> void:
	if affect == CEL:
		DrawGD.canvas.handle_undo("Draw")
		commit_action(current_cel, pixels)
		DrawGD.canvas.handle_redo("Draw")
	elif affect == FRAME:
		DrawGD.canvas.handle_undo("Draw", DrawGD.current_project, -1)
		for cel in DrawGD.current_project.frames[DrawGD.current_project.current_frame].cels:
			commit_action(cel.image, pixels)
		DrawGD.canvas.handle_redo("Draw", DrawGD.current_project, -1)

	elif affect == ALL_FRAMES:
		DrawGD.canvas.handle_undo("Draw", DrawGD.current_project, -1, -1)
		for frame in DrawGD.current_project.frames:
			for cel in frame.cels:
				commit_action(cel.image, pixels)
		DrawGD.canvas.handle_redo("Draw", DrawGD.current_project, -1, -1)

	elif affect == ALL_PROJECTS:
		for project in DrawGD.projects:
			var _pixels := []
			if selection_checkbox.pressed:
				_pixels = project.selected_pixels.duplicate()
			else:
				for x in project.size.x:
					for y in project.size.y:
						_pixels.append(Vector2(x, y))

			DrawGD.canvas.handle_undo("Draw", project, -1, -1)
			for frame in project.frames:
				for cel in frame.cels:
					commit_action(cel.image, _pixels, project)
			DrawGD.canvas.handle_redo("Draw", project, -1, -1)


func commit_action(_cel : Image, _pixels : Array, _project : Project = DrawGD.current_project) -> void:
	pass


func set_nodes() -> void:
	pass


func _on_SelectionCheckBox_toggled(button_pressed : bool) -> void:
	pixels.clear()
	if button_pressed:
		pixels = DrawGD.current_project.selected_pixels.duplicate()
	else:
		for x in DrawGD.current_project.size.x:
			for y in DrawGD.current_project.size.y:
				pixels.append(Vector2(x, y))

	update_preview()


func _on_AffectOptionButton_item_selected(index : int) -> void:
	affect = index
	update_preview()


func update_preview() -> void:
	match affect:
		CEL:
			preview_image.copy_from(current_cel)
		_:
			preview_image.copy_from(current_frame)
	commit_action(preview_image, pixels)
	preview_texture.create_from_image(preview_image, 0)
	preview.texture = preview_texture


func update_transparent_background_size() -> void:
	if !preview:
		return
	var image_size_y = preview.rect_size.y
	var image_size_x = preview.rect_size.x
	if preview_image.get_size().x > preview_image.get_size().y:
		var scale_ratio = preview_image.get_size().x / image_size_x
		image_size_y = preview_image.get_size().y / scale_ratio
	else:
		var scale_ratio = preview_image.get_size().y / image_size_y
		image_size_x = preview_image.get_size().x / scale_ratio

	preview.get_node("TransparentChecker").rect_size.x = image_size_x
	preview.get_node("TransparentChecker").rect_size.y = image_size_y


func _popup_hide() -> void:
	DrawGD.dialog_open(false)

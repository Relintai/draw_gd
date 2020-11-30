tool
class_name Project extends Reference
# A class for project properties.

var export_script = preload("res://addons/draw_gd/src/Autoload/Export.gd")
var Export = export_script.new()

var DrawGD : Node = null

var name := "" setget name_changed
var size : Vector2 setget size_changed
var undo_redo : UndoRedo
var undos := 0 # The number of times we added undo properties
var has_changed := false setget has_changed_changed
var frames = null
var layers := [] setget layers_changed # Array of Layers
var current_layer := 0 setget layer_changed
var guides := [] # Array of Guides

var brushes := [] # Array of Images

var x_symmetry_point
var y_symmetry_point
var x_symmetry_axis : SymmetryGuide
var y_symmetry_axis : SymmetryGuide

var selected_pixels := []
var selected_rect := Rect2(0, 0, 0, 0) setget _set_selected_rect

# For every camera (currently there are 3)
var cameras_zoom := [Vector2(0.15, 0.15), Vector2(0.15, 0.15), Vector2(0.15, 0.15)] # Array of Vector2
var cameras_offset := [Vector2.ZERO, Vector2.ZERO, Vector2.ZERO] # Array of Vector2

# Export directory path and export file name
var directory_path := ""
var file_name := "untitled"
var file_format : int = Export.FileFormat.PNG


func _init(pDrawGD, _frames = null, _name := tr("untitled"), _size := Vector2(64, 64)) -> void:
	if !_frames:
		frames = Frame.new()
	else:
		frames = _frames
		
	name = _name
	size = _size
	select_all_pixels()

	undo_redo = UndoRedo.new()

	DrawGD = pDrawGD
	DrawGD.tabs.add_tab(name)
	DrawGD.opensave.current_save_paths.append("")
	DrawGD.opensave.backup_save_paths.append("")

	x_symmetry_point = size.x / 2
	y_symmetry_point = size.y / 2

	if !x_symmetry_axis:
		x_symmetry_axis = SymmetryGuide.new()
		x_symmetry_axis.type = x_symmetry_axis.Types.HORIZONTAL
		x_symmetry_axis.project = self
		x_symmetry_axis.add_point(Vector2(-19999, y_symmetry_point))
		x_symmetry_axis.add_point(Vector2(19999, y_symmetry_point))
		DrawGD.canvas.add_child(x_symmetry_axis)

	if !y_symmetry_axis:
		y_symmetry_axis = SymmetryGuide.new()
		y_symmetry_axis.type = y_symmetry_axis.Types.VERTICAL
		y_symmetry_axis.project = self
		y_symmetry_axis.add_point(Vector2(x_symmetry_point, -19999))
		y_symmetry_axis.add_point(Vector2(x_symmetry_point, 19999))
		DrawGD.canvas.add_child(y_symmetry_axis)

	if OS.get_name() == "HTML5":
		directory_path = "user://"
	else:
		directory_path = OS.get_system_dir(OS.SYSTEM_DIR_DESKTOP)


func select_all_pixels() -> void:
	clear_selection()
	for x in size.x:
		for y in size.y:
			selected_pixels.append(Vector2(x, y))


func clear_selection() -> void:
	selected_pixels.clear()


func _set_selected_rect(value : Rect2) -> void:
	selected_rect = value
	DrawGD.selection_rectangle.set_rect(value)


func change_project() -> void:
	# Remove old nodes
	for container in DrawGD.layers_container.get_children():
		container.queue_free()

	# Create new ones
	for i in range(layers.size() - 1, -1, -1):
		# Create layer buttons
		var layer_container = load("res://addons/draw_gd/src/UI/Timeline/LayerButton.tscn").instance()
		layer_container.i = i
		if layers[i].name == tr("Layer") + " 0":
			layers[i].name = tr("Layer") + " %s" % i

		DrawGD.layers_container.add_child(layer_container)
		layer_container.label.text = layers[i].name
		layer_container.line_edit.text = layers[i].name
		
		if frames && frames.cels.size() > 0:
			layer_container.cel_button.texture = frames.cels[0].image_texture

	var layer_button = DrawGD.layers_container.get_child(DrawGD.layers_container.get_child_count() - 1 - current_layer)
	layer_button.pressed = true

	toggle_layer_buttons_layers()
	toggle_layer_buttons_current_layer()

	# Change the selection rectangle
	DrawGD.selection_rectangle.set_rect(selected_rect)

	# Change the guides
	for guide in DrawGD.canvas.get_children():
		if guide is Guide:
			if guide in guides:
				guide.visible = DrawGD.show_guides
				if guide is SymmetryGuide:
					if guide.type == Guide.Types.HORIZONTAL:
						guide.visible = DrawGD.show_x_symmetry_axis and DrawGD.show_guides
					else:
						guide.visible = DrawGD.show_y_symmetry_axis and DrawGD.show_guides
			else:
				guide.visible = false

	# Change the project brushes
	Brushes.clear_project_brush(DrawGD)
	for brush in brushes:
		Brushes.add_project_brush(DrawGD, brush)

	var cameras = [DrawGD.camera, DrawGD.camera2, DrawGD.camera_preview]
	var i := 0
	for camera in cameras:
		camera.zoom = cameras_zoom[i]
		camera.offset = cameras_offset[i]
		i += 1
	DrawGD.zoom_level_label.text = str(round(100 / DrawGD.camera.zoom.x)) + " %"
	DrawGD.canvas.update()
	DrawGD.canvas.grid.isometric_polylines.clear()
	DrawGD.canvas.grid.update()
	DrawGD.transparent_checker._ready()
	DrawGD.horizontal_ruler.update()
	DrawGD.vertical_ruler.update()
	DrawGD.preview_zoom_slider.value = -DrawGD.camera_preview.zoom.x
	DrawGD.cursor_position_label.text = "[%s×%s]" % [size.x, size.y]

	DrawGD.window_title = "%s - Pixelorama %s" % [name, DrawGD.current_version]
	if has_changed:
		DrawGD.window_title = DrawGD.window_title + "(*)"

	var save_path = DrawGD.opensave.current_save_paths[DrawGD.current_project_index]
	if save_path != "":
		DrawGD.open_sprites_dialog.current_path = save_path
		DrawGD.save_sprites_dialog.current_path = save_path
		DrawGD.file_menu.get_popup().set_item_text(3, tr("Save") + " %s" % save_path.get_file())
	else:
		DrawGD.file_menu.get_popup().set_item_text(3, tr("Save"))

	Export.directory_path = directory_path
	Export.file_name = file_name
	Export.file_format = file_format

	if directory_path.empty():
		DrawGD.file_menu.get_popup().set_item_text(5, tr("Export"))
	else:
		DrawGD.file_menu.get_popup().set_item_text(5, tr("Export") + " %s" % (file_name + Export.file_format_string(file_format)))


func serialize() -> Dictionary:
	var layer_data := []
	for layer in layers:
		layer_data.append({
			"name" : layer.name,
			"visible" : layer.visible,
			"locked" : layer.locked,
		})

	var guide_data := []
	for guide in guides:
		if guide is SymmetryGuide:
			continue
		if !is_instance_valid(guide):
			continue
		var coords = guide.points[0].x
		if guide.type == Guide.Types.HORIZONTAL:
			coords = guide.points[0].y

		guide_data.append({"type" : guide.type, "pos" : coords})

	var frame_data := []
	var cel_data := []
	for cel in frames.cels:
		cel_data.append({
			"opacity" : cel.opacity,
#			"image_data" : cel.image.get_data()
		})
	frame_data.append({
		"cels" : cel_data
	})
	
	var brush_data := []
	for brush in brushes:
		brush_data.append({
			"size_x" : brush.get_size().x,
			"size_y" : brush.get_size().y
		})

	var project_data := {
		"pixelorama_version" : DrawGD.current_version,
		"name" : name,
		"size_x" : size.x,
		"size_y" : size.y,
		"save_path" : DrawGD.opensave.current_save_paths[DrawGD.projects.find(self)],
		"layers" : layer_data,
		"guides" : guide_data,
		"symmetry_points" : [x_symmetry_point, y_symmetry_point],
		"frames" : frame_data,
		"brushes" : brush_data,
		"export_directory_path" : directory_path,
		"export_file_name" : file_name,
		"export_file_format" : file_format,
	}

	return project_data


func deserialize(dict : Dictionary) -> void:
	if dict.has("name"):
		name = dict.name
	if dict.has("size_x") and dict.has("size_y"):
		size.x = dict.size_x
		size.y = dict.size_y
		select_all_pixels()
	if dict.has("save_path"):
		DrawGD.opensave.current_save_paths[DrawGD.projects.find(self)] = dict.save_path
		
	if dict.has("frames"):
		var frame = dict.frames
		var cels := []
		for cel in frame.cels:
			cels.append(Cel.new(Image.new(), cel.opacity))
			
		frames = Frame.new(cels)
		
		if dict.has("layers"):
			var layer_i :=  0
			for saved_layer in dict.layers:
				var layer := Layer.new(saved_layer.name, saved_layer.visible, saved_layer.locked, HBoxContainer.new())
				layers.append(layer)
				layer_i += 1
				
				
	if dict.has("guides"):
		for g in dict.guides:
			var guide := Guide.new()
			guide.type = g.type
			if guide.type == Guide.Types.HORIZONTAL:
				guide.add_point(Vector2(-99999, g.pos))
				guide.add_point(Vector2(99999, g.pos))
			else:
				guide.add_point(Vector2(g.pos, -99999))
				guide.add_point(Vector2(g.pos, 99999))
			guide.has_focus = false
			DrawGD.canvas.add_child(guide)
			guides.append(guide)
			
	if dict.has("symmetry_points"):
		x_symmetry_point = dict.symmetry_points[0]
		y_symmetry_point = dict.symmetry_points[1]
		x_symmetry_axis.points[0].y = floor(y_symmetry_point / 2 + 1)
		x_symmetry_axis.points[1].y = floor(y_symmetry_point / 2 + 1)
		y_symmetry_axis.points[0].x = floor(x_symmetry_point / 2 + 1)
		y_symmetry_axis.points[1].x = floor(x_symmetry_point / 2 + 1)
		
	if dict.has("export_directory_path"):
		directory_path = dict.export_directory_path
	if dict.has("export_file_name"):
		file_name = dict.export_file_name
	if dict.has("export_file_format"):
		file_format = dict.export_file_format


func name_changed(value : String) -> void:
	name = value
	DrawGD.tabs.set_tab_title(DrawGD.tabs.current_tab, name)


func size_changed(value : Vector2) -> void:
	size = value
	if DrawGD.selection_rectangle._selected_rect.has_no_area():
		select_all_pixels()

func layers_changed(value : Array) -> void:
	layers = value
	if DrawGD.layers_changed_skip:
		DrawGD.layers_changed_skip = false
		return

	for container in DrawGD.layers_container.get_children():
		container.queue_free()

	for i in range(layers.size() - 1, -1, -1):
		var layer_container = load("res://addons/draw_gd/src/UI/Timeline/LayerButton.tscn").instance()
		layer_container.i = i
		layer_container.DrawGD = DrawGD
		layer_container.init()
		
		if layers[i].name == tr("Layer") + " 0":
			layers[i].name = tr("Layer") + " %s" % i

		DrawGD.layers_container.add_child(layer_container)
		layer_container.label.text = layers[i].name
		layer_container.line_edit.text = layers[i].name
		
		if frames && frames.cels.size() > 0:
			layer_container.cel_button.texture = frames.cels[0].image_texture
			
	DrawGD.canvas.update()
	DrawGD.transparent_checker._ready() # To update the rect size


	var layer_button = DrawGD.layers_container.get_child(DrawGD.layers_container.get_child_count() - 1 - current_layer)
	layer_button.pressed = true
	toggle_layer_buttons_layers()

#func frame_changed(value : int) -> void:
#	var text_color := Color.white
#	if DrawGD.theme_type == DrawGD.Theme_Types.CARAMEL || DrawGD.theme_type == DrawGD.Theme_Types.LIGHT:
#		text_color = Color.black
#
#	for layer in layers: # De-select all the other frames
#		if 0 < layer.frame_container.get_child_count():
#			layer.frame_container.get_child(0).pressed = false
#
#	# Select the new frame
#	if layers and current_frame < layers[current_layer].frame_container.get_child_count():
#		layers[current_layer].frame_container.get_child(current_frame).pressed = true
#
#	DrawGD.canvas.update()
#	DrawGD.transparent_checker._ready() # To update the rect size


func layer_changed(value : int) -> void:
	current_layer = value

	DrawGD.layer_opacity_slider.value = frames.cels[current_layer].opacity * 100
	DrawGD.layer_opacity_spinbox.value = frames.cels[current_layer].opacity * 100

	for container in DrawGD.layers_container.get_children():
		container.pressed = false

	if current_layer < DrawGD.layers_container.get_child_count():
		var layer_button = DrawGD.layers_container.get_child(DrawGD.layers_container.get_child_count() - 1 - current_layer)
		layer_button.pressed = true

	toggle_layer_buttons_current_layer()

	yield(DrawGD.get_tree().create_timer(0.01), "timeout")


func toggle_layer_buttons_layers() -> void:
	if !layers:
		return
	if layers[current_layer].locked:
		DrawGD.disable_button(DrawGD.remove_layer_button, true)

	if layers.size() == 1:
		DrawGD.disable_button(DrawGD.remove_layer_button, true)
		DrawGD.disable_button(DrawGD.move_up_layer_button, true)
		DrawGD.disable_button(DrawGD.move_down_layer_button, true)
		DrawGD.disable_button(DrawGD.merge_down_layer_button, true)
	elif !layers[current_layer].locked:
		DrawGD.disable_button(DrawGD.remove_layer_button, false)


func toggle_layer_buttons_current_layer() -> void:
	if current_layer < layers.size() - 1:
		DrawGD.disable_button(DrawGD.move_up_layer_button, false)
	else:
		DrawGD.disable_button(DrawGD.move_up_layer_button, true)

	if current_layer > 0:
		DrawGD.disable_button(DrawGD.move_down_layer_button, false)
		DrawGD.disable_button(DrawGD.merge_down_layer_button, false)
	else:
		DrawGD.disable_button(DrawGD.move_down_layer_button, true)
		DrawGD.disable_button(DrawGD.merge_down_layer_button, true)

	if current_layer < layers.size():
		if layers[current_layer].locked:
			DrawGD.disable_button(DrawGD.remove_layer_button, true)
		else:
			if layers.size() > 1:
				DrawGD.disable_button(DrawGD.remove_layer_button, false)

func has_changed_changed(value : bool) -> void:
	has_changed = value
	if value:
		DrawGD.tabs.set_tab_title(DrawGD.tabs.current_tab, name + "(*)")
	else:
		DrawGD.tabs.set_tab_title(DrawGD.tabs.current_tab, name)

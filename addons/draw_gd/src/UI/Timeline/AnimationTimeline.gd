tool
extends Panel

var fps := 6.0
var animation_loop := 1 # 0 is no loop, 1 is cycle loop, 2 is ping-pong loop
var animation_forward := true
var first_frame := 0
var last_frame := 0

var timeline_scroll : ScrollContainer
var tag_scroll_container : ScrollContainer

var DrawGD : Node = null

func _ready() -> void:
	var n : Node = get_parent()
	while n:
		if n.name == "DrawGDSingleton":
			DrawGD = n
			break
		n = n.get_parent()
		
	timeline_scroll = DrawGD.find_node_by_name(self, "TimelineScroll")
	tag_scroll_container = DrawGD.find_node_by_name(self, "TagScroll")
	timeline_scroll.get_h_scrollbar().connect("value_changed", self, "_h_scroll_changed")


func _h_scroll_changed(value : float) -> void:
	# Let the main timeline ScrollContainer affect the tag ScrollContainer too
	tag_scroll_container.get_child(0).rect_min_size.x = timeline_scroll.get_child(0).rect_size.x - 212
	tag_scroll_container.scroll_horizontal = value


func _on_FrameTagButton_pressed() -> void:
	DrawGD.tag_dialog.popup_centered()

# Layer buttons

func add_layer(is_new := true) -> void:
	var new_layers : Array = DrawGD.current_project.layers.duplicate()
	var l := Layer.new()
	if !is_new: # Clone layer
		l.name = DrawGD.current_project.layers[DrawGD.current_project.current_layer].name + " (" + tr("copy") + ")"
	new_layers.append(l)

	DrawGD.current_project.undos += 1
	DrawGD.current_project.undo_redo.create_action("Add Layer")

	for f in DrawGD.current_project.frames:
		var new_layer := Image.new()
		if is_new:
			new_layer.create(DrawGD.current_project.size.x, DrawGD.current_project.size.y, false, Image.FORMAT_RGBA8)
		else: # Clone layer
			new_layer.copy_from(f.cels[DrawGD.current_project.current_layer].image)

		new_layer.lock()

		var new_cels : Array = f.cels.duplicate()
		new_cels.append(Cel.new(new_layer, 1))
		DrawGD.current_project.undo_redo.add_do_property(f, "cels", new_cels)
		DrawGD.current_project.undo_redo.add_undo_property(f, "cels", f.cels)

	DrawGD.current_project.undo_redo.add_do_property(DrawGD.current_project, "current_layer", DrawGD.current_project.current_layer + 1)
	DrawGD.current_project.undo_redo.add_do_property(DrawGD.current_project, "layers", new_layers)
	DrawGD.current_project.undo_redo.add_undo_property(DrawGD.current_project, "current_layer", DrawGD.current_project.current_layer)
	DrawGD.current_project.undo_redo.add_undo_property(DrawGD.current_project, "layers", DrawGD.current_project.layers)

	DrawGD.current_project.undo_redo.add_undo_method(DrawGD, "undo")
	DrawGD.current_project.undo_redo.add_do_method(DrawGD, "redo")
	DrawGD.current_project.undo_redo.commit_action()


func _on_RemoveLayer_pressed() -> void:
	if DrawGD.current_project.layers.size() == 1:
		return
	var new_layers : Array = DrawGD.current_project.layers.duplicate()
	new_layers.remove(DrawGD.current_project.current_layer)
	DrawGD.current_project.undos += 1
	DrawGD.current_project.undo_redo.create_action("Remove Layer")
	if DrawGD.current_project.current_layer > 0:
		DrawGD.current_project.undo_redo.add_do_property(DrawGD.current_project, "current_layer", DrawGD.current_project.current_layer - 1)
	else:
		DrawGD.current_project.undo_redo.add_do_property(DrawGD.current_project, "current_layer", DrawGD.current_project.current_layer)

	for f in DrawGD.current_project.frames:
		var new_cels : Array = f.cels.duplicate()
		new_cels.remove(DrawGD.current_project.current_layer)
		DrawGD.current_project.undo_redo.add_do_property(f, "cels", new_cels)
		DrawGD.current_project.undo_redo.add_undo_property(f, "cels", f.cels)

	DrawGD.current_project.undo_redo.add_do_property(DrawGD.current_project, "layers", new_layers)
	DrawGD.current_project.undo_redo.add_undo_property(DrawGD.current_project, "current_layer", DrawGD.current_project.current_layer)
	DrawGD.current_project.undo_redo.add_undo_property(DrawGD.current_project, "layers", DrawGD.current_project.layers)
	DrawGD.current_project.undo_redo.add_do_method(DrawGD, "redo")
	DrawGD.current_project.undo_redo.add_undo_method(DrawGD, "undo")
	DrawGD.current_project.undo_redo.commit_action()


func change_layer_order(rate : int) -> void:
	var change = DrawGD.current_project.current_layer + rate

	var new_layers : Array = DrawGD.current_project.layers.duplicate()
	var temp = new_layers[DrawGD.current_project.current_layer]
	new_layers[DrawGD.current_project.current_layer] = new_layers[change]
	new_layers[change] = temp
	DrawGD.current_project.undo_redo.create_action("Change Layer Order")
	for f in DrawGD.current_project.frames:
		var new_cels : Array = f.cels.duplicate()
		var temp_canvas = new_cels[DrawGD.current_project.current_layer]
		new_cels[DrawGD.current_project.current_layer] = new_cels[change]
		new_cels[change] = temp_canvas
		DrawGD.current_project.undo_redo.add_do_property(f, "cels", new_cels)
		DrawGD.current_project.undo_redo.add_undo_property(f, "cels", f.cels)

	DrawGD.current_project.undo_redo.add_do_property(DrawGD.current_project, "current_layer", change)
	DrawGD.current_project.undo_redo.add_do_property(DrawGD.current_project, "layers", new_layers)
	DrawGD.current_project.undo_redo.add_undo_property(DrawGD.current_project, "layers", DrawGD.current_project.layers)
	DrawGD.current_project.undo_redo.add_undo_property(DrawGD.current_project, "current_layer", DrawGD.current_project.current_layer)

	DrawGD.current_project.undo_redo.add_undo_method(DrawGD, "undo")
	DrawGD.current_project.undo_redo.add_do_method(DrawGD, "redo")
	DrawGD.current_project.undo_redo.commit_action()


func _on_MergeDownLayer_pressed() -> void:
	var new_layers : Array = DrawGD.current_project.layers.duplicate()
	# Loop through the array to create new classes for each element, so that they
	# won't be the same as the original array's classes. Needed for undo/redo to work properly.
	for i in new_layers.size():
		var new_linked_cels = new_layers[i].linked_cels.duplicate()
		new_layers[i] = Layer.new(new_layers[i].name, new_layers[i].visible, new_layers[i].locked, new_layers[i].frame_container, new_layers[i].new_cels_linked, new_linked_cels)

	DrawGD.current_project.undos += 1
	DrawGD.current_project.undo_redo.create_action("Merge Layer")
	for f in DrawGD.current_project.frames:
		var new_cels : Array = f.cels.duplicate()
		for i in new_cels.size():
			new_cels[i] = Cel.new(new_cels[i].image, new_cels[i].opacity)
		var selected_layer := Image.new()
		selected_layer.copy_from(new_cels[DrawGD.current_project.current_layer].image)
		selected_layer.lock()

		if f.cels[DrawGD.current_project.current_layer].opacity < 1: # If we have layer transparency
			for xx in selected_layer.get_size().x:
				for yy in selected_layer.get_size().y:
					var pixel_color : Color = selected_layer.get_pixel(xx, yy)
					var alpha : float = pixel_color.a * f.cels[DrawGD.current_project.current_layer].opacity
					selected_layer.set_pixel(xx, yy, Color(pixel_color.r, pixel_color.g, pixel_color.b, alpha))

		var new_layer := Image.new()
		new_layer.copy_from(f.cels[DrawGD.current_project.current_layer - 1].image)
		new_layer.lock()
		new_layer.blend_rect(selected_layer, Rect2(DrawGD.canvas.location, DrawGD.current_project.size), Vector2.ZERO)
		new_cels.remove(DrawGD.current_project.current_layer)
		if !selected_layer.is_invisible() and DrawGD.current_project.layers[DrawGD.current_project.current_layer - 1].linked_cels.size() > 1 and (f in DrawGD.current_project.layers[DrawGD.current_project.current_layer - 1].linked_cels):
			new_layers[DrawGD.current_project.current_layer - 1].linked_cels.erase(f)
			new_cels[DrawGD.current_project.current_layer - 1].image = new_layer
		else:
			DrawGD.current_project.undo_redo.add_do_property(f.cels[DrawGD.current_project.current_layer - 1].image, "data", new_layer.data)
			DrawGD.current_project.undo_redo.add_undo_property(f.cels[DrawGD.current_project.current_layer - 1].image, "data", f.cels[DrawGD.current_project.current_layer - 1].image.data)

		DrawGD.current_project.undo_redo.add_do_property(f, "cels", new_cels)
		DrawGD.current_project.undo_redo.add_undo_property(f, "cels", f.cels)

	new_layers.remove(DrawGD.current_project.current_layer)
	DrawGD.current_project.undo_redo.add_do_property(DrawGD.current_project, "current_layer", DrawGD.current_project.current_layer - 1)
	DrawGD.current_project.undo_redo.add_do_property(DrawGD.current_project, "layers", new_layers)
	DrawGD.current_project.undo_redo.add_undo_property(DrawGD.current_project, "layers", DrawGD.current_project.layers)
	DrawGD.current_project.undo_redo.add_undo_property(DrawGD.current_project, "current_layer", DrawGD.current_project.current_layer)

	DrawGD.current_project.undo_redo.add_undo_method(DrawGD, "undo")
	DrawGD.current_project.undo_redo.add_do_method(DrawGD, "redo")
	DrawGD.current_project.undo_redo.commit_action()


func _on_OpacitySlider_value_changed(value) -> void:
	DrawGD.current_project.frames[DrawGD.current_project.current_frame].cels[DrawGD.current_project.current_layer].opacity = value / 100
	DrawGD.layer_opacity_slider.value = value
	DrawGD.layer_opacity_slider.value = value
	DrawGD.layer_opacity_spinbox.value = value
	DrawGD.canvas.update()


func _on_OnionSkinningSettings_popup_hide() -> void:
	DrawGD.can_draw = true


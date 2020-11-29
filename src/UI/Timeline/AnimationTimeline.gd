extends Panel

var fps := 6.0
var animation_loop := 1 # 0 is no loop, 1 is cycle loop, 2 is ping-pong loop
var animation_forward := true
var first_frame := 0
var last_frame := 0

var timeline_scroll : ScrollContainer
var tag_scroll_container : ScrollContainer


func _ready() -> void:
	timeline_scroll = DrawGD.find_node_by_name(self, "TimelineScroll")
	tag_scroll_container = DrawGD.find_node_by_name(self, "TagScroll")
	timeline_scroll.get_h_scrollbar().connect("value_changed", self, "_h_scroll_changed")
	DrawGD.animation_timer.wait_time = 1 / fps


func _h_scroll_changed(value : float) -> void:
	# Let the main timeline ScrollContainer affect the tag ScrollContainer too
	tag_scroll_container.get_child(0).rect_min_size.x = timeline_scroll.get_child(0).rect_size.x - 212
	tag_scroll_container.scroll_horizontal = value


func add_frame() -> void:
	var frame : Frame = DrawGD.canvas.new_empty_frame()
	var new_frames : Array = DrawGD.current_project.frames.duplicate()
	new_frames.append(frame)
	var new_layers : Array = DrawGD.current_project.layers.duplicate()
	# Loop through the array to create new classes for each element, so that they
	# won't be the same as the original array's classes. Needed for undo/redo to work properly.
	for i in new_layers.size():
		var new_linked_cels = new_layers[i].linked_cels.duplicate()
		new_layers[i] = Layer.new(new_layers[i].name, new_layers[i].visible, new_layers[i].locked, new_layers[i].frame_container, new_layers[i].new_cels_linked, new_linked_cels)

	for l_i in range(new_layers.size()):
		if new_layers[l_i].new_cels_linked: # If the link button is pressed
			new_layers[l_i].linked_cels.append(frame)
			frame.cels[l_i].image = new_layers[l_i].linked_cels[0].cels[l_i].image
			frame.cels[l_i].image_texture = new_layers[l_i].linked_cels[0].cels[l_i].image_texture

	DrawGD.current_project.undos += 1
	DrawGD.current_project.undo_redo.create_action("Add Frame")
	DrawGD.current_project.undo_redo.add_do_method(DrawGD, "redo")
	DrawGD.current_project.undo_redo.add_undo_method(DrawGD, "undo")

	DrawGD.current_project.undo_redo.add_do_property(DrawGD.current_project, "frames", new_frames)
	DrawGD.current_project.undo_redo.add_do_property(DrawGD.current_project, "current_frame", new_frames.size() - 1)
	DrawGD.current_project.undo_redo.add_do_property(DrawGD.current_project, "layers", new_layers)

	DrawGD.current_project.undo_redo.add_undo_property(DrawGD.current_project, "frames", DrawGD.current_project.frames)
	DrawGD.current_project.undo_redo.add_undo_property(DrawGD.current_project, "current_frame", DrawGD.current_project.current_frame)
	DrawGD.current_project.undo_redo.add_undo_property(DrawGD.current_project, "layers", DrawGD.current_project.layers)
	DrawGD.current_project.undo_redo.commit_action()


func _on_DeleteFrame_pressed(frame := -1) -> void:
	if DrawGD.current_project.frames.size() == 1:
		return
	if frame == -1:
		frame = DrawGD.current_project.current_frame

	var frame_to_delete : Frame = DrawGD.current_project.frames[frame]
	var new_frames : Array = DrawGD.current_project.frames.duplicate()
	new_frames.erase(frame_to_delete)
	var current_frame := DrawGD.current_project.current_frame
	if current_frame > 0 && current_frame == new_frames.size(): # If it's the last frame
		current_frame -= 1

	var new_animation_tags := DrawGD.current_project.animation_tags.duplicate()
	# Loop through the tags to create new classes for them, so that they won't be the same
	# as DrawGD.current_project.animation_tags's classes. Needed for undo/redo to work properly.
	for i in new_animation_tags.size():
		new_animation_tags[i] = AnimationTag.new(new_animation_tags[i].name, new_animation_tags[i].color, new_animation_tags[i].from, new_animation_tags[i].to)

	# Loop through the tags to see if the frame is in one
	for tag in new_animation_tags:
		if frame + 1 >= tag.from && frame + 1 <= tag.to:
			if tag.from == tag.to: # If we're deleting the only frame in the tag
				new_animation_tags.erase(tag)
			else:
				tag.to -= 1
		elif frame + 1 < tag.from:
			tag.from -= 1
			tag.to -= 1

	# Check if one of the cels of the frame is linked
	# if they are, unlink them too
	# this prevents removed cels being kept in linked memory
	var new_layers : Array = DrawGD.current_project.layers.duplicate()
	# Loop through the array to create new classes for each element, so that they
	# won't be the same as the original array's classes. Needed for undo/redo to work properly.
	for i in new_layers.size():
		var new_linked_cels = new_layers[i].linked_cels.duplicate()
		new_layers[i] = Layer.new(new_layers[i].name, new_layers[i].visible, new_layers[i].locked, new_layers[i].frame_container, new_layers[i].new_cels_linked, new_linked_cels)

	for layer in new_layers:
		for linked in layer.linked_cels:
			if linked == DrawGD.current_project.frames[frame]:
				layer.linked_cels.erase(linked)

	DrawGD.current_project.undos += 1
	DrawGD.current_project.undo_redo.create_action("Remove Frame")

	DrawGD.current_project.undo_redo.add_do_property(DrawGD.current_project, "frames", new_frames)
	DrawGD.current_project.undo_redo.add_do_property(DrawGD.current_project, "current_frame", current_frame)
	DrawGD.current_project.undo_redo.add_do_property(DrawGD.current_project, "animation_tags", new_animation_tags)
	DrawGD.current_project.undo_redo.add_do_property(DrawGD.current_project, "layers", new_layers)

	DrawGD.current_project.undo_redo.add_undo_property(DrawGD.current_project, "frames", DrawGD.current_project.frames)
	DrawGD.current_project.undo_redo.add_undo_property(DrawGD.current_project, "current_frame", DrawGD.current_project.current_frame)
	DrawGD.current_project.undo_redo.add_undo_property(DrawGD.current_project, "animation_tags", DrawGD.current_project.animation_tags)
	DrawGD.current_project.undo_redo.add_undo_property(DrawGD.current_project, "layers", DrawGD.current_project.layers)

	DrawGD.current_project.undo_redo.add_do_method(DrawGD, "redo")
	DrawGD.current_project.undo_redo.add_undo_method(DrawGD, "undo")
	DrawGD.current_project.undo_redo.commit_action()


func _on_CopyFrame_pressed(frame := -1) -> void:
	if frame == -1:
		frame = DrawGD.current_project.current_frame

	var new_frame := Frame.new()

	var new_frames := DrawGD.current_project.frames.duplicate()
	new_frames.insert(frame + 1, new_frame)

	for cel in DrawGD.current_project.frames[frame].cels: # Copy every cel
		var sprite := Image.new()
		sprite.copy_from(cel.image)
		sprite.lock()
		new_frame.cels.append(Cel.new(sprite, cel.opacity))

	var new_animation_tags := DrawGD.current_project.animation_tags.duplicate()
	# Loop through the tags to create new classes for them, so that they won't be the same
	# as DrawGD.current_project.animation_tags's classes. Needed for undo/redo to work properly.
	for i in new_animation_tags.size():
		new_animation_tags[i] = AnimationTag.new(new_animation_tags[i].name, new_animation_tags[i].color, new_animation_tags[i].from, new_animation_tags[i].to)

	# Loop through the tags to see if the frame is in one
	for tag in new_animation_tags:
		if frame + 1 >= tag.from && frame + 1 <= tag.to:
			tag.to += 1

	DrawGD.current_project.undos += 1
	DrawGD.current_project.undo_redo.create_action("Add Frame")
	DrawGD.current_project.undo_redo.add_do_method(DrawGD, "redo")
	DrawGD.current_project.undo_redo.add_undo_method(DrawGD, "undo")

	DrawGD.current_project.undo_redo.add_do_property(DrawGD.current_project, "frames", new_frames)
	DrawGD.current_project.undo_redo.add_do_property(DrawGD.current_project, "current_frame", frame + 1)
	DrawGD.current_project.undo_redo.add_do_property(DrawGD.current_project, "animation_tags", new_animation_tags)
	for i in range(DrawGD.current_project.layers.size()):
		for child in DrawGD.current_project.layers[i].frame_container.get_children():
			DrawGD.current_project.undo_redo.add_do_property(child, "pressed", false)
			DrawGD.current_project.undo_redo.add_undo_property(child, "pressed", child.pressed)

	DrawGD.current_project.undo_redo.add_undo_property(DrawGD.current_project, "frames", DrawGD.current_project.frames)
	DrawGD.current_project.undo_redo.add_undo_property(DrawGD.current_project, "current_frame", frame)
	DrawGD.current_project.undo_redo.add_undo_property(DrawGD.current_project, "animation_tags", DrawGD.current_project.animation_tags)
	DrawGD.current_project.undo_redo.commit_action()


func _on_FrameTagButton_pressed() -> void:
	DrawGD.tag_dialog.popup_centered()

func _on_MoveLeft_pressed() -> void:
	var frame : int = DrawGD.current_project.current_frame
	if frame == 0:
		return
	DrawGD.current_project.layers[DrawGD.current_project.current_layer].frame_container.get_child(frame).change_frame_order(-1)

func _on_MoveRight_pressed() -> void:
	var frame : int = DrawGD.current_project.current_frame
	if frame == last_frame:
		return
	DrawGD.current_project.layers[DrawGD.current_project.current_layer].frame_container.get_child(frame).change_frame_order(1)

func _on_OnionSkinning_pressed() -> void:
	DrawGD.onion_skinning = !DrawGD.onion_skinning
	DrawGD.canvas.update()
	var texture_button : TextureRect = DrawGD.onion_skinning_button.get_child(0)
	if DrawGD.onion_skinning:
		DrawGD.change_button_texturerect(texture_button, "onion_skinning.png")
	else:
		DrawGD.change_button_texturerect(texture_button, "onion_skinning_off.png")

func _on_OnionSkinningSettings_pressed() -> void:
	$OnionSkinningSettings.popup(Rect2(DrawGD.onion_skinning_button.rect_global_position.x - $OnionSkinningSettings.rect_size.x - 16, DrawGD.onion_skinning_button.rect_global_position.y - 106, 136, 126))


func _on_LoopAnim_pressed() -> void:
	var texture_button : TextureRect = DrawGD.loop_animation_button.get_child(0)
	match animation_loop:
		0: # Make it loop
			animation_loop = 1
			DrawGD.change_button_texturerect(texture_button, "loop.png")
			DrawGD.loop_animation_button.hint_tooltip = "Cycle loop"
		1: # Make it ping-pong
			animation_loop = 2
			DrawGD.change_button_texturerect(texture_button, "loop_pingpong.png")
			DrawGD.loop_animation_button.hint_tooltip = "Ping-pong loop"
		2: # Make it stop
			animation_loop = 0
			DrawGD.change_button_texturerect(texture_button, "loop_none.png")
			DrawGD.loop_animation_button.hint_tooltip = "No loop"


func _on_PlayForward_toggled(button_pressed : bool) -> void:
	if button_pressed:
		DrawGD.change_button_texturerect(DrawGD.play_forward.get_child(0), "pause.png")
	else:
		DrawGD.change_button_texturerect(DrawGD.play_forward.get_child(0), "play.png")

	play_animation(button_pressed, true)


func _on_PlayBackwards_toggled(button_pressed : bool) -> void:
	if button_pressed:
		DrawGD.change_button_texturerect(DrawGD.play_backwards.get_child(0), "pause.png")
	else:
		DrawGD.change_button_texturerect(DrawGD.play_backwards.get_child(0), "play_backwards.png")

	play_animation(button_pressed, false)


func _on_AnimationTimer_timeout() -> void:
	if first_frame == last_frame:
		$AnimationTimer.stop()
		return

	if animation_forward:
		if DrawGD.current_project.current_frame < last_frame:
			DrawGD.current_project.current_frame += 1
		else:
			match animation_loop:
				0: # No loop
					DrawGD.play_forward.pressed = false
					DrawGD.play_backwards.pressed = false
					DrawGD.animation_timer.stop()
				1: # Cycle loop
					DrawGD.current_project.current_frame = first_frame
				2: # Ping pong loop
					animation_forward = false
					_on_AnimationTimer_timeout()

	else:
		if DrawGD.current_project.current_frame > first_frame:
			DrawGD.current_project.current_frame -= 1
		else:
			match animation_loop:
				0: # No loop
					DrawGD.play_backwards.pressed = false
					DrawGD.play_forward.pressed = false
					DrawGD.animation_timer.stop()
				1: # Cycle loop
					DrawGD.current_project.current_frame = last_frame
				2: # Ping pong loop
					animation_forward = true
					_on_AnimationTimer_timeout()


func play_animation(play : bool, forward_dir : bool) -> void:
	first_frame = 0
	last_frame = DrawGD.current_project.frames.size() - 1
	if DrawGD.play_only_tags:
		for tag in DrawGD.current_project.animation_tags:
			if DrawGD.current_project.current_frame + 1 >= tag.from && DrawGD.current_project.current_frame + 1 <= tag.to:
				first_frame = tag.from - 1
				last_frame = min(DrawGD.current_project.frames.size() - 1, tag.to - 1)

	if first_frame == last_frame:
		if forward_dir:
			DrawGD.play_forward.pressed = false
		else:
			DrawGD.play_backwards.pressed = false
		return

	if forward_dir:
		DrawGD.play_backwards.disconnect("toggled", self, "_on_PlayBackwards_toggled")
		DrawGD.play_backwards.pressed = false
		DrawGD.change_button_texturerect(DrawGD.play_backwards.get_child(0), "play_backwards.png")
		DrawGD.play_backwards.connect("toggled", self, "_on_PlayBackwards_toggled")
	else:
		DrawGD.play_forward.disconnect("toggled", self, "_on_PlayForward_toggled")
		DrawGD.play_forward.pressed = false
		DrawGD.change_button_texturerect(DrawGD.play_forward.get_child(0), "play.png")
		DrawGD.play_forward.connect("toggled", self, "_on_PlayForward_toggled")

	if play:
		DrawGD.animation_timer.wait_time = 1 / fps
		DrawGD.animation_timer.start()
		animation_forward = forward_dir
	else:
		DrawGD.animation_timer.stop()


func _on_NextFrame_pressed() -> void:
	if DrawGD.current_project.current_frame < DrawGD.current_project.frames.size() - 1:
		DrawGD.current_project.current_frame += 1


func _on_PreviousFrame_pressed() -> void:
	if DrawGD.current_project.current_frame > 0:
		DrawGD.current_project.current_frame -= 1


func _on_LastFrame_pressed() -> void:
	DrawGD.current_project.current_frame = DrawGD.current_project.frames.size() - 1


func _on_FirstFrame_pressed() -> void:
	DrawGD.current_project.current_frame = 0


func _on_FPSValue_value_changed(value : float) -> void:
	fps = float(value)
	DrawGD.animation_timer.wait_time = 1 / fps


func _on_PastOnionSkinning_value_changed(value : float) -> void:
	DrawGD.onion_skinning_past_rate = int(value)
	DrawGD.canvas.update()


func _on_FutureOnionSkinning_value_changed(value : float) -> void:
	DrawGD.onion_skinning_future_rate = int(value)
	DrawGD.canvas.update()


func _on_BlueRedMode_toggled(button_pressed : bool) -> void:
	DrawGD.onion_skinning_blue_red = button_pressed
	DrawGD.canvas.update()


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


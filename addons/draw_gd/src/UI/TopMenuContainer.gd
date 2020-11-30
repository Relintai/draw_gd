tool
extends Control

var Export = preload("res://addons/draw_gd/src/Autoload/Export.gd")
var DrawingAlgos = preload("res://addons/draw_gd/src/Autoload/DrawingAlgos.gd")

var file_menu : PopupMenu
var view_menu : PopupMenu
var zen_mode := false

var was_exported = false

var DrawGD : Node = null

func _enter_tree() -> void:
	var n : Node = get_parent()
	while n:
		if n.name == "DrawGDSingleton":
			DrawGD = n
			break
		n = n.get_parent()
	
	setup_file_menu()
	setup_edit_menu()
	setup_view_menu()
	setup_image_menu()
	
#	DrawGds = get_tree().root.find_node("DrawGDSingleton")
	
#	print(DrawGds)

func setup_file_menu() -> void:
	
#	var file_menu_items := {
#		"New..." : InputMap.get_action_list("new_file")[0].get_scancode_with_modifiers(),
#		"Open..." : InputMap.get_action_list("open_file")[0].get_scancode_with_modifiers(),
#		'Open last project...' : 0,
#		"Save..." : InputMap.get_action_list("save_file")[0].get_scancode_with_modifiers(),
#		"Save as..." : InputMap.get_action_list("save_file_as")[0].get_scancode_with_modifiers(),
#		"Export..." : InputMap.get_action_list("export_file")[0].get_scancode_with_modifiers(),
#		"Export as..." : InputMap.get_action_list("export_file_as")[0].get_scancode_with_modifiers(),
#		"Quit" : InputMap.get_action_list("quit")[0].get_scancode_with_modifiers(),
#		}
		
	var file_menu_items := {
		"New..." : 0,
		"Open..." : 0,
		'Open last project...' : 0,
		"Save..." : 0,
		"Save as..." : 0,
		"Export..." : 0,
		"Export as..." : 0,
		"Quit" : 0,
		}
		
	file_menu = DrawGD.file_menu.get_popup()
	var i := 0

	for item in file_menu_items.keys():
		file_menu.add_item(item, i, file_menu_items[item])
		i += 1

	file_menu.connect("id_pressed", self, "file_menu_id_pressed")


func setup_edit_menu() -> void:
#	var edit_menu_items := {
#		"Undo" : InputMap.get_action_list("undo")[0].get_scancode_with_modifiers(),
#		"Redo" : InputMap.get_action_list("redo")[0].get_scancode_with_modifiers(),
#		"Copy" : InputMap.get_action_list("copy")[0].get_scancode_with_modifiers(),
#		"Cut" : InputMap.get_action_list("cut")[0].get_scancode_with_modifiers(),
#		"Paste" : InputMap.get_action_list("paste")[0].get_scancode_with_modifiers(),
#		"Delete" : InputMap.get_action_list("delete")[0].get_scancode_with_modifiers(),
#		"Clear Selection" : 0,
#		"Preferences" : 0
#		}
		
	var edit_menu_items := {
		"Undo" : 0,
		"Redo" : 0,
		"Copy" : 0,
		"Cut" : 0,
		"Paste" : 0,
		"Delete" : 0,
		"Clear Selection" : 0,
		"Preferences" : 0
		}
		
	var edit_menu : PopupMenu = DrawGD.edit_menu.get_popup()
	var i := 0

	for item in edit_menu_items.keys():
		edit_menu.add_item(item, i, edit_menu_items[item])
		i += 1

	edit_menu.connect("id_pressed", self, "edit_menu_id_pressed")


func setup_view_menu() -> void:
#	var view_menu_items := {
#		"Tile Mode" : InputMap.get_action_list("tile_mode")[0].get_scancode_with_modifiers(),
#		"Show Grid" : InputMap.get_action_list("show_grid")[0].get_scancode_with_modifiers(),
#		"Show Rulers" : InputMap.get_action_list("show_rulers")[0].get_scancode_with_modifiers(),
#		"Show Guides" : InputMap.get_action_list("show_guides")[0].get_scancode_with_modifiers(),
#		"Show Animation Timeline" : 0,
#		"Zen Mode" : InputMap.get_action_list("zen_mode")[0].get_scancode_with_modifiers(),
#		"Fullscreen Mode" : InputMap.get_action_list("toggle_fullscreen")[0].get_scancode_with_modifiers(),
#		}
		
	var view_menu_items := {
		"Tile Mode" : 0,
		"Show Grid" : 0,
		"Show Rulers" : 0,
		"Show Guides" : 0,
		"Zen Mode" : 0,
		}
		
	view_menu = DrawGD.view_menu.get_popup()

	var i := 0
	for item in view_menu_items.keys():
		view_menu.add_check_item(item, i, view_menu_items[item])
		i += 1

	view_menu.set_item_checked(2, true) # Show Rulers
	view_menu.set_item_checked(3, true) # Show Guides
	view_menu.hide_on_checkable_item_selection = false
	view_menu.connect("id_pressed", self, "view_menu_id_pressed")

func setup_image_menu() -> void:
	var image_menu_items := {
		"Scale Image" : 0,
		"Crop Image" : 0,
		"Resize Canvas" : 0,
		"Flip" : 0,
		"Rotate Image" : 0,
		"Invert Colors" : 0,
		"Desaturation" : 0,
		"Outline" : 0,
		"Adjust Hue/Saturation/Value" : 0,
		"Gradient" : 0,
		# "Shader" : 0
		}
	var image_menu : PopupMenu = DrawGD.image_menu.get_popup()

	var i := 0
	for item in image_menu_items.keys():
		image_menu.add_item(item, i, image_menu_items[item])
		if i == 2:
			image_menu.add_separator()
		i += 1

	image_menu.connect("id_pressed", self, "image_menu_id_pressed")


func file_menu_id_pressed(id : int) -> void:
	match id:
		0: # New
			on_new_project_file_menu_option_pressed()
		1: # Open
			open_project_file()
		2: # Open last project
			on_open_last_project_file_menu_option_pressed()
		3: # Save
			save_project_file()
		4: # Save as
			save_project_file_as()
		5: # Export
			export_file()
		6: # Export as
			DrawGD.export_dialog.popup_centered()
			DrawGD.dialog_open(true)
		7: # Quit
			DrawGD.control.show_quit_dialog()


func on_new_project_file_menu_option_pressed() -> void:
	DrawGD.new_image_dialog.popup_centered()
	DrawGD.dialog_open(true)


func open_project_file() -> void:
	DrawGD.open_sprites_dialog.popup_centered()
	DrawGD.dialog_open(true)
	DrawGD.control.opensprite_file_selected = false


func on_open_last_project_file_menu_option_pressed() -> void:
	# Check if last project path is set and if yes then open
	if DrawGD.config_cache.has_section_key("preferences", "last_project_path"):
		DrawGD.control.load_last_project()
	else: # if not then warn user that he didn't edit any project yet
		DrawGD.error_dialog.set_text("You haven't saved or opened any project in Pixelorama yet!")
		DrawGD.error_dialog.popup_centered()
		DrawGD.dialog_open(true)


func save_project_file() -> void:
	DrawGD.control.is_quitting_on_save = false
	var path = DrawGD.opensave.current_save_paths[DrawGD.current_project_index]
	if path == "":
		DrawGD.save_sprites_dialog.popup_centered()
		DrawGD.dialog_open(true)
	else:
		DrawGD.control._on_SaveSprite_file_selected(path)


func save_project_file_as() -> void:
	DrawGD.control.is_quitting_on_save = false
	DrawGD.save_sprites_dialog.popup_centered()
	DrawGD.dialog_open(true)


func export_file() -> void:
	if was_exported == false:
		DrawGD.export_dialog.popup_centered()
		DrawGD.dialog_open(true)
	else:
		Export.external_export()


func edit_menu_id_pressed(id : int) -> void:
	match id:
		0: # Undo
			DrawGD.current_project.undo_redo.undo()
		1: # Redo
			DrawGD.control.redone = true
			DrawGD.current_project.undo_redo.redo()
			DrawGD.control.redone = false
		2: # Copy
			DrawGD.selection_rectangle.copy()
		3: # cut
			DrawGD.selection_rectangle.cut()
		4: # paste
			DrawGD.selection_rectangle.paste()
		5: # Delete
			DrawGD.selection_rectangle.delete()
		6: # Clear selection
			DrawGD.selection_rectangle.set_rect(Rect2(0, 0, 0, 0))
			DrawGD.selection_rectangle.select_rect()
		7: # Preferences
			DrawGD.preferences_dialog.popup_centered(Vector2(400, 280))
			DrawGD.dialog_open(true)


func view_menu_id_pressed(id : int) -> void:
	match id:
		0: # Tile mode
			toggle_tile_mode()
		1: # Show grid
			toggle_show_grid()
		2: # Show rulers
			toggle_show_rulers()
		3: # Show guides
			toggle_show_guides()
		4: # Zen mode
			toggle_zen_mode()

	DrawGD.canvas.update()


func toggle_tile_mode() -> void:
	DrawGD.tile_mode = !DrawGD.tile_mode
	view_menu.set_item_checked(0, DrawGD.tile_mode)


func toggle_show_grid() -> void:
	DrawGD.draw_grid = !DrawGD.draw_grid
	view_menu.set_item_checked(1, DrawGD.draw_grid)
	DrawGD.canvas.grid.update()


func toggle_show_rulers() -> void:
	DrawGD.show_rulers = !DrawGD.show_rulers
	view_menu.set_item_checked(2, DrawGD.show_rulers)
	DrawGD.horizontal_ruler.visible = DrawGD.show_rulers
	DrawGD.vertical_ruler.visible = DrawGD.show_rulers


func toggle_show_guides() -> void:
	DrawGD.show_guides = !DrawGD.show_guides
	view_menu.set_item_checked(3, DrawGD.show_guides)
	for guide in DrawGD.canvas.get_children():
		if guide is Guide and guide in DrawGD.current_project.guides:
			guide.visible = DrawGD.show_guides
			if guide is SymmetryGuide:
				if guide.type == Guide.Types.HORIZONTAL:
					guide.visible = DrawGD.show_x_symmetry_axis and DrawGD.show_guides
				else:
					guide.visible = DrawGD.show_y_symmetry_axis and DrawGD.show_guides


func toggle_zen_mode() -> void:
	DrawGD.control.get_node("MenuAndUI/UI/ToolPanel").visible = zen_mode
	DrawGD.control.get_node("MenuAndUI/UI/RightPanel").visible = zen_mode
	#DrawGD.control.get_node("MenuAndUI/UI/CanvasAndTimeline/ViewportAndRulers/TabsContainer").visible = zen_mode
	zen_mode = !zen_mode
	view_menu.set_item_checked(4, zen_mode)


func image_menu_id_pressed(id : int) -> void:
	if DrawGD.current_project.layers[DrawGD.current_project.current_layer].locked: # No changes if the layer is locked
		return
	var image : Image = DrawGD.current_project.frames[DrawGD.current_project.current_frame].cels[DrawGD.current_project.current_layer].image
	match id:
		0: # Scale Image
			show_scale_image_popup()

		1: # Crop Image
			DrawingAlgos.crop_image(image)

		2: # Resize Canvas
			show_resize_canvas_popup()

		3: # Flip
			DrawGD.control.get_node("Dialogs/ImageEffects/FlipImageDialog").popup_centered()
			DrawGD.dialog_open(true)

		4: # Rotate
			show_rotate_image_popup()

		5: # Invert Colors
			DrawGD.control.get_node("Dialogs/ImageEffects/InvertColorsDialog").popup_centered()
			DrawGD.dialog_open(true)

		6: # Desaturation
			DrawGD.control.get_node("Dialogs/ImageEffects/DesaturateDialog").popup_centered()
			DrawGD.dialog_open(true)

		7: # Outline
			show_add_outline_popup()

		8: # HSV
			show_hsv_configuration_popup()

		9: # Gradient
			DrawGD.control.get_node("Dialogs/ImageEffects/GradientDialog").popup_centered()
			DrawGD.dialog_open(true)

		10: # Shader
			DrawGD.control.get_node("Dialogs/ImageEffects/ShaderEffect").popup_centered()
			DrawGD.dialog_open(true)


func show_scale_image_popup() -> void:
	DrawGD.control.get_node("Dialogs/ImageEffects/ScaleImage").popup_centered()
	DrawGD.dialog_open(true)


func show_resize_canvas_popup() -> void:
	DrawGD.control.get_node("Dialogs/ImageEffects/ResizeCanvas").popup_centered()
	DrawGD.dialog_open(true)


func show_rotate_image_popup() -> void:
	DrawGD.control.get_node("Dialogs/ImageEffects/RotateImage").popup_centered()
	DrawGD.dialog_open(true)


func show_add_outline_popup() -> void:
	DrawGD.control.get_node("Dialogs/ImageEffects/OutlineDialog").popup_centered()
	DrawGD.dialog_open(true)


func show_hsv_configuration_popup() -> void:
	DrawGD.control.get_node("Dialogs/ImageEffects/HSVDialog").popup_centered()
	DrawGD.dialog_open(true)

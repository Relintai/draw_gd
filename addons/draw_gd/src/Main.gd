tool
extends Control

var Export = preload("res://addons/draw_gd/src/Autoload/Export.gd")
var ImportScript = preload("res://addons/draw_gd/src/Autoload/Import.gd")
var Import = ImportScript.new()

var opensprite_file_selected := false
var redone := false
var is_quitting_on_save := false

var DrawGD : Node = null

# Called when the node enters the scene tree for the first time.
func _enter_tree() -> void:
	DrawGD = get_node("..")
	#get_tree().set_auto_accept_quit(false)
	setup_application_window_size()

	DrawGD.window_title = tr("untitled") + " - Pixelorama " + DrawGD.current_version

	DrawGD.current_project.layers[0].name = tr("Layer") + " 0"
	#DrawGD.layers_container.get_child(0).label.text = DrawGD.current_project.layers[0].name
	#DrawGD.layers_container.get_child(0).line_edit.text = DrawGD.current_project.layers[0].name

	Import.import_brushes(DrawGD.directory_module.get_brushes_search_path_in_order())
	Import.import_patterns(DrawGD.directory_module.get_patterns_search_path_in_order())

	DrawGD.quit_and_save_dialog.add_button("Save & Exit", false, "Save")
	DrawGD.quit_and_save_dialog.get_ok().text = "Exit without saving"

	var zstd_checkbox := CheckBox.new()
	zstd_checkbox.name = "ZSTDCompression"
	zstd_checkbox.pressed = true
	zstd_checkbox.text = "Use ZSTD Compression"
	zstd_checkbox.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	DrawGD.save_sprites_dialog.get_vbox().add_child(zstd_checkbox)

	if not DrawGD.config_cache.has_section_key("preferences", "startup"):
		DrawGD.config_cache.set_value("preferences", "startup", true)
		
	show_splash_screen()
	handle_backup()

	# If the user wants to run Pixelorama with arguments in terminal mode
	# or open files with Pixelorama directly, then handle that
	if OS.get_cmdline_args():
		DrawGD.opensave.handle_loading_files(OS.get_cmdline_args())
	get_tree().connect("files_dropped", self, "_on_files_dropped")
	
func show_splash_screen():
	yield(get_tree().create_timer(0.2), "timeout")
	DrawGD.can_draw = true

func _input(event : InputEvent) -> void:
#	DrawGD.left_cursor.position = get_global_mouse_position() + Vector2(-32, 32)
#	DrawGD.left_cursor.texture = DrawGD.left_cursor_tool_texture
#	DrawGD.right_cursor.position = get_global_mouse_position() + Vector2(32, 32)
#	DrawGD.right_cursor.texture = DrawGD.right_cursor_tool_texture

#	if event is InputEventKey and (event.scancode == KEY_ENTER or event.scancode == KEY_KP_ENTER):
#		if get_focus_owner() is LineEdit:
#			get_focus_owner().release_focus()

	#TODO TEMP
	return 

	if event.is_action_pressed("redo_secondary"): # Shift + Ctrl + Z
		redone = true
		DrawGD.current_project.undo_redo.redo()
		redone = false


func setup_application_window_size() -> void:
	if OS.get_name() == "HTML5":
		return
	# Set a minimum window size to prevent UI elements from collapsing on each other.
	OS.min_window_size = Vector2(1024, 576)

	# Restore the window position/size if values are present in the configuration cache
	if DrawGD.config_cache.has_section_key("window", "screen"):
		OS.current_screen = DrawGD.config_cache.get_value("window", "screen")
	if DrawGD.config_cache.has_section_key("window", "maximized"):
		OS.window_maximized = DrawGD.config_cache.get_value("window", "maximized")

	if !OS.window_maximized:
		if DrawGD.config_cache.has_section_key("window", "position"):
			OS.window_position = DrawGD.config_cache.get_value("window", "position")
		if DrawGD.config_cache.has_section_key("window", "size"):
			OS.window_size = DrawGD.config_cache.get_value("window", "size")


func handle_backup() -> void:
	# If backup file exists then Pixelorama was not closed properly (probably crashed) - reopen backup
#	var backup_confirmation : ConfirmationDialog = $Dialogs/BackupConfirmation
#	backup_confirmation.get_cancel().text = tr("Delete")
#	if DrawGD.config_cache.has_section("backups"):
#		var project_paths = DrawGD.config_cache.get_section_keys("backups")
#		if project_paths.size() > 0:
#			# Get backup paths
#			var backup_paths := []
#			for p_path in project_paths:
#				backup_paths.append(DrawGD.config_cache.get_value("backups", p_path))
#			# Temporatily stop autosave until user confirms backup
#			DrawGD.opensave.autosave_timer.stop()
#			backup_confirmation.dialog_text = tr("Autosaved backup was found. Do you want to reload it?")
#			backup_confirmation.connect("confirmed", self, "_on_BackupConfirmation_confirmed", [project_paths, backup_paths])
#			backup_confirmation.get_cancel().connect("pressed", self, "_on_BackupConfirmation_delete", [project_paths, backup_paths])
#			backup_confirmation.popup_centered()
#			DrawGD.can_draw = false
#			modulate = Color(0.5, 0.5, 0.5)
#		else:
#			if DrawGD.open_last_project:
#				load_last_project()
#	else:
#		if DrawGD.open_last_project:
#			load_last_project()
			
	if DrawGD.open_last_project:
		load_last_project()


func _notification(what : int) -> void:
	if what == MainLoop.NOTIFICATION_WM_QUIT_REQUEST: # Handle exit
		show_quit_dialog()


func _on_files_dropped(_files : PoolStringArray, _screen : int) -> void:
	DrawGD.opensave.handle_loading_files(_files)


func load_last_project() -> void:
	if OS.get_name() == "HTML5":
		return
	# Check if any project was saved or opened last time
	if DrawGD.config_cache.has_section_key("preferences", "last_project_path"):
		# Check if file still exists on disk
		var file_path = DrawGD.config_cache.get_value("preferences", "last_project_path")
		var file_check := File.new()
		if file_check.file_exists(file_path): # If yes then load the file
			DrawGD.opensave.open_pxo_file(file_path)
		else:
			# If file doesn't exist on disk then warn user about this
			DrawGD.error_dialog.set_text("Cannot find last project file.")
			DrawGD.error_dialog.popup_centered()
			DrawGD.dialog_open(true)


func _on_OpenSprite_file_selected(path : String) -> void:
	DrawGD.opensave.handle_loading_files([path])


func _on_SaveSprite_file_selected(path : String) -> void:
	var zstd = DrawGD.save_sprites_dialog.get_vbox().get_node("ZSTDCompression").pressed
	DrawGD.opensave.save_pxo_file(path, false, zstd)

	if is_quitting_on_save:
		_on_QuitDialog_confirmed()


func _on_SaveSpriteHTML5_confirmed() -> void:
	var file_name = DrawGD.save_sprites_html5_dialog.get_node("FileNameContainer/FileNameLineEdit").text
	file_name += ".pxo"
	var path = "user://".plus_file(file_name)
	DrawGD.opensave.save_pxo_file(path, false, false)


func _on_OpenSprite_popup_hide() -> void:
	if !opensprite_file_selected:
		_can_draw_true()


func _can_draw_true() -> void:
	DrawGD.dialog_open(false)


func show_quit_dialog() -> void:
	if !DrawGD.quit_dialog.visible:
		if !DrawGD.current_project.has_changed:
			DrawGD.quit_dialog.call_deferred("popup_centered")
		else:
			DrawGD.quit_and_save_dialog.call_deferred("popup_centered")

	DrawGD.dialog_open(true)


func _on_QuitAndSaveDialog_custom_action(action : String) -> void:
	if action == "Save":
		is_quitting_on_save = true
		DrawGD.save_sprites_dialog.popup_centered()
		DrawGD.quit_dialog.hide()
		DrawGD.dialog_open(true)


func _on_QuitDialog_confirmed() -> void:
	# Darken the UI to denote that the application is currently exiting
	# (it won't respond to user input in this state).
	modulate = Color(0.5, 0.5, 0.5)
	get_tree().quit()


func _on_BackupConfirmation_confirmed(project_paths : Array, backup_paths : Array) -> void:
	DrawGD.opensave.reload_backup_file(project_paths, backup_paths)
	DrawGD.opensave.autosave_timer.start()
	Export.file_name = DrawGD.opensave.current_save_paths[0].get_file().trim_suffix(".pxo")
	Export.directory_path = DrawGD.opensave.current_save_paths[0].get_base_dir()
	Export.was_exported = false
	DrawGD.file_menu.get_popup().set_item_text(3, tr("Save") + " %s" % DrawGD.opensave.current_save_paths[0].get_file())
	DrawGD.file_menu.get_popup().set_item_text(5, tr("Export"))


func _on_BackupConfirmation_delete(project_paths : Array, backup_paths : Array) -> void:
	for i in range(project_paths.size()):
		DrawGD.opensave.remove_backup_by_path(project_paths[i], backup_paths[i])
	DrawGD.opensave.autosave_timer.start()
	# Reopen last project
	if DrawGD.open_last_project:
		load_last_project()

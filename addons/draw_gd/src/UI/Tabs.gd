tool
extends Tabs


func _on_Tabs_tab_changed(tab : int) -> void:
	DrawGD.current_project_index = tab


func _on_Tabs_tab_close(tab : int) -> void:
	if DrawGD.projects.size() == 1 or DrawGD.current_project_index != tab:
		return

	if DrawGD.current_project.has_changed:
		if !DrawGD.unsaved_changes_dialog.is_connected("confirmed", self, "delete_tab"):
			DrawGD.unsaved_changes_dialog.connect("confirmed", self, "delete_tab", [tab])
		DrawGD.unsaved_changes_dialog.popup_centered()
		DrawGD.dialog_open(true)
	else:
		delete_tab(tab)


func _on_Tabs_reposition_active_tab_request(idx_to : int) -> void:
	var temp = DrawGD.projects[DrawGD.current_project_index]
	DrawGD.projects.erase(temp)
	DrawGD.projects.insert(idx_to, temp)

	# Change save paths
	var temp_save_path = DrawGD.opensave.current_save_paths[DrawGD.current_project_index]
	DrawGD.opensave.current_save_paths[DrawGD.current_project_index] = DrawGD.opensave.current_save_paths[idx_to]
	DrawGD.opensave.current_save_paths[idx_to] = temp_save_path
	var temp_backup_path = DrawGD.opensave.backup_save_paths[DrawGD.current_project_index]
	DrawGD.opensave.backup_save_paths[DrawGD.current_project_index] = DrawGD.opensave.backup_save_paths[idx_to]
	DrawGD.opensave.backup_save_paths[idx_to] = temp_backup_path


func delete_tab(tab : int) -> void:
	remove_tab(tab)
	DrawGD.projects[tab].undo_redo.free()
	DrawGD.opensave.remove_backup(tab)
	DrawGD.opensave.current_save_paths.remove(tab)
	DrawGD.opensave.backup_save_paths.remove(tab)
	DrawGD.projects.remove(tab)
	if tab > 0:
		DrawGD.current_project_index -= 1
	else:
		DrawGD.current_project_index = 0
	if DrawGD.unsaved_changes_dialog.is_connected("confirmed", self, "delete_tab"):
		DrawGD.unsaved_changes_dialog.disconnect("confirmed", self, "delete_tab")

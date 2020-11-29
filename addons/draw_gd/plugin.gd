tool
extends EditorPlugin

func has_main_screen():
	return true
	
func get_plugin_icon():
	
	return null
	
func get_plugin_name():
	return "DrawGD"
	

func _enter_tree():
	#add_autoload_singleton("DrawGD", "res://addons/draw_gd/src/Autoload/DrawGD.gd")
	
	pass

func _exit_tree():
	#remove_autoload_singleton("DrawGD")
	
	
	pass

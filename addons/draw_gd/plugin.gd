tool
extends EditorPlugin

const _icon : Texture = preload("res://addons/draw_gd/icons/icon_copy.png")
const _scene : PackedScene = preload("res://addons/draw_gd/src/Main.tscn")

var main_node : Node = null

func has_main_screen():
	return true
	
func get_plugin_icon():
	return _icon
	
func get_plugin_name():
	return "DrawGD"
	

func _enter_tree():
	#add_autoload_singleton("DrawGD", "res://addons/draw_gd/src/Autoload/DrawGD.gd")
	
	main_node = _scene.instance()
	
	get_editor_interface().get_editor_viewport().add_child(main_node)
	
	make_visible(false)
	

func _exit_tree():
	#remove_autoload_singleton("DrawGD")
	
	if main_node:
		main_node.queue_free()


func make_visible(visible):
	if !main_node:
		return
	
	if visible:
		main_node.show()
	else:
		main_node.hide()
		
		

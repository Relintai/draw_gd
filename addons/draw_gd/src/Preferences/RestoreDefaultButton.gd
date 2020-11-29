tool
extends TextureButton


var setting_name : String
var value_type : String
var default_value
var node : Node

var DrawGD : Node = null


func _ready() -> void:
	# Handle themes
	if DrawGD.theme_type == DrawGD.Theme_Types.LIGHT:
		texture_normal = load("res://addons/draw_gd/assets/graphics/light_themes/misc/icon_reload.png")
	elif DrawGD.theme_type == DrawGD.Theme_Types.CARAMEL:
		texture_normal = load("res://addons/draw_gd/assets/graphics/caramel_themes/misc/icon_reload.png")


func _on_RestoreDefaultButton_pressed() -> void:
	DrawGD.set(setting_name, default_value)
	DrawGD.config_cache.set_value("preferences", setting_name, default_value)
	DrawGD.preferences_dialog.preference_update(setting_name)
	DrawGD.preferences_dialog.disable_restore_default_button(self, true)
	node.set(value_type, default_value)

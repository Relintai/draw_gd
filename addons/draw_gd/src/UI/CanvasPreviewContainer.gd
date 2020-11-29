tool
extends PanelContainer


onready var canvas_preview = $HBoxContainer/PreviewViewportContainer/Viewport/CanvasPreview
onready var camera : Camera2D = $HBoxContainer/PreviewViewportContainer/Viewport/CameraPreview

var DrawGD : Node = null

func _on_PreviewZoomSlider_value_changed(value : float) -> void:
	camera.zoom = -Vector2(value, value)
	camera.save_values_to_project()
	camera.update_transparent_checker_offset()


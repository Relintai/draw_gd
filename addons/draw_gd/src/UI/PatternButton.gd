tool
extends BaseButton


var pattern := Patterns.Pattern.new()

var DrawGD : Node = null

func _on_PatternButton_pressed() -> void:
	DrawGD.patterns_popup.select_pattern(pattern)

tool
extends Camera2D


var tween : Tween
var zoom_min := Vector2(0.005, 0.005)
var zoom_max := Vector2.ONE
var viewport_container : ViewportContainer
var transparent_checker : ColorRect
var mouse_pos := Vector2.ZERO
var drag := false

var DrawGD : Node = null

func _enter_tree():
	var n : Node = get_parent()
	while n:
		if n.name == "DrawGDSingleton":
			DrawGD = n
			break
		n = n.get_parent()

	viewport_container = get_parent().get_parent()
	transparent_checker = get_parent().get_node("TransparentChecker")
	tween = Tween.new()
	add_child(tween)
	tween.connect("tween_step", self, "_on_tween_step")
	update_transparent_checker_offset()


func update_transparent_checker_offset() -> void:
	var o = get_global_transform_with_canvas().get_origin()
	var s = get_global_transform_with_canvas().get_scale()
	o.y = get_viewport_rect().size.y - o.y
	transparent_checker.update_offset(o, s)

# Get the speed multiplier for when you've pressed
# a movement key for the given amount of time
func dir_move_zoom_multiplier(press_time : float) -> float:
	if press_time < 0:
		return 0.0
	if Input.is_key_pressed(KEY_SHIFT) and Input.is_key_pressed(KEY_CONTROL) :
		return DrawGD.high_speed_move_rate
	elif Input.is_key_pressed(KEY_SHIFT):
		return DrawGD.medium_speed_move_rate
	elif !Input.is_key_pressed(KEY_CONTROL):
		# control + right/left is used to move frames so
		# we do this check to ensure that there is no conflict
		return DrawGD.low_speed_move_rate
	else:
		return 0.0


func reset_dir_move_time(direction) -> void:
	DrawGD.key_move_press_time[direction] = 0.0


const key_move_action_names := ["ui_up", "ui_down", "ui_left", "ui_right"]

# Check if an event is a ui_up/down/left/right event-press :)
func is_action_direction_pressed(event : InputEvent, allow_echo: bool = true) -> bool:
	for action in key_move_action_names:
		if event.is_action_pressed(action, allow_echo):
			return true
	return false


# Check if an event is a ui_up/down/left/right event release nya
func is_action_direction_released(event: InputEvent) -> bool:
	for action in key_move_action_names:
		if event.is_action_released(action):
			return true
	return false


# get the Direction associated with the event.
# if not a direction event return null
func get_action_direction(event: InputEvent):  # -> Optional[Direction]
	if event.is_action("ui_up"):
		return DrawGD.Direction.UP
	elif event.is_action("ui_down"):
		return DrawGD.Direction.DOWN
	elif event.is_action("ui_left"):
		return DrawGD.Direction.LEFT
	elif event.is_action("ui_right"):
		return DrawGD.Direction.RIGHT
	return null


# Holds sign multipliers for the given directions nyaa
# (per the indices in DrawGD.gd defined by Direction)
# UP, DOWN, LEFT, RIGHT in that order
const directional_sign_multipliers := [
	Vector2(0.0, -1.0),
	Vector2(0.0, 1.0),
	Vector2(-1.0, 0.0),
	Vector2(1.0, 0.0)
]


# Process an action event for a pressed direction
# action
func process_direction_action_pressed(event: InputEvent) -> void:
	var dir = get_action_direction(event)
	if dir == null:
		return
	var increment := get_process_delta_time()
	# Count the total time we've been doing this ^.^
	DrawGD.key_move_press_time[dir] += increment
	var this_direction_press_time : float = DrawGD.key_move_press_time[dir]
	var move_speed := dir_move_zoom_multiplier(this_direction_press_time)
	offset = offset + move_speed * increment * directional_sign_multipliers[dir] * zoom
	update_rulers()
	update_transparent_checker_offset()


# Process an action for a release direction action
func process_direction_action_released(event: InputEvent) -> void:
	var dir = get_action_direction(event)
	if dir == null:
		return
	reset_dir_move_time(dir)


func _input(event : InputEvent) -> void:
	mouse_pos = viewport_container.get_local_mouse_position()
	var viewport_size := viewport_container.rect_size
	if event.is_action_pressed("middle_mouse") || event.is_action_pressed("space"):
		drag = true
	elif event.is_action_released("middle_mouse") || event.is_action_released("space"):
		drag = false

	if DrawGD.can_draw && Rect2(Vector2.ZERO, viewport_size).has_point(mouse_pos):
		if event.is_action_pressed("zoom_in"): # Wheel Up Event
			zoom_camera(-1)
		elif event.is_action_pressed("zoom_out"): # Wheel Down Event
			zoom_camera(1)
		elif event is InputEventMouseMotion && drag:
			offset = offset - event.relative * zoom
			update_transparent_checker_offset()
			update_rulers()
		elif is_action_direction_pressed(event):
			process_direction_action_pressed(event)
		elif is_action_direction_released(event):
			process_direction_action_released(event)

		save_values_to_project()


# Zoom Camera
func zoom_camera(dir : int) -> void:
	var viewport_size := viewport_container.rect_size
	if DrawGD.smooth_zoom:
		var zoom_margin = zoom * dir / 5
		var new_zoom = zoom + zoom_margin
		if new_zoom > zoom_min && new_zoom < zoom_max:
			var new_offset = offset + (-0.5 * viewport_size + mouse_pos) * (zoom - new_zoom)
			tween.interpolate_property(self, "zoom", zoom, new_zoom, 0.05, Tween.TRANS_LINEAR, Tween.EASE_IN)
			tween.interpolate_property(self, "offset", offset, new_offset, 0.05, Tween.TRANS_LINEAR, Tween.EASE_IN)
			tween.start()

	else:
		var prev_zoom := zoom
		var zoom_margin = zoom * dir / 10
		if zoom + zoom_margin > zoom_min:
			zoom += zoom_margin

		if zoom > zoom_max:
			zoom = zoom_max

		offset = offset + (-0.5 * viewport_size + mouse_pos) * (prev_zoom - zoom)
		zoom_changed()


func zoom_changed() -> void:
	update_transparent_checker_offset()
	if name == "Camera2D":
		DrawGD.zoom_level_label.text = str(round(100 / zoom.x)) + " %"
		update_rulers()
		for guide in DrawGD.current_project.guides:
			guide.width = zoom.x * 2
	elif name == "CameraPreview":
		DrawGD.preview_zoom_slider.value = -zoom.x


func update_rulers() -> void:
	DrawGD.horizontal_ruler.update()
	DrawGD.vertical_ruler.update()


func _on_tween_step(_object: Object, _key: NodePath, _elapsed: float, _value: Object) -> void:
	zoom_changed()


func zoom_100() -> void:
	zoom = Vector2.ONE
	offset = DrawGD.current_project.size / 2
	zoom_changed()


func fit_to_frame(size : Vector2) -> void:
	viewport_container = get_parent().get_parent()
	var h_ratio := viewport_container.rect_size.x / size.x
	var v_ratio := viewport_container.rect_size.y / size.y
	var ratio := min(h_ratio, v_ratio)
	if ratio == 0:
		ratio = 0.1 # Set it to a non-zero value just in case
		# If the ratio is 0, it means that the viewport container is hidden
		# in that case, use the other viewport to get the ratio
		if name == "Camera2D":
			h_ratio = DrawGD.second_viewport.rect_size.x / size.x
			v_ratio = DrawGD.second_viewport.rect_size.y / size.y
			ratio = min(h_ratio, v_ratio)
		elif name == "Camera2D2":
			h_ratio = DrawGD.main_viewport.rect_size.x / size.x
			v_ratio = DrawGD.main_viewport.rect_size.y / size.y
			ratio = min(h_ratio, v_ratio)

	zoom = Vector2(1 / ratio, 1 / ratio)
	offset = size / 2
	zoom_changed()


func save_values_to_project() -> void:
	if name == "Camera2D":
		DrawGD.current_project.cameras_zoom[0] = zoom
		DrawGD.current_project.cameras_offset[0] = offset
	elif name == "Camera2D2":
		DrawGD.current_project.cameras_zoom[1] = zoom
		DrawGD.current_project.cameras_offset[1] = offset
	elif name == "CameraPreview":
		DrawGD.current_project.cameras_zoom[2] = zoom
		DrawGD.current_project.cameras_offset[2] = offset

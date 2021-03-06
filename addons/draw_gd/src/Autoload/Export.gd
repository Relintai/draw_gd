tool
extends Node

var DrawGD : Node = null

# Frame options
var frame_number := 0

# All frames and their layers processed/blended into images
var processed_images = [] # Image[]

# Spritesheet options
var frame_current_tag := 0 # Export only current frame tag
var number_of_frames := 1
enum Orientation { ROWS = 0, COLUMNS = 1 }
var orientation : int = Orientation.ROWS
# How many rows/columns before new line is added
var lines_count := 1

# Animation options
enum AnimationType { MULTIPLE_FILES = 0, ANIMATED = 1 }
var animation_type : int = AnimationType.MULTIPLE_FILES
enum AnimationDirection { FORWARD = 0, BACKWARDS = 1, PING_PONG = 2 }
var direction : int = AnimationDirection.FORWARD

# Options
var resize := 100
var interpolation := 0 # Image.Interpolation
var new_dir_for_each_frame_tag : bool = true # you don't need to store this after export

# Export directory path and export file name
var directory_path := ""
var file_name := "untitled"
var file_format : int = FileFormat.PNG
enum FileFormat { PNG = 0}

var was_exported : bool = false

# Export coroutine signal
var stop_export = false

var file_exists_alert = "File %s already exists. Overwrite?"

# Export progress variables
var export_progress_fraction := 0.0
var export_progress := 0.0


func external_export() -> void:
	process_frame()
	export_processed_images(true, DrawGD.export_dialog)


func process_frame() -> void:
	processed_images.clear()
	var frame = DrawGD.current_project.frames[frame_number - 1]
	var image := Image.new()
	image.create(DrawGD.current_project.size.x, DrawGD.current_project.size.y, false, Image.FORMAT_RGBA8)
	blend_layers(image, frame)
	processed_images.append(image)

func export_processed_images(ignore_overwrites: bool, export_dialog: AcceptDialog ) -> bool:
	# Stop export if directory path or file name are not valid
	var dir = Directory.new()
	if not dir.dir_exists(directory_path) or not file_name.is_valid_filename():
		export_dialog.open_path_validation_alert_popup()
		return false

	# Check export paths
	var export_paths = []
	for i in range(processed_images.size()):
		stop_export = false
		var multiple_files := false
		var export_path = create_export_path(multiple_files, i + 1)
		# If user want to create new directory for each animation tag then check if directories exist and create them if not
		if multiple_files and new_dir_for_each_frame_tag:
			var frame_tag_directory := Directory.new()
			if not frame_tag_directory.dir_exists(export_path.get_base_dir()):
				frame_tag_directory.open(directory_path)
				frame_tag_directory.make_dir(export_path.get_base_dir().get_file())
		# Check if the file already exists
		var fileCheck = File.new()
		if fileCheck.file_exists(export_path):
			# Ask user if he want's to overwrite the file
			if not was_exported or (was_exported and not ignore_overwrites):
				# Overwrite existing file?
				export_dialog.open_file_exists_alert_popup(file_exists_alert % export_path)
				# Stops the function until the user decides if he want's to overwrite
				yield(export_dialog, "resume_export_function")
				if stop_export:
					# User decided to stop export
					return
		export_paths.append(export_path)
		
		# Only get one export path if single file animated image is exported
#		if current_tab == ExportTab.ANIMATION and animation_type == AnimationType.ANIMATED:
#			break

	# Scale images that are to export
	scale_processed_images()

	for i in range(processed_images.size()):
		var err = processed_images[i].save_png(export_paths[i])
		if err != OK:
			OS.alert("Can't save file. Error code: %s" % err)

	# Store settings for quick export and when the dialog is opened again
	was_exported = true
	DrawGD.file_menu.get_popup().set_item_text(5, tr("Export") + " %s" % (file_name + file_format_string(file_format)))

	return true

func increase_export_progress(export_dialog: Node) -> void:
	export_progress += export_progress_fraction
	export_dialog.set_export_progress_bar(export_progress)


func scale_processed_images() -> void:
	for processed_image in processed_images:
		if resize != 100:
			processed_image.unlock()
			processed_image.resize(processed_image.get_size().x * resize / 100, processed_image.get_size().y * resize / 100, interpolation)


func file_format_string(format_enum : int) -> String:
	match format_enum:
		0: # PNG
			return '.png'
		_:
			return ''


func create_export_path(multifile: bool, frame: int = 0) -> String:
	var path = file_name
	# Only append frame number when there are multiple files exported
	if multifile:
		var frame_tag_and_start_id = get_proccessed_image_animation_tag_and_start_id(frame - 1)
		# Check if exported frame is in frame tag
		if frame_tag_and_start_id != null:
			var frame_tag = frame_tag_and_start_id[0]
			var start_id = frame_tag_and_start_id[1]
			# Remove unallowed characters in frame tag directory
			var regex := RegEx.new()
			regex.compile("[^a-zA-Z0-9_]+")
			var frame_tag_dir = regex.sub(frame_tag, "", true)
			if new_dir_for_each_frame_tag:
				# Add frame tag if frame has one
				# (frame - start_id + 1) Makes frames id to start from 1 in each frame tag directory
				path += "_" + frame_tag_dir + "_" + String(frame - start_id + 1)
				return directory_path.plus_file(frame_tag_dir).plus_file(path + file_format_string(file_format))
			else:
				# Add frame tag if frame has one
				# (frame - start_id + 1) Makes frames id to start from 1 in each frame tag
				path += "_" + frame_tag_dir + "_" + String(frame - start_id + 1)
		else:
			path += "_" + String(frame)

	return directory_path.plus_file(path + file_format_string(file_format))


func get_proccessed_image_animation_tag_and_start_id(processed_image_id : int) -> Array:
	var result_animation_tag_and_start_id = null
	for animation_tag in DrawGD.current_project.animation_tags:
		# Check if processed image is in frame tag and assign frame tag and start id if yes
		# Then stop
		if (processed_image_id + 1) >= animation_tag.from and (processed_image_id + 1) <= animation_tag.to:
			result_animation_tag_and_start_id = [animation_tag.name, animation_tag.from]
			break
	return result_animation_tag_and_start_id


# Blends canvas layers into passed image starting from the origin position
func blend_layers(image : Image, frame : Frame, origin : Vector2 = Vector2(0, 0)) -> void:
	image.lock()
	var layer_i := 0
	for cel in frame.cels:
		if DrawGD.current_project.layers[layer_i].visible:
			var cel_image := Image.new()
			cel_image.copy_from(cel.image)
			cel_image.lock()
			if cel.opacity < 1: # If we have cel transparency
				for xx in cel_image.get_size().x:
					for yy in cel_image.get_size().y:
						var pixel_color := cel_image.get_pixel(xx, yy)
						var alpha : float = pixel_color.a * cel.opacity
						cel_image.set_pixel(xx, yy, Color(pixel_color.r, pixel_color.g, pixel_color.b, alpha))
			image.blend_rect(cel_image, Rect2(DrawGD.canvas.location, DrawGD.current_project.size), origin)
			cel_image.unlock()
		layer_i += 1
	image.unlock()


func frames_divided_by_spritesheet_lines() -> int:
	return int(ceil(number_of_frames / float(lines_count)))

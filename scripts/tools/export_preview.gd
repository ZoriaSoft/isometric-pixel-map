extends SceneTree
## Headless: write demo map PNG to user:// and project screenshots folder.


func _init() -> void:
	var m := MapData.make_seed()
	var img := PngExporter.render_map(m, 2)
	var err := img.save_png("user://demo_village.png")
	print("user://demo_village.png err=", err, " size=", img.get_width(), "x", img.get_height())
	# also try project-relative via absolute if possible
	var dir := DirAccess.open("res://")
	if dir:
		dir.make_dir_recursive("screenshots")
	err = img.save_png("res://screenshots/demo_village.png")
	# res:// write may fail on export; use absolute via OS
	if err != OK:
		var abs_path := ProjectSettings.globalize_path("res://screenshots/demo_village.png")
		# ensure dir
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://screenshots"))
		err = img.save_png(abs_path)
		print("abs save ", abs_path, " err=", err)
	else:
		print("saved res://screenshots/demo_village.png")
	quit(0 if err == OK else 1)

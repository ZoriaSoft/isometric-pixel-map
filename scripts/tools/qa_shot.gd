extends Node
## QA screenshot runner — geçici. 3 boyutta bar konumu testi.

func _ready() -> void:
	await _settle(1.0)
	var img := get_viewport().get_texture().get_image()
	img.save_png("res://screenshots/qa_size_test.png")
	print("QA_SHOT: saved (viewport ", get_viewport().get_visible_rect().size, ")")
	get_tree().quit()


func _settle(secs: float) -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().create_timer(secs).timeout

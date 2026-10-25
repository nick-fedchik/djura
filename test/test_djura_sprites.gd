extends SceneTree
## Verifies Djura hero 3D-to-2D sprite package in Godot engine.
## Follows SHR-004, SWR-003, and Invariants I-3, I-4.

func _init() -> void:
	var passed = true
	var sheet_path = "res://assets/sprites/djura_sheet.png"
	var frames_path = "res://assets/sprites/djura_frames.tres"
	var manifest_path = "res://assets/sprites/djura_manifest.json"

	# 1. Texture check
	if not FileAccess.file_exists(sheet_path):
		printerr("FAIL: Djura sheet texture does not exist: ", sheet_path)
		passed = false

	# 2. Manifest check
	if not FileAccess.file_exists(manifest_path):
		printerr("FAIL: Djura manifest JSON does not exist: ", manifest_path)
		passed = false
	else:
		var f = FileAccess.open(manifest_path, FileAccess.READ)
		var json = JSON.new()
		var parse_res = json.parse(f.get_as_text())
		if parse_res != OK:
			printerr("FAIL: Invalid Djura manifest JSON")
			passed = false
		else:
			var data = json.data
			if not data.has("pivot_point") or not data.has("frames") or data.frames.size() < 20:
				printerr("FAIL: Djura manifest missing pivot_point or frames count is too small")
				passed = false

	# 3. SpriteFrames resource check
	if not FileAccess.file_exists(frames_path):
		printerr("FAIL: Djura SpriteFrames resource does not exist: ", frames_path)
		passed = false
	else:
		var frames_res = load(frames_path)
		if not (frames_res is SpriteFrames):
			printerr("FAIL: Djura resource is not of type SpriteFrames: ", frames_path)
			passed = false
		else:
			var required_anims = ["idle", "run", "jump", "glide", "hopak_kick", "bonk", "victory"]
			var anim_names = frames_res.get_animation_names()

			for req_anim in required_anims:
				if not anim_names.has(req_anim):
					printerr("FAIL: Djura SpriteFrames missing required animation: ", req_anim)
					passed = false
				else:
					var count = frames_res.get_frame_count(req_anim)
					if count <= 0:
						printerr("FAIL: Animation ", req_anim, " has 0 frames")
						passed = false
					for i in range(count):
						var tex = frames_res.get_frame_texture(req_anim, i)
						if tex == null:
							printerr("FAIL: Frame texture is null for ", req_anim, " at index ", i)
							passed = false
							break

	if passed:
		print("PASSED: Djura Hero 2D Sprite Package verified successfully in Godot!")
		quit(0)
	else:
		printerr("FAILED: Djura Hero Sprite Package verification failed")
		quit(1)

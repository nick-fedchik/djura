extends SceneTree
## Verifies 3D-to-2D sprite pipeline output in Godot engine.
## Follows SWR-003-07 and ADR-003.

func _init() -> void:
	var passed = true
	var sheet_path = "res://assets/sprites/test_cossack_sheet.png"
	var frames_path = "res://assets/sprites/test_cossack_frames.tres"
	var manifest_path = "res://assets/sprites/test_cossack_manifest.json"

	# 1. Texture file check
	if not FileAccess.file_exists(sheet_path):
		printerr("FAIL: Sprite sheet texture does not exist: ", sheet_path)
		passed = false

	# 2. Manifest JSON check
	if not FileAccess.file_exists(manifest_path):
		printerr("FAIL: Sprite manifest JSON does not exist: ", manifest_path)
		passed = false
	else:
		var f = FileAccess.open(manifest_path, FileAccess.READ)
		var json = JSON.new()
		var parse_res = json.parse(f.get_as_text())
		if parse_res != OK:
			printerr("FAIL: Invalid manifest JSON")
			passed = false
		else:
			var data = json.data
			if not data.has("pivot_point") or not data.has("frames") or data.frames.size() == 0:
				printerr("FAIL: Manifest missing pivot_point or frames")
				passed = false

	# 3. SpriteFrames resource check
	if not FileAccess.file_exists(frames_path):
		printerr("FAIL: SpriteFrames resource does not exist: ", frames_path)
		passed = false
	else:
		var frames_res = load(frames_path)
		if not (frames_res is SpriteFrames):
			printerr("FAIL: Resource is not of type SpriteFrames: ", frames_path)
			passed = false
		else:
			var anim_names = frames_res.get_animation_names()
			if not anim_names.has("idle"):
				printerr("FAIL: SpriteFrames missing 'idle' animation")
				passed = false
			else:
				var frame_count = frames_res.get_frame_count("idle")
				if frame_count < 8:
					printerr("FAIL: Expected at least 8 frames for idle, got: ", frame_count)
					passed = false

				for i in range(frame_count):
					var tex = frames_res.get_frame_texture("idle", i)
					if tex == null:
						printerr("FAIL: Frame texture is null at index ", i)
						passed = false
						break
					if tex is AtlasTexture:
						if tex.region.size.x <= 0 or tex.region.size.y <= 0:
							printerr("FAIL: Invalid atlas region for frame ", i)
							passed = false
							break

	if passed:
		print("PASSED: 3D-to-2D Sprite Pipeline verified successfully in Godot!")
		quit(0)
	else:
		printerr("FAILED: 3D-to-2D Sprite Pipeline verification failed")
		quit(1)

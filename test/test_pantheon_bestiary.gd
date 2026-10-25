extends SceneTree
## T-C08: перевірка обов'язкових рантайм-активів Пантеону та Бестіарію
## (docs/PANTHEON_AND_BESTIARY.md): файли існують і завантажуються рушієм.

const TEXTURES := [
	"res://assets/sprites/djura_sheet.png",
	"res://assets/sprites/mentor_portrait.png",
	"res://assets/sprites/vohnyk_sheet.png",
	"res://assets/sprites/qirimli_sheet.png",
	"res://assets/sprites/story/slide_level1_1_meeting.png",
	"res://assets/sprites/story/slide_level1_2_pledge.png",
	"res://assets/sprites/story/slide_level1_3_mission.png",
]
const FRAMES := [
	"res://assets/sprites/djura_frames.tres",
	"res://assets/sprites/vohnyk_frames.tres",
	"res://assets/sprites/qirimli_frames.tres",
]

func _init() -> void:
	var ok := true
	for p in TEXTURES:
		var tex := load(p) as Texture2D
		if tex == null or tex.get_width() <= 0 or tex.get_height() <= 0:
			printerr("[FAIL] текстура відсутня або не завантажується: ", p)
			ok = false
	for p in FRAMES:
		var sf := load(p) as SpriteFrames
		if sf == null:
			printerr("[FAIL] SpriteFrames відсутній або не завантажується: ", p)
			ok = false
			continue
		var total := 0
		for anim in sf.get_animation_names():
			total += sf.get_frame_count(anim)
			for i in sf.get_frame_count(anim):
				if sf.get_frame_texture(anim, i) == null:
					printerr("[FAIL] порожній кадр ", anim, "#", i, " у ", p)
					ok = false
		if total == 0:
			printerr("[FAIL] SpriteFrames без кадрів: ", p)
			ok = false
	if ok:
		print("[OK] test_pantheon_bestiary PASSED")
	quit(0 if ok else 1)

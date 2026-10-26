extends RefCounted
class_name PlayerPose
# Скелетна поза Джури (COD-01): чиста функція від стану гравця, винесена з player.gd без зміни логіки.
# Читає стан із `p` і нічого в ньому не змінює.


static func compute(p: JackPlayer, flip: float, run_anim: float, on_ground: bool) -> Dictionary:
	# Base neutral standing pose (relative to character origin)
	var pelvis := Vector2(0.0, 0.0)
	var torso_angle := 0.0
	var torso_twist := 0.0
	var head_offset := Vector2(0.0, 0.0)
	var punch_streak := Vector2.ZERO

	var hip_l := Vector2(-3.5 * flip, 2.5)
	var hip_r := Vector2(3.5 * flip, 2.5)
	var knee_l := Vector2(-5.5 * flip, 7.5)
	var knee_r := Vector2(5.5 * flip, 7.5)
	var ankle_l := Vector2(-5.5 * flip, 12.2)
	var ankle_r := Vector2(5.5 * flip, 12.2)
	var foot_ang_l := 0.0
	var foot_ang_r := 0.0

	var shoulder_l := Vector2(-4.8 * flip, -8.5)
	var shoulder_r := Vector2(4.8 * flip, -8.5)
	var elbow_l := Vector2(-7.5 * flip, -3.0)
	var elbow_r := Vector2(7.5 * flip, -3.0)
	var wrist_l := Vector2(-6.5 * flip, 2.0)
	var wrist_r := Vector2(6.5 * flip, 2.0)
	var fist_l := false
	var fist_r := false
	var head_facing: float = flip

	if p.is_hopak and not p.hopak_waiting_for_floor:
		var t := p.hopak_time
		if t < 0.68:
			# PHASE 1 (0.00 - 0.68s): "Тичок лівою" - Athletic Horse Stance & Strike to the LEFT!
			var u := clampf(t / 0.68, 0.0, 1.0)
			var strike := sin(pow(u, 0.75) * PI)
			var stance := sin(minf(u * 2.2, 1.0) * PI * 0.5) if u < 0.8 else sin((1.0 - u) / 0.2 * PI * 0.5)

			# Head turns decisively to the LEFT (-1.0)
			head_facing = lerp(0.0, -1.0, smoothstep(0.0, 0.22, u))
			head_offset = Vector2(-2.2 * strike, 0.5 * strike)

			pelvis = Vector2(-2.0 * strike, 3.2 * stance)
			torso_angle = -0.11 * strike
			torso_twist = -0.65 * strike

			# Wide horse-stance articulated legs
			knee_l = pelvis + Vector2(-11.5, 5.0)
			ankle_l = Vector2(-11.0, 12.2)
			knee_r = pelvis + Vector2(10.0, 5.0)
			ankle_r = Vector2(9.5, 12.2)

			# Lead LEFT arm uncoils from guard into a straight punch to the LEFT!
			# Посилення розмаху та ударної хвилі при вивченні Сталевого Тичка Володимира Кличка
			var jab_reach := 29.5 if JackPlayer.ChampionSkill.STEELHAMMER_JAB in p.unlocked_skills else 22.5
			elbow_l = pelvis + Vector2(-3.0, -3.5).lerp(Vector2(-12.5, -9.2), strike)
			wrist_l = pelvis + Vector2(-2.0, -7.5).lerp(Vector2(-jab_reach, -9.5), strike)
			fist_l = true
			if strike > 0.65:
				punch_streak = pelvis + Vector2(-jab_reach - 3.0, -9.5)

			# Rear RIGHT arm chambers tightly at ribs on the right
			elbow_r = pelvis + Vector2(6.0, -3.0).lerp(Vector2(9.5, -2.5), strike)
			wrist_r = pelvis + Vector2(5.0, 1.0).lerp(Vector2(2.5, -4.5), strike)
			fist_r = true

		elif t < 1.36:
			# PHASE 2 (0.68 - 1.36s): "Козацький хрест правою" - Strike to the RIGHT!
			var u := clampf((t - 0.68) / 0.68, 0.0, 1.0)
			var strike := sin(pow(u, 0.72) * PI)

			# Head whips dynamically from LEFT (-1.0) to the RIGHT (+1.0)!
			head_facing = lerp(-1.0, 1.0, smoothstep(0.0, 0.28, u))
			head_offset = Vector2(2.2 * strike, 0.8 * strike)

			pelvis = Vector2(3.5 * strike, 3.8 * strike)
			torso_angle = 0.15 * strike
			torso_twist = 0.80 * strike

			# Rear knee drives forward as hip pivots into the cross
			knee_l = pelvis + Vector2(-7.5, 5.5)
			ankle_l = Vector2(-11.0, 12.2)
			foot_ang_l = -0.18 * strike
			knee_r = pelvis + Vector2(11.5, 4.8)
			ankle_r = Vector2(10.5, 12.2)

			# Lead LEFT arm retracts to high cheek guard on the left
			elbow_l = pelvis + Vector2(-8.5, -2.0)
			wrist_l = pelvis + Vector2(-1.5, -9.0)
			fist_l = true

			# Rear RIGHT arm unleashes full cross punch to the RIGHT!
			# Посилення розмаху при вивченні Залізного Хреста Віталія Кличка
			var cross_reach := 31.5 if JackPlayer.ChampionSkill.IRONFIST_HOOK in p.unlocked_skills else 23.0
			elbow_r = pelvis + Vector2(3.0, -3.0).lerp(Vector2(12.5, -8.8), strike)
			wrist_r = pelvis + Vector2(1.0, -5.0).lerp(Vector2(cross_reach, -8.8), strike)
			fist_r = true
			if strike > 0.65:
				punch_streak = pelvis + Vector2(cross_reach + 3.0, -8.8)

		elif t < 2.06:
			# PHASE 3 (1.36 - 2.06s): "Тинок лівою" - High Flying Kick to the LEFT!
			var u := clampf((t - 1.36) / 0.70, 0.0, 1.0)
			var jump_arc := sin(u * PI)
			var kick_ext := sin(clampf((u - 0.08) / 0.84, 0.0, 1.0) * PI)

			# Head turns sharply to the LEFT (-1.0) tracking the high kick
			head_facing = lerp(1.0, -1.0, smoothstep(0.0, 0.25, u))
			head_offset = Vector2(-1.5 * kick_ext, -1.0 * jump_arc)

			# Whole body leaps 26px into the air!
			pelvis = Vector2(1.5 * kick_ext, -25.0 * jump_arc)
			torso_angle = 0.26 * kick_ext
			torso_twist = 0.35 * kick_ext

			# Supporting RIGHT leg tucks athletically under the airborne pelvis
			knee_r = pelvis + Vector2(5.5, 7.5).lerp(Vector2(8.5, 5.5), jump_arc)
			ankle_r = pelvis + Vector2(5.5, 12.2).lerp(Vector2(11.5, 10.5), jump_arc)
			foot_ang_r = -0.45 * jump_arc

			# LEFT kicking leg chambers high and snaps shin & boot to the LEFT!
			knee_l = pelvis + Vector2(-5.5, 7.5).lerp(Vector2(-10.5, -4.5), kick_ext)
			ankle_l = pelvis + Vector2(-5.5, 12.2).lerp(Vector2(-20.5, -12.5), kick_ext)
			foot_ang_l = 0.72 * kick_ext

			# Arms sweep wide like eagle wings for mid-air balance
			elbow_l = pelvis + Vector2(-12.5, -10.5 * jump_arc - 3.0)
			wrist_l = pelvis + Vector2(-20.0, -14.5 * jump_arc - 2.0)
			elbow_r = pelvis + Vector2(10.5, -9.5 * jump_arc - 3.0)
			wrist_r = pelvis + Vector2(17.5, -12.0 * jump_arc - 2.0)

		elif t < 2.76:
			# PHASE 4 (2.06 - 2.76s): "Повітряний Щупак / Різножка 180°" - Symmetrical Leap!
			var u := clampf((t - 2.06) / 0.70, 0.0, 1.0)
			var jump_arc := sin(u * PI)
			var split_ext := sin(clampf((u - 0.06) / 0.88, 0.0, 1.0) * PI)

			# Head centers proudly forward (0.0) facing the audience/screen!
			head_facing = lerp(-1.0, 0.0, smoothstep(0.0, 0.30, u))
			head_offset = Vector2(0.0, 1.4 * split_ext)

			# Explosive leap into the air (посилений олімпійський стрибок Олександра Усика)!
			var leap_height := 38.0 if JackPlayer.ChampionSkill.USYK_SLIP_COUNTER in p.unlocked_skills else 31.0
			pelvis = Vector2(0.0, -leap_height * jump_arc)
			torso_angle = 0.0
			torso_twist = 0.0

			# Symmetrical 180-degree horizontal split (both left and right)!
			knee_l = pelvis + Vector2(-5.5, 7.5).lerp(Vector2(-12.0, 1.5), split_ext)
			ankle_l = pelvis + Vector2(-5.5, 12.2).lerp(Vector2(-22.5, -1.5), split_ext)
			foot_ang_l = -0.65 * split_ext

			knee_r = pelvis + Vector2(5.5, 7.5).lerp(Vector2(12.0, 1.5), split_ext)
			ankle_r = pelvis + Vector2(5.5, 12.2).lerp(Vector2(22.5, -1.5), split_ext)
			foot_ang_r = 0.65 * split_ext

			# Both articulated arms reach down & outward to touch both boot tips
			elbow_l = pelvis + Vector2(-10.5, -4.5)
			wrist_l = pelvis + Vector2(-7.0, 1.0).lerp(Vector2(-18.5, -2.5), split_ext)
			elbow_r = pelvis + Vector2(10.5, -4.5)
			wrist_r = pelvis + Vector2(7.0, 1.0).lerp(Vector2(18.5, -2.5), split_ext)

		elif t < 3.44:
			# PHASE 5 (2.76 - 3.44s): "Низький Повзунець / Пістоль правою" - Sweep to the RIGHT!
			var u := clampf((t - 2.76) / 0.68, 0.0, 1.0)
			var squat_ext := sin(u * PI)

			# Head turns decisively to the RIGHT (+1.0) tracking the ground sweep
			head_facing = lerp(0.0, 1.0, smoothstep(0.0, 0.28, u))
			head_offset = Vector2(1.8 * squat_ext, 0.0)

			# Pelvis drops deeply down (+8.2px) over supporting left heel
			pelvis = Vector2(-2.0 * squat_ext, 8.2 * squat_ext)
			torso_angle = 0.08 * squat_ext
			torso_twist = 0.35 * squat_ext

			# Supporting left leg deeply flexed
			knee_l = Vector2(-5.5, 7.5).lerp(Vector2(-11.5, 6.5), squat_ext)
			ankle_l = Vector2(-5.5, 12.2).lerp(Vector2(-4.5, 12.4), squat_ext)

			# Right leg shoots straight out horizontally to the RIGHT
			knee_r = Vector2(5.5, 7.5).lerp(Vector2(11.0, 11.2), squat_ext)
			ankle_r = Vector2(5.5, 12.2).lerp(Vector2(21.5, 12.0), squat_ext)
			foot_ang_r = 0.45 * squat_ext

			# Proud Cossack crossed arms over the chest ("Руки хрестом на грудях")
			elbow_l = pelvis + Vector2(-7.5, -3.0).lerp(Vector2(-10.5, -2.5), squat_ext)
			wrist_l = pelvis + Vector2(-6.5, 2.0).lerp(Vector2(4.0, -3.8), squat_ext)
			fist_l = true
			elbow_r = pelvis + Vector2(7.5, -3.0).lerp(Vector2(10.5, -2.5), squat_ext)
			wrist_r = pelvis + Vector2(6.5, 2.0).lerp(Vector2(-4.0, -3.2), squat_ext)
			fist_r = true

		else:
			# PHASE 6 (3.44 - 4.10s): "Козак у поли / Руки в боки" - Symmetrical Victory Stance!
			var u := clampf((t - 3.44) / 0.66, 0.0, 1.0)
			var pose_hold := sin(minf(u * 2.5, 1.0) * PI * 0.5)
			if u > 0.85:
				pose_hold *= (1.0 - (u - 0.85) / 0.15)
			var breath := sin(u * PI * 2.0) * 0.8

			# Head returns to CENTER (0.0), nodding proudly at the player!
			head_facing = lerp(1.0, 0.0, smoothstep(0.0, 0.32, u))
			head_offset = Vector2(0.0, -0.8 * pose_hold)

			pelvis = Vector2(0.0, -0.8 * pose_hold + breath * 0.4)
			torso_angle = 0.0
			torso_twist = 0.0

			# Proud symmetrical athletic stance
			knee_l = Vector2(-6.5, 7.2)
			ankle_l = Vector2(-6.0, 12.2)
			knee_r = Vector2(6.5, 7.2)
			ankle_r = Vector2(6.0, 12.2)

			# Symmetrical "Руки в боки" (Both hands on golden sash, sharp flared elbows)
			elbow_l = pelvis + Vector2(-7.5, -3.0).lerp(Vector2(-12.5, -3.8), pose_hold)
			wrist_l = pelvis + Vector2(-6.5, 2.0).lerp(Vector2(-6.2, 1.2), pose_hold)
			fist_l = true
			elbow_r = pelvis + Vector2(7.5, -3.0).lerp(Vector2(12.5, -3.8), pose_hold)
			wrist_r = pelvis + Vector2(6.5, 2.0).lerp(Vector2(6.2, 1.2), pose_hold)
			fist_r = true

	elif p.is_gliding or p.flap_timer > 0.0:
		var flap_lift := sin(p.time_passed * 24.0) * 2.5
		pelvis = Vector2(0.0, -1.0)
		knee_l = Vector2(-5.5 * flip, 6.5)
		ankle_l = Vector2(-7.5 * flip, 11.5)
		foot_ang_l = 0.25 * flip
		knee_r = Vector2(5.5 * flip, 6.5)
		ankle_r = Vector2(4.0 * flip, 11.5)
		foot_ang_r = 0.20 * flip

		elbow_l = Vector2(-13.0 * flip, -12.0 + flap_lift * 0.5)
		wrist_l = Vector2(-24.0 * flip, -16.0 + flap_lift)
		elbow_r = Vector2(13.0 * flip, -10.0 + flap_lift * 0.5)
		wrist_r = Vector2(24.0 * flip, -12.0 + flap_lift)

	elif p.is_fast_dropping:
		pelvis = Vector2(0.0, 1.0)
		knee_l = Vector2(-5.0 * flip, 6.0)
		ankle_l = Vector2(-4.0 * flip, 12.0)
		knee_r = Vector2(5.0 * flip, 6.0)
		ankle_r = Vector2(4.0 * flip, 12.0)
		elbow_l = Vector2(-8.0 * flip, -12.0)
		wrist_l = Vector2(-6.0 * flip, -18.5)
		elbow_r = Vector2(8.0 * flip, -12.0)
		wrist_r = Vector2(6.0 * flip, -18.5)

	elif p.is_rolling:
		# Акробатичний козацький перекат після падіння (групування тіла в колесо)
		var roll_prog := clampf(1.0 - (p.roll_timer / maxf(p.roll_duration, 0.01)), 0.0, 1.0)
		torso_angle = roll_prog * TAU * p.roll_dir
		pelvis = Vector2(0.0, 3.5)
		head_offset = Vector2(0.0, 2.0)

		# Підібгані до грудей козацькі ноги в шароварах
		knee_l = pelvis + Vector2(-6.0 * p.roll_dir, 4.0)
		ankle_l = pelvis + Vector2(-2.5 * p.roll_dir, 2.0)
		foot_ang_l = 0.45 * p.roll_dir
		knee_r = pelvis + Vector2(6.0 * p.roll_dir, 4.0)
		ankle_r = pelvis + Vector2(2.5 * p.roll_dir, 2.0)
		foot_ang_r = -0.45 * p.roll_dir

		# Руки охоплюють коліна для перекату
		elbow_l = pelvis + Vector2(-8.0 * p.roll_dir, -2.0)
		wrist_l = pelvis + Vector2(-2.0 * p.roll_dir, 3.0)
		fist_l = true
		elbow_r = pelvis + Vector2(8.0 * p.roll_dir, -2.0)
		wrist_r = pelvis + Vector2(2.0 * p.roll_dir, 3.0)
		fist_r = true

	elif p.squat_timer > 0.0:
		# Deep 3-point parkour superhero landing
		pelvis = Vector2(1.0 * flip, 5.5)
		torso_angle = 0.22 * flip
		knee_l = Vector2(-9.5 * flip, 8.5)
		ankle_l = Vector2(-7.5 * flip, 12.4)
		knee_r = Vector2(10.5 * flip, 7.5)
		ankle_r = Vector2(8.5 * flip, 12.4)

		# Right hand planted on ground, left arm counter-balancing back
		elbow_r = pelvis + Vector2(6.5 * flip, 1.0)
		wrist_r = Vector2(7.5 * flip, 14.5)
		elbow_l = pelvis + Vector2(-8.5 * flip, -4.0)
		wrist_l = pelvis + Vector2(-13.5 * flip, -1.0)

	elif not on_ground:
		# Athletic airborne parkour jump pose (one knee tucked high, one trailing)
		pelvis = Vector2(0.0, -1.5)
		knee_l = Vector2(-6.0 * flip, 6.5)
		ankle_l = Vector2(-9.5 * flip, 11.5)
		foot_ang_l = 0.30 * flip
		knee_r = Vector2(8.5 * flip, 4.0)
		ankle_r = Vector2(6.0 * flip, 9.5)
		foot_ang_r = 0.15 * flip

		elbow_l = Vector2(-9.5 * flip, -5.0)
		wrist_l = Vector2(-12.5 * flip, -1.0)
		elbow_r = Vector2(8.5 * flip, -6.5)
		wrist_r = Vector2(12.5 * flip, -9.5)

	else:
		# Dynamic anatomical ground sprint / idle breathing
		var is_running := absf(p.velocity.x) > 15.0
		var idle_breath := sin(p.time_passed * 3.8) * 0.6 if not is_running else 0.0
		var bounce := absf(run_anim) * -1.8 if is_running else idle_breath
		pelvis = Vector2(0.0, bounce)

		# 2-joint running stride with realistic knee lift
		var stride_l := run_anim
		var stride_r := -run_anim
		knee_l = pelvis + Vector2((-4.5 + stride_l * 6.5) * flip, 7.2 - maxf(0.0, stride_l) * 2.5)
		ankle_l = Vector2((-4.8 + stride_l * 8.0) * flip, 12.2 - maxf(0.0, stride_l) * 2.2)
		foot_ang_l = stride_l * -0.25 * flip

		knee_r = pelvis + Vector2((4.5 + stride_r * 6.5) * flip, 7.2 - maxf(0.0, stride_r) * 2.5)
		ankle_r = Vector2((4.8 + stride_r * 8.0) * flip, 12.2 - maxf(0.0, stride_r) * 2.2)
		foot_ang_r = stride_r * -0.25 * flip

		# Counter-swinging 2-joint arms with bent elbows during sprint
		var arm_swing_l := -run_anim
		var arm_swing_r := run_anim
		elbow_l = pelvis + Vector2((-6.5 + arm_swing_l * 4.5) * flip, -3.0)
		wrist_l = pelvis + Vector2((-5.0 + arm_swing_l * 8.5) * flip, 1.8 - maxf(0.0, arm_swing_l) * 3.5)
		fist_l = is_running

		elbow_r = pelvis + Vector2((6.5 + arm_swing_r * 4.5) * flip, -3.0)
		wrist_r = pelvis + Vector2((5.0 + arm_swing_r * 8.5) * flip, 1.8 - maxf(0.0, arm_swing_r) * 3.5)
		fist_r = is_running

	# Recompute hip & shoulder anchors from pelvis + torso_angle + torso_twist
	var torso_up := Vector2(sin(torso_angle), -cos(torso_angle))
	var torso_right := Vector2(cos(torso_angle), sin(torso_angle))
	var chest_center := pelvis + torso_up * 8.5

	hip_l = pelvis + torso_right * (-3.5 * flip) + Vector2(0, 2.5)
	hip_r = pelvis + torso_right * (3.5 * flip) + Vector2(0, 2.5)
	var twist_shift := torso_twist * 2.2 * flip
	shoulder_l = chest_center + torso_right * (-5.0 * flip + twist_shift)
	shoulder_r = chest_center + torso_right * (5.0 * flip - twist_shift)

	# Apply Analytical 2-Bone IK to legs when not in specialized Hopak split
	if not p.is_hopak:
		knee_l = knee_l.lerp(p._solve_2bone_ik(hip_l, ankle_l, 5.8, 5.8, flip), 0.65)
		knee_r = knee_r.lerp(p._solve_2bone_ik(hip_r, ankle_r, 5.8, 5.8, flip), 0.65)
		elbow_l = elbow_l.lerp(p._solve_2bone_ik(shoulder_l, wrist_l, 6.2, 6.0, -flip), 0.55)
		elbow_r = elbow_r.lerp(p._solve_2bone_ik(shoulder_r, wrist_r, 6.2, 6.0, -flip), 0.55)

	if p.bonk_timer > 0.0:
		head_offset.y += 2.2

	# Champion Boxing Strike Active Arm & Torso Override
	if p.punch_timer > 0.0:
		var p_ratio: float = p.punch_timer / 0.32
		var p_ext: float = sin(p_ratio * PI)
		fist_r = true
		fist_l = true
		head_facing = p.punch_facing
		head_offset = Vector2(2.2 * p.punch_facing * p_ext, 0.5 * p_ext)

		match p.punch_active_skill:
			JackPlayer.ChampionSkill.STEELHAMMER_JAB:
				torso_twist = 0.42 * p.punch_facing
				wrist_r = pelvis + Vector2((18.0 + p_ext * 15.0) * p.punch_facing, -12.0)
				elbow_r = p._solve_2bone_ik(shoulder_r, wrist_r, 8.5, 8.5, -p.punch_facing)
				punch_streak = wrist_r + Vector2(8.5 * p.punch_facing, 0.0)
				wrist_l = pelvis + Vector2(2.0 * p.punch_facing, -12.0)
				elbow_l = p._solve_2bone_ik(shoulder_l, wrist_l, 6.5, 6.5, p.punch_facing)
			JackPlayer.ChampionSkill.IRONFIST_HOOK:
				torso_angle = 0.22 * p.punch_facing * p_ext
				wrist_r = pelvis + Vector2(17.0 * p.punch_facing, -5.0 + p_ext * 17.0)
				elbow_r = p._solve_2bone_ik(shoulder_r, wrist_r, 8.5, 8.5, -p.punch_facing)
				punch_streak = wrist_r + Vector2(4.5 * p.punch_facing, 6.0)
				wrist_l = pelvis + Vector2(2.0 * p.punch_facing, -12.0)
				elbow_l = p._solve_2bone_ik(shoulder_l, wrist_l, 6.5, 6.5, p.punch_facing)
			JackPlayer.ChampionSkill.USYK_SLIP_COUNTER:
				torso_angle = -0.18 * p.punch_facing * p_ext
				torso_twist = -0.45 * p.punch_facing
				wrist_l = pelvis + Vector2((16.0 + p_ext * 13.0) * p.punch_facing, -8.0)
				elbow_l = p._solve_2bone_ik(shoulder_l, wrist_l, 8.0, 8.0, -p.punch_facing)
				wrist_r = pelvis + Vector2((21.0 + p_ext * 15.0) * p.punch_facing, -11.5)
				elbow_r = p._solve_2bone_ik(shoulder_r, wrist_r, 8.5, 8.5, -p.punch_facing)
				punch_streak = wrist_r + Vector2(8.5 * p.punch_facing, -2.0)
			JackPlayer.ChampionSkill.UNDISPUTED_TRIO:
				torso_twist = sin(p.time_passed * 32.0) * 0.48
				wrist_r = pelvis + Vector2((22.0 + p_ext * 16.5) * p.punch_facing, -10.5)
				elbow_r = p._solve_2bone_ik(shoulder_r, wrist_r, 8.8, 8.8, -p.punch_facing)
				wrist_l = pelvis + Vector2((16.0 + p_ext * 13.0) * p.punch_facing, -6.5)
				elbow_l = p._solve_2bone_ik(shoulder_l, wrist_l, 8.0, 8.0, -p.punch_facing)
				punch_streak = wrist_r + Vector2(10.5 * p.punch_facing, 0.0)
			JackPlayer.ChampionSkill.HOPAK_TYNOK_KICK:
				# Високий прямий удар ногою «Тинок» у червоному сап'янці вперед на рівні грудей/голови!
				torso_angle = -0.26 * p.punch_facing * p_ext
				pelvis += Vector2(-2.0 * p.punch_facing * p_ext, -1.5 * p_ext)
				ankle_r = pelvis + Vector2((14.0 + p_ext * 16.0) * p.punch_facing, -6.0 * p_ext + 2.0)
				knee_r = p._solve_2bone_ik(hip_r, ankle_r, 8.5, 8.5, -p.punch_facing)
				foot_ang_r = -0.85 * p.punch_facing * p_ext
				ankle_l = Vector2(-5.5 * p.punch_facing, 12.2)
				knee_l = p._solve_2bone_ik(hip_l, ankle_l, 6.2, 6.2, p.punch_facing)
				wrist_l = pelvis + Vector2(-11.0 * p.punch_facing, -10.0)
				wrist_r = pelvis + Vector2(9.0 * p.punch_facing, -8.0)
				punch_streak = ankle_r + Vector2(9.0 * p.punch_facing, -2.0)
			JackPlayer.ChampionSkill.HOPAK_SHCHUPAK_SPLIT:
				# Повітряний шпагат двома ногами «Щупак / Різножка» на 180 градусів у обидва боки!
				pelvis += Vector2(0.0, -6.0 * p_ext)
				torso_angle = 0.0
				head_facing = 0.0
				ankle_l = pelvis + Vector2(-15.0 - p_ext * 13.0, 1.5)
				knee_l = pelvis + Vector2(-8.5 - p_ext * 5.0, 0.5)
				foot_ang_l = 0.45
				ankle_r = pelvis + Vector2(15.0 + p_ext * 13.0, 1.5)
				knee_r = pelvis + Vector2(8.5 + p_ext * 5.0, 0.5)
				foot_ang_r = -0.45
				wrist_l = pelvis + Vector2(-14.5, -16.0 * p_ext - 4.0)
				elbow_l = pelvis + Vector2(-9.0, -9.0)
				wrist_r = pelvis + Vector2(14.5, -16.0 * p_ext - 4.0)
				elbow_r = pelvis + Vector2(9.0, -9.0)
				punch_streak = ankle_r + Vector2(7.0, 0.0)
			JackPlayer.ChampionSkill.HOPAK_POVZUNETS_SWEEP:
				# Низька обертова підсічка ногою «Повзунець / Коса» вздовж балки!
				pelvis += Vector2(2.5 * p.punch_facing * p_ext, 5.2 * p_ext)
				torso_angle = -0.22 * p.punch_facing * p_ext
				ankle_l = pelvis + Vector2(-6.5 * p.punch_facing, 7.0)
				knee_l = pelvis + Vector2(-9.5 * p.punch_facing, 2.0)
				ankle_r = pelvis + Vector2((14.0 + p_ext * 15.0) * p.punch_facing, 7.0)
				knee_r = pelvis + Vector2((7.5 + p_ext * 6.5) * p.punch_facing, 5.0)
				foot_ang_r = -0.35 * p.punch_facing
				wrist_l = pelvis + Vector2(-9.0 * p.punch_facing, 4.0)
				wrist_r = pelvis + Vector2(11.0 * p.punch_facing, -4.0)
				punch_streak = ankle_r + Vector2(8.0 * p.punch_facing, 0.0)

	return {
		"pelvis": pelvis,
		"chest": chest_center,
		"torso_angle": torso_angle,
		"torso_twist": torso_twist,
		"head_facing": head_facing,
		"head_offset": head_offset,
		"punch_streak": punch_streak,
		"hip_l": hip_l,
		"knee_l": knee_l,
		"ankle_l": ankle_l,
		"foot_ang_l": foot_ang_l,
		"hip_r": hip_r,
		"knee_r": knee_r,
		"ankle_r": ankle_r,
		"foot_ang_r": foot_ang_r,
		"shoulder_l": shoulder_l,
		"elbow_l": elbow_l,
		"wrist_l": wrist_l,
		"fist_l": fist_l,
		"shoulder_r": shoulder_r,
		"elbow_r": elbow_r,
		"wrist_r": wrist_r,
		"fist_r": fist_r
	}

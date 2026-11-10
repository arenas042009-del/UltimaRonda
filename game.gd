extends Node2D

const HoloUI := preload("res://scripts/holo_ui.gd")
const ARENA: Texture2D = preload("res://assets/game/arena_runtime.png")
const SURVIVOR: Texture2D = preload("res://assets/game/superviviente_runtime.png")
const ZOMBIE: Texture2D = preload("res://assets/game/zombi_runtime.png")
const UI_FONT: Font = preload("res://assets/template/fonts/ui_regular.tres")
const MEDIUM_FONT: Font = preload("res://assets/template/fonts/ui_medium.tres")
const BOLD_FONT: Font = preload("res://assets/template/fonts/ui_bold.tres")
const TITLE_FONT: Font = preload("res://assets/template/fonts/display/display_title.tres")
const W := 1280.0
const H := 720.0
const MAX_ZOMBIES := 26
const SAVE_PATH := "user://ultima_ronda.cfg"
const AMBER := Color(1.0, 0.43, 0.18)
const PALE := Color(0.95, 0.94, 0.87)
const TEAL := Color(0.35, 0.82, 0.70)
const RED := Color(0.94, 0.20, 0.17)
const GREEN := Color(0.58, 0.88, 0.48)
const MUTED := Color(0.72, 0.76, 0.69)

enum Phase { PLAYING, UPGRADES, PAUSED, GAME_OVER }

var phase: Phase = Phase.PLAYING
var player_pos := Vector2(W * 0.5, H * 0.57)
var player_health := 100.0
var player_max_health := 100.0
var player_invulnerable := 0.0
var player_hit_flash := 0.0
var wave := 0
var score := 0
var points := 0
var best_score := 0
var spawn_remaining := 0
var spawn_timer := 0.0
var fire_timer := 0.0
var wave_banner_timer := 0.0
var notification_timer := 0.0
var notification_text := ""
var shop_purchased := false
var damage_level := 0
var rapid_level := 0
var armor_level := 0
var hit_count := 0
var zombies: Array[Dictionary] = []
var bullets: Array[Dictionary] = []
var medkits: Array[Dictionary] = []
var particles: Array[Dictionary] = []
var point_popups: Array[Dictionary] = []
var elapsed := 0.0
var rng := RandomNumberGenerator.new()

const SHOP_CARDS := [
	Rect2(139, 330, 308, 185),
	Rect2(486, 330, 308, 185),
	Rect2(833, 330, 308, 185),
]
const SHOP_CONTINUE := Rect2(475, 552, 330, 58)
const PAUSE_RESUME := Rect2(465, 395, 350, 60)
const PAUSE_MENU := Rect2(465, 475, 350, 56)
const RESULT_RETRY := Rect2(465, 495, 350, 60)

func _ready() -> void:
	rng.randomize()
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) == OK:
		best_score = int(config.get_value("progress", "best_score", 0))
	get_node("/root/TuningStore").begin_run()
	_start_wave()
	set_process(true)
	set_process_unhandled_input(true)
	queue_redraw()

func _process(delta: float) -> void:
	var dt := minf(delta, 0.05)
	elapsed += dt
	player_invulnerable = maxf(0.0, player_invulnerable - dt)
	player_hit_flash = maxf(0.0, player_hit_flash - dt)
	wave_banner_timer = maxf(0.0, wave_banner_timer - dt)
	notification_timer = maxf(0.0, notification_timer - dt)
	_update_visuals(dt)
	if phase == Phase.PLAYING:
		_update_player(dt)
		_update_spawning(dt)
		_update_zombies(dt)
		_update_bullets(dt)
		_update_medkits(dt)
		if spawn_remaining <= 0 and zombies.is_empty() and phase == Phase.PLAYING:
			_finish_wave()
	elif phase == Phase.UPGRADES and player_health < player_max_health:
		var regen: float = get_node("/root/TuningStore").active_value("energy_rate")
		player_health = minf(player_max_health, player_health + regen * dt)
	queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE or event.keycode == KEY_P:
			if phase == Phase.PLAYING:
				phase = Phase.PAUSED
			elif phase == Phase.PAUSED:
				phase = Phase.PLAYING
			queue_redraw()
			get_viewport().set_input_as_handled()
			return
		if phase == Phase.UPGRADES:
			if event.keycode == KEY_1:
				_buy_upgrade(0)
			elif event.keycode == KEY_2:
				_buy_upgrade(1)
			elif event.keycode == KEY_3:
				_buy_upgrade(2)
			elif event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER or event.keycode == KEY_SPACE:
				_continue_round()
		elif phase == Phase.PAUSED:
			if event.keycode == KEY_ENTER or event.keycode == KEY_SPACE:
				phase = Phase.PLAYING
			elif event.keycode == KEY_M:
				_return_to_title()
		elif phase == Phase.GAME_OVER and (event.keycode == KEY_ENTER or event.keycode == KEY_R or event.keycode == KEY_SPACE):
			_restart_run()
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var p: Vector2 = event.position
		if phase == Phase.UPGRADES:
			for index in range(SHOP_CARDS.size()):
				if SHOP_CARDS[index].has_point(p):
					_buy_upgrade(index)
					get_viewport().set_input_as_handled()
					return
			if SHOP_CONTINUE.has_point(p):
				_continue_round()
				get_viewport().set_input_as_handled()
		elif phase == Phase.PAUSED:
			if PAUSE_RESUME.has_point(p):
				phase = Phase.PLAYING
			elif PAUSE_MENU.has_point(p):
				_return_to_title()
			get_viewport().set_input_as_handled()
		elif phase == Phase.GAME_OVER and RESULT_RETRY.has_point(p):
			_restart_run()
			get_viewport().set_input_as_handled()

func _start_wave() -> void:
	var tuning := get_node("/root/TuningStore")
	tuning.apply_boundary("NEXT_WAVE", ["enemy_count"])
	wave += 1
	spawn_remaining = maxi(1, int(round((6 + wave * 3) * tuning.active_value("enemy_count"))))
	spawn_timer = 0.28
	fire_timer = 0.0
	wave_banner_timer = 1.7
	shop_purchased = false
	phase = Phase.PLAYING

func _update_player(delta: float) -> void:
	var direction := Vector2.ZERO
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT): direction.x -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT): direction.x += 1.0
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP): direction.y -= 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN): direction.y += 1.0
	if direction.length_squared() > 1.0:
		direction = direction.normalized()
	player_pos += direction * get_node("/root/TuningStore").active_value("player_speed") * delta
	player_pos.x = clampf(player_pos.x, 46.0, W - 46.0)
	player_pos.y = clampf(player_pos.y, 112.0, H - 42.0)
	fire_timer = maxf(0.0, fire_timer - delta)
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) or Input.is_key_pressed(KEY_SPACE):
		if fire_timer <= 0.0:
			_shoot()

func _shoot() -> void:
	var tuning := get_node("/root/TuningStore")
	tuning.apply_boundary("NEXT_ATTACK", ["fire_delay"])
	var target: Vector2 = get_global_mouse_position()
	if Input.is_key_pressed(KEY_SPACE) and not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		var closest: Variant = _nearest_zombie()
		if closest != null:
			target = closest.pos
	var direction: Vector2 = (target - player_pos).normalized()
	if direction.length_squared() < 0.001:
		direction = Vector2.UP
	var delay: float = tuning.active_value("fire_delay") * pow(0.86, rapid_level)
	fire_timer = maxf(0.075, delay)
	bullets.append({"pos": player_pos + direction * 29.0, "vel": direction * 850.0,
		"life": 1.15, "damage": 1 + damage_level, "radius": 5.0})
	_spawn_burst(player_pos + direction * 30.0, Color(1.0, 0.61, 0.25), 3, 55.0)

func _nearest_zombie() -> Variant:
	if zombies.is_empty():
		return null
	var nearest: Dictionary = zombies[0]
	var best_distance := player_pos.distance_squared_to(nearest.pos)
	for zombie in zombies:
		var distance := player_pos.distance_squared_to(zombie.pos)
		if distance < best_distance:
			nearest = zombie
			best_distance = distance
	return nearest

func _update_spawning(delta: float) -> void:
	if spawn_remaining <= 0:
		return
	spawn_timer -= delta
	if spawn_timer > 0.0 or zombies.size() >= MAX_ZOMBIES:
		return
	var kind := 0
	if wave >= 3 and rng.randf() < 0.24:
		kind = 1
	if wave >= 5 and rng.randf() < 0.13:
		kind = 2
	_spawn_random_zombie(kind)
	spawn_remaining -= 1
	var tuning := get_node("/root/TuningStore")
	tuning.apply_boundary("NEXT_ATTACK", ["enemy_bullet_speed"])
	var interval := 0.94 - minf(0.48, float(wave - 1) * 0.035)
	spawn_timer = maxf(0.20, interval / maxf(0.5, tuning.active_value("enemy_bullet_speed")))

func _spawn_random_zombie(kind: int = 0) -> void:
	var position := Vector2.ZERO
	for attempt in range(10):
		var side := rng.randi_range(0, 3)
		match side:
			0: position = Vector2(rng.randf_range(28.0, W - 28.0), 88.0)
			1: position = Vector2(W - 28.0, rng.randf_range(110.0, H - 28.0))
			2: position = Vector2(rng.randf_range(28.0, W - 28.0), H - 28.0)
			_: position = Vector2(28.0, rng.randf_range(110.0, H - 28.0))
		if position.distance_to(player_pos) > 300.0:
			break
	spawn_zombie_at(position, kind)

func spawn_zombie_at(position: Vector2, kind: int = 0) -> void:
	var tuning := get_node("/root/TuningStore")
	tuning.apply_boundary("NEXT_SPAWN", ["enemy_health"])
	var base_health := 1 + int(maxi(0, wave - 4) / 4)
	var speed := 70.0 + float(wave) * 4.2
	var radius := float(tuning.active_value("hit_radius")) + 13.0
	if kind == 1:
		base_health = maxi(1, base_health - 1)
		speed *= 1.48
		radius -= 3.0
	elif kind == 2:
		tuning.apply_boundary("NEXT_BOSS", ["boss_health"])
		base_health = 3 + int(wave / 3)
		base_health = int(ceil(float(base_health) * tuning.active_value("boss_health")))
		speed *= 0.68
		radius += 11.0
	else:
		base_health = int(ceil(float(base_health) * tuning.active_value("enemy_health")))
	zombies.append({"pos": position, "hp": maxi(1, base_health), "max_hp": maxi(1, base_health),
		"speed": speed, "kind": kind, "radius": radius, "flash": 0.0, "attack_timer": 0.0})

func _update_zombies(delta: float) -> void:
	var speed_multiplier: float = get_node("/root/TuningStore").active_value("enemy_speed")
	for index in range(zombies.size() - 1, -1, -1):
		var zombie: Dictionary = zombies[index]
		zombie.flash = maxf(0.0, float(zombie.flash) - delta)
		zombie.attack_timer = maxf(0.0, float(zombie.attack_timer) - delta)
		var to_player: Vector2 = player_pos - zombie.pos
		var distance: float = to_player.length()
		if distance > 0.001:
			zombie.pos += to_player / distance * float(zombie.speed) * speed_multiplier * delta
		var contact_radius: float = float(zombie.radius) + get_node("/root/TuningStore").active_value("hit_radius")
		if distance <= contact_radius and zombie.attack_timer <= 0.0:
			_damage_player(13.0 if int(zombie.kind) != 2 else 18.0)
			zombie.attack_timer = 0.8
		zombies[index] = zombie
		if phase == Phase.GAME_OVER:
			return

func _update_bullets(delta: float) -> void:
	for bullet_index in range(bullets.size() - 1, -1, -1):
		var bullet: Dictionary = bullets[bullet_index]
		bullet.pos += bullet.vel * delta
		bullet.life = float(bullet.life) - delta
		var remove_bullet: bool = bullet.life <= 0.0 or bullet.pos.x < -20.0 or bullet.pos.x > W + 20.0 or bullet.pos.y < -20.0 or bullet.pos.y > H + 20.0
		if not remove_bullet:
			for zombie_index in range(zombies.size() - 1, -1, -1):
				var zombie: Dictionary = zombies[zombie_index]
				var reach := float(zombie.radius) + float(bullet.radius)
				if zombie.pos.distance_squared_to(bullet.pos) <= reach * reach:
					_damage_zombie(zombie_index, int(bullet.damage))
					remove_bullet = true
					break
		if remove_bullet:
			bullets.remove_at(bullet_index)
		else:
			bullets[bullet_index] = bullet

func _damage_zombie(index: int, amount: int) -> void:
	if index < 0 or index >= zombies.size():
		return
	var zombie: Dictionary = zombies[index]
	zombie.hp = int(zombie.hp) - amount
	zombie.flash = 0.12
	var position: Vector2 = zombie.pos
	if int(zombie.hp) <= 0:
		_kill_zombie(index)
	else:
		zombies[index] = zombie
		_spawn_burst(position, AMBER, 5, 95.0)

func _kill_zombie(index: int) -> void:
	var zombie: Dictionary = zombies[index]
	zombies.remove_at(index)
	var reward := 80 + wave * 5
	points += reward
	score += reward
	point_popups.append({"pos": zombie.pos + Vector2(0, -18), "text": "+%d PTS" % reward, "life": 0.9, "max": 0.9})
	_spawn_burst(zombie.pos, Color(0.94, 0.37, 0.19), 12 if int(zombie.kind) != 2 else 20, 170.0)
	if rng.randf() < get_node("/root/TuningStore").active_value("bone_drop"):
		medkits.append({"pos": zombie.pos, "life": 9.0, "pulse": rng.randf_range(0.0, TAU)})
	_update_best_score()

func _damage_player(amount: float) -> void:
	if player_invulnerable > 0.0 or phase != Phase.PLAYING:
		return
	player_health = maxf(0.0, player_health - amount)
	player_invulnerable = 0.78
	player_hit_flash = 0.23
	hit_count += 1
	_spawn_burst(player_pos, RED, 12, 130.0)
	if player_health <= 0.0:
		phase = Phase.GAME_OVER
		_update_best_score()

func _update_medkits(delta: float) -> void:
	for index in range(medkits.size() - 1, -1, -1):
		var medkit: Dictionary = medkits[index]
		medkit.life = float(medkit.life) - delta
		medkit.pulse = float(medkit.pulse) + delta * 2.8
		if player_pos.distance_to(medkit.pos) < 32.0:
			player_health = minf(player_max_health, player_health + 28.0)
			_spawn_burst(medkit.pos, GREEN, 14, 125.0)
			point_popups.append({"pos": medkit.pos + Vector2(0, -20), "text": "+28 SALUD", "life": 0.9, "max": 0.9})
			medkits.remove_at(index)
		elif medkit.life <= 0.0:
			medkits.remove_at(index)
		else:
			medkits[index] = medkit

func _spawn_burst(position: Vector2, color: Color, count: int, speed: float) -> void:
	for index in range(count):
		var angle := rng.randf_range(0.0, TAU)
		var velocity := Vector2.from_angle(angle) * rng.randf_range(speed * 0.25, speed)
		particles.append({"pos": position, "vel": velocity, "life": rng.randf_range(0.16, 0.42),
			"max": 0.42, "color": color, "size": rng.randf_range(1.5, 4.5)})
	while particles.size() > 180:
		particles.pop_front()

func _update_visuals(delta: float) -> void:
	for index in range(particles.size() - 1, -1, -1):
		var item: Dictionary = particles[index]
		item.pos += item.vel * delta
		item.vel *= 0.91
		item.life = float(item.life) - delta
		if item.life <= 0.0:
			particles.remove_at(index)
		else:
			particles[index] = item
	for index in range(point_popups.size() - 1, -1, -1):
		var popup: Dictionary = point_popups[index]
		popup.pos.y -= 34.0 * delta
		popup.life = float(popup.life) - delta
		if popup.life <= 0.0:
			point_popups.remove_at(index)
		else:
			point_popups[index] = popup

func _finish_wave() -> void:
	phase = Phase.UPGRADES
	shop_purchased = false
	var bonus := 100 + wave * 50
	points += bonus
	score += bonus
	point_popups.append({"pos": Vector2(W * 0.5, H * 0.47), "text": "+%d BONUS DE RONDA" % bonus, "life": 1.5, "max": 1.5})
	_update_best_score()

func _upgrade_cards() -> Array[Dictionary]:
	return [
		{"title": I18n.t("shop.damage"), "description": I18n.t("shop.damage_desc", {"damage": 1 + damage_level}), "cost": 210 + damage_level * 150, "maxed": damage_level >= 3},
		{"title": I18n.t("shop.rapid"), "description": I18n.t("shop.rapid_desc", {"level": rapid_level + 1}), "cost": 180 + rapid_level * 130, "maxed": rapid_level >= 4},
		{"title": I18n.t("shop.armor"), "description": I18n.t("shop.armor_desc", {"health": int(player_max_health + 20.0)}), "cost": 220 + armor_level * 140, "maxed": armor_level >= 4},
	]

func _buy_upgrade(index: int) -> bool:
	if phase != Phase.UPGRADES or shop_purchased or index < 0 or index >= 3:
		return false
	var card := _upgrade_cards()[index]
	if bool(card.maxed):
		_set_notice(I18n.t("shop.maxed"))
		return false
	if points < int(card.cost):
		_set_notice(I18n.t("shop.not_enough", {"points": int(card.cost) - points}))
		return false
	points -= int(card.cost)
	shop_purchased = true
	match index:
		0:
			damage_level += 1
		1:
			rapid_level += 1
		2:
			armor_level += 1
			player_max_health += 20.0
			player_health = minf(player_max_health, player_health + 30.0)
	_set_notice(I18n.t("shop.bought", {"title": str(card.title)}))
	return true

func _continue_round() -> void:
	if phase == Phase.UPGRADES:
		_start_wave()

func _set_notice(text: String) -> void:
	notification_text = text
	notification_timer = 1.8

func _update_best_score() -> void:
	if score <= best_score:
		return
	best_score = score
	var config := ConfigFile.new()
	config.set_value("progress", "best_score", best_score)
	config.set_value("progress", "best_wave", wave)
	config.save(SAVE_PATH)

func _restart_run() -> void:
	player_pos = Vector2(W * 0.5, H * 0.57)
	player_health = 100.0
	player_max_health = 100.0
	player_invulnerable = 0.0
	player_hit_flash = 0.0
	wave = 0
	score = 0
	points = 0
	spawn_remaining = 0
	spawn_timer = 0.0
	fire_timer = 0.0
	wave_banner_timer = 0.0
	shop_purchased = false
	damage_level = 0
	rapid_level = 0
	armor_level = 0
	hit_count = 0
	zombies.clear()
	bullets.clear()
	medkits.clear()
	particles.clear()
	point_popups.clear()
	get_node("/root/TuningStore").begin_run()
	_start_wave()

func _return_to_title() -> void:
	get_tree().change_scene_to_file("res://scenes/title_screen.tscn")

func _draw() -> void:
	draw_texture_rect(ARENA, Rect2(Vector2.ZERO, Vector2(W, H)), false)
	draw_rect(Rect2(Vector2.ZERO, Vector2(W, H)), Color(0.018, 0.03, 0.026, 0.34))
	_draw_arena_details()
	_draw_medkits()
	_draw_zombies()
	_draw_bullets()
	_draw_player()
	_draw_particles()
	_draw_popups()
	_draw_hud()
	if wave_banner_timer > 0.0 and phase == Phase.PLAYING:
		_draw_wave_banner()
	if player_hit_flash > 0.0:
		draw_rect(Rect2(Vector2.ZERO, Vector2(W, H)), Color(0.8, 0.03, 0.02, player_hit_flash * 0.20))
	match phase:
		Phase.UPGRADES: _draw_shop()
		Phase.PAUSED: _draw_pause()
		Phase.GAME_OVER: _draw_results()

func _draw_arena_details() -> void:
	for y in range(108, 690, 52):
		draw_line(Vector2(30, y), Vector2(W - 30, y), Color(0.70, 0.84, 0.74, 0.035), 1.0)
	for x in range(32, 1260, 82):
		draw_line(Vector2(x, 104), Vector2(x, H - 26), Color(0.70, 0.84, 0.74, 0.025), 1.0)

func _draw_zombies() -> void:
	for zombie in zombies:
		var pos: Vector2 = zombie.pos
		var tint := Color(1.0, 1.0, 1.0)
		var size := Vector2(58.0, 62.0)
		match int(zombie.kind):
			1:
				tint = Color(1.0, 0.56, 0.38)
				size = Vector2(52.0, 58.0)
			2:
				tint = Color(0.63, 0.88, 0.65)
				size = Vector2(78.0, 82.0)
		if float(zombie.flash) > 0.0:
			tint = Color(1.0, 0.94, 0.79)
		_draw_ellipse(pos + Vector2(2, 15), size.x * 0.33, size.y * 0.20, Color(0.0, 0.02, 0.02, 0.45))
		_draw_actor(ZOMBIE, pos, size, 0.0, tint)
		if int(zombie.kind) == 2:
			var width := 40.0
			draw_rect(Rect2(pos.x - width * 0.5, pos.y - 52.0, width, 5), Color(0.05, 0.08, 0.07, 0.86))
			draw_rect(Rect2(pos.x - width * 0.5, pos.y - 52.0, width * float(zombie.hp) / float(zombie.max_hp), 5), AMBER)

func _draw_bullets() -> void:
	for bullet in bullets:
		var tail: Vector2 = bullet.pos - bullet.vel.normalized() * 17.0
		draw_line(tail, bullet.pos, Color(1.0, 0.56, 0.21, 0.92), 3.5)
		draw_circle(bullet.pos, 3.4, Color(1.0, 0.91, 0.60))

func _draw_player() -> void:
	_draw_ellipse(player_pos + Vector2(0, 18), 27.0, 13.0, Color(0, 0.02, 0.02, 0.58))
	var aim := get_global_mouse_position() - player_pos
	if Input.is_key_pressed(KEY_SPACE):
		var nearest: Variant = _nearest_zombie()
		if nearest != null:
			aim = nearest.pos - player_pos
	var rotation := aim.angle() + PI * 0.25 if aim.length_squared() > 0.001 else 0.0
	var tint := Color(1, 0.56, 0.42) if player_invulnerable > 0.0 and int(elapsed * 12.0) % 2 == 0 else Color.WHITE
	_draw_actor(SURVIVOR, player_pos, Vector2(88.0, 88.0), rotation, tint)
	if player_invulnerable > 0.0:
		draw_arc(player_pos, 43.0, 0.0, TAU, 48, Color(0.36, 0.85, 0.70, 0.38), 2.0)

func _draw_actor(texture: Texture2D, position: Vector2, size: Vector2, rotation: float, tint: Color) -> void:
	draw_set_transform(position, rotation, Vector2(size.x / float(texture.get_width()), size.y / float(texture.get_height())))
	draw_texture(texture, -Vector2(texture.get_size()) * 0.5, tint)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _draw_medkits() -> void:
	for medkit in medkits:
		var pulse := 0.5 + 0.5 * sin(float(medkit.pulse))
		var p: Vector2 = medkit.pos
		draw_circle(p, 13.0 + pulse * 3.0, Color(0.38, 0.88, 0.50, 0.18))
		draw_rect(Rect2(p - Vector2(9, 9), Vector2(18, 18)), Color(0.15, 0.46, 0.32))
		draw_rect(Rect2(p - Vector2(2, 6), Vector2(4, 12)), Color(0.89, 1.0, 0.79))
		draw_rect(Rect2(p - Vector2(6, 2), Vector2(12, 4)), Color(0.89, 1.0, 0.79))

func _draw_particles() -> void:
	for particle in particles:
		var color: Color = particle.color
		color.a *= clampf(float(particle.life) / float(particle.max), 0.0, 1.0)
		draw_circle(particle.pos, float(particle.size), color)

func _draw_popups() -> void:
	for popup in point_popups:
		var color := Color(1.0, 0.84, 0.53, clampf(float(popup.life) / float(popup.max), 0.0, 1.0))
		HoloUI.glow_text(self, MEDIUM_FONT, Vector2(clampf(float(popup.pos.x) - 95.0, 0.0, W - 190.0), popup.pos.y), str(popup.text), 16, color, AMBER, HORIZONTAL_ALIGNMENT_CENTER, 190.0, 0.55)

func _draw_hud() -> void:
	HoloUI.panel(self, Rect2(20, 16, W - 40, 82), TEAL, 0.94, 10.0, false, 8.0)
	HoloUI.glow_text(self, MEDIUM_FONT, Vector2(43, 46), I18n.t("hud.health"), 15, MUTED, TEAL, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 0.25)
	var bar_rect := Rect2(43, 58, 218, 17)
	draw_rect(bar_rect, Color(0.02, 0.09, 0.07, 0.96))
	var ratio := clampf(player_health / maxf(1.0, player_max_health), 0.0, 1.0)
	var health_color := GREEN if ratio > 0.55 else (AMBER if ratio > 0.27 else RED)
	draw_rect(Rect2(bar_rect.position, Vector2(bar_rect.size.x * ratio, bar_rect.size.y)), health_color)
	draw_rect(bar_rect, Color(0.75, 0.90, 0.81, 0.42), false, 1.0)
	HoloUI.glow_text(self, BOLD_FONT, Vector2(277, 73), "%d%%" % int(round(ratio * 100.0)), 18, PALE, health_color, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 0.28)
	HoloUI.glow_text(self, TITLE_FONT, Vector2(515, 60), I18n.t("hud.wave", {"round": wave}), 29, PALE, AMBER, HORIZONTAL_ALIGNMENT_CENTER, 250.0, 0.7)
	HoloUI.glow_text(self, MEDIUM_FONT, Vector2(490, 83), I18n.t("hud.remaining", {"count": spawn_remaining + zombies.size()}), 13, MUTED, TEAL, HORIZONTAL_ALIGNMENT_CENTER, 300.0, 0.2)
	HoloUI.glow_text(self, MEDIUM_FONT, Vector2(960, 43), I18n.t("hud.points"), 14, MUTED, AMBER, HORIZONTAL_ALIGNMENT_RIGHT, 250.0, 0.25)
	HoloUI.glow_text(self, BOLD_FONT, Vector2(960, 71), "%06d" % points, 26, PALE, AMBER, HORIZONTAL_ALIGNMENT_RIGHT, 250.0, 0.6)
	HoloUI.glow_text(self, UI_FONT, Vector2(960, 88), I18n.t("hud.score", {"score": "%07d" % score}), 12, MUTED, TEAL, HORIZONTAL_ALIGNMENT_RIGHT, 250.0, 0.15)
	HoloUI.panel(self, Rect2(20, H - 45, 565, 27), Color(0.65, 0.8, 0.72), 0.72, 5.0, false, 0.0)
	HoloUI.glow_text(self, UI_FONT, Vector2(34, H - 26), I18n.t("hud.controls"), 13, PALE, TEAL, HORIZONTAL_ALIGNMENT_LEFT, 540.0, 0.18)
	HoloUI.glow_text(self, UI_FONT, Vector2(W - 284, H - 26), I18n.t("hud.pause"), 13, MUTED, TEAL, HORIZONTAL_ALIGNMENT_RIGHT, 250.0, 0.15)

func _draw_wave_banner() -> void:
	var alpha := minf(1.0, wave_banner_timer * 1.4)
	var banner := Rect2(390, 124, 500, 55)
	draw_rect(banner, Color(0.025, 0.09, 0.075, 0.76 * alpha))
	draw_rect(banner, Color(AMBER, 0.55 * alpha), false, 1.2)
	HoloUI.glow_text(self, TITLE_FONT, Vector2(405, 162), I18n.t("hud.wave", {"round": wave}), 30, Color(PALE, alpha), AMBER, HORIZONTAL_ALIGNMENT_CENTER, 470.0, 0.55)

func _draw_shop() -> void:
	draw_rect(Rect2(Vector2.ZERO, Vector2(W, H)), Color(0.005, 0.02, 0.017, 0.76))
	HoloUI.panel(self, Rect2(92, 100, W - 184, 525), AMBER, 0.98, 14.0, true, 12.0)
	HoloUI.glow_text(self, TITLE_FONT, Vector2(190, 158), I18n.t("shop.title"), 38, PALE, AMBER, HORIZONTAL_ALIGNMENT_CENTER, 900.0, 0.7)
	HoloUI.glow_text(self, UI_FONT, Vector2(190, 190), I18n.t("shop.subtitle"), 16, MUTED, TEAL, HORIZONTAL_ALIGNMENT_CENTER, 900.0, 0.2)
	HoloUI.glow_text(self, BOLD_FONT, Vector2(390, 235), I18n.t("shop.points", {"points": "%06d" % points}), 19, Color(1.0, 0.84, 0.55), AMBER, HORIZONTAL_ALIGNMENT_CENTER, 500.0, 0.4)
	var cards := _upgrade_cards()
	for index in range(cards.size()):
		var rect: Rect2 = SHOP_CARDS[index]
		var card: Dictionary = cards[index]
		var is_hovered := rect.has_point(get_viewport().get_mouse_position())
		var accent := TEAL if index == 1 else AMBER
		var disabled := bool(card.maxed) or (points < int(card.cost) and not shop_purchased)
		HoloUI.panel(self, rect, accent if not disabled else Color(0.42, 0.48, 0.43), 0.98, 8.0, false, 5.0)
		if is_hovered:
			draw_rect(rect.grow(-4.0), Color(accent, 0.09), true)
		HoloUI.glow_text(self, BOLD_FONT, Vector2(rect.position.x + 10.0, rect.position.y + 40), str(card.title), 20, PALE, accent, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x - 20.0, 0.45)
		HoloUI.glow_text(self, UI_FONT, Vector2(rect.position.x + 12.0, rect.position.y + 79), str(card.description), 15, MUTED, accent, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x - 24.0, 0.15)
		var cost_text := I18n.t("shop.maxed") if bool(card.maxed) else I18n.t("shop.cost", {"cost": int(card.cost)})
		var cost_color := MUTED if disabled else Color(1.0, 0.84, 0.55)
		HoloUI.glow_text(self, BOLD_FONT, Vector2(rect.position.x + 10.0, rect.position.y + 143), cost_text, 17, cost_color, accent, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x - 20.0, 0.25)
		HoloUI.glow_text(self, UI_FONT, Vector2(rect.position.x + 10.0, rect.position.y + 169), "%d  |  %s" % [index + 1, I18n.t("shop.key_hint")], 12, MUTED, accent, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x - 20.0, 0.1)
	var continue_text := I18n.t("shop.continue") if not shop_purchased else I18n.t("shop.next")
	_draw_button(SHOP_CONTINUE, continue_text, shop_purchased or notification_timer <= 0.0)
	if notification_timer > 0.0:
		HoloUI.glow_text(self, MEDIUM_FONT, Vector2(W * 0.5, 536), notification_text, 14, Color(1.0, 0.78, 0.55), AMBER, HORIZONTAL_ALIGNMENT_CENTER, 640.0, 0.3)

func _draw_pause() -> void:
	draw_rect(Rect2(Vector2.ZERO, Vector2(W, H)), Color(0.005, 0.02, 0.017, 0.78))
	HoloUI.panel(self, Rect2(386, 205, 508, 345), TEAL, 0.98, 12.0, true, 10.0)
	HoloUI.glow_text(self, TITLE_FONT, Vector2(420, 287), I18n.t("pause.title"), 44, PALE, TEAL, HORIZONTAL_ALIGNMENT_CENTER, 440.0, 0.6)
	HoloUI.glow_text(self, UI_FONT, Vector2(420, 331), I18n.t("pause.info"), 15, MUTED, TEAL, HORIZONTAL_ALIGNMENT_CENTER, 440.0, 0.2)
	_draw_button(PAUSE_RESUME, I18n.t("pause.resume"), true)
	_draw_button(PAUSE_MENU, I18n.t("pause.menu"), false)

func _draw_results() -> void:
	draw_rect(Rect2(Vector2.ZERO, Vector2(W, H)), Color(0.018, 0.022, 0.02, 0.84))
	HoloUI.panel(self, Rect2(338, 145, 604, 450), RED, 0.99, 14.0, true, 12.0)
	HoloUI.glow_text(self, TITLE_FONT, Vector2(365, 239), I18n.t("results.title"), 43, PALE, RED, HORIZONTAL_ALIGNMENT_CENTER, 550.0, 0.72)
	HoloUI.glow_text(self, BOLD_FONT, Vector2(380, 316), I18n.t("results.score", {"score": "%07d" % score}), 23, Color(1.0, 0.82, 0.68), AMBER, HORIZONTAL_ALIGNMENT_CENTER, 520.0, 0.4)
	HoloUI.glow_text(self, MEDIUM_FONT, Vector2(380, 358), I18n.t("results.wave", {"round": wave}), 18, PALE, TEAL, HORIZONTAL_ALIGNMENT_CENTER, 520.0, 0.3)
	HoloUI.glow_text(self, UI_FONT, Vector2(380, 400), I18n.t("results.best", {"score": "%07d" % best_score}), 15, MUTED, TEAL, HORIZONTAL_ALIGNMENT_CENTER, 520.0, 0.18)
	_draw_button(RESULT_RETRY, I18n.t("results.retry"), true)
	HoloUI.glow_text(self, UI_FONT, Vector2(360, 585), I18n.t("results.menu_hint"), 13, MUTED, TEAL, HORIZONTAL_ALIGNMENT_CENTER, 560.0, 0.15)

func _draw_button(rect: Rect2, label: String, highlighted: bool) -> void:
	var hovered := rect.has_point(get_viewport().get_mouse_position())
	var accent := AMBER if highlighted else TEAL
	var fill := Color(0.24, 0.09, 0.045, 0.96) if highlighted else Color(0.035, 0.10, 0.085, 0.92)
	if hovered:
		fill = fill.lightened(0.18)
	draw_rect(rect, fill)
	draw_rect(rect, Color(accent, 0.84), false, 1.5)
	HoloUI.glow_text(self, BOLD_FONT, rect.position + Vector2(10, rect.size.y * 0.64), label, 17, PALE, accent, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x - 20.0, 0.35)

func _draw_ellipse(center: Vector2, radius_x: float, radius_y: float, color: Color) -> void:
	var points := PackedVector2Array()
	for index in range(24):
		var angle := TAU * float(index) / 24.0
		points.append(center + Vector2(cos(angle) * radius_x, sin(angle) * radius_y))
	draw_colored_polygon(points, color)

extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var store := root.get_node("TuningStore")
	store.reset_all()
	var title_scene := load("res://scenes/title_screen.tscn") as PackedScene
	assert(title_scene != null)
	var title := title_scene.instantiate()
	root.add_child(title)
	await process_frame
	assert(title.has_method("_start_game"))
	assert(not title.starting)
	assert(not str(title.auth_hint).is_empty())
	title.queue_free()
	await process_frame

	var game_scene := load("res://scenes/game.tscn") as PackedScene
	assert(game_scene != null)
	var game := game_scene.instantiate()
	root.add_child(game)
	await process_frame
	game.set_process(false)
	assert(game.wave == 1)
	assert(game.phase == 0)
	assert(game.spawn_remaining == 9)
	assert(game.player_health == 100.0)
	assert(game.score == 0 and game.points == 0)
	assert(game._upgrade_cards().size() == 3)

	# First horde spawn, elimination reward, and transition into the upgrade shop.
	game.rng.seed = 8128
	game._update_spawning(0.30)
	assert(game.spawn_remaining == 8)
	assert(game.zombies.size() == 1)
	game._damage_zombie(0, 1)
	assert(game.zombies.is_empty())
	assert(game.points == 85 and game.score == 85)
	game.spawn_remaining = 0
	game._process(0.016)
	assert(game.phase == 1)
	assert(game.wave == 1)
	assert(game.points == 235 and game.score == 235)

	# Buy one between-round upgrade and verify that points are consumed.
	assert(game._buy_upgrade(2))
	assert(game.points == 15)
	assert(game.armor_level == 1)
	assert(game.player_max_health == 120.0 and game.player_health == 120.0)
	assert(not game._buy_upgrade(0))
	assert(game.damage_level == 0)
	game._continue_round()
	assert(game.phase == 0 and game.wave == 2)
	assert(game.spawn_remaining == 12)

	# Pause and resume without advancing a round.
	var pause := InputEventKey.new()
	pause.keycode = KEY_ESCAPE
	pause.pressed = true
	game._unhandled_input(pause)
	assert(game.phase == 2)
	game._unhandled_input(pause)
	assert(game.phase == 0)

	# Tuning only changes combat values at their saved application boundaries.
	if store.enabled():
		assert(not store.set_value("enemy_health", 99.0))
		assert(not store.set_value("enemy_health", "fast"))
		store.set_value("player_speed", 440.0)
		assert(store.active_value("player_speed") == 440.0)
		store.set_value("enemy_health", 2.0)
		assert(store.active_value("enemy_health") == 0.5)
		game.spawn_zombie_at(Vector2(940, 360), 0)
		assert(int(game.zombies.back().hp) == 2)
		assert(store.run_custom)
		store.set_value("fire_delay", 0.20)
		assert(store.active_value("fire_delay") == 0.16)
		game._shoot()
		assert(is_equal_approx(game.fire_timer, 0.20))
		assert(store.active_value("fire_delay") == 0.20)
		store.reset_all()
		assert(store.run_custom) # Integrity remains marked until the next run.

	# Defeat records the local best, then retry clears the run but keeps the record.
	var saved_best: int = int(game.best_score)
	game.player_health = 5.0
	game.player_invulnerable = 0.0
	game._damage_player(10.0)
	assert(game.phase == 3 and game.player_health == 0.0)
	assert(game.best_score >= game.score)
	var recorded_best: int = int(game.best_score)
	game._restart_run()
	assert(game.phase == 0 and game.wave == 1)
	assert(game.score == 0 and game.points == 0)
	assert(game.player_health == 100.0 and game.player_max_health == 100.0)
	assert(game.best_score == recorded_best and game.best_score >= saved_best)
	if store.enabled():
		assert(not store.run_custom)

	game.queue_free()
	await process_frame
	print("[ULTIMA_ROUNDA_SMOKE_PASS] title waves zombies scoring upgrades pause game-over retry local-best")
	quit(0)

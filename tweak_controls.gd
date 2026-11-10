extends SceneTree

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var store := root.get_node("TuningStore")
	assert(store.descriptors.size() == 10)
	assert(store.enabled() == OS.is_debug_build())
	store.reset_all()
	store.begin_run()
	assert(not store.set_value("missing", 1.0))
	assert(not store.set_value("enemy_speed", NAN))
	assert(not store.set_value("player_speed", "fast"))
	if store.enabled():
		var game: Node = (load("res://scenes/game.tscn") as PackedScene).instantiate()
		root.add_child(game)
		await process_frame
		game.set_process(false)
		assert(store.set_value("player_speed", 420.0))
		assert(store.active_value("player_speed") == 420.0)
		assert(store.set_value("fire_delay", 0.20))
		assert(store.active_value("fire_delay") == 0.16)
		store.apply_boundary("NEXT_ATTACK", ["fire_delay"])
		assert(store.active_value("fire_delay") == 0.20)
		assert(store.set_value("enemy_health", 2.0))
		assert(store.active_value("enemy_health") == 0.5)
		game.spawn_zombie_at(Vector2(900, 360), 0)
		assert(int(game.zombies[0].hp) == 2)
		assert(store.run_custom)
		var descriptor: Dictionary = store.descriptor("enemy_bullet_speed")
		var control: Dictionary = root.get_node("TuningBridge").control_for(descriptor)
		assert(str(control.description).contains("siguiente aparición"))
		assert(store.set_value("enemy_count", 1.5))
		assert(store.active_value("enemy_count") == 1.0)
		game._start_wave()
		assert(store.active_value("enemy_count") == 1.5)
		assert(game.spawn_remaining == int(round(6.0 + game.wave * 3.0) * 1.5))
		store.reset_all()
		assert(store.run_custom) # Custom eligibility is sticky for the active run.
		store.begin_run()
		assert(not store.run_custom)
		assert(store.active_value("enemy_health") == 0.5)
		game.queue_free()
		await process_frame
	print("[ULTIMA_ROUNDA_TWEAK_PASS] stable IDs, bounds, wave/spawn/attack boundaries and sticky integrity")
	quit(0)

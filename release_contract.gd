extends SceneTree

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var store := root.get_node_or_null("TuningStore")
	assert(store != null)
	assert(store.enabled() == OS.is_debug_build())
	assert(root.get_node_or_null("TweakControls") == null)
	if not ResourceLoader.exists("res://scripts/manus/preview/tuning_transport.gd"):
		assert(root.get_node_or_null("TuningBridge") == null)

	var game := load("res://scenes/game.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.set_process(false)
	assert(game.wave == 1 and game.phase == 0)
	assert(store.active_value("player_speed") == 350.0)
	assert(store.active_value("enemy_health") == 0.5)
	game.spawn_zombie_at(Vector2(930, 360), 0)
	assert(game.zombies.size() == 1)
	assert(int(game.zombies[0].hp) == 1)
	game._shoot()
	assert(game.bullets.size() == 1)
	for child in game.get_children():
		assert(not (child is HTTPRequest))
	game.queue_free()
	await process_frame
	print("[ULTIMA_ROUNDA_RELEASE_PASS] default simulation, local gameplay and preview boundary")
	quit(0)

extends Node

func _ready() -> void:
	call_deferred("_run")

func _capture(name: String) -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	var dir := OS.get_environment("GAME_CAPTURE_DIR")
	if dir.is_empty():
		dir = ProjectSettings.globalize_path("user://captures")
	var mkdir_result := DirAccess.make_dir_recursive_absolute(dir)
	assert(mkdir_result == OK or mkdir_result == ERR_ALREADY_EXISTS)
	var image := get_viewport().get_texture().get_image()
	var result := image.save_png(dir.path_join(name + ".png"))
	assert(result == OK)

func _run() -> void:
	var title: Node = (load("res://scenes/title_screen.tscn") as PackedScene).instantiate()
	add_child(title)
	await _capture("title")
	title.queue_free()
	await get_tree().process_frame

	var game: Node = (load("res://scenes/game.tscn") as PackedScene).instantiate()
	add_child(game)
	await get_tree().process_frame
	game.set_process(false)
	game.set_process_unhandled_input(false)
	game.wave = 5
	game.wave_banner_timer = 0.0
	game.player_pos = Vector2(640, 418)
	game.player_health = 74.0
	game.points = 735
	game.score = 2180
	game.best_score = 2640
	game.spawn_remaining = 4
	game.zombies.clear()
	game.spawn_zombie_at(Vector2(371, 316), 0)
	game.spawn_zombie_at(Vector2(999, 343), 1)
	game.spawn_zombie_at(Vector2(875, 540), 2)
	game.queue_redraw()
	await _capture("gameplay")

	game.phase = 1
	game.points = 735
	game.shop_purchased = false
	game.queue_redraw()
	await _capture("mejoras")

	game.phase = 2
	game.queue_redraw()
	await _capture("pausa")

	game.phase = 3
	game.queue_redraw()
	await _capture("derrota")

	print("[DEBUG_CAPTURE_PASS] title gameplay upgrades pause game-over")
	for child in get_children():
		child.queue_free()
	await get_tree().process_frame
	get_tree().quit(0)

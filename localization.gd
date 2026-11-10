extends SceneTree

var failures: Array[String] = []

func _initialize() -> void:
	_run.call_deferred()

func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)

func _run() -> void:
	var i18n := root.get_node("I18n")
	_check(i18n.get_locale() == "es", "startup language is Spanish")
	_check(i18n.catalog_keys("es").size() >= 70, "Spanish catalog loaded")
	_check(i18n.catalog_keys("en").is_empty(), "English is not exposed as a second game language")
	_check(i18n.t("title.play") == "ENTRAR A LA ARENA", "start menu copy")
	_check(i18n.t("hud.wave", {"round": 8}) == "RONDA 8", "round placeholder")
	_check(i18n.t("results.score", {"score": "001245"}) == "PUNTUACIÓN  001245", "score placeholder")
	_check(i18n.set_locale("es"), "Spanish selection is accepted")
	_check(not i18n.set_locale("en") and i18n.get_locale() == "es", "unsupported locale cannot switch the game")

	var catalog: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://localization/es.json"))
	_check(catalog is Dictionary, "catalog JSON parses")
	if catalog is Dictionary:
		var pattern := RegEx.new()
		pattern.compile('I18n\\.t\\("([^"\\n]+)"')
		for script_path in ["res://scripts/game.gd", "res://scripts/title_screen.gd"]:
			var source := FileAccess.get_file_as_string(script_path)
			for match_result in pattern.search_all(source):
				_check(catalog.has(match_result.get_string(1)), "missing game string: " + match_result.get_string(1))

	var title = load("res://scenes/title_screen.tscn").instantiate()
	root.add_child(title)
	await process_frame
	_check(not title.starting and not str(title.auth_hint).is_empty(), "Spanish title and account status render")
	title.queue_free()
	await process_frame
	var game = load("res://scenes/game.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.set_process(false)
	_check(game._upgrade_cards()[0].title == "POTENCIA", "upgrade title uses Spanish")
	_check(game._upgrade_cards()[0].description == "Daño por disparo: 1", "upgrade description uses Spanish")
	_check(i18n.t("tuning.label.ship_speed") == "Velocidad del sobreviviente", "Tweak uses Spanish labels")
	game.queue_free()
	await process_frame
	if failures.is_empty():
		print("[ULTIMA_ROUNDA_LOCALIZATION_PASS] Spanish menu, gameplay, upgrades, tuning and placeholders")
	else:
		for failure in failures:
			push_error("[ULTIMA_ROUNDA_LOCALIZATION_FAIL] " + failure)
	quit(0 if failures.is_empty() else 1)

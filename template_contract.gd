extends SceneTree

var failures: Array[String] = []

func _initialize() -> void:
	_run.call_deferred()

func _check(ok: bool, detail: String) -> void:
	if not ok:
		failures.append(detail)

func _run() -> void:
	_check(ProjectSettings.get_setting("application/config/name") == "Última Ronda", "project title")
	_check(ProjectSettings.get_setting("display/window/stretch/aspect") == "keep", "fixed aspect")
	_check(ProjectSettings.get_setting("display/window/size/viewport_width") == 1280, "canvas width")
	_check(ProjectSettings.get_setting("display/window/size/viewport_height") == 720, "canvas height")
	_check(ProjectSettings.get_setting("application/config/icon") == "res://assets/share/favicon_runtime.png", "game-specific icon")

	var font_path := "res://assets/template/fonts/ui_regular.tres"
	var font := load(font_path) as FontVariation
	_check(font != null, "runtime composite font")
	if font != null:
		_check(font.resource_path == font_path, "runtime inherited project font")
		_check(font.get_font_name().begins_with("Exo 2"), "Exo 2 primary")
		_check(font.base_font is FontFile and not font.base_font.allow_system_fallback, "no primary system fallback")
		var cjk := font.fallbacks[0] as FontVariation if font.fallbacks.size() == 1 else null
		_check(cjk != null and cjk.base_font is FontFile and cjk.base_font.get_font_name().begins_with("Noto Sans SC") and not cjk.base_font.allow_system_fallback, "bundled Noto Sans SC fallback without system fallback")
		for char in "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz !%+-/.:,()¿¡ÁÉÍÓÚÜÑáéíóúüñ×·":
			_check(font.has_char(char.unicode_at(0)), "Spanish and UI glyph: " + char)

	var catalog: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://localization/es.json"))
	_check(catalog is Dictionary and catalog.size() >= 70, "Spanish catalog is bundled")
	if catalog is Dictionary and font != null:
		for value: Variant in catalog.values():
			for char in str(value):
				if char.unicode_at(0) >= 32:
					_check(font.has_char(char.unicode_at(0)), "catalog glyph: " + char)

	var code_pattern := RegEx.new()
	code_pattern.compile('"([^"\\n]*)"')
	for script_path in ["res://scripts/game.gd", "res://scripts/title_screen.gd"]:
		var source := FileAccess.get_file_as_string(script_path)
		for match_result in code_pattern.search_all(source):
			for char in match_result.get_string(1):
				if char.unicode_at(0) >= 32 and font != null:
					_check(font.has_char(char.unicode_at(0)), "runtime glyph: " + char)

	var arena := load("res://assets/game/arena_runtime.png") as Texture2D
	var survivor := load("res://assets/game/superviviente_runtime.png") as Texture2D
	var zombie := load("res://assets/game/zombi_runtime.png") as Texture2D
	var icon := load("res://assets/share/favicon_runtime.png") as Texture2D
	var web_favicon := load("res://assets/share/favicon_web.png") as Texture2D
	var cover := load("res://assets/share/og_runtime_fixed.png") as Texture2D
	_check(arena != null and arena.get_width() >= 1280 and arena.get_height() >= 720, "arena covers canvas")
	_check(survivor != null and zombie != null, "runtime actors load")
	_check(icon != null and icon.get_width() == icon.get_height(), "square application icon")
	_check(web_favicon != null and web_favicon.get_width() == 32 and web_favicon.get_height() == 32, "32 by 32 web favicon")
	_check(cover != null and cover.get_width() == 1200 and cover.get_height() == 675, "OG cover size")

	var title = load("res://scenes/title_screen.tscn").instantiate()
	root.add_child(title)
	await process_frame
	_check(title.has_method("_start_game") and not title.starting, "title flow is reachable")
	_check(not str(title.auth_hint).is_empty(), "account status is explicit")
	title.queue_free()
	await process_frame

	var game = load("res://scenes/game.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.set_process(false)
	_check(game.wave == 1 and game.phase == 0, "game starts in round one")
	_check(game._upgrade_cards().size() == 3, "between-round shop has three upgrades")
	_check(root.get_node("TuningStore").descriptors.size() == 10, "ten inherited stable tuning values")
	_check(root.get_node("TuningStore").enabled() == OS.is_debug_build(), "release/debug gate")
	_check(game.SAVE_PATH == "user://ultima_ronda.cfg", "local high-score path")
	_check(game.get_child_count() == 0, "game simulation does not introduce unused online/audio nodes")
	game.queue_free()
	await process_frame

	if failures.is_empty():
		print("[ULTIMA_ROUNDA_CONTRACT_PASS] viewport, fonts, Spanish copy, resources, title, tuning and local saves")
	else:
		for failure in failures:
			push_error("[ULTIMA_ROUNDA_CONTRACT_FAIL] " + failure)
	quit(0 if failures.is_empty() else 1)

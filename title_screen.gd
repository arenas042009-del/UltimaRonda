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
const PLAY_RECT := Rect2(82, 452, 342, 72)
const ACCOUNT_RECT := Rect2(82, 548, 342, 52)
const AMBER := Color(1.0, 0.43, 0.18)
const PALE := Color(0.96, 0.94, 0.87)
const TEAL := Color(0.35, 0.82, 0.70)
const MUTED := Color(0.72, 0.76, 0.69)

var elapsed := 0.0
var best_score := 0
var starting := false
var authenticated := false
var auth_available := false
var auth_hint := ""

func _ready() -> void:
	var config := ConfigFile.new()
	if config.load("user://ultima_ronda.cfg") == OK:
		best_score = int(config.get_value("progress", "best_score", 0))
	if ManusAuth.auth_state_changed.is_connected(_on_auth_state_changed) == false:
		ManusAuth.auth_state_changed.connect(_on_auth_state_changed)
	ManusAuth.auth_error.connect(_on_auth_error)
	_on_auth_state_changed(ManusAuth.get_session())
	set_process(true)
	set_process_unhandled_input(true)
	queue_redraw()

func _process(delta: float) -> void:
	elapsed += minf(delta, 0.05)
	queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
	if starting:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER or event.keycode == KEY_SPACE:
			_start_game()
			get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if PLAY_RECT.has_point(event.position):
			_start_game()
			get_viewport().set_input_as_handled()
		elif ACCOUNT_RECT.has_point(event.position):
			_handle_account_click()
			get_viewport().set_input_as_handled()

func _start_game() -> void:
	if starting:
		return
	starting = true
	get_tree().change_scene_to_file("res://scenes/game.tscn")

func _handle_account_click() -> void:
	if not auth_available:
		auth_hint = I18n.t("auth.web_only")
		return
	# Invoke directly from the input gesture so the browser retains user activation.
	if authenticated:
		ManusAuth.logout()
	else:
		ManusAuth.login()

func _on_auth_state_changed(state: Dictionary) -> void:
	var status := str(state.get("status", "logged_out"))
	var user: Variant = state.get("user", null)
	authenticated = status == "authenticated" and user is Dictionary
	auth_available = OS.has_feature("web") and status != "unavailable"
	if authenticated:
		auth_hint = I18n.t("auth.connected")
	elif not OS.has_feature("web"):
		auth_hint = I18n.t("auth.web_only")
	elif status == "unavailable":
		auth_hint = I18n.t("auth.not_available")
	else:
		auth_hint = I18n.t("auth.optional")
	queue_redraw()

func _on_auth_error(code: String) -> void:
	match code:
		"online_preview_requires_checkpoint", "online_preview_required", "auth_bootstrap_missing":
			auth_hint = I18n.t("auth.not_available")
		"auth_unavailable":
			auth_hint = I18n.t("auth.retry")
		_:
			auth_hint = I18n.t("auth.retry")
	queue_redraw()

func _draw() -> void:
	draw_texture_rect(ARENA, Rect2(Vector2.ZERO, Vector2(W, H)), false)
	draw_rect(Rect2(Vector2.ZERO, Vector2(W, H)), Color(0.012, 0.025, 0.023, 0.66))
	draw_rect(Rect2(0, 0, 630, H), Color(0.012, 0.022, 0.021, 0.70))
	for y in range(34, 700, 56):
		draw_line(Vector2(50, y), Vector2(1226, y), Color(0.70, 0.88, 0.78, 0.035), 1.0)
	draw_line(Vector2(617, 38), Vector2(617, H - 40), Color(AMBER, 0.42), 1.0)
	HoloUI.panel(self, Rect2(71, 55, 445, 38), TEAL, 0.8, 6.0, false, 5.0)
	HoloUI.glow_text(self, MEDIUM_FONT, Vector2(90, 81), I18n.t("title.kicker"), 13, TEAL, TEAL, HORIZONTAL_ALIGNMENT_LEFT, 410.0, 0.25)
	HoloUI.chroma_text(self, TITLE_FONT, Vector2(85, 196), "ÚLTIMA", 80, PALE, AMBER, HORIZONTAL_ALIGNMENT_LEFT, 495.0, 1.8)
	HoloUI.chroma_text(self, TITLE_FONT, Vector2(82, 288), "RONDA", 94, Color(1.0, 0.55, 0.29), AMBER, HORIZONTAL_ALIGNMENT_LEFT, 495.0, 1.6)
	HoloUI.glow_text(self, BOLD_FONT, Vector2(88, 332), I18n.t("title.tagline"), 20, PALE, TEAL, HORIZONTAL_ALIGNMENT_LEFT, 500.0, 0.35)
	HoloUI.glow_text(self, UI_FONT, Vector2(88, 374), I18n.t("title.description"), 16, MUTED, TEAL, HORIZONTAL_ALIGNMENT_LEFT, 486.0, 0.15)
	HoloUI.panel(self, Rect2(82, 402, 342, 28), AMBER, 0.68, 5.0, false, 0.0)
	HoloUI.glow_text(self, MEDIUM_FONT, Vector2(94, 421), I18n.t("title.best", {"score": "%07d" % best_score}), 14, Color(1.0, 0.84, 0.59), AMBER, HORIZONTAL_ALIGNMENT_LEFT, 318.0, 0.22)
	_draw_button(PLAY_RECT, I18n.t("title.play"), true)
	_draw_account_button()
	HoloUI.glow_text(self, UI_FONT, Vector2(86, 637), I18n.t("title.controls"), 13, MUTED, TEAL, HORIZONTAL_ALIGNMENT_LEFT, 520.0, 0.1)
	HoloUI.glow_text(self, UI_FONT, Vector2(86, 674), I18n.t("title.footer"), 12, Color(MUTED, 0.82), TEAL, HORIZONTAL_ALIGNMENT_LEFT, 520.0, 0.08)
	_draw_actor()

func _draw_button(rect: Rect2, label: String, highlighted: bool) -> void:
	var fill := Color(0.25, 0.085, 0.035, 0.98) if highlighted else Color(0.025, 0.09, 0.078, 0.95)
	var accent := AMBER if highlighted else TEAL
	if rect.has_point(get_viewport().get_mouse_position()):
		fill = fill.lightened(0.18)
	draw_rect(rect, fill)
	draw_rect(rect, Color(accent, 0.9), false, 1.6)
	HoloUI.glow_text(self, BOLD_FONT, rect.position + Vector2(12, rect.size.y * 0.65), label, 19, PALE, accent, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x - 24.0, 0.38)

func _draw_account_button() -> void:
	var label := I18n.t("auth.logout") if authenticated else I18n.t("auth.login")
	if not auth_available:
		label = I18n.t("auth.web_only_button")
	var hovered := ACCOUNT_RECT.has_point(get_viewport().get_mouse_position())
	var accent := TEAL if auth_available else Color(0.48, 0.58, 0.54)
	var fill := Color(0.025, 0.09, 0.078, 0.91)
	if hovered and auth_available:
		fill = fill.lightened(0.18)
	draw_rect(ACCOUNT_RECT, fill)
	draw_rect(ACCOUNT_RECT, Color(accent, 0.65), false, 1.0)
	HoloUI.glow_text(self, MEDIUM_FONT, ACCOUNT_RECT.position + Vector2(10, 32), label, 15, PALE, accent, HORIZONTAL_ALIGNMENT_CENTER, ACCOUNT_RECT.size.x - 20, 0.22)
	HoloUI.glow_text(self, UI_FONT, Vector2(ACCOUNT_RECT.position.x, ACCOUNT_RECT.end.y + 17), auth_hint, 12, MUTED, accent, HORIZONTAL_ALIGNMENT_LEFT, 410.0, 0.08)

func _draw_actor() -> void:
	_draw_ellipse(Vector2(954, 591), 125.0, 29.0, Color(0.0, 0.01, 0.008, 0.52))
	var survivor_position := Vector2(918, 409)
	var survivor_scale := Vector2(302, 302)
	var player_angle := -0.10 + sin(elapsed * 0.65) * 0.025
	_draw_sprite(SURVIVOR, survivor_position, survivor_scale, player_angle, Color(1.0, 0.89, 0.70))
	var zombie_position := Vector2(1120, 512)
	_draw_sprite(ZOMBIE, zombie_position, Vector2(155, 155), 0.0, Color(0.71, 0.88, 0.68, 0.78))
	for offset in range(3):
		var point := Vector2(744 + offset * 82, 570 + sin(elapsed * 1.2 + offset) * 5.0)
		draw_circle(point, 2.0 + float(offset % 2), Color(AMBER, 0.60))

func _draw_sprite(texture: Texture2D, position: Vector2, size: Vector2, angle: float, tint: Color) -> void:
	draw_set_transform(position, angle, Vector2(size.x / float(texture.get_width()), size.y / float(texture.get_height())))
	draw_texture(texture, -Vector2(texture.get_size()) * 0.5, tint)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _draw_ellipse(center: Vector2, radius_x: float, radius_y: float, color: Color) -> void:
	var points := PackedVector2Array()
	for index in range(28):
		var angle := TAU * float(index) / 28.0
		points.append(center + Vector2(cos(angle) * radius_x, sin(angle) * radius_y))
	draw_colored_polygon(points, color)

extends Node
## HTML must await ManusAuth.prepare() before engine.startGame().
signal auth_state_changed(state: Dictionary)
signal auth_error(code: String)

var _bridge
var _callback
var _on_change

func _ready() -> void:
	if not OS.has_feature("web"):
		auth_error.emit("online_preview_required")
		return
	_bridge = JavaScriptBridge.get_interface("ManusAuth")
	if _bridge == null:
		auth_error.emit("auth_bootstrap_missing")
		return
	_callback = JavaScriptBridge.create_callback(_completed)
	_on_change = JavaScriptBridge.create_callback(_changed)
	JavaScriptBridge.get_interface("window").addEventListener("manus-auth-change", _on_change)
	auth_state_changed.emit(get_session())

func _exit_tree() -> void:
	if _on_change != null:
		JavaScriptBridge.get_interface("window").removeEventListener("manus-auth-change", _on_change)

func get_session() -> Dictionary:
	if _bridge == null:
		return {"status": "unavailable", "user": null}
	var value = JavaScriptBridge.get_interface("JSON").stringify(_bridge.get_session())
	var parsed = JSON.parse_string(str(value))
	return parsed if parsed is Dictionary else {"status": "unavailable", "user": null}

func login() -> void:
	_run("login")

func logout() -> void:
	_run("logout")

# Call directly from a button/input handler to preserve browser user activation.
func open_standalone() -> void:
	if _bridge == null:
		auth_error.emit("auth_bootstrap_missing")
		return
	_bridge.open_standalone()

func _run(operation: String) -> void:
	if _bridge == null:
		auth_error.emit("auth_bootstrap_missing")
		return
	# Retain the Godot callback until the Promise settles; no token crosses the bridge.
	_bridge.invoke(operation, _callback)

func _completed(args: Array) -> void:
	if not str(args[0]).is_empty():
		auth_error.emit(str(args[0]))

func _changed(_args: Array) -> void:
	auth_state_changed.emit(get_session())

extends Node

signal locale_changed(locale: String)

const DEFAULT_LOCALE := "es"
const SAVE_PATH := "user://language.cfg"
const CATALOG_PATH := "res://localization/es.json"

var _catalog: Dictionary = {}
var save_succeeded := true

func _ready() -> void:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(CATALOG_PATH))
	if not parsed is Dictionary:
		push_error("I18n: catálogo español no válido")
		return
	_catalog = parsed
	TranslationServer.set_locale(DEFAULT_LOCALE)

func t(key: String, placeholders: Dictionary = {}) -> String:
	var result := str(_catalog.get(key, key))
	for token: Variant in placeholders:
		result = result.replace("{%s}" % str(token), str(placeholders[token]))
	return result

func get_locale() -> String:
	return DEFAULT_LOCALE

func set_locale(locale: String) -> bool:
	if locale != DEFAULT_LOCALE:
		return false
	locale_changed.emit(DEFAULT_LOCALE)
	return true

func catalog_keys(locale: String) -> Array:
	return _catalog.keys() if locale == DEFAULT_LOCALE else []

static func locale_for_system(_system_locale: String) -> String:
	return DEFAULT_LOCALE

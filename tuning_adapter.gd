extends "res://scripts/manus/preview/tuning_transport.gd"

func store() -> Variant:
	return get_node_or_null("/root/TuningStore")

func settings() -> Array:
	return store().descriptors

func requested(setting: Dictionary) -> Variant:
	return store().requested[setting.id]

func active(setting: Dictionary) -> Variant:
	return store().active[setting.id]

func commit(patch: Dictionary) -> bool:
	return store().apply_preview_patch(patch)

func control_for(setting: Dictionary) -> Dictionary:
	var localized := setting.duplicate(true)
	localized["label_key"] = str(setting.label)
	localized["description_key"] = str(setting.description)
	localized["category_key"] = "tweak.category." + str(setting.category).to_lower()
	var result: Dictionary = super.control_for(localized)
	var mode := str(setting.get("mode", "LIVE"))
	var timing_keys := {
		"NEXT_ATTACK": "tweak.mode.next_attack",
		"NEXT_WAVE": "tweak.mode.next_wave",
		"NEXT_SPAWN": "tweak.mode.next_spawn",
		"NEXT_BOSS": "tweak.mode.next_brute",
	}
	if setting.id == "enemy_bullet_speed":
		timing_keys["NEXT_ATTACK"] = "tweak.mode.next_spawn"
	if timing_keys.has(mode):
		var suffix := mode.replace("_", " ").capitalize() + "."
		var description := str(result.get("description", ""))
		if description.ends_with(suffix):
			description = description.left(description.length() - suffix.length()).strip_edges()
		result["description"] = (description + " " + translate(str(timing_keys[mode]))).strip_edges()
	return result

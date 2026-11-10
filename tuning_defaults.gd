class_name UltimaRondaTuningDefaults
extends RefCounted

const PLAYER_SPEED := 350.00
const FIRE_DELAY := 0.160
const ENEMY_COUNT := 1.00
const ENEMY_HEALTH := 0.50
const ENEMY_SPEED := 1.00
const ENEMY_BULLET_SPEED := 1.00
const BOSS_HEALTH := 1.75
const HIT_RADIUS := 7.00
const ENERGY_RATE := 1.25
const BONE_DROP := 0.0150

# Stable parameter IDs/defaults/bounds/boundaries remain managed by TuningStore.
# Labels and descriptions are presented in the session language selected in the Blueprint (Spanish).
static func descriptors() -> Array[Dictionary]:
	return [
		{"id": "player_speed", "label": "tuning.label.ship_speed", "description": "tuning.description.player_speed", "category": "PLAYER", "type": "float", "default": PLAYER_SPEED, "min": 220, "max": 520, "step": 10, "mode": "LIVE", "unit": "px/s", "integrity": "GAMEPLAY"},
		{"id": "fire_delay", "label": "tuning.label.fire_interval", "description": "tuning.description.fire_delay", "category": "PLAYER", "type": "float", "default": FIRE_DELAY, "min": 0.08, "max": 0.3, "step": 0.01, "mode": "NEXT_ATTACK", "unit": "s", "integrity": "GAMEPLAY"},
		{"id": "enemy_count", "label": "tuning.label.density", "description": "tuning.description.enemy_count", "category": "ENEMIES", "type": "float", "default": ENEMY_COUNT, "min": 0.5, "max": 2, "step": 0.1, "mode": "NEXT_WAVE", "unit": "×", "integrity": "GAMEPLAY"},
		{"id": "enemy_health", "label": "tuning.label.enemy_health", "description": "tuning.description.enemy_health", "category": "ENEMIES", "type": "float", "default": ENEMY_HEALTH, "min": 0.5, "max": 3, "step": 0.1, "mode": "NEXT_SPAWN", "unit": "×", "integrity": "GAMEPLAY"},
		{"id": "enemy_speed", "label": "tuning.label.enemy_speed", "description": "tuning.description.enemy_speed", "category": "ENEMIES", "type": "float", "default": ENEMY_SPEED, "min": 0.5, "max": 1.8, "step": 0.05, "mode": "LIVE", "unit": "×", "integrity": "GAMEPLAY"},
		{"id": "enemy_bullet_speed", "label": "tuning.label.bullet_speed", "description": "tuning.description.spawn_rate", "category": "ENEMIES", "type": "float", "default": ENEMY_BULLET_SPEED, "min": 0.5, "max": 1.8, "step": 0.05, "mode": "NEXT_ATTACK", "unit": "×", "integrity": "GAMEPLAY"},
		{"id": "boss_health", "label": "tuning.label.boss_health", "description": "tuning.description.brute_health", "category": "ENEMIES", "type": "float", "default": BOSS_HEALTH, "min": 0.5, "max": 5, "step": 0.25, "mode": "NEXT_BOSS", "unit": "×", "integrity": "GAMEPLAY"},
		{"id": "hit_radius", "label": "tuning.label.hit_radius", "description": "tuning.description.hit_radius", "category": "PLAYER", "type": "float", "default": HIT_RADIUS, "min": 3, "max": 12, "step": 1, "mode": "LIVE", "unit": "px", "integrity": "GAMEPLAY"},
		{"id": "energy_rate", "label": "tuning.label.recharge", "description": "tuning.description.recovery", "category": "PLAYER", "type": "float", "default": ENERGY_RATE, "min": 0.5, "max": 4, "step": 0.25, "mode": "LIVE", "unit": "PV/s", "integrity": "GAMEPLAY"},
		{"id": "bone_drop", "label": "tuning.label.bone_drop", "description": "tuning.description.medkit_drop", "category": "GAMEPLAY", "type": "float", "default": BONE_DROP, "min": 0, "max": 0.05, "step": 0.005, "mode": "LIVE", "unit": "%", "integrity": "GAMEPLAY"},
	]

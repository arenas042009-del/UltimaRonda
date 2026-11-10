import { dirname } from 'node:path'
import { fileURLToPath } from 'node:url'
import { runGodotCheck } from './godot-check.mjs'

const root = dirname(dirname(fileURLToPath(import.meta.url)))
const checks = [
  ['smoke', '[ULTIMA_ROUNDA_SMOKE_PASS]'],
  ['template_contract', '[ULTIMA_ROUNDA_CONTRACT_PASS]'],
  ['localization', '[ULTIMA_ROUNDA_LOCALIZATION_PASS]'],
  ['tweak_controls', '[ULTIMA_ROUNDA_TWEAK_PASS]'],
]
for (const [script, marker] of checks) {
  runGodotCheck(process.env.GODOT_BIN || 'godot', ['--headless', '--path', root, '--script', `test/${script}.gd`], marker, root)
}

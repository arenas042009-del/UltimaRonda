import assert from 'node:assert/strict'
import { existsSync, readFileSync } from 'node:fs'
import { dirname, join } from 'node:path'
import { fileURLToPath } from 'node:url'
import test from 'node:test'

const root = dirname(dirname(fileURLToPath(import.meta.url)))
const read = (path) => readFileSync(join(root, path), 'utf8')

test('Última Ronda ships Spanish game text, bundled fonts and matching share art', () => {
  const project = read('project.godot')
  assert.match(project, /config\/name="Última Ronda"/)
  assert.match(project, /config\/icon="res:\/\/assets\/share\/favicon_runtime\.png"/)

  const composite = read('assets/template/fonts/ui_regular.tres')
  assert.ok(composite.includes('res://assets/template/fonts/Exo2-VF.subset.woff2'))
  assert.ok(composite.includes('res://assets/template/fonts/noto_sans_sc_regular.tres'))
  const cjk = read('assets/template/fonts/noto_sans_sc_regular.tres')
  assert.ok(cjk.includes('res://assets/template/fonts/NotoSansSC-VF.subset.woff2'))

  const catalog = JSON.parse(read('localization/es.json'))
  assert.ok(Object.keys(catalog).length >= 70)
  assert.equal(catalog['title.play'], 'ENTRAR A LA ARENA')
  assert.ok(catalog['shop.damage_desc'].includes('{damage}'))
  assert.ok(catalog['tweak.mode.next_wave'].includes('ronda'))
  assert.doesNotMatch(JSON.stringify(catalog), /\p{Script=Han}/u)
  assert.match(read('autoload/i18n.gd'), /localization\/es\.json/)
  assert.doesNotMatch(read('autoload/i18n.gd'), /localization\/(?:en\.json|zh-CN\.json)/)

  for (const path of ['scripts/game.gd', 'scripts/title_screen.gd']) {
    assert.ok(read(path).includes('I18n.t('), path)
  }
  assert.ok(read('scripts/title_screen.gd').includes('"ÚLTIMA"'))
  assert.ok(read('scripts/title_screen.gd').includes('"RONDA"'))

  const share = JSON.parse(read('game-sharing.json'))
  assert.equal(share.title, 'Última Ronda')
  assert.ok(share.description.includes('zombis'))
  assert.equal(share.assets.og, 'assets/share/og_runtime_fixed.png')
  assert.equal(share.assets.favicon, 'assets/share/favicon_web.png')
  for (const path of Object.values(share.assets)) assert.ok(existsSync(join(root, path)), path)

  const presets = read('export_presets.cfg')
  assert.ok(presets.includes('localization/es.json'))
  assert.ok(presets.includes('localization/en.json'))
  assert.ok(presets.includes('localization/zh-CN.json'))
  assert.ok(read('assets.lock.json').includes('"arena"'))
})

# Provenance and license separation

## Font output — CC0 1.0 Universal

All `fonts/ManusCC0SansCJKSC-*.ttf` and `.woff2` files are released under CC0 1.0 Universal.
The license is recorded in font name IDs 13/14 and the pack's `LICENSE`. Attribution and
retention of a bundled license/copyright text file are not required to use, embed,
modify or redistribute these generated fonts. No OFL/Noto font data is incorporated.

## Skeletal input — unrestricted GlyphWiki permission

Source: <https://glyphwiki.org/dump.tar.gz>, retrieved 2026-09-16.
The server's archive timestamp was 2026-09-15 17:01:31 UTC.
Archive SHA-256: `6857f32ad7ff2efbbe9dd1eaa812cc4d843f8ed64f138872acc07802e185583b`.

The archive contains `dump_newest_only.txt`, `dump_all_versions.txt`, `LICENSE.txt`
and English/Japanese README files. The primary license grants unlimited permission to
use, copy and distribute the data, with or without modification, commercially or
non-commercially. It imposes no attribution or notice-retention condition. **The
upstream license is a custom unrestricted grant, not named CC0.** We retain its original
text here to make this build's provenance reviewable; its inclusion is not a downstream
game-distribution condition.

The font uses 6,547 selected whole-character glyphs: 6,513 mainland `u<hex>-g` forms and
34 punctuation/symbol forms. The complete recursive closure is 11,277 entries. Every
explicit historical `@version` reference is preserved. Unversioned references are bound
to the selected snapshot's current version, then written as explicit versions in the
frozen source. No components are fetched from a moving website during normal rebuilds.
The original font outline geometry is rendered from these skeletons with this project's
recorded sans profile, rather than copied from any existing font binary.

`source/glyphwiki-skeletons.json.gz` carries the frozen selected mappings and complete
component closure. Its hashes and build outputs appear in `metadata.json`.

## Authored build/design materials — CC0

This project's adapter, font compiler glue, validators, documentation and rendered
specimens are dedicated under CC0. GlyphWiki source data keeps the unrestricted grant
above. The skeleton source does not include KAGE renderer code.

## External build tools — their own licenses

- `@kurgm/kage-engine` 0.7.0: GPL-3.0, <https://github.com/kurgm/kage-engine>.
- FontTools 4.60.2: MIT, <https://github.com/fonttools/fonttools>.
- skia-pathops 0.8.0.post2: BSD-3-Clause, <https://github.com/fonttools/skia-pathops>.
- Brotli 1.2.0: MIT, <https://github.com/google/brotli>.
- Pillow, HarfBuzz and FreeType are used for validation/rendering only under their
  respective upstream licenses.

These tools are installed as development dependencies. Their source code and executables
are not embedded into the generated font files or distributed in games. This distinction
matters: the rendered font output does not contain the GPL compiler's code. GPLv3 section
2 says output is covered only when its content itself constitutes a covered work:
<https://www.gnu.org/licenses/gpl-3.0.html#section2>.

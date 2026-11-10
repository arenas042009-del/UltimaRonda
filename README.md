# ManusCC0 Sans CJK SC

A compact Simplified Chinese sans companion to the original ManusCC0 English UI family.
The generated font files are dedicated to the public domain under **CC0 1.0 Universal**.
They may be used, embedded, modified and redistributed commercially without attribution,
a credits screen, or keeping a copyright/license notice beside the font.

## Game usage

Keep **ManusCC0** as the primary family. Use **ManusCC0 Sans CJK SC** after it for Chinese
glyphs. Bundle `fonts/ManusCC0SansCJKSC-Regular.woff2` as the default game fallback for all
English weights. Each WOFF2 is below 1,000,000 bytes. The larger TTF files are authoring /
installation alternatives; do not bundle TTF and WOFF2 copies of the same face in a game.

The font contains **6,547 codepoints**: the existing shared game repertoire of 6,500 common
Simplified Chinese characters plus 47 game symbols/name/text extras. It is a bounded
repertoire, not every Chinese character. Rare player-name characters outside it are not
supported. Preserve such input rather than silently deleting unsupported characters.

The CJK faces have fixed 1,000-unit advances and match ManusCC0's 1,020 / -250 line metrics.
Regular is the default compact runtime face. Medium and Bold are optional independently
bundled faces for projects that require stronger Chinese emphasis; use only needed styles.

```css
@font-face {
  font-family: "ManusCC0 Sans CJK SC";
  src: url("ManusCC0SansCJKSC-Regular.woff2") format("woff2");
  font-weight: 400;
  font-style: normal;
  font-display: swap;
}
.game-ui { font-family: "ManusCC0", "ManusCC0 Sans CJK SC", sans-serif; }
```

## Provenance and editable source

The font is rendered from GlyphWiki skeletal data under its **unrestricted permission
license**. That upstream data license is not itself called CC0. It permits unlimited
use, copying and distribution, with or without modification, commercially or otherwise,
and imposes no attribution or notice-retention condition. The newly generated font
files and authored build/design files are released under CC0. No Noto / OFL font outlines,
font tables or rendered glyphs are used. See `PROVENANCE.md` for the pinned source and
separation of font, data and build-tool licenses.

`source/glyphwiki-skeletons.json.gz` is the complete editable skeletal source, including
exact historical component references. `source/build_font.py` and `render_kage.cjs`
record the geometry profile. To edit a glyph, decompress the JSON and change its selected
component data; preserve valid KAGE semantics and rerun validation.

## Rebuild

Use Python 3.9+ and Node.js, then install the pinned build-only dependencies:

```sh
python3 -m venv .venv
.venv/bin/pip install -r source/requirements.txt
(cd source && npm ci)
.venv/bin/python source/build_font.py --style all
.venv/bin/python source/validate_font.py
```

The external KAGE renderer is GPL-3.0 build software. It is installed by npm; its source
and runtime are not embedded in the font, not distributed with games, and not included
in this pack. Keep its own license intact when distributing the build tool itself.

## Size and performance

- Preserve shared radicals as skeletal components in the authoring source.
- Generate only the documented repertoire; omit unused language/vertical-layout tables.
- Use one Regular fallback at runtime unless additional styles are needed.
- Resolve overlapping stroke contours and normalize winding before compilation.
- Remove redundant polygon samples with maximum 1 font-unit geometric deviation
  (0.024 pixel at 24 px), without rasterizing glyphs or removing characters.
- Use compact glyph-name-free TrueType outlines, then lossless WOFF2/Brotli compression.
- Do not enable whole-font MSDF caches or large prebaked glyph atlases by default.
- Loader fonts should be small subsets of this same CC0 source, containing the union of
  loader-localization text. They do not replace the full runtime repertoire for user input.

See `proofs/` for build, repertoire, outline, shaping and rendering checks. CC0 has no
warranty; this release does not claim a linguistic review of every rare character.

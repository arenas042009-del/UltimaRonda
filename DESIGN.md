# ManusCC0 Sans CJK SC — design and construction

This is an original rendering profile built from permission-cleared Chinese stroke
skeletons. It is not an outline modification of Noto or a claim that conventional Han
character structures were invented by this project.

- Family: ManusCC0 Sans CJK SC; release 1.000.
- Sans / Gothic construction with low contrast, flat terminals and gently curved turns.
- Proportions complement the calm, open UI rhythm of the original ManusCC0 Latin family.
- 1,000 units per em; 1,000-unit glyph advance; CJK design area maps KAGE's 200-unit box
  into a 900-unit box at x=50..950 and y=-50..850. Optical overshoots remain within line bounds.
- Shared ascent 1,020; descent -250; line gap 0. ManusCC0 cap-height metadata 720 and
  x-height 540 are retained for line alignment; Chinese glyphs occupy their larger visual box.
- Regular stroke target 58.5 units; Medium 67.5; Bold 76.5. Dense Chinese characters use
  lighter stems than Latin to keep their counters open at game UI sizes.
- Curve sampling uses KAGE rate 50; bend parameter 8. Source skeletons use the mainland
  `-g` whole-character variant for all 6,513 Han glyphs. The remaining 34 characters are
  punctuation or game symbols, selected from their full Unicode glyphs.
- Pin all 11,277 referenced source/component versions. Do not substitute the latest version
  for explicitly older references. An unversioned reference is pinned to its snapshot version.
- Normalize stroke-contour winding before overlap removal. This avoids accidental holes
  where independent strokes cross.
- Remove redundant samples with a 1-unit error threshold; retain all nonempty glyphs and
  full metric precision needed for runtime layout. No bitmap trace or lossy font compressor.
- Use a visible outlined box for `.notdef`. Never report it as a supported character.
- Each style is a separate real outline export, with fixed advances across styles.

The production runtime default is Regular. The pack may offer heavier optional faces;
there is no requirement to ship all styles in each game.

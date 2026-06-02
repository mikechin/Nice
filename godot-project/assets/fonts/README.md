# Fonts

Three families, all licensed under the SIL Open Font License 1.1.
The OFL.txt for each family is included alongside its font file as the license requires.

| File | Family | Source |
|---|---|---|
| `Manrope-VariableFont.ttf` | Manrope (UI) — 200–800 weight axis | https://github.com/sharanda/manrope |
| `NotoSerifSC-VariableFont.ttf` | Noto Serif SC (Chinese hero) — 200–900 weight axis | https://github.com/notofonts/noto-cjk |
| `JetBrainsMono-VariableFont.ttf` | JetBrains Mono (data, tokens) — 100–800 weight axis | https://github.com/JetBrains/JetBrainsMono |

Noto Serif SC is ~24 MB because it ships every simplified CJK glyph. We only
need ~1,350 (HSK 2–5); a subsetting pass can drop this to under 2 MB before
shipping. Tracked as a Phase 4 polish task.

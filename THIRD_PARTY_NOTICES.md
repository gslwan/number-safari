# Number Safari — third-party notices

## Godot Engine

Number Safari uses Godot Engine, licensed under the MIT License.
See https://godotengine.org/license/.

[`licenses/GODOT-NOTICES.txt`](licenses/GODOT-NOTICES.txt) contains the engine
license, third-party copyright information, and third-party license texts
reported by the installed Godot 4.7.2 engine. Godot and its dependencies retain
their own notices; the project's license does not replace them.

When changing engine versions or export templates, refresh and verify these
notices against the engine distributed with the game.

## Artwork, sound, and fonts

- Lion artwork: see [`assets/README.md`](assets/README.md) for origin, credit,
  AI-assisted material scope, and CC BY 4.0 terms.
- Sound effects are synthesized by `scripts/sfx.gd`; no external audio files
  are included in this project.
- The game requests locally installed system fonts. No system font files are
  bundled in this source tree. Godot's own embedded components are covered by
  the engine notices above.

## Binary release packaging

Include these readable files beside the exported game in each release archive:

- `LICENSE`
- `THIRD_PARTY_NOTICES.md`
- `assets/README.md` (preserve its directory or adjust its relative links)
- `licenses/CC-BY-4.0.txt`
- `licenses/GODOT-NOTICES.txt`

Merely adding files to the source repository does not ensure they accompany an
exported executable. Check the actual release archive before publishing.

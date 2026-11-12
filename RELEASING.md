# Publishing Number Safari on itch.io

The source lives on GitHub. Player distribution is moving to itch.io; the
Windows GitHub release has been withdrawn. The v0.1.0 source tag is retained.

## Build

Use Godot 4.7.2 standard with matching web export templates and Python 3.
Close the running game, then run:

```sh
python3 tools/release.py web
```

This runs all four test suites and writes `dist/NumberSafari-0.1.0-web.zip`
and its SHA-256 checksum. The ZIP contains `index.html` at its root, the
JavaScript/WebAssembly/PCK files, and all license and attribution notices.
The Web preset disables threads to avoid cross-origin-isolation requirements.
Move an existing archive aside before rebuilding; the command will not overwrite it.

## Upload

1. Create or edit a project at https://itch.io/game/new.
2. Set the title to **Number Safari**, kind to **HTML**, and pricing to **No payments**.
3. Upload `dist/NumberSafari-0.1.0-web.zip` and select **This file will be played in the browser**.
4. Use a 1280×720 viewport, Click to Play, and the fullscreen button.
5. State that a keyboard is required; do not mark the game mobile-friendly.
6. Add the description from `ITCH_PAGE.md`, screenshots, and the existing
   AI-assisted artwork disclosure where itch.io requests it.
7. Preview all three modes, sound, fullscreen, and history after reloading.
   Browser storage may be unavailable or cleared; history is local to that browser.
8. Publish the page and add the confirmed play URL near the top of `README.md`.

The legacy Windows export preset and packaging command remain available for
local development, but Windows binaries are no longer published on GitHub.

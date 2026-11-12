# Number Safari

A multiplication adventure built with Godot. Guide a lion through a number grid,
collect the multiples, and watch its body and mane grow.

## Play and develop

Open `project.godot` with **Godot 4.7.2** (standard edition; no .NET required),
then press **F6** to run the open scene or **F5** to run the project.
Alternatively, from the project directory:

```sh
godot --path .
```

Choose a times table from 2 to 12 and a mode:

| Mode | Rules |
| --- | --- |
| Beginner (default) | Collect by moving. One correct adjacent choice at each step; cleared tiles cannot be revisited. Multipliers ×1–×10. |
| Classic | Collect by moving. A guaranteed route spans the grid; cleared tiles can be revisited. Multipliers ×1–×10. |
| Freestyle | Move freely and choose when to eat. Multipliers ×1–×12. |

Arrow keys or WASD move. Space or Enter eats in Freestyle. Esc returns to the menu.
In Beginner and Classic, a wrong step plays the stomach-ache animation and returns
the lion to its previous tile. Each mistake reduces body and mane growth by one
step, down to the original cub size. Correct answers grow from that penalized state.
A mistake-free finish earns **Perfect! Impressive!**

Completed rounds are saved locally in Godot's `user://history.json`. The game
has no account system or network service.

## Tests and releases

With Python 3 and Godot on PATH, run `python3 tools/release.py test` to import
assets and run the board, Beginner, Classic, and growth tests. Close the game
before running integration tests, which temporarily write local history.

Run `python3 tools/release.py windows` to validate and package a Windows x86_64
release with licenses and a SHA-256 checksum. Matching Godot export templates
are required. See [the release guide](RELEASING.md) for setup and GitHub steps.

## Licenses

- **Code, scenes, configuration, tests, and project documentation:**
  [MIT](LICENSE), Copyright (c) 2026 [gslwan](https://github.com/gslwan).
- **Lion SVG artwork:** [CC BY 4.0](licenses/CC-BY-4.0.txt), to the extent
  copyright applies. See [artwork attribution and AI-assisted material notes](assets/README.md).
- **Godot and its dependencies:** retain their own licenses; see
  [third-party notices and release packaging instructions](THIRD_PARTY_NOTICES.md).

These are separate scopes, not a choice of either license for every file.
Third-party license texts retain their original terms.

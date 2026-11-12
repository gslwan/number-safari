# Releasing Number Safari

The first planned version is **0.1.0**. Publishing is a separate step from
preparation. Commands below run from the project root on macOS or Linux with
Python 3, Git, GitHub CLI, and Godot 4.7.2 standard installed.

## Validate and build

1. Install the matching **4.7.2 export templates** through Godot's
   **Editor → Manage Export Templates**.
2. Run `python3 tools/release.py test` to import assets and run all four test
   suites. Close the running game first: integration tests temporarily save
   completed rounds and restore the previous history on successful completion.
3. Run `python3 tools/release.py windows`. This repeats validation, exports
   Windows x86_64, and creates `dist/NumberSafari-0.1.0-windows-x86_64.zip`
   plus its `.zip.sha256` checksum. Set `GODOT` if the binary is not on PATH.
   Packaging includes the game, README, and all required attribution/license files.
4. Extract the archive on Windows and launch `NumberSafari.exe`. Check all
   three modes, sound, movement, mistakes, victory, replay, and saved history
   after restarting. Headless tests do not replace this check. The executable
   is unsigned.
5. Review `CHANGELOG.md`, change Unreleased to the release date, and confirm
   the version in `project.godot` and `tools/release.py` matches the tag.

## First GitHub upload

Review `git status --short` before committing. Generated caches, credentials,
and release output are ignored; Godot UID and import metadata are retained.

```sh
git add .
git diff --cached --stat
git commit -m "Prepare Number Safari 0.1.0"
gh auth login --hostname github.com
# Choose repository visibility deliberately; this example creates a private repo.
gh repo create gslwan/number-safari --private --source=. --remote=origin --push
```

If the repository already exists, add its remote and push instead of creating it.
After the Windows smoke check and a clean commit, create a draft release:

```sh
git tag -a v0.1.0 -m "Number Safari 0.1.0"
git push origin v0.1.0
gh release create v0.1.0 dist/NumberSafari-0.1.0-windows-x86_64.zip dist/NumberSafari-0.1.0-windows-x86_64.zip.sha256 --verify-tag --draft --title "Number Safari 0.1.0" --notes-file .github/RELEASE_NOTES.md
```

Review the draft and attachments on GitHub before publishing. For later
versions, update the version, changelog, notes, artifact names, and tag together.

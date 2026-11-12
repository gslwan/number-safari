#!/usr/bin/env python3
"""Validate the game and package a web or Windows release using Godot templates."""
import argparse
import hashlib
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import zipfile

ROOT = Path(__file__).resolve().parents[1]
VERSION = "0.1.0"
ENGINE = "4.7.2"
NOTICES = ["README.md", "LICENSE", "THIRD_PARTY_NOTICES.md", "assets/README.md",
           "licenses/MIT.txt", "licenses/CC-BY-4.0.txt", "licenses/GODOT-NOTICES.txt"]


def run(godot, *args):
    subprocess.run([godot, "--headless", "--path", str(ROOT),
                    "--log-file", str(ROOT / "build" / "godot.log"), *args],
                   cwd=ROOT, check=True, timeout=300)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("command", choices=["test", "web", "windows"])
    args = parser.parse_args()
    godot = shutil.which(os.environ.get("GODOT", "godot"))
    if not godot:
        parser.error("Install Godot 4.7.2 or set GODOT to its executable path.")
    actual = subprocess.check_output([godot, "--version"], text=True).strip()
    if not actual.startswith(ENGINE + ".stable."):
        parser.error(f"Expected Godot {ENGINE} stable; found {actual}")
    (ROOT / "build").mkdir(exist_ok=True)
    run(godot, "--editor", "--import")
    for test in sorted((ROOT / "tests").glob("test_*.gd")):
        run(godot, "--script", str(test))
    if args.command == "test":
        return
    web = args.command == "web"
    name = f"NumberSafari-{VERSION}-{'web' if web else 'windows-x86_64'}"
    dist = ROOT / "dist"
    dist.mkdir(exist_ok=True)
    archive = dist / f"{name}.zip"
    if archive.exists():
        parser.error(f"Archive already exists: {archive}; move it before rebuilding.")
    with tempfile.TemporaryDirectory(prefix="number-safari-") as temp:
        package = Path(temp) / name
        package.mkdir()
        executable = package / ("index.html" if web else "NumberSafari.exe")
        run(godot, "--export-release", "Web" if web else "Windows Desktop", str(executable))
        if not executable.is_file() or executable.stat().st_size == 0:
            raise RuntimeError("Godot did not produce an executable")
        for relative in NOTICES:
            target = package / relative
            target.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(ROOT / relative, target)
        with zipfile.ZipFile(archive, "w", zipfile.ZIP_DEFLATED) as output:
            for file in sorted(package.rglob("*")):
                if file.is_file():
                    output.write(file, file.relative_to(package if web else package.parent))
        with zipfile.ZipFile(archive) as output:
            assert output.testzip() is None
            required = ["index.html", "index.js", "index.wasm", "index.pck"] if web else ["NumberSafari.exe"]
            for relative in NOTICES + required:
                assert (relative if web else f"{name}/{relative}") in output.namelist()
    digest = hashlib.sha256(archive.read_bytes()).hexdigest()
    archive.with_suffix(".zip.sha256").write_text(f"{digest}  {archive.name}\n")
    print(f"Release archive: {archive}")


if __name__ == "__main__":
    main()

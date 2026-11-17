"""Portable project checks. Run from any directory with Python 3 and a JDK."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile

ROOT = Path(__file__).resolve().parent.parent

def run(command):
    print("\n> " + " ".join(map(str, command)), flush=True)
    result = subprocess.run(list(map(str, command)), cwd=ROOT, stdout=subprocess.PIPE,
                            stderr=subprocess.STDOUT, text=True, encoding="utf-8", errors="replace", timeout=180)
    print(result.stdout, end="", flush=True)
    if result.returncode or "SCRIPT ERROR:" in result.stdout or "ERROR:" in result.stdout:
        raise SystemExit(f"Check failed (exit {result.returncode}): {command[0]}")

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--godot", default=os.environ.get("GODOT_BIN"))
    parser.add_argument("--java-home", default=os.environ.get("JAVA_HOME"))
    args = parser.parse_args()
    godot = args.godot or shutil.which("godot") or shutil.which("godot4")
    if not godot:
        local = ROOT / "tools" / "Godot_v4.5.1-stable_win64_console.exe"
        godot = str(local) if local.is_file() else None
    if not godot:
        parser.error("Supply --godot /path/to/godot or put Godot on PATH.")
    suffix = ".exe" if os.name == "nt" else ""
    java_home = Path(args.java_home) if args.java_home else next(iter(sorted((ROOT / "tools" / "android").glob("jdk-*"))), None)
    javac = str(java_home / "bin" / ("javac" + suffix)) if java_home else shutil.which("javac")
    java = str(java_home / "bin" / ("java" + suffix)) if java_home else shutil.which("java")
    if not javac or not java:
        parser.error("A JDK is required; supply --java-home or put javac/java on PATH.")
    run([godot, "--headless", "--path", ".", "--editor", "--import", "--quit"])
    for script in ("physics_test.gd", "profiles_test.gd", "world_test.gd", "integration_test.gd", "phone_test.gd"):
        run([godot, "--headless", "--path", ".", "--script", "tests/" + script])
    package = Path("android-controller/src/com/vectorflight/controller")
    tests = Path("android-controller/tests")
    with tempfile.TemporaryDirectory(prefix="vector-java-checks-") as output:
        run([javac, "-encoding", "UTF-8", "-d", output,
             package / "ControlState.java", package / "HapticCues.java",
             tests / "ControlStateTest.java", tests / "HapticCuesTest.java"])
        for test in ("ControlStateTest", "HapticCuesTest"):
            run([java, "-cp", output, "com.vectorflight.controller." + test])
    artifact = ROOT / "dist" / "VectorController.apk"
    expected = (ROOT / "dist" / "VectorController.apk.sha256").read_text().split()[0].lower()
    if hashlib.sha256(artifact.read_bytes()).hexdigest() != expected:
        raise SystemExit("APK checksum does not match dist/VectorController.apk.sha256")
    print("PASS: Distributed APK matches its SHA-256 checksum", flush=True)
    for source in json.loads((ROOT / "assets" / "sources.json").read_text()):
        if hashlib.md5((ROOT / source["file"]).read_bytes()).hexdigest() != source["md5"]:
            raise SystemExit("Environment asset checksum mismatch: " + source["file"])
    print("PASS: Bundled CC0 environment assets match their source checksums", flush=True)
    run([sys.executable, "tests/transfer_test.py"])
    print("\nALL PROJECT CHECKS PASSED", flush=True)

if __name__ == "__main__":
    main()

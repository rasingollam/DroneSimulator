"""Fetch CC0 scenery sources, verifying every upstream checksum.

Run from any directory. Downloads use Poly Haven's public API, with a descriptive
user agent; the resulting game runs offline. Nothing is installed globally.
"""
from concurrent.futures import ThreadPoolExecutor
import hashlib
import json
from pathlib import Path
from urllib.request import Request, urlopen

ROOT = Path(__file__).resolve().parent.parent
HEADERS = {"User-Agent": "VectorFlightLab/1.3 (CC0 Godot scenery integration)"}
MODELS = {"rock_09": "2k", "namaqualand_boulder_02": "2k", "wooden_crate_01": "1k", "barrel_03": "2k", "modular_factory_facade": "1k"}
TEXTURES = {"concrete_wall_001": "concrete", "wood_planks_dirt": "planks", "gravelly_sand": "gravel", "corrugated_iron_02": "corrugated", "forest_ground_04": "forest"}


def get_json(url):
    with urlopen(Request(url, headers=HEADERS), timeout=60) as response:
        return json.load(response)


def task(asset, entry, destination, channel):
    return dict(asset=asset, channel=channel, file=destination, url=entry["url"],
                md5=entry["md5"], source="https://polyhaven.com/a/" + asset,
                license="CC0-1.0", license_url="https://polyhaven.com/license")


def main():
    jobs = []
    for asset, resolution in MODELS.items():
        entry = get_json("https://api.polyhaven.com/files/" + asset)["gltf"][resolution]["gltf"]
        base = "assets/models/" + asset + "/"
        jobs.append(task(asset, entry, base + asset + "_" + resolution + ".gltf", "glTF"))
        for name, dependency in entry["include"].items():
            jobs.append(task(asset, dependency, base + name, "glTF dependency"))
    for asset, label in TEXTURES.items():
        data = get_json("https://api.polyhaven.com/files/" + asset)
        for channel, suffix in [("Diffuse", "color"), ("nor_gl", "normal"), ("Rough", "roughness")]:
            entry = data[channel]["2k"]["jpg"]
            jobs.append(task(asset, entry, "assets/environment/" + label + "_" + suffix + ".jpg", channel))

    def fetch(job):
        path = ROOT / job["file"]
        if not path.is_file() or hashlib.md5(path.read_bytes()).hexdigest() != job["md5"]:
            with urlopen(Request(job["url"], headers=HEADERS), timeout=180) as response:
                data = response.read()
            if hashlib.md5(data).hexdigest() != job["md5"]:
                raise ValueError("Upstream checksum mismatch: " + job["file"])
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_bytes(data)
        print("Verified", job["file"], path.stat().st_size, flush=True)

    with ThreadPoolExecutor(max_workers=3) as pool:
        list(pool.map(fetch, jobs))
    manifest = ROOT / "assets/sources.json"
    old = {entry["file"]: entry for entry in json.loads(manifest.read_text())}
    old.update({entry["file"]: entry for entry in jobs})
    manifest.write_text(json.dumps(list(old.values()), indent=2) + "\n")
    print("All scenery files verified; source and license manifest updated.")


if __name__ == "__main__":
    main()

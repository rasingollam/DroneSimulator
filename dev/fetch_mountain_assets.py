"""Download checksum-verified CC0 alpine materials and a sunset HDR panorama."""
from concurrent.futures import ThreadPoolExecutor
import hashlib
import json
from urllib.request import Request, urlopen
from fetch_scenery_assets import ROOT, HEADERS, get_json, task


def main():
    jobs = []
    for asset, label in [('rock_face', 'cliff'), ('rocky_terrain', 'scree'), ('snow_02', 'snow')]:
        data = get_json('https://api.polyhaven.com/files/' + asset)
        for channel, suffix in [('Diffuse', 'color'), ('nor_gl', 'normal'), ('Rough', 'roughness')]:
            jobs.append(task(asset, data[channel]['2k']['jpg'], 'assets/environment/%s_%s.jpg' % (label, suffix), channel))
    asset = 'kiara_8_sunset'
    data = get_json('https://api.polyhaven.com/files/' + asset)
    jobs.append(task(asset, data['hdri']['2k']['hdr'], 'assets/environment/sunset.hdr', 'hdri'))
    def fetch(job):
        path = ROOT / job['file']
        if not path.exists() or hashlib.md5(path.read_bytes()).hexdigest() != job['md5']:
            with urlopen(Request(job['url'], headers=HEADERS), timeout=180) as response:
                content = response.read()
            assert hashlib.md5(content).hexdigest() == job['md5']
            path.write_bytes(content)
        print('Verified', job['file'], flush=True)
    with ThreadPoolExecutor(max_workers=3) as pool:
        list(pool.map(fetch, jobs))
    manifest = ROOT / 'assets/sources.json'
    sources = {entry['file']: entry for entry in json.loads(manifest.read_text(encoding="utf-8"))}
    sources.update({entry['file']: entry for entry in jobs})
    manifest.write_text(json.dumps(list(sources.values()), indent=2) + '\n', encoding='utf-8')


if __name__ == '__main__':
    main()

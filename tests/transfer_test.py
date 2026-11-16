"""Verify LAN APK delivery and that arbitrary project files cannot be downloaded."""
import importlib.util
from http.server import ThreadingHTTPServer
from pathlib import Path
from threading import Thread
from urllib.request import urlopen
from urllib.error import HTTPError

root = Path(__file__).resolve().parent.parent
spec = importlib.util.spec_from_file_location("serve_apk", root / "android-controller" / "serve_apk.py")
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)
server = ThreadingHTTPServer(("127.0.0.1", 0), module.Handler)
Thread(target=server.serve_forever, daemon=True).start()
base = f"http://127.0.0.1:{server.server_port}"
try:
    with urlopen(base + "/") as response:
        assert b"VectorController.apk" in response.read()
    print("PASS: Installation page links the APK")
    with urlopen(base + "/VectorController.apk") as response:
        assert response.headers["Content-Type"] == "application/vnd.android.package-archive"
        assert response.read() == module.APK.read_bytes()
    print("PASS: APK download is complete and byte-identical")
    for route in ("/../tools/android/controller-local.jks", "/README.md", "/android-controller/src/"):
        try:
            urlopen(base + route)
            raise AssertionError("Project file was exposed: " + route)
        except HTTPError as failure:
            assert failure.code == 404
    print("PASS: Other project files and signing key cannot be downloaded")
finally:
    server.shutdown()
    server.server_close()

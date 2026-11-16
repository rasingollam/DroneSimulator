"""Optional LAN transfer helper. Serves only the APK and an installation page."""
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
import socket

APK = Path(__file__).resolve().parent.parent / "dist" / "VectorController.apk"
PAGE = b"""<!doctype html><html><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Vector Controller</title><style>body{background:#0b1c23;color:#e1eee9;font:18px system-ui;max-width:580px;margin:50px auto;padding:24px;line-height:1.6}a{display:block;background:#6ef0ce;color:#0b1c23;padding:18px;text-align:center;border-radius:12px;font-weight:bold;text-decoration:none}small{color:#94aaaa}</style>
<h1>Vector Controller</h1><p>Two touch sticks for your PC drone simulator.</p>
<a href="/VectorController.apk">Download Android APK</a>
<p>Open the download on your phone. If prompted, allow your browser to install this app.</p>
<p>Launch the PC simulator and press <b>F2</b>. In the app, enter the PC address and pairing code. Tap <b>START / RESUME</b>, then <b>ARM</b>.</p>
<small>Android 6.0 or newer. Phone and PC must be on the same private Wi-Fi network. Close the transfer window when finished.</small></html>"""

class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path in ("/", "/index.html"):
            data, content_type = PAGE, "text/html; charset=utf-8"
        elif self.path == "/VectorController.apk":
            data, content_type = APK.read_bytes(), "application/vnd.android.package-archive"
        else:
            self.send_error(404)
            return
        self.send_response(200)
        self.send_header("Content-Type", content_type)
        self.send_header("Content-Length", str(len(data)))
        self.send_header("Cache-Control", "no-store")
        if self.path == "/VectorController.apk":
            self.send_header("Content-Disposition", 'attachment; filename="VectorController.apk"')
        self.end_headers()
        self.wfile.write(data)

if __name__ == "__main__":
    if not APK.is_file():
        raise SystemExit("Build dist/VectorController.apk first.")
    addresses = sorted({item[4][0] for item in socket.getaddrinfo(socket.gethostname(), None, socket.AF_INET)})
    print("On your phone, open one of these addresses in its browser:", flush=True)
    for address in addresses:
        if not address.startswith("127."):
            print(f"  http://{address}:8765", flush=True)
    print("Same Wi-Fi required. If Windows asks, allow Python on Private networks.\nOnly the APK and this installation page are served. Ctrl+C stops sharing.", flush=True)
    try:
        ThreadingHTTPServer(("0.0.0.0", 8765), Handler).serve_forever()
    except KeyboardInterrupt:
        print("APK sharing stopped.")

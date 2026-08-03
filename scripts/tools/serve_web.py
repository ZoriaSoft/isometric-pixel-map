#!/usr/bin/env python3
"""Local web export server — COOP/COEP + correct MIME."""
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
import os
import sys

ROOT = os.path.join(os.path.dirname(__file__), "../../build/web")
ROOT = os.path.abspath(ROOT)
PORT = int(sys.argv[1]) if len(sys.argv) > 1 else 8770

if not os.path.isdir(ROOT) or not os.path.isfile(os.path.join(ROOT, "index.html")):
    print("FAIL: build/web/index.html missing — run scripts/tools/export_web.sh first", flush=True)
    sys.exit(1)

os.chdir(ROOT)


class H(SimpleHTTPRequestHandler):
    extensions_map = {
        **SimpleHTTPRequestHandler.extensions_map,
        ".wasm": "application/wasm",
        ".pck": "application/octet-stream",
        ".js": "application/javascript",
    }

    def end_headers(self):
        self.send_header("Cross-Origin-Opener-Policy", "same-origin")
        self.send_header("Cross-Origin-Embedder-Policy", "credentialless")
        self.send_header("Cache-Control", "no-cache")
        super().end_headers()

    def log_message(self, fmt, *args):
        print("[%s] %s" % (self.log_date_time_string(), fmt % args), flush=True)


print("Serving", ROOT, "on :%d" % PORT, flush=True)
print("Open http://127.0.0.1:%d/" % PORT, flush=True)
ThreadingHTTPServer(("0.0.0.0", PORT), H).serve_forever()
